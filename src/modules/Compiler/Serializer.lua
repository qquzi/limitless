local bit = require("modules/Compiler/bit")

local Serialize = {}

local function addByte(buffer, v)
    buffer[#buffer+1] = string.char(v) .. "\\"
end

local function w8(buf, v)
    addByte(buf, v)
end

local function w16(buf, v)
    for i = 0, 1 do
        addByte(buf, bit.band(bit.rshift(v, i * 8), 255))
    end
end

local function w32(buf, v)
    for i = 0, 3 do
        addByte(buf, bit.band(bit.rshift(v, i * 8), 255))
    end
end

local function writeFloat(buf, v)
    local sign = (v < 0 or (v == 0 and 1 / v == -math.huge)) and 1 or 0

    local mantissa, exponent = math.frexp(math.abs(v))

    if v == 0 then
        exponent, mantissa = 0, 0
    elseif v == math.huge then
        exponent, mantissa = 2047, 0
    elseif v ~= v then
        exponent, mantissa = 2047, 1
    else
        mantissa = (mantissa * 2 - 1) * 2 ^ 52
        exponent = exponent + 1022
    end

    local high = sign * 2 ^ 31
        + exponent * 2 ^ 20
        + math.floor(mantissa / 2 ^ 32)

    local low = mantissa % 2 ^ 32

    w32(buf, low)
    w32(buf, high)
end

local function writeString(buf, s)
    w32(buf, #s)
    for i = 1, #s do
        w8(buf, s:byte(i))
    end
end

local function argFlag(v)
    if v == "OpArgK" then return 1 end
    return 0
end

local function writeChunk(buf, c)
    w8(buf, c.Upvals)
    w8(buf, c.Parameters)
    w8(buf, c.MaxStack)

    w32(buf, #c.Instructions)

    for i = 1, #c.Instructions do
        local ins = c.Instructions[i]

        w32(buf, ins.Value)
        w8(buf, ins.Enum)
        w8(buf, (ins.Type == "ABC" and 1) or (ins.Type == "ABx" and 2) or 3)

        w16(buf, ins.A)
        w8(buf, argFlag(ins.Mode.b))
        w8(buf, argFlag(ins.Mode.c))

        if ins.Type == "ABC" then
            w16(buf, ins.B)
            w16(buf, ins.C)
        elseif ins.Type == "ABx" then
            w32(buf, ins.Bx)
        else
            w32(buf, ins.sBx + 131071)
        end
    end

    w32(buf, #c.Constants)

    for i = 1, #c.Constants do
        local ct = c.Constants[i]
        local t = type(ct)

        if t == "boolean" then
            w8(buf, 1)
            w8(buf, ct and 1 or 0)
        elseif t == "number" then
            w8(buf, 3)
            writeFloat(buf, ct)
        elseif t == "string" then
            w8(buf, 4)
            writeString(buf, ct)
        end
    end

    w32(buf, #c.Protos)

    for i = 1, #c.Protos do
        writeChunk(buf, c.Protos[i])
    end
end

function Serialize(Chunk)
    local buf = {}
    writeChunk(buf, Chunk)
    return table.concat(buf)
end

return Serialize
