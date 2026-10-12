-- Typst (PDF) helpers for the ODI document layouts in typst/.
--
-- * Defaults from _brand.yml meta: `org` (header/footer name) and, for the
--   one-pager and flyer layouts, the `eyebrow` above the title
--   (`eyebrow: false` to hide).
-- * `odi-artwork`: path to artwork/ for the report cover, relative to the
--   Typst root (the project directory).
-- * `::: {.lead}` becomes a Merriweather lead paragraph (#odi-lead).

if not quarto.doc.is_format("typst") then
  return {}
end

local BRAND = dofile(quarto.utils.resolve_path("brand-meta.lua"))

local function absolute(path)
  if not pandoc.path.is_absolute(path) then
    path = pandoc.path.join({ pandoc.system.get_working_directory(), path })
  end
  path = pandoc.path.normalize(path)
  -- Collapse "dir/.." segments (normalize leaves them).
  local n
  repeat
    path, n = path:gsub("/[^/]+/%.%.", "", 1)
  until n == 0
  return path
end

-- Metadata value inserted verbatim as a Typst string literal (Pandoc would
-- otherwise escape characters such as "_").
local function typst_string(value)
  local str = pandoc.utils.stringify(value):gsub("\\", "\\\\"):gsub('"', '\\"')
  return pandoc.MetaInlines({ pandoc.RawInline("typst", str) })
end

-- Root-relative path ("/..."), as Typst resolves image paths against the project root.
local function root_path(rel)
  local abs = absolute(quarto.utils.resolve_path(rel))
  local root = absolute(quarto.project.directory or pandoc.path.directory(quarto.doc.input_file))
  local path = pandoc.path.make_relative(abs, root):gsub("^/+", ""):gsub("/%./", "/")
  return "/" .. path
end

local function meta_defaults(meta)
  local layout = meta.layout and pandoc.utils.stringify(meta.layout) or "paper"
  if meta.org == nil and BRAND.name then
    meta.org = BRAND.name
  end
  if meta.org ~= nil then
    meta.org = typst_string(meta.org)
  end
  if meta.eyebrow == nil and BRAND.name and (layout == "one-pager" or layout == "flyer") then
    meta.eyebrow = pandoc.MetaString(BRAND.name)
  end
  meta["odi-artwork"] = typst_string(root_path("../artwork"))
  return meta
end

local function lead(div)
  if div.classes:includes("lead") then
    local blocks = pandoc.Blocks({ pandoc.RawBlock("typst", "#odi-lead[") })
    blocks:extend(div.content)
    blocks:insert(pandoc.RawBlock("typst", "]"))
    return blocks
  end
end

return {
  { Meta = meta_defaults },
  { Div = lead },
}
