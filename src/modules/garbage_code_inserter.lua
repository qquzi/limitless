-- using ai cuz im lazy
local GarbageCodeInserter = {}

local LOWER_A, LOWER_Z = 97, 122
local MAX_NUM = 100
local MAX_LOOP = 8
local VAR_LEN = 6

local function randName()
    local t = {}
    for _ = 1, VAR_LEN do
        t[#t+1] = string.char(math.random(LOWER_A, LOWER_Z))
    end
    return table.concat(t)
end

local function randNum(max)
    return math.random(1, max or MAX_NUM)
end

local function deadMath()
    local a, b = randNum(), randNum()
    return string.format("local %s = %d * %d - %d + %d",
        randName(), a, b, a, b
    )
end

local function deadBranch()
    return string.format([[
if (%d > %d and %d < %d) then
    local %s = %d
else
    local %s = %d
end
]], randNum(), randNum(), randNum(), randNum(),
randName(), randNum(), randName(), randNum())
end

local function deadLoop()
    local var = randName()
    return string.format([[
for %s = 1, %d do
    local %s = %d
end
]], var, randNum(MAX_LOOP), randName(), randNum())
end

local function deadFunction()
    return string.format([[
local function %s(%s)
    local %s = %d
    return %s
end
]], randName(), randName(), randName(), randNum(), randNum())
end

local generators = {
    deadMath,
    deadBranch,
    deadLoop,
    deadFunction
}

local function pick()
    return generators[math.random(#generators)]()
end

local function generateGarbage(count)
    local out = {}
    for _ = 1, count do
        out[#out+1] = pick()
    end
    return table.concat(out, "\n")
end

function GarbageCodeInserter.process(code, garbage_blocks)
    if type(code) ~= "string" or #code == 0 then
        error("Invalid code input", 2)
    end

    garbage_blocks = garbage_blocks or 5

    local prefix = generateGarbage(garbage_blocks)
    local suffix = generateGarbage(garbage_blocks)

    return table.concat({
        prefix,
        code,
        suffix
    }, "\n")
end

function GarbageCodeInserter.setSeed(seed)
    math.randomseed(seed or os.clock() * 1e6)
end

return GarbageCodeInserter
