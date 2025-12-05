"""Dataset builder 스텁."""

from __future__ import annotations

import pandas as pd


def build_datasets(
    feature_df: pd.DataFrame,
    targets: dict[str, str],
    config: dict,
) -> dict[str, dict]:
    """train/validation/test 데이터셋을 생성한다."""

    if feature_df.empty:
        return {}

    df = feature_df.reset_index().copy()
    df.sort_values(["feature_date", "ticker"], inplace=True)

    target_columns = list(targets.values())
    df.dropna(subset=target_columns, inplace=True)

    target_family_columns = [col for col in df.columns if col.startswith("target_")]
    feature_exclude = set(["ticker", "feature_date", "price_date", *target_family_columns])
    feature_columns = config.get("feature_columns")
    if feature_columns is None:
        feature_columns = [col for col in df.columns if col not in feature_exclude]

    feature_matrix = df[feature_columns].apply(pd.to_numeric, errors="coerce")
    valid_columns = [col for col in feature_matrix.columns if feature_matrix[col].notna().any()]
    feature_matrix = feature_matrix[valid_columns]

    feature_matrix.dropna(inplace=True)
    if feature_matrix.empty:
        return {}

    df = df.loc[feature_matrix.index]
    feature_columns = valid_columns

    X = feature_matrix.to_numpy(dtype=float)

    datasets: dict[str, dict] = {}
    for task_name, target_col in targets.items():
        y = pd.to_numeric(df[target_col], errors="coerce").to_numpy(dtype=float)
        datasets[task_name] = {
            "X": X,
            "y": y,
            "feature_names": feature_columns,
            "index": df[["ticker", "feature_date"]].to_records(index=False),
        }
    return datasets


