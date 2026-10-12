"""ODI chart styles for matplotlib and Plotly.

Colors come from odi-plotly.json and odi.mplstyle, which tools/build-assets.py
generates from _brand.yml. In a Quarto document:

    import os, sys
    sys.path.insert(0, os.path.join(os.environ.get("QUARTO_PROJECT_DIR", "."),
                                    "_extensions/cagov/caldata-quarto-brand/charts"))
    import odi_charts
    odi_charts.use()

use() styles whichever of matplotlib and Plotly are installed. With kaleido
installed, Plotly charts also get a static PNG, so they appear in PDFs. SERIES,
SEQUENTIAL, and DIVERGING hold the hex colors for other libraries.
"""

import json
from pathlib import Path

HERE = Path(__file__).resolve().parent
FONTS = HERE.parent / "fonts"

PLOTLY_TEMPLATE = json.loads((HERE / "odi-plotly.json").read_text())
PLOTLY_TEMPLATE.pop("_comment", None)
_layout = PLOTLY_TEMPLATE["layout"]
SERIES = _layout["colorway"]
SEQUENTIAL = [c for _, c in _layout["colorscale"]["sequential"]]
DIVERGING = [c for _, c in _layout["colorscale"]["diverging"]]


def use_matplotlib():
    import matplotlib as mpl
    import matplotlib.pyplot as plt
    from matplotlib import font_manager
    from matplotlib.colors import LinearSegmentedColormap

    for font in FONTS.glob("*/*.ttf"):
        font_manager.fontManager.addfont(str(font))
    plt.style.use(str(HERE / "odi.mplstyle"))
    for name, colors in (("odi-sequential", SEQUENTIAL), ("odi-diverging", DIVERGING)):
        if name not in mpl.colormaps:
            mpl.colormaps.register(LinearSegmentedColormap.from_list(name, colors))
    mpl.rcParams["image.cmap"] = "odi-sequential"


def use_plotly():
    import importlib.util

    import plotly.graph_objects as go
    import plotly.io as pio

    pio.templates["odi"] = go.layout.Template(PLOTLY_TEMPLATE)
    pio.templates.default = "odi"
    # PDFs can't show interactive charts, and Quarto drops them from Typst
    # output. With kaleido installed, also emit a PNG, which PDFs use while
    # web pages keep the interactive chart.
    if importlib.util.find_spec("kaleido") and "png" not in pio.renderers.default:
        pio.renderers.default += "+png"


def use():
    """Apply the ODI style to every installed charting library."""
    for apply in (use_matplotlib, use_plotly):
        try:
            apply()
        except ImportError:
            pass
