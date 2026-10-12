"""Helper functions for the data ethics exercise.

You don't need to read or change this file to do the exercise. Each function
has a short description you can see in the notebook with help(function_name).
"""

from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd

DATA_DIR = Path(__file__).resolve().parent / "data"
BRAND_CHARTS = Path(__file__).resolve().parent.parent / "_extensions/cagov/caldata-quarto-brand/charts"
CHART_BLUE = "#1F6CB0"


def set_style():
    """Use the CalData chart style if it's available (otherwise matplotlib's default)."""
    import sys

    if BRAND_CHARTS.exists():
        sys.path.insert(0, str(BRAND_CHARTS))
        try:
            import odi_charts

            odi_charts.use_matplotlib()
        except Exception:
            pass


# --- Loading data ----------------------------------------------------------------

def load_enrollment():
    """County-level enrollment counts by race/ethnicity and age group (synthetic)."""
    return pd.read_csv(DATA_DIR / "enrollment_by_county.csv")


def load_extract():
    """A "de-identified" record-level extract for a few small ZIP codes (synthetic)."""
    return pd.read_csv(DATA_DIR / "extract_deidentified.csv", dtype={"zip": str})


def load_roster():
    """A fictional public roster of residents in the same ZIP codes (synthetic)."""
    return pd.read_csv(DATA_DIR / "public_roster.csv", dtype={"zip": str})


# --- Part 2: small-cell suppression --------------------------------------------------

def _check_threshold(threshold):
    if threshold is ...:
        raise ValueError("Replace the ... with a number, for example threshold=11.")
    if isinstance(threshold, bool) or not isinstance(threshold, (int, float)):
        raise ValueError(f"threshold should be a number without quotes, like threshold=11 (got {threshold!r}).")


def suppress(df, threshold):
    """Hide counts that are greater than 0 but less than `threshold`.

    Returns a copy with two new columns:
      - published: the count the public would see (blank where suppressed)
      - suppressed: True if the count was hidden
    Zeros are shown, as in the CalHHS guidelines.
    """
    _check_threshold(threshold)
    out = df.copy()
    out["suppressed"] = (out["enrolled"] > 0) & (out["enrolled"] < threshold)
    out["published"] = out["enrolled"].where(~out["suppressed"]).astype("Int64")
    out["reason"] = out["suppressed"].map({True: "small cell", False: ""})
    return out


def suppression_by_group(published, by="race_ethnicity"):
    """Share of cells and share of enrollees hidden, for each group in `by`."""
    d = published.assign(hidden=published["enrolled"].where(published["suppressed"], 0))
    out = d.groupby(by).agg(
        cells=("enrolled", "size"),
        cells_hidden=("suppressed", "sum"),
        enrollees=("enrolled", "sum"),
        enrollees_hidden=("hidden", "sum"),
    )
    out["pct_cells_hidden"] = (100 * out["cells_hidden"] / out["cells"]).round(1)
    out["pct_enrollees_hidden"] = (100 * out["enrollees_hidden"] / out["enrollees"]).round(1)
    return out.sort_values("pct_enrollees_hidden", ascending=False)


def plot_hidden_by_group(summary, title="Share of enrollees hidden by suppression"):
    """Horizontal bar chart of pct_enrollees_hidden from suppression_by_group()."""
    s = summary["pct_enrollees_hidden"].sort_values()
    fig, ax = plt.subplots(figsize=(8, 4))
    ax.barh(s.index, s.values, color=CHART_BLUE, height=0.6)
    for y, v in enumerate(s.values):
        ax.text(v + 0.5, y, f"{v:.1f}%", va="center", fontsize=10)
    ax.set_xlabel("Percent of the group's enrollees in suppressed cells")
    ax.set_title(title)
    ax.grid(axis="y", visible=False)
    ax.grid(axis="x", visible=True)
    ax.set_xlim(0, max(10, s.max() * 1.15))
    plt.show()


# --- Part 3: recovering hidden cells -------------------------------------------------

def published_totals(df):
    """The row totals the department also publishes: county x race/ethnicity, all ages."""
    return (df.groupby(["county", "race_ethnicity"], as_index=False)["enrolled"].sum()
              .rename(columns={"enrolled": "total"}))


def recover_hidden_cells(published, totals):
    """Use published row totals to work out hidden cells.

    If exactly one cell in a county x race/ethnicity row is hidden, its value is
    simply the row total minus the visible cells. Returns the cells that can be
    recovered, with the recovered value and the true (hidden) value.
    """
    rows = []
    merged = published.merge(totals, on=["county", "race_ethnicity"])
    for (county, race), g in merged.groupby(["county", "race_ethnicity"]):
        hidden = g[g["published"].isna()]
        if len(hidden) == 1:
            recovered = int(g["total"].iloc[0] - g["published"].sum())
            rows.append({
                "county": county,
                "race_ethnicity": race,
                "age_group": hidden["age_group"].iloc[0],
                "recovered_value": recovered,
                "true_value": int(hidden["enrolled"].iloc[0]),
            })
    return pd.DataFrame(rows, columns=["county", "race_ethnicity", "age_group",
                                       "recovered_value", "true_value"])


def complementary_suppress(df, threshold):
    """Small-cell suppression plus complementary suppression.

    First hides small cells (like suppress()). Then, in any county x race/ethnicity
    row with hidden cells, keeps hiding the next-smallest visible cell until at
    least two cells are hidden and the hidden cells add up to at least `threshold`.
    That way the row total can't be used to work backward to a small number.
    """
    out = suppress(df, threshold)
    for _, idx in out.groupby(["county", "race_ethnicity"]).groups.items():
        row = out.loc[idx]
        if not row["suppressed"].any():
            continue
        while True:
            hidden = row[row["suppressed"]]
            if len(hidden) >= 2 and hidden["enrolled"].sum() >= threshold:
                break
            visible = row[~row["suppressed"]]
            if visible.empty:
                break
            nxt = visible["enrolled"].idxmin()
            out.loc[nxt, ["suppressed", "reason"]] = [True, "complementary"]
            row = out.loc[idx]
    out["published"] = out["enrolled"].where(~out["suppressed"]).astype("Int64")
    return out


# --- Part 4: linkage -----------------------------------------------------------------

def share_unique(df, columns):
    """Percent of rows whose combination of `columns` appears only once."""
    if isinstance(columns, str):
        columns = [columns]
    counts = df.groupby(columns)[columns[0]].transform("size")
    return round(100 * (counts == 1).mean(), 1)
