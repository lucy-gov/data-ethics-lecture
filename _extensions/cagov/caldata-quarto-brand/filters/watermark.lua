-- Optional watermark, set with `watermark:` metadata:
--
--   watermark: draft          DRAFT
--   watermark: confidential   CONFIDENTIAL
--   watermark: "Do not cite"  any other text, shown in capitals
--
-- HTML: a stamp in the bottom right corner, plus large faint diagonal text
-- over the page as decoration (also printed).
-- RevealJS: a stamp in the corner of every slide.
-- Typst: large faint diagonal text on every page (typst/typst-template.typ,
-- passed as `odi-watermark`).
-- Styles for HTML and RevealJS are in html/_shared.scss.

local function text_of(meta)
  local value = meta.watermark
  if value == nil or value == false then
    return nil
  end
  local text = pandoc.utils.stringify(value)
  if text == "" or text == "false" then
    return nil
  end
  return text:upper()
end

local function escape_html(str)
  return (str:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;"))
end

function Meta(meta)
  local text = text_of(meta)
  if not text then
    return nil
  end

  local label = escape_html(text)
  if quarto.doc.is_format("revealjs") then
    quarto.doc.include_text("after-body",
      '<div class="odi-watermark-stamp slides" role="note">' .. label .. "</div>")
  elseif quarto.doc.is_format("html") then
    -- Visible stamp (accessible) plus the decorative diagonal (CSS-drawn, hidden).
    quarto.doc.include_text("after-body", string.format(
      '<div class="odi-watermark-stamp" role="note">%s</div>'
        .. '<div class="odi-watermark" data-label="%s" style="--odi-watermark-chars: %d" aria-hidden="true"></div>',
      label, label, utf8.len(text) or #text))
  elseif quarto.doc.is_format("typst") then
    -- Inserted verbatim as a Typst string literal.
    local str = text:gsub("\\", "\\\\"):gsub('"', '\\"')
    meta["odi-watermark"] = pandoc.MetaInlines({ pandoc.RawInline("typst", str) })
    return meta
  end
end
