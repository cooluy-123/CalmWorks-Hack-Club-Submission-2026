-- Shared presentation only. Preserve wording/facts; remove deliberate paragraph breaks.
local Text = {}
function Text.OneParagraph(value)
    if type(value) ~= "string" then
        return ""
    end
    local text = value
    text = text:gsub(utf8.char(0x2028), " ")
    text = text:gsub(utf8.char(0x2029), " ")
    text = text:gsub(utf8.char(0x0085), " ")
    text = text:gsub(utf8.char(0x00A0), " ")
    text = text:gsub("%s+", " ")
    text = text:match("^%s*(.-)%s*$")
    return text
end
function Text.Compose(background, customerInsight)
    local facts, insight = Text.OneParagraph(background), Text.OneParagraph(customerInsight)
    if facts == "" then
        return insight
    end
    if insight == "" then
        return facts
    end
    return facts .. " " .. insight
end
return Text
