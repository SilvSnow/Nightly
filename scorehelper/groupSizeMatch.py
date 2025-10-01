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
    Combines both groups' individual fits into a 0–100 score.
    """
    fit_a = ideal_size_fit(a_size, b_size, a_ideal)
    fit_b = ideal_size_fit(b_size, a_size, b_ideal)

    # average the two scores
    score = (fit_a + fit_b) / 2
    return round(score * 100)
