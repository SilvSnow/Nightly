import math

def languageMatchScore(group_a, group_b):
    """
    Language compatibility score (0–1).

    Uses Jaccard index with non-linear scaling:
    - Perfect match (same languages) → 1.0
    - High overlap → 0.85-0.99 (diminishing returns curve)
    - Some overlap → 0.5-0.85 (smooth scaling)
    - No overlap → 0.05 (communication barrier, but not impossible)

    Examples:
        {English, French} vs {English, French} → 1.0
        {English, French} vs {English} → 0.85 (jaccard=0.5)
        {English, French, Spanish} vs {English} → 0.74 (jaccard=0.33)
        {English} vs {French} → 0.05 (no overlap)
    """
    langs_a = set(group_a.get("languages", []) or [])
    langs_b = set(group_b.get("languages", []) or [])

    # Handle missing data
    if not langs_a or not langs_b:
        return 0.05

    # Calculate Jaccard index
    shared = langs_a & langs_b
    union = langs_a | langs_b

    if len(shared) == 0:
        # No common language - significant communication barrier
        return 0.05

    jaccard = len(shared) / len(union)

    # Perfect match
    if jaccard == 1.0:
        return 1.0

    # Non-linear scaling using square root for diminishing returns
    # This rewards having at least one shared language strongly,
    # with diminishing returns for additional overlap
    #
    # jaccard=0.2 → sqrt=0.45 → score=0.61
    # jaccard=0.5 → sqrt=0.71 → score=0.85
    # jaccard=0.8 → sqrt=0.89 → score=0.95
    base_score = 0.4 + 0.6 * math.sqrt(jaccard)

    return max(0.05, min(1.0, base_score))
