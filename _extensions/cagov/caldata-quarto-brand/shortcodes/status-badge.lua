-- {{< status-badge STATUS >}}: an inline colored status pill.
--
-- Statuses: draft, in-review, final, deprecated. Any other text becomes a
-- charcoal badge with that label, e.g. {{< status-badge "Pilot" >}}.
--
-- HTML and RevealJS get a <span> (styled in html/_shared.scss), Typst an
-- #odi-badge call (typst/typst-template.typ), other formats a [BRACKETED] tag.
-- Colors are _brand.yml palette names; nothing is hardcoded.

local STATUSES = {
  -- Orange fails contrast with white text, so draft uses navy text.
  draft = { label = "Draft", fill = "orange", text = "navy" },
  ["in-review"] = { label = "In review", fill = "blue", text = "white" },
  final = { label = "Final", fill = "navy", text = "white" },
  deprecated = { label = "Deprecated", fill = "red", text = "white" },
}
local CUSTOM = { fill = "charcoal", text = "white" }

local function typst_string(str)
  return '"' .. str:gsub("\\", "\\\\"):gsub('"', '\\"') .. '"'
end

return {
  ["status-badge"] = function(args)
    local raw = args[1] and pandoc.utils.stringify(args[1]) or ""
    if raw == "" then
      quarto.log.warning("status-badge: missing status, e.g. {{< status-badge draft >}}")
      return pandoc.Inlines({})
    end
    local spec = STATUSES[raw:lower()] or CUSTOM
    local label = spec.label or raw

    if quarto.doc.is_format("html") then
      local style = "--odi-badge-fill: var(--brand-" .. spec.fill .. "); --odi-badge-text: var(--brand-" .. spec.text .. ")"
      return pandoc.Span(pandoc.Inlines(label), pandoc.Attr("", { "odi-badge" }, { style = style }))
    elseif quarto.doc.is_format("typst") then
      return pandoc.RawInline("typst", string.format(
        '#odi-badge(fill: brand-color.at("%s", default: gray), text-color: brand-color.at("%s", default: white), %s)',
        spec.fill, spec.text, typst_string(label)))
    end
    return pandoc.Str("[" .. label:upper() .. "]")
  end,
}
