def score(group_a, group_b):
    """
    Badge compatibility score (1–100).
    Full score if both groups match on the sexuality_inclusive badge
    (either both True or both False).
    Otherwise 0.
    """
    sa = bool(group_a.get("sexuality_inclusive", False))
    sb = bool(group_b.get("sexuality_inclusive", False))

    if sa == sb:
        return 100
    return 0
