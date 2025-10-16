def gender_request_score(group_a: dict, group_b: dict) -> int:
    """
    Returns a 1–100 score for how well TWO groups match based ONLY on:
      - each group's gender breakdown, and
      - each group's special gender request.

    Expected fields:
      group['gender_group'] : int {1=women, 2=men, 3=mixed}  (if you stored strings, see fallback)
      group['special_selections'] : int {1=women, 2=men, 3=mixed, 4=none}

    Logic (per side):
      - request == none (4)               -> satisfaction = 1.0
      - request == other group's gender   -> satisfaction = 1.0
      - request is single, other is mixed -> 0.7 (partial)
      - request is mixed, other is single -> 0.6 (partial)
      - opposite single-gender            -> 0.0

    Final score = average of both sides' satisfactions * 100, rounded to int.
    """

    # --- helpers -------------------------------------------------------------
    def _norm_gender_code(val):
        # Prefer integer codes
        try:
            g = int(val)
            if g in (1, 2, 3):
                return g
        except Exception:
            pass
        # Fallback: accept string labels if present
        if val is not None:
            s = str(val).strip().lower()
            if s in {"women", "female", "f", "girls", "ladies"}:
                return 1
            if s in {"men", "male", "m", "boys", "guys"}:
                return 2
            if s in {"mixed", "coed", "any", "all"}:
                return 3
        # Default to mixed if unclear
        return 3

    def _norm_request_code(val):
        try:
            r = int(val)
            if r in (1, 2, 3, 4):
                return r
        except Exception:
            pass
        return 4  # none

    def _satisfaction(req_code, other_gender_code):
        if req_code == 4:                 # none
            return 1.0
        if req_code == other_gender_code: # exact
            return 1.0
        if req_code in (1, 2) and other_gender_code == 3:  # wanted single, got mixed
            return 0.7
        if req_code == 3 and other_gender_code in (1, 2):  # wanted mixed, got single
            return 0.6
        return 0.0  # opposite singles

    # --- normalize inputs ----------------------------------------------------
    ga = _norm_gender_code(group_a.get("gender_group", group_a.get("gender")))
    gb = _norm_gender_code(group_b.get("gender_group", group_b.get("gender")))
    ra = _norm_request_code(group_a.get("special_selections"))
    rb = _norm_request_code(group_b.get("special_selections"))

    # --- compute per-side satisfaction and final score -----------------------
    sa = _satisfaction(ra, gb)
    sb = _satisfaction(rb, ga)
    return int(round(100 * (sa + sb) / 2.0))
