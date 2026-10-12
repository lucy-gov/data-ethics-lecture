#!/usr/bin/env python3
"""Export an ODI slide deck to PDF, one slide per page.

Does what "open the deck with ?print-pdf and print" does by hand: renders the
deck if given a .qmd, serves it locally, opens it in reveal.js's print mode in
headless Chromium, waits for the print pages (and fonts) to be ready, and saves
a PDF with background colors. The theme's print styles (revealjs/theme.scss)
and the per-page footer script (filters/slides.lua) handle the layout.

Usage, from the project folder:

    python _extensions/cagov/caldata-quarto-brand/tools/slides_pdf.py deck.qmd
    python _extensions/cagov/caldata-quarto-brand/tools/slides_pdf.py _output/deck.html -o deck.pdf

A .qmd is rendered first (`quarto render`, RevealJS format only). The PDF goes
next to the rendered HTML unless -o says otherwise.

Setup, once (Playwright downloads its own Chromium, about 150 MB):

    pip install playwright
    python -m playwright install chromium

Chrome-printed PDFs aren't tagged for screen readers. Share the HTML deck, or
the matching document, when accessibility matters.
"""

import argparse
import functools
import http.server
import re
import subprocess
import sys
import threading
from pathlib import Path

try:
    from playwright.sync_api import sync_playwright
except ImportError:
    sys.exit("Playwright isn't installed. Run: pip install playwright && python -m playwright install chromium")

FORMAT = "caldata-quarto-brand-revealjs"


def render(qmd: Path) -> Path:
    """Render a .qmd to RevealJS and return the HTML path Quarto reports."""
    result = subprocess.run(
        ["quarto", "render", qmd.name, "--to", FORMAT],
        cwd=qmd.parent, capture_output=True, text=True,
    )
    log = result.stdout + result.stderr
    if result.returncode != 0:
        sys.exit(f"quarto render failed:\n{log}")
    created = re.findall(r"Output created: (.+\.html)", log)
    if not created:
        sys.exit(f"Couldn't find the rendered HTML in Quarto's output:\n{log}")
    # Quarto reports the path relative to the project folder (nearest _quarto.yml).
    project = next((d for d in [qmd.parent, *qmd.parents] if (d / "_quarto.yml").exists()), qmd.parent)
    for base in (project, qmd.parent):
        html = (base / created[-1].strip()).resolve()
        if html.exists():
            return html
    sys.exit(f"Rendered HTML not found: {created[-1]}")


class QuietHandler(http.server.SimpleHTTPRequestHandler):
    def log_message(self, *args):
        pass


def export(html: Path, pdf: Path) -> int:
    handler = functools.partial(QuietHandler, directory=str(html.parent))
    # Port 0 picks a free ephemeral port; Chrome blocks some low "unsafe" ports.
    server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), handler)
    threading.Thread(target=server.serve_forever, daemon=True).start()
    url = f"http://127.0.0.1:{server.server_address[1]}/{html.name}?print-pdf"
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch()
            page = browser.new_page()
            page.goto(url, wait_until="networkidle")
            # reveal.js builds one .pdf-page per slide after load; the ODI
            # script adds footers on its "pdf-ready" event.
            page.wait_for_selector(".pdf-page", timeout=30_000)
            page.evaluate("document.fonts.ready")
            page.wait_for_timeout(500)
            pages = page.locator(".pdf-page").count()
            page.pdf(path=str(pdf), print_background=True, prefer_css_page_size=True)
            browser.close()
    finally:
        server.shutdown()
    return pages


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("deck", type=Path, help="a slide deck .qmd, or its rendered .html")
    ap.add_argument("-o", "--output", type=Path, help="PDF path (default: next to the HTML)")
    args = ap.parse_args()

    deck = args.deck.resolve()
    if not deck.exists():
        sys.exit(f"Not found: {args.deck}")
    html = render(deck) if deck.suffix == ".qmd" else deck
    if html.suffix != ".html":
        sys.exit(f"Expected a .qmd or .html file: {args.deck}")
    pdf = (args.output or html.with_suffix(".pdf")).resolve()
    pages = export(html, pdf)
    print(f"Wrote {pdf} ({pages} pages)")


if __name__ == "__main__":
    main()
