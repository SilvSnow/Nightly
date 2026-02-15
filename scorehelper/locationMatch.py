import math

def haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
    """
    Calculate the great-circle distance between two points on Earth (in km).
    Uses the Haversine formula.
    """
    R = 6371  # Earth's radius in kilometers

    lat1_rad = math.radians(lat1)
    lat2_rad = math.radians(lat2)
    delta_lat = math.radians(lat2 - lat1)
    delta_lon = math.radians(lon2 - lon1)

    a = (math.sin(delta_lat / 2) ** 2 +
         math.cos(lat1_rad) * math.cos(lat2_rad) * math.sin(delta_lon / 2) ** 2)
    c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a))

    return R * c

def location_match(group_a: dict, group_b: dict) -> tuple[float, float] | tuple[None, float]:
    """
    Calculate location compatibility based on intersection of travel radii.

    Each group specifies:
        - target_lat, target_lon: where they want to go
        - travel_radius_km: how far they're willing to travel

    Scoring logic:
        - combined_radius = radius_a + radius_b (circles just touch at this distance)
        - At distance = 0: score = 1.0 (perfect overlap)
        - At distance = combined_radius: score = 0.8 (80% at max combined radius)
        - Beyond combined_radius: rapid exponential dropoff
        - At distance >= 1.5 * combined_radius: no match (dealbreaker)

    Args:
        group_a: Dict with 'target_lat', 'target_lon', 'travel_radius_km'
        group_b: Dict with 'target_lat', 'target_lon', 'travel_radius_km'

    Returns:
        Tuple of (score, distance_km) or (None, distance_km) if no match
    """
    # Calculate distance between target locations
    distance = haversine(
        group_a["target_lat"], group_a["target_lon"],
        group_b["target_lat"], group_b["target_lon"]
    )

    radius_a = group_a["travel_radius_km"]
    radius_b = group_b["travel_radius_km"]
    combined_radius = radius_a + radius_b

    # Hard cutoff at 1.5x combined radius
    if distance >= 1.5 * combined_radius:
        return None, distance

    # Calculate score based on how much the circles overlap
    ratio = distance / combined_radius if combined_radius > 0 else 0

    if ratio <= 1.0:
        # Circles overlap - linear falloff from 1.0 to 0.8
        # At ratio=0 (same target): score = 1.0
        # At ratio=1.0 (circles just touch): score = 0.8
        score = 1.0 - 0.2 * ratio
    else:
        # Beyond combined radius but within 1.5x - rapid exponential dropoff
        # ratio goes from 1.0 to 1.5, overshoot goes from 0 to 1
        overshoot = (ratio - 1.0) / 0.5
        # Exponential decay from 0.8 toward 0
        score = 0.8 * math.exp(-4 * overshoot)

    return max(0.0, min(1.0, score)), distance


def best_location_match(group_a: dict, group_b: dict) -> tuple[float, float] | tuple[None, float]:
    """
    Find the best location match across all location pairs between two groups.

    Each group may have a 'locations' key containing a list of
    {target_lat, target_lon, travel_radius_km} dicts. If missing, falls back
    to flat target_lat/target_lon/travel_radius_km fields on the group dict.

    Returns the pair with the highest score: (best_score, best_distance)
    or (None, best_distance) if no pair matches.
    """
    locs_a = group_a.get("locations")
    if not locs_a:
        locs_a = [{"target_lat": group_a["target_lat"],
                    "target_lon": group_a["target_lon"],
                    "travel_radius_km": group_a["travel_radius_km"]}]

    locs_b = group_b.get("locations")
    if not locs_b:
        locs_b = [{"target_lat": group_b["target_lat"],
                    "target_lon": group_b["target_lon"],
                    "travel_radius_km": group_b["travel_radius_km"]}]

    best_score = None
    best_distance = float("inf")

    for la in locs_a:
        for lb in locs_b:
            score, dist = location_match(la, lb)
            if score is not None and (best_score is None or score > best_score):
                best_score = score
                best_distance = dist
            elif best_score is None and dist < best_distance:
                best_distance = dist

    return best_score, best_distance
