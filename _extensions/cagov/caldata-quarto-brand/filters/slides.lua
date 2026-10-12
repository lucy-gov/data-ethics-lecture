-- RevealJS layout helpers for the ODI slide design.
--
-- * Title slide: gradient + California dot-map background. The eyebrow
--   defaults to the brand's full name (`eyebrow:` to change, `eyebrow: false`
--   to hide).
-- * Section slides (level 1) get the orange-tint section background.
-- * Content slides (level 2) get an eyebrow with the current section name,
--   shown above the slide title. Override with `## Title {eyebrow="Text"}`
--   or hide with `eyebrow=""`.
-- * `## {.quote}`: full-bleed red; with `background-image`, the photo shows
--   faintly under the red. `.quote-light`: centered on white.
-- * `## {.image-full background-image="..."}`: full-bleed image, slide text
--   becomes a caption box, no footer.
-- * `## Questions? {.closing}`: gradient background plus a contact block from
--   _brand.yml meta (override with `contact:` metadata, hide with `contact: false`).
-- * `.timeline` steps marked `.current` get a "We are here" label (`label=`).
-- * If no `footer` is set, the presentation title is used.
-- * Divs that start with a heading stay divs (not reveal.js slides).
--
-- Colors and identity come from _brand.yml; nothing is hardcoded.

if not quarto.doc.is_format("revealjs") then
  return {}
end

-- Slide classes with their own layout and no automatic eyebrow.
local NO_EYEBROW = { "quote", "quote-light", "contents", "agenda", "closing", "image-full" }

local function brand_color(name, fallback)
  local ok, value = pcall(quarto.brand.get_color, "light", name)
  if ok and value then
    return value
  end
  return fallback
end

local function read_file(rel)
  local f = io.open(quarto.utils.resolve_path(rel), "rb")
  if not f then
    return nil
  end
  local text = f:read("a")
  f:close()
  return text
end

-- Embedded as data URIs so nothing is copied into the user's project.
local function svg_uri(rel)
  local svg = read_file(rel)
  return svg and ("data:image/svg+xml;base64," .. quarto.base64.encode(svg)) or nil
end

local BRAND = dofile(quarto.utils.resolve_path("brand-meta.lua"))

-- Quarto doesn't copy brand font files for RevealJS, so ship them as an HTML
-- dependency with fonts/fonts.css (generated from _brand.yml by tools/build-assets.py).
local function add_fonts()
  local resources = {}
  local fonts_dir = quarto.utils.resolve_path("../fonts")
  for _, family in ipairs(pandoc.system.list_directory(fonts_dir)) do
    local family_dir = pandoc.path.join({ fonts_dir, family })
    if pandoc.path.split_extension(family) == family and family:sub(1, 1) ~= "." then
      for _, file in ipairs(pandoc.system.list_directory(family_dir)) do
        if file:match("%.ttf$") or file:match("%.otf$") or file:match("%.woff2?$") then
          table.insert(resources, {
            name = family .. "/" .. file,
            path = pandoc.path.join({ family_dir, file }),
          })
        end
      end
    end
  end
  quarto.doc.add_html_dependency({
    name = "caldata-brand-fonts",
    version = "1.0.0",
    stylesheets = { "../fonts/fonts.css" },
    resources = resources,
  })
  -- Quarto also writes @font-face rules from _brand.yml into the RevealJS theme,
  -- with paths it never copies, so browsers request missing files (404s in
  -- `quarto preview`). When @font-face rules match, the last one loaded wins, so
  -- link fonts.css again after the theme. Moving the existing link with
  -- appendChild isn't enough: a script-inserted stylesheet doesn't block
  -- rendering, so a slow reload (preview disables caching) loses the race to
  -- first paint. document.write adds the link while the head is still being
  -- parsed, so the browser waits for it. The path depends on the output name
  -- and project type, so copy it from the dependency's link.
  quarto.doc.include_text("in-header", [[<script>
(l => l && document.write('<link rel="stylesheet" href="' + l.getAttribute("href") + '">'))(document.querySelector('link[href*="caldata-brand-fonts"]'));
</script>]])
end

local function gradient()
  return "linear-gradient(to bottom, " .. brand_color("orange-tint", "#FAECDA") .. ", "
    .. brand_color("white", "#FFFFFF") .. ")"
end

-- reveal.js's viewport tag disables pinch-zoom on phones (`user-scalable=no`),
-- which fails WCAG 1.4.4. Its tag isn't in a template partial, so rewrite it
-- as soon as the head is parsed.
local function allow_zoom()
  quarto.doc.include_text("in-header", [[<script>
document.querySelector('meta[name="viewport"]')?.setAttribute("content", "width=device-width, initial-scale=1.0");
</script>]])
end

-- Quarto's slide-menu button is an icon-only link with no accessible name
-- (WCAG 4.1.2). The menu plugin adds it during Reveal's startup, so label it
-- once Reveal is ready (or right away if it already is).
local function label_menu_button()
  quarto.doc.include_text("in-header", [[<script>
document.addEventListener("DOMContentLoaded", () => {
  const label = () => document.querySelectorAll(".slide-menu-button a:not([aria-label])").forEach(a => {
    a.setAttribute("aria-label", "Slide menu");
    a.setAttribute("role", "button");
  });
  label();
  if (window.Reveal) Reveal.on("ready", label);
});
</script>]])
end

-- The corner logo. Quarto links brand logos straight from _extensions/ (and
-- sets the logo before filters run), so a deck shared as index.html +
-- index_files/ loses it. Embed the logo named by `logo:` (or the brand's
-- default small logo) and point the image at it once the page loads. Other
-- `logo:` values (a file path, `false`) are left alone.
local BRAND_LOGOS = (function()
  local text = read_file("../_brand.yml")
  local brand = text and pandoc.read("---\n" .. text .. "\n---\n", "markdown").meta or {}
  local logo = type(brand.logo) == "table" and brand.logo or {}
  local images = {}
  for key, image in pairs(logo.images or {}) do
    if type(image) == "table" and image.path then
      images[key] = pandoc.utils.stringify(image.path)
    end
  end
  return { images = images, small = logo.small and pandoc.utils.stringify(logo.small) }
end)()

local function embed_logo(meta)
  local name = BRAND_LOGOS.small
  if meta.logo ~= nil then
    name = pandoc.utils.type(meta.logo) ~= "boolean" and pandoc.utils.stringify(meta.logo) or nil
  end
  local path = name and BRAND_LOGOS.images[name]
  local uri = path and svg_uri("../" .. path)
  if not uri then
    return
  end
  quarto.doc.include_text("after-body", '<script>document.querySelectorAll(\'img.slide-logo[src$="/'
    .. pandoc.path.filename(path) .. '"]\').forEach(img => { img.src = "' .. uri .. '"; });</script>')
end

-- PDF export (?print-pdf): reveal.js hides the shared footer and logo, so copy
-- them onto each page once the pages exist. Pages follow the on-screen rules:
-- title and full-bleed slides (odi-title-slide, odi-full-slide states) stay
-- bare, and dark slides get white footer text. Styles are in theme.scss.
local function pdf_footers()
  quarto.doc.include_text("after-body", [[<script>
document.addEventListener("pdf-ready", () => {
  const footer = document.querySelector(".reveal > .footer");
  const logo = document.querySelector(".reveal .slide-logo");
  document.querySelectorAll(".pdf-page").forEach(page => {
    const states = (page.querySelector("section")?.dataset.state || "").split(" ");
    if (states.includes("odi-title-slide") || states.includes("odi-full-slide")) {
      page.classList.add("odi-pdf-bare");
      return;
    }
    if (states.includes("odi-dark-slide")) page.classList.add("odi-pdf-dark");
    if (footer) {
      const copy = document.createElement("div");
      copy.className = "odi-pdf-footer";
      copy.textContent = footer.textContent.trim();
      page.appendChild(copy);
    }
    if (logo) {
      const copy = document.createElement("img");
      copy.className = "odi-pdf-logo";
      copy.src = logo.src;
      copy.alt = logo.alt || "";
      page.appendChild(copy);
    }
  });
});
</script>]])
end

local function title_slide(meta)
  add_fonts()
  pdf_footers()
  allow_zoom()
  label_menu_button()
  embed_logo(meta)
  local attrs = meta["title-slide-attributes"] or {}
  local has_bg = attrs["data-background"] or attrs["data-background-gradient"]
    or attrs["data-background-image"] or attrs["data-background-color"]
  if has_bg == nil then
    local blue = brand_color("blue", "#0D4F8C")
    -- Layers, top to bottom: blue bar along the bottom edge, dot map, gradient.
    -- Uses data-background (the CSS `background` shorthand) because
    -- data-background-gradient only sets background-image.
    local layers = { "linear-gradient(" .. blue .. ", " .. blue .. ") left bottom / 100% 2.85% no-repeat" }
    local map = svg_uri("../artwork/ca-dot-map.svg")
    if map then
      table.insert(layers, "url(" .. map .. ") left 5vw top 9vh / auto 86vh no-repeat")
    end
    table.insert(layers, gradient())
    attrs["data-background"] = pandoc.MetaString(table.concat(layers, ", "))
  end
  -- Lets the theme hide the footer, logo, and slide number on the title slide.
  if attrs["data-state"] == nil then
    attrs["data-state"] = pandoc.MetaString("odi-title-slide")
  end
  meta["title-slide-attributes"] = attrs

  if meta.eyebrow == nil and BRAND.name then
    meta.eyebrow = pandoc.MetaString(BRAND.name)
  end
  return meta
end

-- Contact block for `.closing` slides: document `contact:` values override brand meta.
local function contact_block(meta)
  if meta.contact == false then
    return nil
  end
  local c = type(meta.contact) == "table" and meta.contact or {}
  local function field(key)
    if c[key] ~= nil then
      return pandoc.utils.stringify(c[key])
    end
    return BRAND[key]
  end
  local name, url, handle = field("name"), field("url"), field("handle")
  local blocks = pandoc.Blocks({})
  if name then
    blocks:insert(pandoc.Para({ pandoc.Strong(pandoc.Str(name)) }))
  end
  local lines = {}
  if url then
    table.insert(lines, pandoc.Link({ pandoc.Str(url) }, url))
  end
  if handle then
    if #lines > 0 then
      table.insert(lines, pandoc.LineBreak())
    end
    table.insert(lines, pandoc.Str(handle))
  end
  if #lines > 0 then
    blocks:insert(pandoc.Para(lines))
  end
  if #blocks == 0 then
    return nil
  end
  local attrs = {}
  local map = svg_uri("../artwork/ca-dot-map-contact.svg")
  if map then
    attrs.style = "background-image: url(" .. map .. ")"
  end
  return pandoc.Div(blocks, pandoc.Attr("", { "contact" }, attrs))
end

local function has_any(classes, list)
  for _, c in ipairs(list) do
    if classes:includes(c) then
      return true
    end
  end
  return false
end

local function slides(doc)
  local section = nil
  local red = brand_color("red", "#C24629")
  local contact = contact_block(doc.meta)
  local out = pandoc.Blocks({})
  local pending_contact = false

  for _, block in ipairs(doc.blocks) do
    local is_slide_start = block.t == "Header" and block.level <= 2
    if is_slide_start and pending_contact then
      out:insert(contact)
      pending_contact = false
    end

    if block.t == "Header" and block.level == 1 then
      section = pandoc.utils.stringify(block.content)
      if block.attributes["background-color"] == nil and block.attributes["background-image"] == nil then
        block.attributes["background-color"] = brand_color("orange-tint", "#FAECDA")
      end
    elseif block.t == "Header" and block.level == 2 then
      local classes = block.classes
      if classes:includes("quote") then
        if block.attributes["background-color"] == nil then
          block.attributes["background-color"] = red
        end
        -- Photo at 20% under the red, as in the template ("transparency 80%").
        if block.attributes["background-image"] and block.attributes["background-opacity"] == nil then
          block.attributes["background-opacity"] = "0.2"
        end
        block.attributes["state"] = block.attributes["state"] or "odi-dark-slide"
      elseif classes:includes("image-full") then
        block.attributes["state"] = block.attributes["state"] or "odi-full-slide"
      elseif classes:includes("closing") then
        if block.attributes["background"] == nil and block.attributes["background-image"] == nil
          and block.attributes["background-color"] == nil then
          block.attributes["background"] = gradient()
        end
        -- No footer on closing slides, as in the template.
        block.attributes["state"] = block.attributes["state"] or "odi-full-slide"
        pending_contact = contact ~= nil
      end

      if block.attributes["eyebrow"] == nil and section ~= nil and not has_any(classes, NO_EYEBROW) then
        block.attributes["eyebrow"] = section
      end
      if block.attributes["eyebrow"] == "" then
        block.attributes["eyebrow"] = nil
      end
    end
    out:insert(block)
  end
  if pending_contact then
    out:insert(contact)
  end
  doc.blocks = out

  -- Quarto injects the footer as an empty `.footer-default` div when no
  -- `footer` is set; fill it with the presentation title.
  local title = doc.meta.title
  if title ~= nil then
    doc.blocks = doc.blocks:walk({
      Div = function(div)
        if div.classes:includes("footer-default") and #div.content == 0 then
          div.content = { pandoc.Plain(pandoc.utils.type(title) == "Inlines" and title or pandoc.Inlines(title)) }
          return div
        end
      end,
    })
  end
  return doc
end

local function divs(div)
  -- Default label for the highlighted timeline step.
  if div.classes:includes("step") and div.classes:includes("current") and div.attributes["label"] == nil then
    div.attributes["label"] = "We are here"
  end
  -- Pandoc turns a Div that starts with a heading into a <section>, and reveal.js
  -- treats every <section> as a slide. A leading comment keeps boxes like
  -- `::: {.highlight}` + `### Title` as plain divs.
  local first = div.content[1]
  if first and first.t == "Header" then
    div.content:insert(1, pandoc.RawBlock("html", "<!-- -->"))
  end
  return div
end

return {
  { Meta = title_slide },
  { Div = divs },
  { Pandoc = slides },
}
