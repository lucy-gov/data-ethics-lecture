# Data ethics and governance in the public sector

Lecture and activity on public-sector data ethics and governance for UC Berkeley CYPLAN 101.

**Slides:** <https://lucy-gov.github.io/data-ethics-lecture/>

## Exercise: to publish or not to publish

You'll need [git](https://git-scm.com/downloads) and [uv](https://docs.astral.sh/uv/getting-started/installation/).

```bash
git clone https://github.com/lucy-gov/data-ethics-lecture.git
cd data-ethics-lecture
uv sync
uv run jupyter lab exercise/
```

Then open `exercise.ipynb` and run the cells in order.

All data in the exercise is **synthetic**. County names are real and county sizes are roughly realistic, but every count and every person is made up. No real program, community, or tribe is represented. To regenerate the data, run `uv run python exercise/make_data.py`.

## Contents

- `slides/`: the lecture deck (Quarto reveal.js, CalData theme). To render locally, run `quarto render` from the repo root and open `_site/slides/index.html`. The `_site/` folder is gitignored, so your editor may grey it out or hide it. Pushing changes to `main` republishes the site through GitHub Actions.
- `exercise/`: the student notebook, helper functions, and synthetic data.
- `instructor/`: the debrief guide and a help guide for stuck students.
