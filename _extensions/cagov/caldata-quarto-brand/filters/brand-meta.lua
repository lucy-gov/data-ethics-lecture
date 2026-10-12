-- Shared helper: identity values from the extension's _brand.yml `meta:`
-- (name, links, copyright). Used by slides.lua, typst.lua, and website.lua via dofile().
--
-- Returns a table: { name = "California Office of Data and Innovation",
--                    short = "ODI", url = "https://...", handle = "@...",
--                    links = { ["privacy-policy"] = "https://...", ... },
--                    copyright = "State of California" }

local function read(path)
  local f = io.open(path, "rb")
  if not f then
    return nil
  end
  local text = f:read("a")
  f:close()
  return text
end

local text = read(quarto.utils.resolve_path("../_brand.yml"))
if not text then
  return {}
end

-- Parse the YAML by reading it as a Markdown metadata block.
local meta = pandoc.read("---\n" .. text .. "\n---\n", "markdown").meta.meta or {}
local s = pandoc.utils.stringify

local name, short = nil, nil
if type(meta.name) == "table" and (meta.name.full or meta.name.short) then
  name = meta.name.full and s(meta.name.full)
  short = meta.name.short and s(meta.name.short)
elseif meta.name then
  name = s(meta.name)
end

local link = meta.link or {}
local url, handle, links = nil, nil, {}
if type(link) == "table" and (link.home or link.twitter) then
  url = link.home and s(link.home)
  if link.twitter then
    handle = "@" .. s(link.twitter):match("([^/]+)/?$")
  end
elseif meta.link then
  url = s(meta.link)
end
if type(link) == "table" then
  for key, value in pairs(link) do
    links[key] = s(value)
  end
end

return {
  name = name,
  short = short,
  url = url,
  handle = handle,
  links = links,
  copyright = meta.copyright and s(meta.copyright),
}
