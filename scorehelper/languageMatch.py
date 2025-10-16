def language_score(group_a, group_b):
    """
    Language compatibility score (0–1).
    - Exact same language set → 1.0
    - Some overlap → 0.8 (base) + bonus based on overlap proportion
    - No overlap → 0.1
    """

    langs_a = set(group_a.get("languages", []) or [])
    langs_b = set(group_b.get("languages", []) or [])

    if not langs_a or not langs_b:
        return 0.1  # treat missing data as incompatible

    if langs_a == langs_b:
        return 1.0

    overlap = len(langs_a & langs_b)
    if overlap > 0:
        # base = 80, then add proportional bonus up to 95
        ratio = overlap / max(len(langs_a), len(langs_b))
        return min(0.95, 0.8 + 0.15 * ratio)

    # no overlap at all
    return 0.1
