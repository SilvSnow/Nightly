def score(group_a, group_b):
    """
    Lifestyle compatibility score (1–100).
    Considers smoking_level, drinking_level, weed_level (1–10).
    Uses squared difference penalty so larger gaps hurt more.
    """

    attrs = ["smoking_level", "drinking_level", "weed_level"]
    sims = []

    for attr in attrs:
        a_val = int(group_a.get(attr, 0) or 0)
        b_val = int(group_b.get(attr, 0) or 0)

        # squared difference
        diff_sq = (a_val - b_val) ** 2

        # maximum squared diff possible is 9^2 = 81
        sim = 1 - (diff_sq / 81.0)
        sims.append(max(0.0, sim))  # clamp at 0

    # Average similarity across the three attributes
    avg_sim = sum(sims) / len(sims)

    return int(round(avg_sim * 100))
