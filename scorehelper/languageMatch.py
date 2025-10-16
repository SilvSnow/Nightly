def languageMatchScore(group_a, group_b):
    """
    Language compatibility score (1–100).
    - Exact same language set → 100
    - Some overlap → 80 (base) + bonus based on overlap proportion
    - No overlap → 10
    """

    langs_a = set(group_a.get("languages", []) or [])
    langs_b = set(group_b.get("languages", []) or [])

    if not langs_a or not langs_b:
        return 10  # treat missing data as incompatible

    if langs_a == langs_b:
        return 100

    overlap = len(langs_a & langs_b)
    if overlap > 0:
        # base = 80, then add proportional bonus up to 95
        ratio = overlap / max(len(langs_a), len(langs_b))
        return int(80 + 15 * ratio)

    # no overlap at all
    return 10
