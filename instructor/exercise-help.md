# Exercise help guide (instructor and GSIs)

Use this when students get stuck during the exercise. It goes part by part:

- the answer
- the mistakes students commonly make, with the error each one produces
- hints to give, from gentlest to most direct

Expected results, timing, and debrief prompts are in [debrief-guide.md](debrief-guide.md). Full answers are in `solutions.ipynb`.

**General approach:** start with the smallest hint that gets them moving. Most students only need a nudge on syntax. The ideas, not the pandas, are the point of the exercise. If someone is more than 5 minutes behind, give them the [catch-up cell](#catch-up-cell) so they can join the discussion.

---

## Setup problems

| Symptom | Likely cause | Fix |
|---|---|---|
| `uv: command not found` | uv isn't installed, or the terminal was opened before installing | Install from <https://docs.astral.sh/uv/getting-started/installation/>, then **open a new terminal** |
| `git: command not found` | git isn't installed | Easiest path: on GitHub, click **Code → Download ZIP**, unzip it, and `cd` into the folder |
| `uv sync` is slow | First-time download of Python and packages | Normal; it can take 2–5 minutes. On weak Wi-Fi, pair the student with a neighbor |
| `uv sync` fails behind campus Wi-Fi | Network or proxy issue | Try eduroam or a phone hotspot, or pair with a neighbor |
| JupyterLab opens but the notebook isn't there | Jupyter was launched from the wrong folder | Run `uv run jupyter lab exercise/` from the repo's top folder (the one with `pyproject.toml`) |
| `ModuleNotFoundError: No module named 'helpers'` | The notebook isn't running from the `exercise/` folder | Open `exercise/exercise.ipynb` from JupyterLab's file browser, not a copy saved elsewhere |
| `ModuleNotFoundError: No module named 'pandas'` | The notebook is using a different Python (common in VS Code) | In VS Code, pick the kernel at `.venv/bin/python`. Or use `uv run jupyter lab` instead |
| Charts look plain, without CalData fonts or colors | `_extensions/` wasn't included in the repo | Fine for the exercise. Everything works with matplotlib's default style |
| Windows: `uv run` errors about scripts or permissions | PowerShell execution policy | Run the commands in **Command Prompt** instead, or follow uv's Windows instructions |

**Last resort:** if a student's setup can't be fixed in about 3 minutes, have them pair with a neighbor. The written answers and the memo matter more than running the code themselves.

---

## Errors that apply everywhere

| Error | What it means | Fix |
|---|---|---|
| Anything mentioning `ellipsis`, or "Replace the ... with a number" | A ✏️ blank still has `...` in it | Fill in the blank |
| `NameError: name 'published' is not defined` (or `protected`, `matches`, `reidentified`) | An earlier ✏️ cell wasn't finished, or the kernel restarted | Go back and run the earlier cells in order. Or use **Run → Run All Above Selected Cell**, or the catch-up cell |
| `SyntaxError` | A typo: a missing quote, bracket, or comma | Look for unmatched `"`, `[`, or `(`. The caret `^` in the error points near the problem |
| Output is just `Ellipsis` | The student ran the cell without filling it in | Fill in the `...` and rerun |

---

## Part 1 · Explore

**1a. The 10 smallest non-zero counts**

```python
smallest = nonzero.nsmallest(10, "enrolled")
```

| Mistake | What they see |
|---|---|
| `nonzero.nsmallest(10)` | `TypeError: ... missing 1 required positional argument: 'columns'` |
| Using `enrollment` instead of `nonzero` | Zeros fill the top of the list |

Hints:
1. "Which method name is in the hint? What two things does it need?"
2. "It needs how many rows, and which column to sort by."
3. Give them the answer.

**1b. How many cells count 1–10 people**

```python
small_cells = enrollment[(enrollment["enrolled"] > 0) & (enrollment["enrolled"] < 11)]
```

Answer: **149**.

| Mistake | What they see |
|---|---|
| Leaving out the parentheses, as in `enrollment["enrolled"] > 0 & enrollment["enrolled"] < 11` | `ValueError: The truth value of a Series is ambiguous` |
| Using `and` instead of `&` | The same `ValueError` |
| `< 10` instead of `< 11` | 141 instead of 149. The rule is *fewer than* 11, so 10 is included |

Hints:
1. "pandas needs each condition in its own parentheses."
2. "For columns, use `&`, not `and`."

**If they finish early:** "Which counties appear most among the small cells?" They can try `small_cells["county"].value_counts().head()`.

---

## Part 2 · Suppress

**2a.**

```python
published = h.suppress(enrollment, threshold=11)
```

| Mistake | What they see |
|---|---|
| `threshold="11"` (with quotes) | "threshold should be a number without quotes, like threshold=11" |
| Skipping this cell | `NameError: name 'published' is not defined` in 2b and later cells |

**2b.** No blank, just run it. If students ask why the statewide numbers look tiny, that's the setup for 2c: big counties have enough people that few cells are small.

**2c.**

```python
small_counties = published[published["county_population"] < 50_000]
```

Expected chart: NHPI 100%, AIAN 14.6%, Black 11.0%, White 0.0%.

| Mistake | What they see |
|---|---|
| Filtering `enrollment` instead of `published` | `KeyError: 'suppressed'`. Only `published` has the suppression columns |
| `< 50,000` with a comma | `InvalidIndexError` (Python reads `50,000` as two numbers). Use `50_000` or `50000` |

Prompts for the written answer, if they're stuck:
- "Which bar is longest? Who is that?"
- "If you were advocating for more clinic funding for that community in a small county, what would this table let you show?"

**Optional threshold change.** They should see that a threshold of 5 hides 75 cells and 20 hides 226. Ask: who chose 11? Could it be different? The guidelines themselves base suppression on a risk score, so 11 isn't automatic.

---

## Part 3 · Recover

**3a.**

```python
recovered = h.recover_hidden_cells(published, totals)
```

Answer: **28 cells can be recovered.**

| Mistake | What they see |
|---|---|
| Passing `enrollment` instead of `published` | `KeyError: 'published'` |

**If they don't see why recovery works,** walk through one row on paper:

> Alpine, White: the row total is published. Three age groups are visible, and one is hidden. Hidden = total − (sum of the visible three).

That's all the helper does.

**3b.**

```python
protected = h.complementary_suppress(enrollment, threshold=11)
```

Answer: 196 cells hidden, **0 recoverable**. The follow-up chart shows AIAN hidden rising to 28.6%.

| Mistake | What they see |
|---|---|
| Passing `published` instead of `enrollment` | It works, since the helper recomputes from `enrolled`. No need to correct it |
| Skipping 3b | `NameError: name 'protected' is not defined` in the chart cell |

Key question to ask: "Privacy went up. Who paid for it?" The answer is in the chart: AIAN and Black enrollees in small counties lose roughly twice as much visibility.

---

## Part 4 · Link

**4a.**

```python
h.share_unique(extract, ["zip", "birth_year", "sex"])
```

Answer: **50.3%**.

| Mistake | What they see |
|---|---|
| A misspelled column, such as `"birthyear"` | `KeyError: 'birthyear'`. Point them to `extract.head()` for exact names |
| Only `"zip"` | 0.0%. ZIP alone identifies no one, which is a nice contrast to show |

**4b.**

```python
matches = extract.merge(roster, on=["zip", "birth_year", "sex"])
```

Then the provided cell shows **17 of 372 records re-identified**.

| Mistake | What they see |
|---|---|
| `on="zip", "birth_year", "sex"` (no square brackets) | `SyntaxError: positional argument follows keyword argument` |
| `on="zip"` only | Runs, but makes about 300,000 rows (every pairing within a ZIP) and re-identifies almost no one |
| Only two of the three columns | Runs, but re-identifies far fewer people. Good teaching moment: each extra detail narrows the crowd |

**4c.**

```python
reidentified[reidentified["name"] == "Ruth Calloway"]
```

Answer: record **R0279**, **$350** per month.

| Mistake | What they see |
|---|---|
| A typo or different capitalization, such as `"ruth calloway"` | An empty table. The match must be exact |
| Searching `extract` instead of `reidentified` | `KeyError: 'name'`. The extract has no names, which is the point |

**If a student asks "isn't this illegal?"** Good question for the debrief:
- In this exercise, linking is easy because the extract kept ZIP code, birth year, and sex (quasi-identifiers).
- The lesson is about what the *department* should have released.
- Re-identifying people in real data can violate data use agreements and laws, and it's harmful whether or not it's legal.

---

## Part 5 · Decide

If students stare at a blank memo, offer these starters:

- "For the records request, I recommend… because…"
- "For data.ca.gov, I recommend… because publishing there is discretionary, so…"
- "This approach hides…, which means… loses visibility. To address that, I'd…"
- "Before posting, I'd consult… by… (when?)"

Push back gently on:

- **"Just don't publish anything."** Ask what the Public Records Act requires, and what accountability is lost.
- **"Publish it all, it's only counts."** Point back to Parts 3 and 4.
- **"Consult the tribes" with no detail.** Ask which tribes, how they'd find out, and when. Remind them that AIAN is a race category, not a tribal nation, and tribes are not a monolith.
- **Memos that treat AIAN enrollees only as a risk to manage.** That's Tuck's damage-centered critique. Ask what a desire-based release would look like.

There's no single right answer. A sample memo is at the end of `solutions.ipynb`.

---

## For students who finish early

- Rerun Part 2 at thresholds of 5 and 20 and compare the small-county chart. Is there a threshold that protects people without erasing anyone?
- In Part 4, try matching on only `["zip", "birth_year"]`. Only 1 person is still re-identified, versus 17 with all three fields. What does that say about which fields to remove, or coarsen, before sharing?
- Write the memo as if the reader were a tribal government, not the department director. What changes?
- Look at `exercise/helpers.py`. Can they find the two lines that decide when complementary suppression stops?

---

## Catch-up cell

If a student is far behind, have them paste this into a new cell, from inside the notebook in `exercise/`, and run it. It sets every variable through Part 4, so they can jump to Part 5 or follow the debrief.

```python
import pandas as pd
import helpers as h

h.set_style()
enrollment = h.load_enrollment()
published = h.suppress(enrollment, threshold=11)
small_counties = published[published["county_population"] < 50_000]
totals = h.published_totals(enrollment)
recovered = h.recover_hidden_cells(published, totals)
protected = h.complementary_suppress(enrollment, threshold=11)
extract = h.load_extract()
roster = h.load_roster()
matches = extract.merge(roster, on=["zip", "birth_year", "sex"])
reidentified = matches[matches.groupby("record_id")["name"].transform("size") == 1]
print("Caught up through Part 4.")
```
