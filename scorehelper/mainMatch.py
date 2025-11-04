import pandas as pd
from itertools import combinations

from groupAgeMatch import groupAgeMatchScore
from lifeStyleMatch import lifeStyleMatchScore
from languageMatch import languageMatchScore
from groupSizeMatch import groupSizeMatchScore
from badgeMatch import badgeMatchScore
from optionalMatch import gender_request_score  # assuming gender_request_score is in optionalMatch.py


def main_match_score(a, b):
    """Combine all submatchers into one weighted final score."""
    # individual sub-scores
    age_score = groupAgeMatchScore(a, b)
    life_score = lifeStyleMatchScore(a, b)
    lang_score = languageMatchScore(a, b)
    size_score = groupSizeMatchScore(a["num_people"], b["num_people"], a["ideal_group_size"], b["ideal_group_size"])
    badge_score = badgeMatchScore(a, b)
    gender_score = gender_request_score(a, b)

    # weights (tweakable)
    weights = {
    "age": 0.15, # average and standard deviation
    "size": 0.20,
    "language": 0.15,
    "lifestyle": 0.25,
    "badge": 0.05,
    "gender": 0.20,   # “special selection” alignment (both sides)
    }

    # weighted average
    final_score = (
        age_score * weights["age"]
        + life_score * weights["lifestyle"]
        + lang_score * weights["language"]
        + size_score * weights["size"]
        + badge_score * weights["badge"]
        + gender_score * weights["gender"]
    )

    parts = {
        "age": age_score,
        "lifestyle": life_score,
        "language": lang_score,
        "size": size_score,
        "badge": badge_score,
        "gender": gender_score,
    }

    return round(final_score, 2), parts


def run_all_matches(csv_path="groups.csv"):
    """Load groups from CSV and compute all pairwise match scores."""
    df = pd.read_csv(csv_path)
    results = []

    for a_idx, b_idx in combinations(df.index, 2):
        a = df.loc[a_idx].to_dict()
        b = df.loc[b_idx].to_dict()
        score, parts = main_match_score(a, b)
        results.append({
            "group_a_id": a["id"],
            "group_b_id": b["id"],
            "final_score": score,
            **{f"{k}_score": v for k, v in parts.items()},
        })

    return pd.DataFrame(results)


if __name__ == "__main__":
    matches = run_all_matches("groups.csv")
    print(matches.sort_values(by="final_score", ascending=False).head(10))
