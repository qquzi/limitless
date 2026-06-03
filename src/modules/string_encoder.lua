local StringEncoder = {}

-- idk decoder

local function randName()
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local s = {}
    for i = 1, math.random(8, 12) do
        local c = chars:sub(math.random(1, #chars), math.random(1, #chars))
        s[#s+1] = c
    end
    return table.concat(s)
end

local function caesar(str, offset)
    local out = {}

    for i = 1, #str do
        local b = str:byte(i)

        if b >= 48 and b <= 57 then
            b = ((b - 48 + offset) % 10) + 48
        elseif b >= 65 and b <= 90 then
            b = ((b - 65 + offset) % 26) + 65
        elseif b >= 97 and b <= 122 then
            b = ((b - 97 + offset) % 26) + 97
        end

        out[#out+1] = string.char(b)
    end

    return table.concat(out)
end

function StringEncoder.process(code)
    local decoderName = randName()

    local decodeFn = string.format([[
local function %s(str, offset)
    local out = {}
    for i = 1, #str do
        local b = str:byte(i)

        if b >= 48 and b <= 57 then
            b = ((b - 48 - offset + 10) %% 10) + 48
        elseif b >= 65 and b <= 90 then
            b = ((b - 65 - offset + 26) %% 26) + 65
        elseif b >= 97 and b <= 122 then
            b = ((b - 97 - offset + 26) %% 26) + 97
        end

        out[#out+1] = string.char(b)
    end
    return table.concat(out)
end
]], decoderName)

    -- string capture
    code = code:gsub("\\\\", "\0ESCAPE\0")

    code = code:gsub([["(.-)"]], function(str)
        local offset = math.random(1, 25)
        local encoded = caesar(str, offset)
        return string.format('%s("%s", %d)', decoderName, encoded, offset)
    end)

    code = code:gsub([['(.-)']], function(str)
        local offset = math.random(1, 25)
        local encoded = caesar(str, offset)
        return string.format("%s('%s', %d)", decoderName, encoded, offset)
    end)

    code = code:gsub("\0ESCAPE\0", "\\\\")

    return decodeFn .. "\n" .. code
end

return StringEncoder
