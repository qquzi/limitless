local VariableRenamer = {}

local reserved = {
    ["if"]=true,["then"]=true,["else"]=true,["elseif"]=true,["end"]=true,
    ["for"]=true,["while"]=true,["do"]=true,["repeat"]=true,["until"]=true,
    ["function"]=true,["local"]=true,["return"]=true,["break"]=true,
    ["and"]=true,["or"]=true,["not"]=true,["nil"]=true,["true"]=true,["false"]=true
}

local function randName(minL, maxL)
    local len = math.random(minL or 8, maxL or 12)
    local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
    local out = {}
    for i = 1, len do
        out[#out+1] = chars:sub(math.random(1,#chars), math.random(1,#chars))
    end
    return table.concat(out)
end

local function replaceWord(code, old, new)
    return code:gsub("%f[%w_]"..old.."%f[^%w_]", new)
end

function VariableRenamer.process(code, options)
    options = options or {}

    local minL = options.min_length or 8
    local maxL = options.max_length or 12

    local map = {}

    code = code:gsub("%-%-[^\n]*", "")

    local localPattern = "local%s+([%w_,%s]+)%s*="

    for vars in code:gmatch(localPattern) do
        for v in vars:gmatch("[%w_]+") do
            if not reserved[v] and #v > 1 and not map[v] then
                map[v] = randName(minL, maxL)
            end
        end
    end

    for fname, args in code:gmatch("function%s+([%w_]+)%s*%(([%w_,%s]*)%)") do
        if not reserved[fname] and not map[fname] then
            map[fname] = randName(minL, maxL)
        end

        for a in args:gmatch("[%w_]+") do
            if not reserved[a] and not map[a] then
                map[a] = randName(minL, maxL)
            end
        end
    end

    for old, new in pairs(map) do
        code = replaceWord(code, old, new)
    end

    return code
end

return VariableRenamer
