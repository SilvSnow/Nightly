"""
Nightly API - FastAPI Backend
Run with: uvicorn api.main:app --reload
"""

from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, List
from datetime import datetime
import psycopg2
from psycopg2.extras import RealDictCursor
from contextlib import contextmanager

from api.auth import (
    get_current_user,
    get_current_user_optional,
    create_access_token,
    create_refresh_token,
    decode_token,
    hash_password,
    verify_password,
    UserRegister,
    UserLogin,
    TokenResponse,
    TokenRefresh,
    UserResponse,
    ACCESS_TOKEN_EXPIRE_MINUTES,
)

app = FastAPI(
    title="Nightly API",
    version="1.0.0",
    description="Group matching API for nightlife activities",
)

# CORS for frontend
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Database connection
DB_CONFIG = {
    "host": "localhost",
    "database": "postgres",
    "user": "postgres",
    "password": "postgres",  # Change this / use env var
}

@contextmanager
def get_db():
    conn = psycopg2.connect(**DB_CONFIG, cursor_factory=RealDictCursor)
    try:
        yield conn
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        conn.close()


# ============================================
# Pydantic Models
# ============================================

class TargetLocation(BaseModel):
    label: Optional[str] = None
    target_lat: float
    target_lon: float
    travel_radius_km: float = 15.0


class GroupActivate(BaseModel):
    target_lat: Optional[float] = None
    target_lon: Optional[float] = None
    travel_radius_km: Optional[float] = None
    locations: Optional[List[TargetLocation]] = None
    ideal_activity: str
    active_until: datetime


class MatchResponse(BaseModel):
    group_id: int
    match_score: float
    distance_km: float
    age_range: str
    num_people: int
    ideal_activity: str
    location_score: float
    age_score: float
    lifestyle_score: float
    activity_score: float
    lang_score: float
    mutual_interest: bool = False


class GroupTendencies(BaseModel):
    group_id: int
    num_people: int
    num_women: int
    num_men: int
    num_nonbinary: int
    age_range: str
    avg_age: float
    drinking_level: Optional[int]
    smoking_level: Optional[int]
    weed_level: Optional[int]


# ============================================
# Endpoints
# ============================================

@app.get("/")
def root():
    return {"message": "Nightly API", "version": "1.0.0"}


# ============================================
# Authentication Endpoints
# ============================================

@app.post("/api/auth/register", response_model=TokenResponse)
def register(data: UserRegister):
    """Register a new user account."""
    with get_db() as conn:
        cur = conn.cursor()

        # Check if email already exists
        cur.execute("SELECT id FROM users WHERE email = %s", (data.email,))
        if cur.fetchone():
            raise HTTPException(status_code=400, detail="Email already registered")

        # Hash password and create user
        password_hash = hash_password(data.password)
        cur.execute("""
            INSERT INTO users (name, email, age, gender, password_hash)
            VALUES (%s, %s, %s, %s, %s)
            RETURNING id
        """, (data.name, data.email, data.age, data.gender, password_hash))

        user_id = cur.fetchone()['id']

    # Generate tokens
    access_token = create_access_token(user_id, data.email)
    refresh_token = create_refresh_token(user_id)

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user_id,
    )


@app.post("/api/auth/login", response_model=TokenResponse)
def login(data: UserLogin):
    """Login with email and password."""
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT id, email, password_hash FROM users
            WHERE email = %s AND deleted_at IS NULL
        """, (data.email,))
        user = cur.fetchone()

    if not user or not verify_password(data.password, user['password_hash']):
        raise HTTPException(status_code=401, detail="Invalid email or password")

    # Generate tokens
    access_token = create_access_token(user['id'], user['email'])
    refresh_token = create_refresh_token(user['id'])

    return TokenResponse(
        access_token=access_token,
        refresh_token=refresh_token,
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user['id'],
    )


@app.post("/api/auth/refresh", response_model=TokenResponse)
def refresh_token(data: TokenRefresh):
    """Get new access token using refresh token."""
    payload = decode_token(data.refresh_token)

    if payload.get("type") != "refresh":
        raise HTTPException(status_code=401, detail="Invalid token type")

    user_id = int(payload["sub"])

    # Verify user still exists
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("SELECT id, email FROM users WHERE id = %s AND deleted_at IS NULL", (user_id,))
        user = cur.fetchone()

    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    # Generate new tokens
    access_token = create_access_token(user['id'], user['email'])
    new_refresh_token = create_refresh_token(user['id'])

    return TokenResponse(
        access_token=access_token,
        refresh_token=new_refresh_token,
        expires_in=ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        user_id=user['id'],
    )


@app.get("/api/auth/me", response_model=UserResponse)
def get_me(current_user: dict = Depends(get_current_user)):
    """Get current authenticated user."""
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT id, email, name, age, gender, drinking_level, smoking_level,
                   weed_level, is_verified
            FROM users WHERE id = %s
        """, (current_user['user_id'],))
        user = cur.fetchone()

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    return UserResponse(**user)


class UserPreferences(BaseModel):
    drinking_level: Optional[int] = None
    smoking_level: Optional[int] = None
    weed_level: Optional[int] = None
    language_ids: Optional[List[int]] = None


@app.post("/api/users/me/preferences")
def update_preferences(data: UserPreferences, current_user: dict = Depends(get_current_user)):
    """Update user preferences (drinking, smoking, weed, languages)."""
    with get_db() as conn:
        cur = conn.cursor()

        # Update user preferences
        cur.execute("""
            UPDATE users SET
                drinking_level = COALESCE(%s, drinking_level),
                smoking_level = COALESCE(%s, smoking_level),
                weed_level = COALESCE(%s, weed_level)
            WHERE id = %s
        """, (data.drinking_level, data.smoking_level, data.weed_level, current_user['user_id']))

    return {"message": "Preferences updated"}


class GroupCreate(BaseModel):
    target_lat: Optional[float] = None
    target_lon: Optional[float] = None
    travel_radius_km: Optional[float] = 15
    ideal_activity: Optional[str] = None
    ideal_group_size: Optional[int] = None
    sexuality_inclusive: bool = True
    accessibility_friendly: bool = False


@app.get("/api/users/me/groups")
def get_my_groups(current_user: dict = Depends(get_current_user)):
    """Get all groups the current user belongs to."""
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT g.* FROM groups g
            JOIN group_memberships gm ON g.id = gm.group_id
            WHERE gm.user_id = %s
            ORDER BY g.created_at DESC
        """, (current_user['user_id'],))
        groups = cur.fetchall()

    return [dict(g) for g in groups]


@app.post("/api/groups")
def create_group(data: GroupCreate, current_user: dict = Depends(get_current_user)):
    """Create a new group and add current user as member."""
    with get_db() as conn:
        cur = conn.cursor()

        # Get user info for group defaults
        cur.execute("""
            SELECT age, drinking_level, smoking_level, weed_level
            FROM users WHERE id = %s
        """, (current_user['user_id'],))
        user = cur.fetchone()
        user_age = user['age'] if user else 21
        age_range = f"{user_age}-{user_age}"

        # Create group with user's data
        cur.execute("""
            INSERT INTO groups (
                target_lat, target_lon, travel_radius_km, ideal_activity,
                ideal_group_size, sexuality_inclusive, accessibility_friendly,
                num_people, age_range, drinking_level, smoking_level, weed_level
            ) VALUES (%s, %s, %s, %s, %s, %s, %s, 1, %s, %s, %s, %s)
            RETURNING id
        """, (
            data.target_lat, data.target_lon, data.travel_radius_km,
            data.ideal_activity, data.ideal_group_size,
            data.sexuality_inclusive, data.accessibility_friendly,
            age_range,
            user['drinking_level'] if user else 5,
            user['smoking_level'] if user else 1,
            user['weed_level'] if user else 1,
        ))
        group_id = cur.fetchone()['id']

        # Add creator as member
        cur.execute("""
            INSERT INTO group_memberships (group_id, user_id)
            VALUES (%s, %s)
        """, (group_id, current_user['user_id']))

    return {"group_id": group_id, "message": "Group created"}


@app.get("/api/groups/{group_id}")
def get_group(group_id: int, current_user: dict = Depends(get_current_user)):
    """Get group details."""
    with get_db() as conn:
        cur = conn.cursor()

        # Verify user is member of group
        cur.execute("""
            SELECT 1 FROM group_memberships
            WHERE group_id = %s AND user_id = %s
        """, (group_id, current_user['user_id']))

        if not cur.fetchone():
            raise HTTPException(status_code=403, detail="Not a member of this group")

        cur.execute("SELECT * FROM groups WHERE id = %s", (group_id,))
        group = cur.fetchone()

    if not group:
        raise HTTPException(status_code=404, detail="Group not found")

    return dict(group)


@app.get("/api/groups/{group_id}/members")
def get_group_members(group_id: int, current_user: dict = Depends(get_current_user)):
    """Get all members of a group."""
    with get_db() as conn:
        cur = conn.cursor()

        # Verify user is member
        cur.execute("""
            SELECT 1 FROM group_memberships
            WHERE group_id = %s AND user_id = %s
        """, (group_id, current_user['user_id']))

        if not cur.fetchone():
            raise HTTPException(status_code=403, detail="Not a member of this group")

        cur.execute("""
            SELECT u.id, u.name, u.age, u.gender, u.profile_picture_url
            FROM users u
            JOIN group_memberships gm ON u.id = gm.user_id
            WHERE gm.group_id = %s
        """, (group_id,))
        members = cur.fetchall()

    return [dict(m) for m in members]


@app.post("/api/groups/{group_id}/members")
def add_group_member(group_id: int, user_id: int, current_user: dict = Depends(get_current_user)):
    """Add a user to a group (must be group member to add others)."""
    with get_db() as conn:
        cur = conn.cursor()

        # Verify current user is member
        cur.execute("""
            SELECT 1 FROM group_memberships
            WHERE group_id = %s AND user_id = %s
        """, (group_id, current_user['user_id']))

        if not cur.fetchone():
            raise HTTPException(status_code=403, detail="Not a member of this group")

        # Add new member
        cur.execute("""
            INSERT INTO group_memberships (group_id, user_id)
            VALUES (%s, %s)
            ON CONFLICT DO NOTHING
        """, (group_id, user_id))

    return {"message": "Member added", "group_id": group_id, "user_id": user_id}


@app.delete("/api/groups/{group_id}/members/{user_id}")
def remove_group_member(group_id: int, user_id: int, current_user: dict = Depends(get_current_user)):
    """Remove a user from a group."""
    with get_db() as conn:
        cur = conn.cursor()

        # Verify current user is member
        cur.execute("""
            SELECT 1 FROM group_memberships
            WHERE group_id = %s AND user_id = %s
        """, (group_id, current_user['user_id']))

        if not cur.fetchone():
            raise HTTPException(status_code=403, detail="Not a member of this group")

        cur.execute("""
            DELETE FROM group_memberships
            WHERE group_id = %s AND user_id = %s
        """, (group_id, user_id))

    return {"message": "Member removed"}


def verify_group_membership(cur, group_id: int, user_id: int):
    """Helper to verify user is member of group."""
    cur.execute("""
        SELECT 1 FROM group_memberships
        WHERE group_id = %s AND user_id = %s
    """, (group_id, user_id))
    if not cur.fetchone():
        raise HTTPException(status_code=403, detail="Not a member of this group")


@app.post("/api/groups/{group_id}/activate")
def activate_group(group_id: int, data: GroupActivate, current_user: dict = Depends(get_current_user)):
    """Mark a group as active for tonight."""
    # Normalize to locations list
    if data.locations:
        locations = data.locations
    elif data.target_lat is not None and data.target_lon is not None:
        locations = [TargetLocation(
            target_lat=data.target_lat,
            target_lon=data.target_lon,
            travel_radius_km=data.travel_radius_km or 15.0,
        )]
    else:
        raise HTTPException(status_code=400, detail="Provide 'locations' or legacy lat/lon fields")

    if len(locations) < 1 or len(locations) > 5:
        raise HTTPException(status_code=400, detail="Must have between 1 and 5 locations")

    with get_db() as conn:
        cur = conn.cursor()

        verify_group_membership(cur, group_id, current_user['user_id'])

        first = locations[0]

        # Update group with activation data (legacy columns use first location)
        cur.execute("""
            UPDATE groups SET
                target_lat = %s,
                target_lon = %s,
                travel_radius_km = %s,
                ideal_activity = %s,
                active_until = %s
            WHERE id = %s
            RETURNING id
        """, (
            first.target_lat,
            first.target_lon,
            first.travel_radius_km,
            data.ideal_activity,
            data.active_until,
            group_id
        ))

        if cur.fetchone() is None:
            raise HTTPException(status_code=404, detail="Group not found")

        # Replace group_locations (delete-then-insert)
        cur.execute("DELETE FROM group_locations WHERE group_id = %s", (group_id,))
        for loc in locations:
            cur.execute("""
                INSERT INTO group_locations (group_id, label, target_lat, target_lon, travel_radius_km)
                VALUES (%s, %s, %s, %s, %s)
            """, (group_id, loc.label, loc.target_lat, loc.target_lon, loc.travel_radius_km))

        # Count potential matches
        cur.execute("""
            SELECT COUNT(*) as count FROM match_scores
            WHERE group_a = %s OR group_b = %s
        """, (group_id, group_id))
        match_count = cur.fetchone()['count']

    return {
        "status": "active",
        "group_id": group_id,
        "active_until": data.active_until.isoformat(),
        "potential_matches": match_count
    }


@app.delete("/api/groups/{group_id}/activate")
def deactivate_group(group_id: int, current_user: dict = Depends(get_current_user)):
    """Deactivate a group (not going out anymore)."""
    with get_db() as conn:
        cur = conn.cursor()

        verify_group_membership(cur, group_id, current_user['user_id'])

        cur.execute("""
            UPDATE groups SET active_until = NULL
            WHERE id = %s
            RETURNING id
        """, (group_id,))

        if cur.fetchone() is None:
            raise HTTPException(status_code=404, detail="Group not found")

        cur.execute("DELETE FROM group_locations WHERE group_id = %s", (group_id,))

    return {"status": "deactivated", "group_id": group_id}


@app.get("/api/groups/{group_id}/locations")
def get_group_locations(group_id: int, current_user: dict = Depends(get_current_user)):
    """Get all target locations for a group."""
    with get_db() as conn:
        cur = conn.cursor()

        verify_group_membership(cur, group_id, current_user['user_id'])

        cur.execute("""
            SELECT id, label, target_lat, target_lon, travel_radius_km, created_at
            FROM group_locations
            WHERE group_id = %s
            ORDER BY id
        """, (group_id,))
        locations = cur.fetchall()

    return [dict(loc) for loc in locations]


@app.get("/api/groups/{group_id}/matches", response_model=List[MatchResponse])
def get_matches(group_id: int, limit: int = 20, offset: int = 0, current_user: dict = Depends(get_current_user)):
    """Get ranked matches for a group."""
    with get_db() as conn:
        cur = conn.cursor()

        verify_group_membership(cur, group_id, current_user['user_id'])

        # Get matches from the view (only active groups)
        cur.execute("""
            SELECT
                CASE WHEN ms.group_a = %s THEN ms.group_b ELSE ms.group_a END as matched_group_id,
                ms.match_score,
                ms.distance_km,
                ms.location_score,
                ms.age_score,
                ms.lifestyle_score,
                ms.activity_score,
                ms.lang_score
            FROM match_scores ms
            JOIN groups g ON g.id = CASE WHEN ms.group_a = %s THEN ms.group_b ELSE ms.group_a END
            WHERE (ms.group_a = %s OR ms.group_b = %s)
              AND g.active_until > NOW()
            ORDER BY ms.match_score DESC
            LIMIT %s OFFSET %s
        """, (group_id, group_id, group_id, group_id, limit, offset))

        matches = cur.fetchall()

        # Enrich with group details and check mutual interest
        result = []
        for match in matches:
            matched_id = match['matched_group_id']

            cur.execute("""
                SELECT age_range, num_people, ideal_activity
                FROM groups WHERE id = %s
            """, (matched_id,))
            group_info = cur.fetchone()

            # Check if they liked us (mutual interest)
            cur.execute("""
                SELECT 1 FROM group_likes
                WHERE liker_id = %s AND liked_id = %s
            """, (matched_id, group_id))
            they_like_us = cur.fetchone() is not None

            result.append(MatchResponse(
                group_id=matched_id,
                match_score=float(match['match_score']),
                distance_km=float(match['distance_km']),
                age_range=group_info['age_range'] or "18-99",
                num_people=group_info['num_people'] or 1,
                ideal_activity=group_info['ideal_activity'] or "",
                location_score=float(match['location_score']),
                age_score=float(match['age_score']),
                lifestyle_score=float(match['lifestyle_score']),
                activity_score=float(match['activity_score']),
                lang_score=float(match['lang_score']),
                mutual_interest=they_like_us
            ))

    return result


@app.get("/api/groups/{group_id}/tendencies", response_model=GroupTendencies)
def get_group_tendencies(group_id: int, current_user: dict = Depends(get_current_user)):
    """Get calculated group tendencies from user data."""
    with get_db() as conn:
        cur = conn.cursor()

        verify_group_membership(cur, group_id, current_user['user_id'])

        cur.execute("""
            SELECT * FROM group_tendencies WHERE group_id = %s
        """, (group_id,))
        tendencies = cur.fetchone()

    if not tendencies:
        raise HTTPException(status_code=404, detail="Group has no members")

    return GroupTendencies(**tendencies)


@app.post("/api/groups/{group_id}/sync")
def sync_group(group_id: int, current_user: dict = Depends(get_current_user)):
    """Sync group attributes from user tendencies."""
    with get_db() as conn:
        cur = conn.cursor()

        verify_group_membership(cur, group_id, current_user['user_id'])

        cur.execute("SELECT sync_group_from_users(%s)", (group_id,))

    return {"status": "synced", "group_id": group_id}


@app.post("/api/groups/{group_id}/like/{other_id}")
def like_group(group_id: int, other_id: int, current_user: dict = Depends(get_current_user)):
    """Express interest in another group."""
    with get_db() as conn:
        cur = conn.cursor()

        verify_group_membership(cur, group_id, current_user['user_id'])

        # Check if other group already liked us (mutual match!)
        cur.execute("""
            SELECT EXISTS (
                SELECT 1 FROM group_likes
                WHERE liker_id = %s AND liked_id = %s
            ) as mutual
        """, (other_id, group_id))
        is_mutual = cur.fetchone()['mutual']

        # Record our like
        cur.execute("""
            INSERT INTO group_likes (liker_id, liked_id, created_at)
            VALUES (%s, %s, NOW())
            ON CONFLICT (liker_id, liked_id) DO NOTHING
        """, (group_id, other_id))

    return {
        "status": "liked",
        "mutual": is_mutual,
        "message": "It's a match!" if is_mutual else "Interest recorded"
    }


@app.get("/api/groups/{group_id}/mutual")
def get_mutual_matches(group_id: int, current_user: dict = Depends(get_current_user)):
    """Get groups where both sides have liked each other."""
    with get_db() as conn:
        cur = conn.cursor()

        verify_group_membership(cur, group_id, current_user['user_id'])

        # Find mutual matches
        cur.execute("""
            SELECT g.id as group_id, g.age_range, g.num_people, g.ideal_activity,
                   COALESCE(ms.match_score, 80) as match_score,
                   COALESCE(ms.distance_km, 0) as distance_km,
                   COALESCE(ms.location_score, 0.8) as location_score,
                   COALESCE(ms.age_score, 0.8) as age_score,
                   COALESCE(ms.lifestyle_score, 0.8) as lifestyle_score,
                   COALESCE(ms.activity_score, 0.8) as activity_score,
                   COALESCE(ms.lang_score, 0.8) as lang_score
            FROM group_likes l1
            JOIN group_likes l2 ON l1.liked_id = l2.liker_id AND l1.liker_id = l2.liked_id
            JOIN groups g ON g.id = l1.liked_id
            LEFT JOIN match_scores ms ON
                (ms.group_a = %s AND ms.group_b = g.id) OR
                (ms.group_b = %s AND ms.group_a = g.id)
            WHERE l1.liker_id = %s
        """, (group_id, group_id, group_id))

        mutual = cur.fetchall()

    return [dict(m) for m in mutual]


@app.get("/api/groups/{group_id}/preview")
def get_group_preview(group_id: int, current_user: dict = Depends(get_current_user)):
    """Get public preview of a group (for viewing matched groups)."""
    with get_db() as conn:
        cur = conn.cursor()

        # Get group info
        cur.execute("""
            SELECT id, age_range, num_people, ideal_activity, target_lat, target_lon
            FROM groups WHERE id = %s
        """, (group_id,))
        group = cur.fetchone()

        if not group:
            raise HTTPException(status_code=404, detail="Group not found")

        # Get members (limited info for privacy)
        cur.execute("""
            SELECT u.name, u.age, u.gender
            FROM users u
            JOIN group_memberships gm ON u.id = gm.user_id
            WHERE gm.group_id = %s
        """, (group_id,))
        members = cur.fetchall()

    return {
        "group": dict(group),
        "members": [dict(m) for m in members]
    }


# ============================================
# Health & Debug
# ============================================

@app.get("/api/health")
def health_check():
    """Health check endpoint."""
    try:
        with get_db() as conn:
            cur = conn.cursor()
            cur.execute("SELECT 1")
        return {"status": "healthy", "database": "connected"}
    except Exception as e:
        return {"status": "unhealthy", "error": str(e)}


@app.get("/api/debug/match-scores")
def debug_match_scores(limit: int = 10):
    """Debug endpoint to view raw match scores."""
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute(f"SELECT * FROM match_scores LIMIT {limit}")
        return cur.fetchall()


@app.get("/api/debug/groups")
def debug_groups():
    """Debug endpoint to view all groups and their status."""
    with get_db() as conn:
        cur = conn.cursor()
        cur.execute("""
            SELECT id, age_range, num_people, target_lat, target_lon,
                   travel_radius_km, ideal_activity, active_until,
                   CASE WHEN active_until > NOW() THEN true ELSE false END as is_active
            FROM groups
            ORDER BY id
        """)
        return cur.fetchall()


# ============================================
# Run with: uvicorn api.main:app --reload
# ============================================
