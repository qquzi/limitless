local StringToExpressions = {}

local math_methods = {}

math_methods[1] = function(v, min, max)
    local n = math.random(min, max)
    return ("%d-(%d)"):format(n, n - v)
end

math_methods[2] = function(v, min, max)
    local n = math.random(min, max)
    return ("%d+(%d)"):format(v - n, n)
end

math_methods[3] = function(v)
    local a = math.random(2, 8)
    return ("(%d*%d)"):format(v, a) .. "/" .. a
end

math_methods[4] = function(v)
    local a = math.random(25, 250)
    local b = a + v
    return ("(%d-%d)"):format(b, a)
end

local function randomIdentifier(length)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local out = {}

    for i = 1, length do
        local index = math.random(#chars)
        out[i] = chars:sub(index, index)
    end

    return table.concat(out)
end

local function buildExpression(value, min, max)
    local method = math_methods[math.random(1, #math_methods)]
    return "(" .. method(value, min, max) .. ")"
end

local function formatChar(value)
    if value < 32 or value > 126 then
        return ("\\%03d"):format(value)
    end

    return string.char(value)
end

local function insertChar(buffer, cache, tableName, value, min, max)
    cache[value] = true

    local access

    if math.random(1, 2) == 1 then
        access = ("%s[%s]"):format(
            tableName,
            buildExpression(value, min, max)
        )
    else
        access = ("%s[(%s)]"):format(
            tableName,
            buildExpression(value, min, max)
        )
    end

    buffer[#buffer + 1] = access
end

local function obfuscateString(str, min, max, cache, tableName)
    if #str == 0 then
        return '""'
    end

    local out = {}

    for i = 1, #str do
        insertChar(
            out,
            cache,
            tableName,
            str:byte(i),
            min,
            max
        )
    end

    if math.random(1, 2) == 1 then
        return table.concat(out, "..")
    end

    return ("table.concat({%s})"):format(
        table.concat(out, ",")
    )
end

function StringToExpressions.process(script_content, min, max)
    local used_ascii = {}
    local tableName = randomIdentifier(math.random(8, 16))

    local output = script_content:gsub(
        "(['\"])(.-)%1",
        function(_, value)
            return obfuscateString(
                value,
                min,
                max,
                used_ascii,
                tableName
            )
        end
    )

    local entries = {}

    for ascii in pairs(used_ascii) do
        entries[#entries + 1] =
            ("[%d]=string.char(%d)"):format(
                ascii,
                ascii
            )
    end

    return ("local %s={%s}\n%s"):format(
        tableName,
        table.concat(entries, ","),
        output
    )
end

return StringToExpressions
