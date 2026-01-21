# Nightly API Documentation

> **Base URL:** `http://localhost:8000/api`
> **Auth:** JWT Bearer tokens
> **Content-Type:** `application/json`

---

## Quick Start

```bash
# Start the API
pip install fastapi uvicorn psycopg2-binary pyjwt
uvicorn api.main:app --reload

# API docs available at http://localhost:8000/docs
```

---

## Authentication

All endpoints except `/auth/*` require a Bearer token in the header:
```
Authorization: Bearer <access_token>
```

### POST /api/auth/register
Create a new user account.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword",
  "name": "John Doe",
  "age": 22,
  "gender": 2
}
```
> Gender: 1=female, 2=male, 3=nonbinary, 4=prefer not to say

**Response:**
```json
{
  "access_token": "eyJ...",
  "refresh_token": "eyJ...",
  "token_type": "bearer",
  "expires_in": 86400,
  "user_id": 1
}
```

### POST /api/auth/login
Login with email and password.

**Request:**
```json
{
  "email": "user@example.com",
  "password": "securepassword"
}
```

**Response:** Same as register

### POST /api/auth/refresh
Get new access token using refresh token.

**Request:**
```json
{
  "refresh_token": "eyJ..."
}
```

**Response:** Same as register

### GET /api/auth/me
Get current authenticated user.

**Response:**
```json
{
  "id": 1,
  "email": "user@example.com",
  "name": "John Doe",
  "age": 22,
  "gender": 2,
  "drinking_level": 5,
  "smoking_level": 2,
  "weed_level": 3,
  "is_verified": false
}
```

---

## Core Endpoints

### Users
| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | `/auth/me` | Get current user |
| GET | `/users/me/groups` | Get user's groups |

### Groups
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/groups` | Create a group |
| GET | `/groups/:id` | Get group details |
| GET | `/groups/:id/members` | Get group members |
| POST | `/groups/:id/members?user_id=X` | Add user to group |
| DELETE | `/groups/:id/members/:uid` | Remove user from group |
| GET | `/groups/:id/tendencies` | Get calculated tendencies |
| POST | `/groups/:id/sync` | Sync from user data |

### Availability & Matching
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/groups/:id/activate` | Mark group as active tonight |
| DELETE | `/groups/:id/activate` | Deactivate group |
| GET | `/groups/:id/matches` | Get ranked matches |
| GET | `/groups/:id/mutual` | Get mutual matches |

### Interactions
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/groups/:id/like/:other` | Like another group |

---

## Detailed Endpoint Documentation

### POST /api/groups
Create a new group.

**Request:**
```json
{
  "target_lat": 45.5017,
  "target_lon": -73.5673,
  "travel_radius_km": 15,
  "ideal_activity": "bar hopping",
  "ideal_group_size": 6,
  "sexuality_inclusive": true,
  "accessibility_friendly": false
}
```

**Response:**
```json
{
  "group_id": 1,
  "message": "Group created"
}
```

---

### GET /api/users/me/groups
Get all groups the current user belongs to.

**Response:**
```json
[
  {
    "id": 1,
    "age_range": "21-25",
    "num_people": 4,
    "target_lat": 45.5017,
    "target_lon": -73.5673,
    "travel_radius_km": 15,
    "ideal_activity": "bar hopping",
    "active_until": "2025-01-22T04:00:00Z"
  }
]
```

---

### POST /api/groups/:id/activate
Mark group as active for tonight.

**Request:**
```json
{
  "target_lat": 45.5017,
  "target_lon": -73.5673,
  "travel_radius_km": 15,
  "ideal_activity": "bar hopping",
  "active_until": "2025-01-22T04:00:00Z"
}
```

**Response:**
```json
{
  "status": "active",
  "group_id": 1,
  "active_until": "2025-01-22T04:00:00Z",
  "potential_matches": 12
}
```

---

### GET /api/groups/:id/matches
Get ranked matches for a group.

**Query params:** `?limit=20&offset=0`

**Response:**
```json
[
  {
    "group_id": 13,
    "match_score": 99.1,
    "distance_km": 3.3,
    "age_range": "21-25",
    "num_people": 4,
    "ideal_activity": "bar hopping",
    "location_score": 0.974,
    "age_score": 1.0,
    "lifestyle_score": 0.996,
    "activity_score": 1.0,
    "lang_score": 1.0,
    "mutual_interest": false
  },
  {
    "group_id": 17,
    "match_score": 98.6,
    "distance_km": 0.9,
    "age_range": "20-26",
    "num_people": 3,
    "ideal_activity": "bar hopping",
    "location_score": 0.994,
    "age_score": 1.0,
    "lifestyle_score": 0.992,
    "activity_score": 1.0,
    "lang_score": 1.0,
    "mutual_interest": true
  }
]
```

---

### POST /api/groups/:id/like/:other_id
Express interest in another group.

**Response (no mutual match):**
```json
{
  "status": "liked",
  "mutual": false,
  "message": "Interest recorded"
}
```

**Response (mutual match!):**
```json
{
  "status": "liked",
  "mutual": true,
  "message": "It's a match!"
}
```

---

### GET /api/groups/:id/mutual
Get all mutual matches (both groups liked each other).

**Response:**
```json
[
  {
    "id": 17,
    "age_range": "20-26",
    "num_people": 3,
    "ideal_activity": "bar hopping",
    "match_score": 98.6,
    "distance_km": 0.9
  }
]
```

---

### GET /api/groups/:id/tendencies
Get calculated group stats from user data.

**Response:**
```json
{
  "group_id": 1,
  "num_people": 4,
  "num_women": 2,
  "num_men": 2,
  "num_nonbinary": 0,
  "age_range": "21-24",
  "avg_age": 22.5,
  "drinking_level": 7,
  "smoking_level": 2,
  "weed_level": 5
}
```

---

## Database Queries Behind the API

### Get matches for a group
```sql
SELECT * FROM match_scores
WHERE (group_a = $1 OR group_b = $1)
  AND group_a IN (SELECT id FROM groups WHERE active_until > NOW())
  AND group_b IN (SELECT id FROM groups WHERE active_until > NOW())
ORDER BY match_score DESC
LIMIT 20 OFFSET $2;
```

### Check mutual interest
```sql
SELECT EXISTS (
  SELECT 1 FROM group_likes
  WHERE liker_id = $other AND liked_id = $me
) as they_like_us;
```

---

## Frontend Flow

```
1. User opens app
   └─▶ GET /api/users/me
   └─▶ GET /api/groups (user's groups)

2. User taps "Go Out Tonight" on a group
   └─▶ POST /api/groups/:id/activate
       └─▶ Backend: marks group active, triggers matching

3. App shows potential matches
   └─▶ GET /api/groups/:id/matches
       └─▶ Backend: queries match_scores view, filters active groups

4. User swipes right (likes a group)
   └─▶ POST /api/groups/:id/like/:other
       └─▶ Backend: records like, checks for mutual
       └─▶ If mutual: notify both groups, enable chat

5. User views mutual matches
   └─▶ GET /api/groups/:id/mutual
       └─▶ Shows groups where both sides liked each other
```

---

## Real-time Updates (WebSocket)

For live updates when:
- A new group activates nearby
- Someone likes your group
- Mutual match occurs

```javascript
// Frontend WebSocket connection
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);

  switch(data.type) {
    case 'NEW_MATCH':
      // Refresh match list
      break;
    case 'MUTUAL_MATCH':
      // Show celebration, enable chat
      break;
    case 'GROUP_LIKED_YOU':
      // Show notification
      break;
  }
};
```

---

## Error Responses

All errors return this format:
```json
{
  "detail": "Error message here"
}
```

| Status Code | Meaning |
|-------------|---------|
| 400 | Bad request (validation error) |
| 401 | Unauthorized (invalid/expired token) |
| 403 | Forbidden (not a member of group) |
| 404 | Not found |
| 500 | Server error |

---

## Flutter Integration Notes

### Base URL Configuration
```dart
// Development
const String baseUrl = 'http://10.0.2.2:8000/api';  // Android emulator
const String baseUrl = 'http://localhost:8000/api'; // iOS simulator

// Production
const String baseUrl = 'https://api.nightly.app/api';
```

### Token Storage
Store tokens securely using `flutter_secure_storage`:
```dart
final storage = FlutterSecureStorage();
await storage.write(key: 'access_token', value: token);
```

### Auto-refresh Token
Implement interceptor to refresh token on 401:
```dart
if (response.statusCode == 401) {
  final newToken = await refreshToken();
  // Retry request with new token
}
```

### Required Headers
```dart
headers: {
  'Content-Type': 'application/json',
  'Authorization': 'Bearer $accessToken',
}
```

---

## Tech Stack

| Layer | Technology |
|-------|------------|
| Frontend | Flutter (your team) |
| Backend | FastAPI (Python) |
| Database | PostgreSQL + matching functions |
| Auth | JWT tokens |

---

## Caching Strategy

Match scores don't change unless groups update their profiles.

```python
# Cache key: f"matches:{group_id}:{hash(group_preferences)}"
# TTL: 5 minutes while group is active

def get_matches(group_id):
    cache_key = f"matches:{group_id}"

    cached = redis.get(cache_key)
    if cached:
        return json.loads(cached)

    # Query database
    matches = db.query(match_scores).filter(...)

    # Cache for 5 min
    redis.setex(cache_key, 300, json.dumps(matches))

    return matches
```

Invalidate cache when:
- Group updates preferences
- Group activates/deactivates
- User joins/leaves group (triggers tendency recalc)
