local OpaquePredicateInjector = {}

local function rand(a, b)
    return math.random(a or 1, b or 100)
end

-- opaque i use ai haha HelloWorld('print')
local function generatePredicate()
    local a, b = rand(), rand()

    local pool = {
        function()
            return string.format("((%d * %d) %% %d) >= 0", a, b, a + 1)
        end,
        function()
            return string.format("(%d ^ 2 + %d ^ 2) >= 0", a, b)
        end,
        function()
            return string.format("(math.sin(%d)^2 + math.cos(%d)^2) <= 1", a, a)
        end,
        function()
            return string.format("((%d < %d) ~= (%d >= %d))", a, b, a, b)
        end
    }

    return pool[math.random(#pool)]()
end

-- statement detect 
local function isSafe(stmt)
    stmt = stmt:gsub("^%s+", ""):gsub("%s+$", "")

    if stmt == "" then return false end

    local unsafe = {
        "^if%s",
        "^for%s",
        "^while%s",
        "^function%s",
        "^repeat%s",
        "^until%s",
        "^do%s",
        "^local%s+function"
    }

    for _, p in ipairs(unsafe) do
        if stmt:match(p) then
            return false
        end
    end

    return true
end

local function wrap(stmt)
    local pred = generatePredicate()
    return string.format("if %s then %s end", pred, stmt)
end

function OpaquePredicateInjector.process(code)
    if type(code) ~= "string" then
        error("code must be string")
    end

    local out = {}

    for line in code:gmatch("[^\n]+") do
        local ws, stmt = line:match("^(%s*)(.*)$")

        if isSafe(stmt) then
            table.insert(out, ws .. wrap(stmt))
        else
            table.insert(out, line)
        end
    end

    return table.concat(out, "\n")
end

function OpaquePredicateInjector.validateCode(code)
    local f, err = load(code)
    return f ~= nil, err
end

return OpaquePredicateInjector
