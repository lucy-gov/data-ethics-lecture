"""Generate the synthetic data for the exercise.

Everything here is made up. County names are real and county populations are
rounded approximations, but every count, record, and person is synthetic. The
data does not describe any real program, community, or tribe.

Run from the repo root to regenerate exercise/data/ (the output is the same
every time, because the random seed is fixed):

    uv run python exercise/make_data.py
"""

from pathlib import Path

import numpy as np
import pandas as pd

SEED = 101
DATA_DIR = Path(__file__).resolve().parent / "data"

# Rounded, approximate county populations (for realistic county sizes only).
COUNTY_POPULATION = {
    "Alameda": 1_682_000, "Alpine": 1_200, "Amador": 41_000, "Butte": 212_000,
    "Calaveras": 46_000, "Colusa": 22_000, "Contra Costa": 1_166_000,
    "Del Norte": 28_000, "El Dorado": 192_000, "Fresno": 1_009_000,
    "Glenn": 29_000, "Humboldt": 136_000, "Imperial": 180_000, "Inyo": 19_000,
    "Kern": 909_000, "Kings": 153_000, "Lake": 68_000, "Lassen": 33_000,
    "Los Angeles": 10_014_000, "Madera": 157_000, "Marin": 262_000,
    "Mariposa": 17_000, "Mendocino": 91_000, "Merced": 281_000, "Modoc": 8_700,
    "Mono": 13_000, "Monterey": 439_000, "Napa": 138_000, "Nevada": 103_000,
    "Orange": 3_186_000, "Placer": 405_000, "Plumas": 20_000,
    "Riverside": 2_418_000, "Sacramento": 1_585_000, "San Benito": 64_000,
    "San Bernardino": 2_181_000, "San Diego": 3_299_000,
    "San Francisco": 874_000, "San Joaquin": 779_000,
    "San Luis Obispo": 283_000, "San Mateo": 764_000, "Santa Barbara": 449_000,
    "Santa Clara": 1_936_000, "Santa Cruz": 271_000, "Shasta": 182_000,
    "Sierra": 3_200, "Siskiyou": 44_000, "Solano": 453_000, "Sonoma": 489_000,
    "Stanislaus": 552_000, "Sutter": 99_000, "Tehama": 65_000,
    "Trinity": 16_000, "Tulare": 473_000, "Tuolumne": 55_000,
    "Ventura": 843_000, "Yolo": 217_000, "Yuba": 81_000,
}

RACE_GROUPS = [
    "Hispanic or Latino",
    "White",
    "Asian",
    "Black or African American",
    "American Indian or Alaska Native",
    "Native Hawaiian or Pacific Islander",
    "Multiracial or other",
]
# Synthetic baseline shares, loosely shaped like a large, diverse state.
URBAN_SHARES = np.array([0.39, 0.35, 0.15, 0.055, 0.004, 0.004, 0.047])
RURAL_SHARES = np.array([0.22, 0.64, 0.03, 0.015, 0.035, 0.003, 0.057])

AGE_GROUPS = ["0-17", "18-34", "35-64", "65+"]
AGE_SHARES = np.array([0.22, 0.24, 0.38, 0.16])
ENROLLMENT_RATE = np.array([0.18, 0.11, 0.09, 0.08])  # by age group

# The record-level extract and public roster cover a few small rural ZIP codes.
ZIP_POPULATION = {
    "96120": ("Alpine", 420),
    "96118": ("Sierra", 700),
    "96125": ("Sierra", 160),
    "96126": ("Sierra", 260),
    "96101": ("Modoc", 1_300),
    "96104": ("Modoc", 320),
}

# The fictional person students re-identify in Part 4.
TARGET = {"name": "Ruth Calloway", "zip": "96120", "birth_year": 1957, "sex": "F",
          "race_ethnicity": "White"}

FIRST_NAMES_F = ["Ana", "Beth", "Carmen", "Dana", "Elena", "Faith", "Grace", "Hana",
                 "Iris", "June", "Kara", "Lena", "Mae", "Nora", "Olive", "Paula",
                 "Rosa", "Sara", "Tess", "Vera", "Wren", "Yara", "Zoe", "Lily"]
FIRST_NAMES_M = ["Alan", "Ben", "Carlos", "Dev", "Eli", "Frank", "Gabe", "Hugo",
                 "Ivan", "Jon", "Kai", "Luis", "Max", "Noel", "Omar", "Paul",
                 "Raul", "Sam", "Theo", "Victor", "Wade", "Xavier", "Yusuf", "Zack"]
LAST_NAMES = ["Abbott", "Barros", "Chen", "Delgado", "Ellis", "Fontaine", "Garza",
              "Hale", "Ito", "Jensen", "Kowalski", "Lopez", "Moreno", "Nash",
              "Ortega", "Price", "Quinn", "Reyes", "Silva", "Tran", "Underwood",
              "Vargas", "Whitaker", "Xu", "Young", "Zamora"]


def county_table(rng):
    rows = []
    for county, pop in COUNTY_POPULATION.items():
        # Blend urban and rural shares by county size, then jitter.
        rurality = float(np.clip((np.log10(pop) - 6.0) / (3.5 - 6.0), 0, 1))
        shares = (1 - rurality) * URBAN_SHARES + rurality * RURAL_SHARES
        shares = shares * rng.uniform(0.7, 1.3, size=len(shares))
        if county == "Alpine":
            shares[RACE_GROUPS.index("American Indian or Alaska Native")] = 0.20
        shares = shares / shares.sum()
        for race, r_share in zip(RACE_GROUPS, shares):
            for age, a_share, rate in zip(AGE_GROUPS, AGE_SHARES, ENROLLMENT_RATE):
                expected = pop * r_share * a_share * rate * rng.uniform(0.8, 1.2)
                rows.append({
                    "county": county,
                    "county_population": pop,
                    "race_ethnicity": race,
                    "age_group": age,
                    "enrolled": int(rng.poisson(expected)),
                })
    return pd.DataFrame(rows)


def roster_and_extract(rng):
    people = []
    for zip_code, (county, n) in ZIP_POPULATION.items():
        for _ in range(n):
            sex = rng.choice(["F", "M"])
            first = rng.choice(FIRST_NAMES_F if sex == "F" else FIRST_NAMES_M)
            people.append({
                "name": f"{first} {rng.choice(LAST_NAMES)}",
                "zip": zip_code,
                "county": county,
                "birth_year": int(rng.integers(1940, 2008)),
                "sex": sex,
                "race_ethnicity": rng.choice(
                    RACE_GROUPS, p=RURAL_SHARES / RURAL_SHARES.sum()),
            })
    people = pd.DataFrame(people)

    # The target is the only person in the roster with her ZIP, birth year, and sex.
    same = ((people["zip"] == TARGET["zip"]) & (people["birth_year"] == TARGET["birth_year"])
            & (people["sex"] == TARGET["sex"]))
    people = people[~same]
    target = {**TARGET, "county": ZIP_POPULATION[TARGET["zip"]][0]}
    people = pd.concat([people, pd.DataFrame([target])], ignore_index=True)
    people = people.sample(frac=1, random_state=SEED).reset_index(drop=True)

    enrolled = rng.random(len(people)) < 0.12
    enrolled[people.index[people["name"] == TARGET["name"]]] = True

    extract = people[enrolled].copy()
    extract["monthly_benefit"] = rng.integers(8, 60, size=len(extract)) * 10
    extract = extract.sample(frac=1, random_state=SEED + 1).reset_index(drop=True)
    extract.insert(0, "record_id", [f"R{i:04d}" for i in range(1, len(extract) + 1)])
    extract = extract[["record_id", "zip", "birth_year", "sex", "race_ethnicity",
                       "monthly_benefit"]]

    roster = people[["name", "zip", "birth_year", "sex"]]
    return roster, extract


def main():
    rng = np.random.default_rng(SEED)
    DATA_DIR.mkdir(exist_ok=True)
    county_table(rng).to_csv(DATA_DIR / "enrollment_by_county.csv", index=False)
    roster, extract = roster_and_extract(rng)
    extract.to_csv(DATA_DIR / "extract_deidentified.csv", index=False)
    roster.to_csv(DATA_DIR / "public_roster.csv", index=False)
    print(f"Wrote synthetic data to {DATA_DIR}")


if __name__ == "__main__":
    main()
