local Parts = {}

local function CreateTbl(_) return {} end
local Select = select
local Unpack = unpack or table.unpack

local function Pack(...)
    return { n = Select('#', ...), ... }
end

local function Move(src, first, last, offset, dst)
    for i = 0, last - first do
        dst[offset + i] = src[first + i]
    end
end

local function BAnd(a, b)
    local result = 0
    local bitval = 1
    while a > 0 and b > 0 do
        if (a % 2 == 1) and (b % 2 == 1) then
            result = result + bitval
        end
        bitval = bitval * 2
        a = math.floor(a / 2)
        b = math.floor(b / 2)
    end
    return result
end

local function LShift(x, n)
    return x * 2 ^ n
end

local function RShift(x, n)
    return math.floor(x / 2 ^ n)
end

local function BOr(a, b)
    local result = 0
    local shift = 1
    while a > 0 or b > 0 do
        local abit = a % 2
        local bbit = b % 2
        if abit == 1 or bbit == 1 then
            result = result + shift
        end
        a = math.floor(a / 2)
        b = math.floor(b / 2)
        shift = shift * 2
    end
    return result
end

local function CloseLuaUpvalues(B, N)
    for i, uv in pairs(B) do
        if uv.N >= N then
            uv.m = uv.M[uv.N]
            uv.M = uv
            uv.N = 'm'
            B[i] = nil
        end
    end
end

local function SetLuaUpvalue(B, N, X)
    local prev = B[N]
    if not prev then
        prev = { N = N, M = X }
        B[N] = prev
    end
    return prev
end

local function NormalizeNumber(v)
    return v
end

local _orig_tostring = tostring
function tostring(v)
    if type(v) == "number" then
        local s = _orig_tostring(v)
        if not s:find("[%.eE]") then
            return s .. ".0"
        end
        return s
    end
    return _orig_tostring(v)
end

local asciilookup = {}
for i = 0, 255 do
    asciilookup[string.char(i)] = i
end

local function chartoascii(str, pos)
    pos = pos or 1
    return asciilookup[str:sub(pos, pos)]
end

function BcToState(Bytecode, charset)
    local base = #charset
    local decoded = {}
    local decode_lookup = {}

    for i = 1, base do
        decode_lookup[charset:sub(i, i)] = i - 1
    end

    for encoded_char in Bytecode:gmatch("([^_]+)") do
        local n = 0
        for i = 1, #encoded_char do
            n = n * base + decode_lookup[encoded_char:sub(i, i)]
        end
        decoded[#decoded + 1] = string.char(n)
    end

    local bytes = {}
    for char in table.concat(decoded):gmatch("(.?)\\") do
        if #char > 0 then
            bytes[#bytes + 1] = chartoascii(char)
        end
    end

    local Pos = 1

    local function gBits8()
        local v = bytes[Pos]
        Pos += 1
        return v
    end

    local function gBits16()
        local v1, v2 = bytes[Pos], bytes[Pos + 1]
        Pos += 2
        return (v2 * 256) + v1
    end

    local function gBits32()
        local v1, v2, v3, v4 = bytes[Pos], bytes[Pos + 1], bytes[Pos + 2], bytes[Pos + 3]
        Pos += 4
        return (v4 * 16777216) + (v3 * 65536) + (v2 * 256) + v1
    end

    function gChunk()
        local Chunk = {
            n = gBits8(),
            c = gBits8(),
            d = gBits8(),
            x = {},
            D = {},
            V = {}
        }

        for i = 1, gBits32() do
            local Data = gBits32()
            local Sco = gBits8()
            local Type = gBits8()

            local Inst = {
                m = Data,
                S = Sco,
                A = gBits16()
            }

            local Mode = {
                b = gBits8(),
                c = gBits8()
            }

            if Type == 1 then
                Inst.B = gBits16()
                Inst.C = gBits16()
                Inst.s = Mode.b == 1 and Inst.B > 0xFF
                Inst.a = Mode.c == 1 and Inst.C > 0xFF
            elseif Type == 2 then
                Inst.F = gBits32()
                Inst.g = Mode.b == 1
            elseif Type == 3 then
                Inst.f = gBits32() - 131071
            end

            Chunk.x[i] = Inst
        end

        for i = 1, gBits32() do
            local Type = gBits8()

            if Type == 1 then
                Chunk.D[i - 1] = (gBits8() ~= 0)
            elseif Type == 3 then
                Chunk.D[i - 1] = (function()
                    local L = gBits32()
                    local R = gBits32()
                    local Mantissa = BOr(LShift(BAnd(R, 0xFFFFF), 32), L)
                    local Exponent = BAnd(RShift(R, 20), 0x7FF)
                    local Sign = (-1) ^ RShift(R, 31)

                    if Exponent == 0 then
                        if Mantissa == 0 then
                            return Sign * 0
                        else
                            Exponent = 1
                        end
                    elseif Exponent == 2047 then
                        if Mantissa == 0 then
                            return Sign * (1 / 0)
                        else
                            return Sign * (0 / 0)
                        end
                    end

                    local raw = math.ldexp(Sign, Exponent - 1023)
                        * (1 + (Mantissa / (2 ^ 52)))

                    return NormalizeNumber(raw)
                end)()
            elseif Type == 4 then
                Chunk.D[i - 1] = (function()
                    local len = gBits32()
                    if len == 0 then return end
                    local chars = {}
                    for j = 1, len do
                        chars[#chars + 1] = string.char(gBits8())
                    end
                    return table.concat(chars)
                end)()
            end
        end

        for i = 1, gBits32() do
            Chunk.V[i - 1] = gChunk()
        end

        for _, v in ipairs(Chunk.x) do
            if v.g then
                v.D = Chunk.D[v.F]
            else
                if v.s then
                    v.A = Chunk.D[v.B - 256]
                end
                if v.a then
                    v.C = Chunk.D[v.C - 256]
                end
            end
        end

        return Chunk
    end

    return gChunk()
end

function LuaFunc(State, Env, n)
    local x = State.x
    local z = State.z

    while true do
        local Inst = x[z]
        if not Inst then break end
        z = z + 1
    end

    State.z = z
end

function WrapState(V, Env, Upval)
    local function Wrapped(...)
        local Passed = Pack(...)
        local X = CreateTbl(V.d)
        local v = { b = 0, B = {} }

        Move(Passed, 0, V.c, 0, X)

        if V.c < Passed.n then
            local Start = V.c + 1
            local b = Passed.n - V.c
            v.b = b
            Move(Passed, Start, Start + b - 1, 0, v.B)
        end

        local State = {
            v = v,
            X = X,
            x = V.x,
            Z = V.V,
            z = 1
        }

        return LuaFunc(State, Env, Upval)
    end

    return Wrapped
end

Parts.Deserializer = BcToState
Parts.Wrapper_1 = LuaFunc
Parts.Wrapper_2 = WrapState

return Parts
