-- HTML helpers for websites and books, styled after innovation.ca.gov
-- (html/_website.scss).
--
-- * The organization name (_brand.yml meta.name) above the navbar site title
--   (a CSS rule that only matches site navbars).
-- * A strip under the page footer with the legal links from _brand.yml
--   meta.link (conditions of use, privacy policy, accessibility) and the
--   copyright line.
-- * Pages with `title-block-banner: true` get the California dot map for the
--   banner background, embedded as a data URI so nothing is copied into the
--   user's project. Colors come from _brand.yml (the artwork is generated from
--   it by tools/build-assets.py).

if not quarto.doc.is_format("html") or quarto.doc.is_format("revealjs") then
  return {}
end

local BRAND = dofile(quarto.utils.resolve_path("brand-meta.lua"))

local LEGAL_LINKS = {
  { key = "conditions-of-use", label = "Conditions of use" },
  { key = "privacy-policy", label = "Privacy policy" },
  { key = "accessibility", label = "Accessibility" },
}

local function escape_html(str)
  return (str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"):gsub('"', "&quot;"))
end

local function css_string(str)
  return '"' .. str:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

local function svg_uri(rel)
  local f = io.open(quarto.utils.resolve_path(rel), "rb")
  if not f then
    return nil
  end
  local svg = f:read("a")
  f:close()
  return "data:image/svg+xml;base64," .. quarto.base64.encode(svg)
end

local function header_org_name()
  if not BRAND.name then
    return
  end
  quarto.doc.include_text("in-header",
    "<style>.navbar .navbar-title::before { content: " .. css_string(BRAND.name) .. "; }</style>")
end

-- Filters can't tell a website or book page from a single document (project
-- options aren't in the metadata), so the strip is added to every HTML page
-- and a script keeps it only on site pages: at the end of <footer> (Quarto
-- writes the page footer after include-after-body content), or at the end of
-- the page if the site has no page footer.
local function legal_footer()
  local items = {}
  for _, link in ipairs(LEGAL_LINKS) do
    local href = BRAND.links and BRAND.links[link.key]
    if href then
      table.insert(items, '<li><a href="' .. escape_html(href) .. '">' .. link.label .. "</a></li>")
    end
  end
  if #items == 0 and not BRAND.copyright then
    return
  end
  local copyright = BRAND.copyright
      and ("<p>Copyright &copy; " .. os.date("%Y") .. " " .. escape_html(BRAND.copyright) .. "</p>")
      or ""
  quarto.doc.include_text("after-body", table.concat({
    '<div class="odi-legal-footer">',
    '<ul class="list-unstyled">' .. table.concat(items) .. "</ul>",
    copyright,
    "</div>",
    "<script>",
    'document.addEventListener("DOMContentLoaded", () => {',
    '  const strip = document.querySelector(".odi-legal-footer");',
    '  if (!strip) return;',
    '  const footer = document.querySelector("footer.footer");',
    '  const site = document.body.matches(".nav-fixed, .nav-sidebar");',
    "  if (footer && site) footer.append(strip);",
    "  else if (site) document.body.append(strip);",
    "  else strip.remove();",
    "});",
    "</script>",
  }, "\n"))
end

local function banner(meta)
  local value = meta["title-block-banner"]
  if value == nil or value == false or pandoc.utils.stringify(value) == "false" then
    return
  end
  local uri = svg_uri("../artwork/ca-dot-map.svg")
  if uri then
    quarto.doc.include_text("in-header",
      '<style>.quarto-title-banner { --odi-dot-map: url("' .. uri .. '"); }</style>')
  end
end

function Meta(meta)
  header_org_name()
  legal_footer()
  banner(meta)
end
