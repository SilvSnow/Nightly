"""
Group Tendencies Helper
Aggregates user attributes into group-level statistics for matching.
"""

import pandas as pd
import numpy as np
from typing import Dict, Any, Optional


def calculate_group_tendencies(
    users_df: pd.DataFrame,
    memberships_df: pd.DataFrame,
    group_id: int
) -> Optional[Dict[str, Any]]:
    """
    Calculate aggregated tendencies for a single group from its members.

    Args:
        users_df: DataFrame with user data (id, age, gender, drinking_level, etc.)
        memberships_df: DataFrame with group_id, user_id mappings
        group_id: The group to calculate tendencies for

    Returns:
        Dict with aggregated group stats, or None if group has no members
    """
    # Get user IDs in this group
    member_ids = memberships_df[memberships_df['group_id'] == group_id]['user_id'].tolist()

    if not member_ids:
        return None

    # Filter to group members
    members = users_df[users_df['id'].isin(member_ids)]

    if members.empty:
        return None

    # Gender breakdown (1=female, 2=male, 3=nonbinary, 4=prefer not to say)
    gender_counts = members['gender'].value_counts()
    num_women = int(gender_counts.get(1, 0))
    num_men = int(gender_counts.get(2, 0))
    num_nonbinary = int(gender_counts.get(3, 0))

    # Age stats
    min_age = int(members['age'].min())
    max_age = int(members['age'].max())
    avg_age = float(members['age'].mean())

    # Lifestyle averages
    drinking = members['drinking_level'].dropna()
    smoking = members['smoking_level'].dropna()
    weed = members['weed_level'].dropna() if 'weed_level' in members.columns else pd.Series()

    return {
        'group_id': group_id,
        'num_people': len(members),
        'num_women': num_women,
        'num_men': num_men,
        'num_nonbinary': num_nonbinary,

        # Age
        'min_age': min_age,
        'max_age': max_age,
        'age_range': f"{min_age}-{max_age}",
        'avg_age': round(avg_age, 1),

        # Lifestyle averages (rounded for matching)
        'drinking_level': round(drinking.mean()) if not drinking.empty else None,
        'smoking_level': round(smoking.mean()) if not smoking.empty else None,
        'weed_level': round(weed.mean()) if not weed.empty else None,

        # Lifestyle spread (standard deviation - high = diverse group)
        'drinking_spread': round(drinking.std(), 1) if len(drinking) > 1 else 0,
        'smoking_spread': round(smoking.std(), 1) if len(smoking) > 1 else 0,
        'weed_spread': round(weed.std(), 1) if len(weed) > 1 else 0,
    }


def calculate_all_group_tendencies(
    users_df: pd.DataFrame,
    memberships_df: pd.DataFrame
) -> pd.DataFrame:
    """
    Calculate tendencies for all groups.

    Returns:
        DataFrame with one row per group containing aggregated stats
    """
    group_ids = memberships_df['group_id'].unique()

    tendencies = []
    for gid in group_ids:
        result = calculate_group_tendencies(users_df, memberships_df, gid)
        if result:
            tendencies.append(result)

    return pd.DataFrame(tendencies)


def sync_group_from_tendencies(
    groups_df: pd.DataFrame,
    tendencies: Dict[str, Any]
) -> pd.DataFrame:
    """
    Update a group's attributes from calculated tendencies.

    Args:
        groups_df: DataFrame with group data
        tendencies: Dict from calculate_group_tendencies()

    Returns:
        Updated groups_df
    """
    group_id = tendencies['group_id']
    idx = groups_df[groups_df['id'] == group_id].index

    if len(idx) == 0:
        return groups_df

    # Update fields
    groups_df.loc[idx, 'num_people'] = tendencies['num_people']
    groups_df.loc[idx, 'age_range'] = tendencies['age_range']

    if tendencies['drinking_level'] is not None:
        groups_df.loc[idx, 'drinking_level'] = tendencies['drinking_level']
    if tendencies['smoking_level'] is not None:
        groups_df.loc[idx, 'smoking_level'] = tendencies['smoking_level']
    if tendencies['weed_level'] is not None:
        groups_df.loc[idx, 'weed_level'] = tendencies['weed_level']

    return groups_df


def sync_all_groups(
    groups_df: pd.DataFrame,
    users_df: pd.DataFrame,
    memberships_df: pd.DataFrame
) -> pd.DataFrame:
    """
    Sync all groups from their member tendencies.
    """
    all_tendencies = calculate_all_group_tendencies(users_df, memberships_df)

    for _, row in all_tendencies.iterrows():
        groups_df = sync_group_from_tendencies(groups_df, row.to_dict())

    return groups_df


# ============================================
# Example usage
# ============================================

if __name__ == "__main__":
    # Sample data
    users_data = {
        'id': [1, 2, 3, 4, 5, 6, 7, 8],
        'name': ['Alice', 'Bob', 'Charlie', 'Diana', 'Eve', 'Frank', 'Grace', 'Henry'],
        'age': [22, 24, 21, 23, 25, 22, 20, 26],
        'gender': [1, 2, 2, 1, 1, 2, 1, 2],  # 1=female, 2=male
        'drinking_level': [6, 7, 8, 5, 7, 6, 4, 8],
        'smoking_level': [2, 3, 1, 2, 4, 2, 1, 5],
        'weed_level': [4, 5, 6, 3, 5, 4, 2, 7],
    }
    users_df = pd.DataFrame(users_data)

    # Group memberships
    memberships_data = {
        'group_id': [1, 1, 1, 1, 2, 2, 2],
        'user_id': [1, 2, 3, 4, 5, 6, 7],
    }
    memberships_df = pd.DataFrame(memberships_data)

    # Calculate tendencies
    print("Group 1 Tendencies:")
    t1 = calculate_group_tendencies(users_df, memberships_df, 1)
    for k, v in t1.items():
        print(f"  {k}: {v}")

    print("\nGroup 2 Tendencies:")
    t2 = calculate_group_tendencies(users_df, memberships_df, 2)
    for k, v in t2.items():
        print(f"  {k}: {v}")

    print("\nAll Group Tendencies:")
    all_t = calculate_all_group_tendencies(users_df, memberships_df)
    print(all_t.to_string())
