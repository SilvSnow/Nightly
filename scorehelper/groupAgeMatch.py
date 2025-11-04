def age_overlap_score(group_a, group_b):
    """
    Jaccard overlap of age ranges. Returns 1–100.
    change up the range
    """
    def parse(age_range):
        lo, hi = age_range.split("-")
        return int(lo), int(hi)

    a_min, a_max = parse(group_a["age_range"])
    b_min, b_max = parse(group_b["age_range"])

    overlap = max(0, min(a_max, b_max) - max(a_min, b_min))
    union = max(a_max, b_max) - min(a_min, b_min)
    if union == 0:
        return 1.0
    return max(0.0, min(1.0, overlap / union))
