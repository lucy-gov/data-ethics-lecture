# Exercise and debrief guide (instructor)

This is a guide for the 30-minute exercise and 10-minute debrief. The completed notebook is `instructor/solutions.ipynb`. For helping stuck students (common errors, hints, a catch-up cell), see [exercise-help.md](exercise-help.md).

## Before class

- If you commit and push `_extensions/` along with the exercise, students' charts use the CalData style. The notebook still works without it, in that case using matplotlib's default style.
- Ask students to install [uv](https://docs.astral.sh/uv/) beforehand if possible. Setup (`git clone`, `uv sync`, `uv run jupyter lab exercise/`) takes 2–5 minutes on a fresh machine, mostly downloading Python packages.
- Regenerate the data any time with `uv run python exercise/make_data.py`. The seed is fixed, so the numbers below stay the same.

## Expected results

| Step | Result |
|---|---|
| 1b: cells with 1–10 people | 149 of 1,624 cells |
| 2c: small counties (under 50,000 people), share of enrollees hidden | NHPI 100%, AIAN 14.6%, Black 11.0%, Multiracial/other 2.6%, Asian 0.9%, Latino 0.2%, White 0.0% |
| Optional threshold change | 75 cells hidden at a threshold of 5; 226 at 20 |
| 3a: hidden cells recoverable from row totals | 28 |
| 3b: after complementary suppression | 196 cells hidden, 0 recoverable |
| 3b chart: small counties after complementary suppression | AIAN 28.6% hidden (about double), Black 21.3% |
| 4a: extract records unique on ZIP, birth year, and sex | 50.3% |
| 4b: records re-identified (exactly one roster match) | 17 of 372 |
| 4c: Ruth Calloway (fictional) | Record R0279, $350 per month |

## Timing

| Part | Minutes | Watch for |
|---|---|---|
| Setup | (before the clock starts, if possible) | uv not installed; Jupyter opening in the wrong folder |
| 1 Explore | 5 | Combining two conditions with `&` needs parentheses around each |
| 2 Suppress | 7 | Students who skip 2a get `NameError` later |
| 3 Recover | 5 | The point is the jump from 28 recoverable to 0, *and* the cost shown in the chart |
| 4 Link | 7 | `merge` needs the column list in square brackets |
| 5 Decide | 6 | Push students to separate the records request from open-data posting |

If time runs short, skip the optional threshold change in Part 2 and go straight from 4b to the memo.

## Debrief (10 minutes)

The slides run in this order: "What you found," three concept slides, "Let's discuss," the re-poll, and "My take."

1. **What you found (1 min).** Three numbers: 28 → 0 recoverable cells; AIAN hidden in small counties going from 15% to 29%; 17 of 372 records re-identified.
2. **Concept slides (2–3 min).** Move fast for students who got it; these are for those who didn't.
   - *Small-cell suppression:* Alpine County, White enrollees. The 65+ cell (10) is hidden.
   - *Working backward:* 75 − 29 − 19 − 17 = 10. Complementary suppression hides the 35–64 cell too, so only the sum (27) is knowable.
   - *Linking:* R0279 has no name, but only one woman born in 1957 lives in ZIP 96120. Point out that the join is just "line up rows that match on the same columns."
3. **Let's discuss (3 min).** Pick two of the four boxes, depending on the room:
   - **Trade-offs:** point back to "What you found." Complementary suppression roughly doubled AIAN erasure in small counties.
   - **Who decides:** "AIAN" is a race category, not a tribal nation, so working out whom to consult is itself the classification problem.
   - **Damage vs. desire:** "Was your memo damage-centered? What would a desire-based release look like?" (Tuck 2009) Possible answers: tribes choose what's shown and how; data framed around community goals, not only deficits; data-sharing agreements that return data to communities.
   - **Linkage:** what should the department remove or coarsen before sharing the extract?
4. **Re-poll (1–2 min).** Run the same Mentimeter question. Who changed their answer, and why?
5. **My take (1–2 min).** Two decisions, not one, plus the extract point.

## Instructor take: two decisions, not one

- **Records request: B (suppress), released on time.** The Public Records Act is an obligation. Agencies must release the parts of a record that can be separated out and justify anything withheld. Suppress small *and* complementary cells, cite privacy for those cells only, and release the rest.
- **Posting on data.ca.gov: D, then maybe C.** Publishing is discretionary, so this is where consultation belongs. Consult tribes in the affected counties. The outcome might be aggregation, an agreed suppression approach, or data-sharing agreements instead of posting.
- **The real lesson:** the decision is already late. These questions belong at collection and publication planning, with tribes at the table, not on a records request deadline.
- **The extract:** a record-level file with ZIP code, birth year, and sex should not be shared shared in that form. Coarsen or remove the identifying details (quasi-identifiers) or use a data use agreement.

Caveat: this is a practitioner's reading, not legal advice. Records request deadlines and which privacy exemptions apply are questions for agency counsel.
