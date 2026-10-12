-- {{< boilerplate NAME >}}: insert a ready-made ODI slide from boilerplate/NAME.md.
--
-- Available: what-we-do, what-we-do-detail, who-we-are, mission, vision,
-- why-odi, projects. Put the shortcode on its own line; it expands to a whole
-- slide (a level-2 heading and its content).
--
-- Options:
--   image="photo.jpg"   background photo (e.g. for mission/vision; shown under red)
--
-- Edit the wording in boilerplate/*.md; no code changes needed.

local function available()
  local names = {}
  for _, file in ipairs(pandoc.system.list_directory(quarto.utils.resolve_path("../boilerplate"))) do
    local name = file:match("^(.+)%.md$")
    if name then
      table.insert(names, name)
    end
  end
  table.sort(names)
  return table.concat(names, ", ")
end

return {
  ["boilerplate"] = function(args, kwargs)
    local name = args[1] and pandoc.utils.stringify(args[1]) or ""
    local path = quarto.utils.resolve_path("../boilerplate/" .. name .. ".md")
    local f = name ~= "" and io.open(path, "r") or nil
    if not f then
      quarto.log.warning("boilerplate: unknown slide '" .. name .. "'. Available: " .. available())
      return pandoc.Para({ pandoc.Str("[boilerplate: unknown slide '" .. name .. "']") })
    end
    local blocks = pandoc.read(f:read("a"), "markdown").blocks
    f:close()

    local image = kwargs["image"] and pandoc.utils.stringify(kwargs["image"]) or ""
    local seen = 0
    for _, block in ipairs(blocks) do
      if block.t == "Header" then
        -- Unique slide ids (the reader's auto ids would collide, e.g. two "What we do").
        seen = seen + 1
        block.identifier = "boilerplate-" .. name .. (seen > 1 and ("-" .. seen) or "")
        if seen == 1 and image ~= "" then
          block.attributes["background-image"] = image
        end
      end
    end
    return blocks
  end,
}
