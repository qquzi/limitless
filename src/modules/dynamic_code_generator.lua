local DynamicCodeGenerator = {}

-- check if string is pure number
local function isNumber(str)
    return tonumber(str) ~= nil
end

-- literals eval
local function safeEval(block)
    block = block:gsub("^%s+", ""):gsub("%s+$", "")

    -- numbers only
    if isNumber(block) then
        return tonumber(block)
    end

    -- allow simple string literals
    if block:match("^'.*'$") or block:match('^".*"$') then
        return block:sub(2, -2)
    end

    return nil
end

function DynamicCodeGenerator.process(code)
    local output = {}
    local buffer = ""

    local function flushBuffer()
        if buffer ~= "" then
            local result = safeEval(buffer)

            if result ~= nil then
                table.insert(output, tostring(result))
            else
                -- keep original if not safely evaluable
                table.insert(output, buffer)
            end

            buffer = ""
        end
    end

    for token in code:gmatch(".") do
        if token:match("[%s%p]") then
            flushBuffer()
            table.insert(output, token)
        else
            buffer = buffer .. token
        end
    end

    flushBuffer()

    return table.concat(output)
end

return DynamicCodeGenerator
