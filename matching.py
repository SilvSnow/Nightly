import pandas as pd
from itertools import combinations
from scorehelper.locationMatch import location_match
from scorehelper.groupSizeMatch import size_compat, groupSizeMatchScore
from scorehelper.groupAgeMatch import age_overlap_score
from scorehelper.lifeStyleMatch import lifestyle_score
from scorehelper.languageMatch import language_score
from scorehelper.badgeMatch import badge_score

DEFAULT_WEIGHTS = {
    "size": 0.20,
    "age": 0.15,
    "lifestyle": 0.20,
    "languages": 0.15,
    "inclusivity_access": 0.10,
    "rating": 0.10,
    "location": 0.10,
}

def compute_pair_scores(groups_df: pd.DataFrame,
                        group_languages_df: pd.DataFrame,
                        languages_df: pd.DataFrame,
                        weights: dict = None,
                        same_city_only: bool = False) -> pd.DataFrame:
    """
    Returns a DataFrame with all unordered pairs and a 0–100 match_score,
    plus the sub-scores for explainability.
    """
    w = (weights or DEFAULT_WEIGHTS).copy()
    required = [
        "id","age_range","num_men","num_women","num_nonbinary","location_id",
        "smoking_level","drinking_level","weed_level","ideal_group_size",
        "sexuality_inclusive","accessibility_friendly","group_rating"
    ]
    missing = [c for c in required if c not in groups_df.columns]
    if missing:
        raise ValueError(f"Missing columns: {missing}")

    # Build a mapping from group_id to set of language names
    lang_id_to_name = dict(zip(languages_df["id"], languages_df["name"]))
    group_to_langs = group_languages_df.groupby("group_id")["language_id"].apply(
        lambda ids: set(lang_id_to_name[i] for i in ids if i in lang_id_to_name)
    ).to_dict()

    rows = []
    by_id = {int(r["id"]): r for _, r in groups_df.iterrows()}

    for a_id, b_id in combinations(sorted(by_id.keys()), 2):
        a, b = by_id[a_id], by_id[b_id]
        loc_score = location_match(a["location_id"], b["location_id"])
        if loc_score is None:
            continue
        a["languages"] = group_to_langs.get(a_id, set())
        b["languages"] = group_to_langs.get(b_id, set())
        lang_score = language_score(a, b)
        size_score = size_compat(a, b)
        age_score = age_overlap_score(a, b)
        life_score = lifestyle_score(a, b)
        # badge_score returns 0-1, use for inclusivity/accessibility/rating
        inc_acc = badge_score(a, b)
        rate = badge_score(a, b)
        city = loc_score
        match_score = (
            w["size"] * size_score +
            w["age"] * age_score +
            w["lifestyle"] * life_score +
            w["languages"] * lang_score +
            w["inclusivity_access"] * inc_acc +
            w["rating"] * rate +
            w["location"] * city
        ) * 100.0
        rows.append({
            "a_id": a_id, "b_id": b_id,
            "match_score": round(match_score, 1),
            "size_score": round(size_score, 3),
            "age_score": round(age_score, 3),
            "lifestyle_score": round(life_score, 3),
            "lang_score": round(lang_score, 3),
            "inclusivity_access_score": round(inc_acc, 3),
            "rating_score": round(rate, 3),
            "city_score": round(city, 3),
        })

    pair_scores_df = pd.DataFrame(rows).sort_values(["match_score","a_id","b_id"], ascending=[False, True, True]).reset_index(drop=True)
    return pair_scores_df

def generate_preference_lists(pair_scores_df, groups_df):
    """
    For each group, generate a ranked list of other groups by compatibility score.
    Returns: {group_id: [other_group_id, ...]}
    """
    group_ids = set(groups_df["id"])
    preferences = {gid: [] for gid in group_ids}
    # For each group, collect all pairs where it is a_id or b_id
    for gid in group_ids:
        # Get all pairs where gid is a_id
        scores_a = pair_scores_df[pair_scores_df["a_id"] == gid][["b_id", "match_score"]].values.tolist()
        # Get all pairs where gid is b_id
        scores_b = pair_scores_df[pair_scores_df["b_id"] == gid][["a_id", "match_score"]].values.tolist()
        # Combine and sort by score descending
        all_scores = [(other_id, score) for other_id, score in scores_a + scores_b]
        all_scores.sort(key=lambda x: x[1], reverse=True)
        preferences[gid] = [other_id for other_id, _ in all_scores]
    return preferences

def display_preference_lists(preferences):
    print("Group Preference Lists:")
    for group_id, pref_list in preferences.items():
        print(f"Group {group_id}: {pref_list}")

def main():
    # Load test data
    groups_df = pd.read_csv('./groups.csv')
    group_languages_df = pd.read_csv('./group_languages.csv')
    languages_df = pd.read_csv('./languages.csv')

    # Compute pair scores
    pair_scores_df = compute_pair_scores(groups_df, group_languages_df, languages_df)

    # Generate and display preference lists
    preferences = generate_preference_lists(pair_scores_df, groups_df)
    display_preference_lists(preferences)

if __name__ == "__main__":
    main()