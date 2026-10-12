// ODI document layouts for Typst (PDF). Choose one with `layout:` metadata:
//
//   report     Cover page (banner, dot field, title, date), optional table of
//              contents, running header with mark + org + title, page numbers.
//   one-pager  Mark + eyebrow + title header, "(Continued)" header after page 1,
//              "Org • page" footer.
//   flyer      One-pager with the orange-tint gradient behind the header.
//   paper      Title block in the flow (title, subtitle, authors, date,
//              abstract); "Org • page" footer. The default.
//
// Measured from the ODI report and one-pager Google Docs templates (US Letter,
// 0.75in side margins, 12pt Public Sans body). Colors and logos come from
// _brand.yml (brand-color / brand-logo-images, passed in by typst-show.typ);
// don't hardcode brand values here.

// Display font for lead paragraphs, set by odi-doc.
#let odi-display = state("odi-display", none)

// Lead paragraph: Merriweather 14pt. Written as `::: {.lead}` (see filters/typst.lua).
#let odi-lead(body) = context {
  let display = odi-display.get()
  set text(size: 14pt)
  set text(font: display) if display != none
  set par(leading: 2.7pt)
  block(above: 15.5pt, below: 32pt, body)  // below: same as callouts
}

// Callout: tinted box with a colored bar on the left. Written as
// `::: {.callout-*}`; filters/callouts.lua picks the colors from _brand.yml.
// Extra room below so the box doesn't crowd the next heading (block spacing
// collapses to the larger value, and headings ask for 20pt).
#let odi-callout(accent: black, tint: white, title-color: black, small: false, title: none, body) = block(
  width: 100%,
  fill: tint,
  stroke: (left: 4pt + accent),
  inset: (left: 16pt, right: 14pt, y: 12pt),
  above: 18pt,
  below: 32pt,
)[
  #set text(size: 10pt) if small
  #set par(spacing: 10pt)
  #if title != none and title != [] {
    block(below: 8pt, sticky: true, text(weight: 700, fill: title-color, title))
  }
  #body
]

// Status badge: `{{< status-badge draft >}}` (shortcodes/status-badge.lua).
#let odi-badge(fill: gray, text-color: white, label) = box(
  fill: fill,
  inset: (x: 5pt),
  outset: (y: 2.5pt),
  radius: 7pt,
  text(size: 0.72em, weight: 700, tracking: 0.6pt, fill: text-color, upper(label)),
)

#let odi-doc(
  title: none,
  subtitle: none,
  eyebrow: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  keywords: (),
  lang: "en",
  region: "US",
  layout: "paper",
  org: none,
  running-title: none,
  artwork: none,
  watermark: none,
  palette: (:),
  logos: (:),
  font: none,
  display-font: none,
  fontsize: 12pt,
  sectionnumbering: none,
  chapter-breaks: false,
  toc: false,
  toc-title: none,
  toc-depth: none,
  doc,
) = {
  let c(name) = palette.at(name, default: black)
  let logo(name, width) = {
    let entry = logos.at(name, default: none)
    if entry != none {
      let path = entry.path
      if not path.starts-with("/") { path = "/" + path }
      image(path, width: width, alt: entry.at("alt", default: none))
    }
  }
  let running = if running-title != none { running-title } else { title }
  let is-onepager = layout in ("one-pager", "flyer")
  let margin-x = 0.75in
  let margin-top = if layout == "paper" { 1in } else { 116pt }
  let navy-rule(width) = line(length: width, stroke: 2pt + c("navy"))

  odi-display.update(display-font)

  // --- Text ------------------------------------------------------------------
  set document(title: title, keywords: keywords)
  set text(lang: lang, region: region, size: fontsize, top-edge: "ascender", bottom-edge: "descender")
  set text(font: font) if font != none
  // Left-aligned (the ODI guide asks for no justified text); 17.6pt line pitch,
  // 12pt between paragraphs.
  set par(justify: false, leading: 3.5pt, spacing: 15.5pt)
  // Books: chapters after Quarto's <appendices> heading are lettered (A, A.1)
  // rather than continuing the chapter numbers.
  let section-numbering = if sectionnumbering == none { none } else {
    (..nums) => context {
      let n = nums.pos()
      let appendices = query(<appendices>)
      let chapters = if appendices.len() > 0 {
        counter(heading).at(appendices.first().location()).first()
      } else { none }
      if chapters != none and n.first() > chapters {
        numbering("A.1", n.first() - chapters, ..n.slice(1))
      } else {
        numbering(sectionnumbering, ..n)
      }
    }
  }
  set heading(numbering: section-numbering)
  show link: underline
  set list(indent: 18pt, body-indent: 12pt, spacing: 15.5pt, marker: text(size: 7pt, baseline: -1.5pt, sym.circle.filled))
  set enum(indent: 18pt, body-indent: 12pt, spacing: 15.5pt)

  // Headings use the base font; Merriweather is reserved for titles and leads.
  show heading: set text(font: font) if font != none
  let numbered(it) = {
    if it.numbering != none { counter(heading).display(it.numbering); h(0.5em) }
    it.body
  }
  // Quarto shifts headings so the top section level is always Typst level 1
  // (`#`, or `##` when a document has no `#` headings).
  // Level 1: Public Sans Bold 16pt with a 2pt gray rule, as in the templates.
  // `chapter-breaks: true` (books) starts each level-1 section on a new page,
  // except the first appendix, which shares a page with the "Appendices" heading.
  show heading.where(level: 1): it => {
    if chapter-breaks {
      context {
        let before = query(heading.where(level: 1).before(here()))
        let prev = if before.len() > 1 { before.at(-2) } else { none }
        let after-divider = prev != none and prev.has("label") and prev.label == <appendices>
        if not after-divider { pagebreak(weak: true) }
      }
    }
    block(above: 26pt, below: 11pt, sticky: true, width: 100%)[
      #text(size: 16pt, weight: 700, fill: c("foreground"), numbered(it))
      #v(6pt, weak: true)
      #line(length: 100%, stroke: 2pt + c("rule-gray"))
    ]
  }
  show heading.where(level: 2): it => block(above: 20pt, below: 8pt, sticky: true,
    text(size: 12pt, weight: 700, fill: c("foreground"), numbered(it)))
  show heading.where(level: 3): it => block(above: 16pt, below: 6pt, sticky: true,
    text(size: 12pt, weight: 700, style: "italic", fill: c("foreground"), numbered(it)))

  // Tables: blue header row, blue-tint cells separated by white gaps (as on
  // slides). Assumes the first row is the header, as Pandoc writes it.
  set table(
    stroke: none,
    gutter: 2pt,
    inset: (x: 8pt, y: 5pt),
    fill: (_, y) => if y == 0 { c("blue") } else { c("blue-tint") },
  )
  set table.hline(stroke: none)
  show table: set text(size: 11pt)
  show table.cell.where(y: 0): set text(fill: c("white"), weight: 700)

  // Typst adds the bibliography at the end; match HTML's "References" title.
  set bibliography(title: "References")

  // --- Page frame: headers, footers, backgrounds -------------------------------
  let frame = context {
    let n = counter(page).get().first()
    let inner = page.width - 2 * margin-x
    if layout == "report" and n == 1 { return }

    if layout == "flyer" and n == 1 {
      place(top + left, rect(width: 100%, height: 210pt, stroke: none,
        fill: gradient.linear(c("orange-tint"), c("white"), angle: 90deg)))
    }

    // Header
    if layout == "report" {
      place(top + left, dx: margin-x, dy: 36pt, grid(
        columns: (24pt, auto), column-gutter: 9pt, align: horizon,
        logo("mark", 24pt),
        text(size: 10pt, weight: 700, fill: c("navy"))[#org \ #running],
      ))
      place(top + left, dx: margin-x, dy: 79.5pt, navy-rule(inner))
    } else if is-onepager and n > 1 {
      place(top + right, dx: -margin-x, dy: 58pt,
        text(size: 10pt)[#strong(running) #emph[(Continued)]])
      place(top + left, dx: margin-x, dy: 79.5pt, navy-rule(inner))
    }

    // Footer
    place(top + left, dx: margin-x, dy: page.height - 57.5pt, navy-rule(inner))
    let number = if layout == "report" {
      text(size: 10pt, fill: c("blue"), str(n))
    } else {
      text(size: 10pt)[#org #sym.bullet #strong(str(n))]
    }
    place(top + right, dx: -margin-x, dy: page.height - 51pt, number)
  }

  // Watermark (`watermark:` metadata, see filters/watermark.lua): faint
  // diagonal text over every page, sized so long labels still fit.
  let stamp = if watermark != none {
    let size = calc.min(120, 1050 / calc.max(watermark.len(), 1)) * 1pt
    place(center + horizon, rotate(-50deg, text(size: size, weight: 700, tracking: 4pt,
      fill: c("red").transparentize(85%), watermark)))
  }

  set page(
    paper: "us-letter",
    margin: (x: margin-x, top: margin-top, bottom: 72pt),
    numbering: none,
    header: none,
    footer: none,
    background: frame,
    foreground: stamp,
  )

  // --- Report cover --------------------------------------------------------------
  if layout == "report" {
    page(margin: 0pt)[
      #if artwork != none { place(top + left, image(artwork + "/dot-field.svg", width: 100%)) }
      // Navy banner with the circle mark overlapping its left end.
      #place(top + left, dy: 88.5pt, rect(width: 512pt, height: 81pt, fill: c("navy"), stroke: none))
      #place(top + left, dx: 32pt, dy: 76pt, logo("mark-dark", 106pt))
      #place(top + left, dx: 32pt, dy: 76pt, circle(radius: 53pt, stroke: 4pt + c("navy"), fill: none))
      #if org != none {
        let parts = if org.starts-with("California ") { (upper("California"), org.slice(11)) } else { (none, org) }
        place(top + left, dx: 159pt, dy: 101pt, text(fill: c("white"))[
          #if parts.at(0) != none { text(size: 17pt, tracking: 1pt, parts.at(0)); linebreak() }
          #text(size: 20pt, weight: 700, parts.at(1))
        ])
      }
      #place(top + left, dx: 54pt, dy: 623pt, block(width: 504pt)[
        #set par(leading: 4pt)
        #text(font: display-font, size: 30pt, weight: 700, fill: c("red"), title)
        #if subtitle != none { v(6pt); text(size: 16pt, weight: 300, fill: c("red"), subtitle) }
        #if date != none { v(12pt); text(size: 14pt, fill: c("charcoal"), date) }
      ])
    ]
  }

  // --- Title blocks ----------------------------------------------------------------
  if is-onepager {
    // Placed in the top margin: mark + eyebrow + title, with a navy rule beneath.
    place(top + left, dy: -(margin-top - 28pt), block(width: 100%, height: 82pt)[
      #grid(
        columns: (58pt, 1fr), column-gutter: 9.5pt, align: horizon,
        logo("mark", 58pt),
        [
          // Brand red is under 4.5:1 on the flyer's orange-tint gradient.
          #if eyebrow != none { text(size: 11pt, fill: c(if layout == "flyer" { "dark-red" } else { "red" }), eyebrow); v(4pt, weak: true) }
          #text(font: display-font, size: 22pt, weight: 700, fill: c("navy"), title)
        ],
      )
      #place(top + left, dy: 80.5pt, navy-rule(100%))
    ])
  } else if layout == "paper" {
    block(below: 24pt, width: 100%)[
      #if eyebrow != none { text(size: 11pt, fill: c("red"), eyebrow); v(6pt, weak: true) }
      #if title != none {
        set par(leading: 4pt)
        text(font: display-font, size: 22pt, weight: 700, fill: c("navy"), title)
      }
      #if subtitle != none { v(8pt, weak: true); text(size: 14pt, weight: 300, fill: c("blue"), subtitle) }
      #if authors != none and authors != () {
        v(12pt, weak: true)
        text(size: 11pt, authors.map(a => a.name).join(", ", last: " and "))
      }
      #if date != none { v(4pt, weak: true); text(size: 11pt, fill: c("charcoal"), date) }
      #v(14pt, weak: true)
      #navy-rule(100%)
    ]
    if abstract != none {
      block(below: 22pt, inset: (left: 12pt), stroke: (left: 2pt + c("rule-gray")))[
        #text(weight: 700, if abstract-title != none { abstract-title } else { "Abstract" })
        #v(4pt, weak: true)
        #abstract
      ]
    }
  }

  // --- Table of contents ------------------------------------------------------------
  if toc {
    block(below: 18pt, text(font: display-font, size: 14pt,
      if toc-title != none { toc-title } else { "Table of contents" }))
    {
      set outline.entry(fill: none)
      show outline.entry: set block(spacing: 22pt)
      outline(title: none, depth: toc-depth, indent: 36pt)
    }
    if layout == "report" { pagebreak() }
  }

  doc
}
