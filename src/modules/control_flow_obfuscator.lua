local ControlFlowObfuscator = {}

math.randomseed(os.clock() * 1e6)

-- generate safe integer ids
local function randId()
    return math.random(100000, 999999)
end

-- wrap a statement block into a fake control-flow loop
local function wrapBlock(block)
    local id = randId()

    return string.format([[
do
    local _cf_%d = false
    while not _cf_%d do
        _cf_%d = true

        %s

    end
end
]], id, id, id, block)
end

-- inject opaque predicate (simple but extensible)
local function opaquePredicate()
    local a = randId()
    local b = randId()

    -- always true but looks dynamic
    return string.format("(%d * %d %%%% %d) == %d", a, b, a + 1, (a * b) % (a + 1))
end

-- main transform
function ControlFlowObfuscator.obfuscate(code, options)
    options = options or {}

    local chunks = {}

    -- naive splitting (you can upgrade this later to AST parsing)
    for line in code:gmatch("[^\r\n]+") do
        line = line:gsub("^%s+", ""):gsub("%s+$", "")

        if line ~= "" then
            if math.random() < 0.35 then
                -- wrap some lines in fake flow
                table.insert(chunks, wrapBlock(line))
            else
                -- opaque predicate junk layer
                local pred = opaquePredicate()
                table.insert(chunks, string.format(
                    "if %s then %s end",
                    pred,
                    line
                ))
            end
        end
    end

    return table.concat(chunks, "\n\n")
end

return ControlFlowObfuscator
