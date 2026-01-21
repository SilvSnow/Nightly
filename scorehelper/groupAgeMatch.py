import math

# Configuration
GAP_DECAY_FACTOR = 3  # Years - controls how fast score drops with gap
OVERLAP_BONUS_THRESHOLD = 0.5  # Overlap ratio above which we give bonus

def age_overlap_score(group_a, group_b):
    """
    Age range compatibility score (0-1).

    Scoring logic:
    1. If ranges overlap well → high score (with bonus for strong overlap)
    2. If ranges just touch or small gap → moderate score
    3. If large gap between ranges → exponential penalty

    Examples:
        21-25 vs 21-25 → 1.0 (identical)
        21-25 vs 23-28 → ~0.85 (good overlap)
        21-25 vs 26-30 → ~0.72 (1 year gap, mild penalty)
        21-25 vs 30-35 → ~0.19 (5 year gap, steep penalty)
        21-25 vs 40-45 → ~0.01 (15 year gap, very low)
    """
    def parse(age_range):
        lo, hi = age_range.split("-")
        return int(lo), int(hi)

    a_min, a_max = parse(group_a["age_range"])
    b_min, b_max = parse(group_b["age_range"])

    # Calculate overlap and gap
    overlap = max(0, min(a_max, b_max) - max(a_min, b_min))
    gap = max(0, max(a_min, b_min) - min(a_max, b_max))

    # Size of each range
    a_range = a_max - a_min
    b_range = b_max - b_min
    min_range = max(1, min(a_range, b_range))  # Avoid division by zero

    if overlap > 0:
        # Ranges overlap - calculate overlap ratio relative to smaller range
        overlap_ratio = overlap / min_range

        # Base score from overlap ratio (0.5 to 1.0)
        # Perfect overlap (ratio >= 1) → 1.0
        # Half overlap → 0.75
        # Minimal overlap → 0.5
        base_score = 0.5 + 0.5 * min(1.0, overlap_ratio)

        # Bonus for strong overlap (squared for non-linearity)
        if overlap_ratio >= OVERLAP_BONUS_THRESHOLD:
            bonus = 0.1 * ((overlap_ratio - OVERLAP_BONUS_THRESHOLD) / (1 - OVERLAP_BONUS_THRESHOLD)) ** 2
            base_score = min(1.0, base_score + bonus)

        return base_score
    else:
        # No overlap - apply exponential decay based on gap
        # gap=0 (ranges just touch) → ~1.0
        # gap=3 (GAP_DECAY_FACTOR) → ~0.37
        # gap=6 → ~0.14
        # gap=10 → ~0.04
        score = math.exp(-gap / GAP_DECAY_FACTOR)

        # Scale down since no overlap should cap lower than overlapping ranges
        # Max score with gap is 0.5 (when gap=0, ranges just touch)
        return 0.5 * score
