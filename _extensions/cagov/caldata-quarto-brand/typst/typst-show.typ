// Passes document metadata to odi-doc (typst-template.typ). Based on Quarto's
// default typst-show.typ, plus the ODI layout options.
#show: doc => odi-doc(
$if(title)$
  title: [$title$],
$endif$
$if(subtitle)$
  subtitle: [$subtitle$],
$endif$
$if(eyebrow)$
  eyebrow: [$eyebrow$],
$endif$
$if(by-author)$
  authors: (
$for(by-author)$
$if(it.name.literal)$
    ( name: [$it.name.literal$],
      affiliation: [$for(it.affiliations)$$it.name$$sep$, $endfor$],
      email: [$it.email$] ),
$endif$
$endfor$
    ),
$endif$
$if(date)$
  date: [$date$],
$endif$
$if(abstract)$
  abstract: [$abstract$],
  abstract-title: "$labels.abstract$",
$endif$
$if(keywords)$
  keywords: ($for(keywords)$"$keywords$",$endfor$),
$endif$
$if(lang)$
  lang: "$lang$",
$endif$
$if(region)$
  region: "$region$",
$endif$
  layout: "$if(layout)$$layout$$else$paper$endif$",
$if(org)$
  org: "$org$",
$endif$
$if(running-title)$
  running-title: [$running-title$],
$endif$
$if(odi-artwork)$
  artwork: "$odi-artwork$",
$endif$
$if(odi-watermark)$
  watermark: "$odi-watermark$",
$endif$
$if(brand)$
  palette: brand-color,
  logos: brand-logo-images,
$endif$
$if(mainfont)$
  font: ("$mainfont$",),
$elseif(brand.typography.base.family)$
  font: $brand.typography.base.family$,
$endif$
$if(fontsize)$
  fontsize: $fontsize$,
$endif$
$if(brand.typography.headings.family)$
  display-font: $brand.typography.headings.family$,
$endif$
$if(section-numbering)$
  sectionnumbering: "$section-numbering$",
$endif$
$if(chapter-breaks)$
  chapter-breaks: true,
$endif$
$if(toc)$
  toc: $toc$,
$endif$
$if(toc-title)$
  toc-title: [$toc-title$],
$endif$
  toc-depth: $toc-depth$,
  doc,
)
