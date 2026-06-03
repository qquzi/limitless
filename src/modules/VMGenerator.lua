local Parts = require("modules/Compiler/VMStrings")
local GetOpcodeCode = require("modules/Compiler/Opcode")
local compile = require("modules/Compiler/Compiler")

math.randomseed(os.time())

local function generate(...)
	local data = { ... }

	local bytecode = data[1]
	local used_opcodes = data[2]

	local lines = {}

	local function add(line)
		lines[#lines + 1] = line
	end

	local function generateVariable(length)
		local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_"
		local result = {}

		local first = math.random(1, 52)
		result[1] = charset:sub(first, first)

		for i = 2, length do
			local rand = math.random(1, #charset)
			result[i] = charset:sub(rand, rand)
		end

		return table.concat(result)
	end

	local function stringShuffle(str)
		local n = #str
		local codes = {}

		for i = 1, n do
			codes[i] = str:byte(i)
		end

		for i = n, 2, -1 do
			local j = math.random(1, i)
			codes[i], codes[j] = codes[j], codes[i]
		end

		for i = 1, n do
			codes[i] = string.char(codes[i])
		end

		return table.concat(codes)
	end

	local function getChar(n)
		local out = {}

		for i = 1, n do
			out[#out + 1] = string.char(i)
		end

		return table.concat(out)
	end

	local charset = stringShuffle(getChar(126))

	local base = #charset
	local encode_lookup = {}
	local decode_lookup = {}

	for i = 1, base do
		local c = charset:sub(i, i)

		encode_lookup[i - 1] = c
		decode_lookup[c] = i - 1
	end

	local function encodeNumber(n)
		local encoded = {}

		repeat
			local r = n % base

			table.insert(encoded, 1, encode_lookup[r])

			n = math.floor(n / base)
		until n == 0

		return table.concat(encoded)
	end

	local function encodeString(str)
		local encoded = {}

		for i = 1, #str do
			encoded[#encoded + 1] = encodeNumber(str:byte(i))
		end

		return table.concat(encoded, "_")
	end

	local function encode(str_param, raw)
		raw = raw or false

		if not raw then
			str_param = encodeString(str_param)
		end

		local out = {}

		for i = 1, #str_param do
			out[#out + 1] = "\\" .. string.byte(str_param, i)
		end

		return table.concat(out)
	end

	add(
		generateVariable(24)
		.. "='Protected By Limitless',function()end,true,1,0"
	)

	add(Parts.Variables)
	add(Parts.Deserializer)
	add(Parts.Wrapper_1)

	local shuffled = {}

	for _, v in pairs(used_opcodes) do
		table.insert(shuffled, v)
	end

	for i = #shuffled, 2, -1 do
		local j = math.random(i)
		shuffled[i], shuffled[j] = shuffled[j], shuffled[i]
	end

	local k = "if"

	for _, v in ipairs(shuffled) do
		local op = used_opcodes[v]

		add(k .. " (S == " .. op .. ") then\n")
		add(GetOpcodeCode(op))

		k = "elseif"
	end

	add("end")
	add(Parts.Wrapper_2)

	local envCall = "(getfenv and getfenv(0)) or _ENV"

	add(
		"(function()"
			.. "local A=BcToState('"
			.. encode(bytecode)
			.. "','"
			.. encode(charset, true)
			.. "');"
			.. "return WrapState(A,"
			.. envCall
			.. ")()"
			.. "end)()"
	)

	return table.concat(lines, "\n")
end

local VM = {}

function VM.process(source)
	local UsedInstructions = _G.UsedInstructions or {}

	UsedInstructions[0] = 0
	UsedInstructions[4] = 4

	_G.UsedInstructions = UsedInstructions

	source = generate(
		compile(source),
		UsedInstructions
	)

	return source
end

return VM
