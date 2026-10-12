-- Branded callouts: a tinted box with a colored bar on the left, no icon.
--
-- Adds four callout types to Quarto's five (note, tip, important, warning,
-- caution), written the same way:
--
--   ::: {.callout-takeaway}        Key takeaway
--   ::: {.callout-recommendation}  Recommendation
--   ::: {.callout-definition}      Definition
--   ::: {.callout-data-note}       Data note (smaller text, for sources and caveats)
--
-- A `title="..."` attribute or a leading heading replaces the default title.
--
-- Runs before Quarto parses callouts (`at: pre-ast`), because Quarto only
-- recognizes its own five types. HTML and RevealJS get the colors as CSS
-- variables (styled in html/_shared.scss); Typst gets an #odi-callout call
-- (typst/typst-template.typ). Callouts with a cross-reference id (#nte-...)
-- are left to Quarto in Typst so references keep working.
--
-- Colors are _brand.yml palette names; nothing is hardcoded.

-- Title colors meet WCAG AA (4.5:1) on their tint: orange, red, and purple
-- don't, so those titles use navy, dark-red, or dark-purple.
local TYPES = {
  note = { accent = "blue", tint = "blue-tint" },
  tip = { accent = "dark-purple", tint = "purple-tint" },
  important = { accent = "red", tint = "red-tint", title_color = "dark-red" },
  warning = { accent = "orange", tint = "orange-tint", title_color = "navy" },
  caution = { accent = "red", tint = "red-tint", title_color = "dark-red" },
  -- Same colors as the slide theme's `.takeaway` box.
  takeaway = { accent = "orange", tint = "orange-tint", title_color = "dark-red", title = "Key takeaway" },
  recommendation = { accent = "navy", tint = "blue-tint", title = "Recommendation" },
  definition = { accent = "purple", tint = "purple-tint", title_color = "dark-purple", title = "Definition" },
  ["data-note"] = { accent = "charcoal", tint = "off-white", title = "Data note", small = true },
}

local CROSSREF_PREFIXES = { "nte", "tip", "imp", "wrn", "cau" }

local function callout_type(div)
  for _, class in ipairs(div.classes) do
    local name = class:match("^callout%-(.+)$")
    if name and TYPES[name] then
      return name, class
    end
  end
end

local function is_crossref(id)
  local prefix = id:match("^(%a+)%-")
  for _, p in ipairs(CROSSREF_PREFIXES) do
    if prefix == p then
      return true
    end
  end
  return false
end

local function typst_color(name)
  return 'brand-color.at("' .. name .. '", default: black)'
end

-- Titles become a leading heading, which Quarto uses as the title (a
-- `title` attribute would also end up as an HTML tooltip, in raw Markdown).
-- Custom types without a title get their default one.
local function normalize_title(div, spec)
  local title = div.attributes["title"]
  div.attributes["title"] = nil
  if title and title ~= "" then
    local inlines = pandoc.utils.blocks_to_inlines(pandoc.read(title, "markdown").blocks)
    div.content:insert(1, pandoc.Header(2, inlines))
  elseif spec.title and not (div.content[1] and div.content[1].t == "Header") then
    div.content:insert(1, pandoc.Header(2, pandoc.Inlines(spec.title)))
  end
end

-- Title and body for Typst: the leading heading, else the type name (as Quarto does).
local function title_and_body(div, name)
  local body = pandoc.Blocks(div.content)
  if body[1] and body[1].t == "Header" then
    return body:remove(1).content, body
  end
  return pandoc.Inlines(name:sub(1, 1):upper() .. name:sub(2)), body
end

local function typst_callout(div, spec, name)
  local title, body = title_and_body(div, name)
  local args = {
    "accent: " .. typst_color(spec.accent),
    "tint: " .. typst_color(spec.tint),
    "title-color: " .. typst_color(spec.title_color or spec.accent),
    "small: " .. tostring(spec.small == true),
  }
  local open = pandoc.Inlines({ pandoc.RawInline("typst", "#odi-callout(" .. table.concat(args, ", ") .. ", title: [") })
  open:extend(title)
  open:insert(pandoc.RawInline("typst", "])["))
  local blocks = pandoc.Blocks({ pandoc.Plain(open) })
  blocks:extend(body)
  blocks:insert(pandoc.RawBlock("typst", "]"))
  return blocks
end

local function css_vars(spec)
  local vars = {
    "--odi-callout-accent: var(--brand-" .. spec.accent .. ")",
    "--odi-callout-tint: var(--brand-" .. spec.tint .. ")",
    "--odi-callout-title: var(--brand-" .. (spec.title_color or spec.accent) .. ")",
  }
  return table.concat(vars, "; ")
end

function Div(div)
  local name, class = callout_type(div)
  if not name then
    return nil
  end
  local spec = TYPES[name]
  normalize_title(div, spec)

  if quarto.doc.is_format("typst") and not is_crossref(div.identifier) then
    return typst_callout(div, spec, name)
  end

  -- Custom types become Quarto callouts: the type class must come before
  -- `callout` for Quarto to read the type from it.
  if not div.classes:includes("callout") then
    local _, index = div.classes:find(class)
    div.classes:insert(index + 1, "callout")
  end
  if quarto.doc.is_format("revealjs") then
    -- Quarto's RevealJS callouts drop the style attribute; the variables
    -- inherit from a wrapper instead.
    return pandoc.Div(div, pandoc.Attr("", { "odi-callout" }, { style = css_vars(spec) }))
  elseif quarto.doc.is_format("html") then
    local style = div.attributes["style"]
    div.attributes["style"] = css_vars(spec) .. (style and ("; " .. style) or "")
  end
  return div
end
