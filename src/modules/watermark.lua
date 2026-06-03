-- modules/watermark.lua
local Watermark = {}

function Watermark.process(code)
    return "--[Obfuscated by 76/105/109/105/116/108/101/115/115]\n" .. code
end

return Watermark
