def size_compat(a, b):
    """
    Returns a normalized group size compatibility score between two groups (0-1).
    Expects dicts with keys: num_people, ideal_group_size.
    """
    a_size = int(a.get("num_people", 0) or 0)
    b_size = int(b.get("num_people", 0) or 0)
    a_ideal = int(a.get("ideal_group_size", 0) or 0)
    b_ideal = int(b.get("ideal_group_size", 0) or 0)
    fit_a = ideal_size_fit(a_size, b_size, a_ideal)
    fit_b = ideal_size_fit(b_size, a_size, b_ideal)
    score = (fit_a + fit_b) / 2
    return score

def ideal_size_fit(a_size, b_size, a_ideal):
    """
    Individual score for ONE group:
    How close the other group's size (b_size) is to this group's ideal (a_ideal).
    Uses squared difference, normalized by ideal size squared.
    """
    if not a_ideal:  # no preference set
        return 1.0

    diff_sq = (a_ideal - b_size) ** 2
    norm_penalty = diff_sq / (a_ideal ** 2)

    return max(0.0, 1.0 - norm_penalty)


def groupSizeMatchScore(a_size, b_size, a_ideal, b_ideal):
    """
    Combines both groups' individual fits into a normalized score (0–1).
    """
    fit_a = ideal_size_fit(a_size, b_size, a_ideal)
    fit_b = ideal_size_fit(b_size, a_size, b_ideal)

    # average the two scores
    score = (fit_a + fit_b) / 2
    return max(0.0, min(1.0, score))
