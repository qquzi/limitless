-- shit on you ts prob not work
local FunctionInliner = {}

local function trim(s)
    return (s:gsub("^%s+", ""):gsub("%s+$", ""))
end

local function splitParams(paramStr)
    local params = {}
    for p in paramStr:gmatch("[^,%s]+") do
        params[#params+1] = p
    end
    return params
end

local function splitArgs(argStr)
    local args = {}
    for a in (argStr .. ","):gmatch("([^,]*),") do
        args[#args+1] = trim(a)
    end
    return args
end

function FunctionInliner.process(code)
    if code:match("^%s*%-%-.*Obfuscated") then
        return code
    end

    local functions = {}

    -- remove comments 
    local cleaned = code:gsub("%-%-[^\n]*", "")

    -- capture top function
    cleaned = cleaned:gsub(
        "local%s+function%s+([%w_]+)%s*%(([^)]*)%)%s*(.-)%s*end",
        function(name, params, body)
            functions[name] = {
                params = splitParams(params),
                body = body
            }
            return ""
        end
    )

    cleaned = cleaned:gsub(
        "function%s+([%w_]+)%s*%(([^)]*)%)%s*(.-)%s*end",
        function(name, params, body)
            functions[name] = {
                params = splitParams(params),
                body = body
            }
            return ""
        end
    )

    -- inline calls 
    for name, func in pairs(functions) do
        cleaned = cleaned:gsub(name .. "%s*(%b())", function(call)
            local args = splitArgs(call:sub(2, -2))
            local body = func.body

            -- replace params with args
            for i, param in ipairs(func.params) do
                local arg = args[i] or "nil"

                body = body:gsub(
                    "%f[%w_]" .. param .. "%f[^%w_]",
                    arg
                )
            end

            body = trim(body)

            -- only inline expression shit returns
            if body:match("^return%s+") then
                body = body:gsub("^return%s+", "")
            else
                -- wrap multiline 
                body = "(" .. body .. ")"
            end

            return "(" .. body .. ")"
        end)
    end

    return cleaned
end

return FunctionInliner
