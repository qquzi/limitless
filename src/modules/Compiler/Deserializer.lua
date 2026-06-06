local bit = require("modules/Compiler/bit")
local UsedOps = {}
if not table.create then
	function table.create(_)
		return {}
	end
end;
local lua_bc_to_state;
local stm_lua_func;
local OPCODE_T = {
	[0] = 'ABC',
	'ABx',
	'ABC',
	'ABC',
	'ABC',
	'ABx',
	'ABC',
	'ABx',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'AsBx',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'ABC',
	'AsBx',
	'AsBx',
	'ABC',
	'ABC',
	'ABC',
	'ABx',
	'ABC'
}
local OPCODE_M = {
	[0] = {
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgK',
		c = 'OpArgN'
	},
	{
		b = 'OpArgU',
		c = 'OpArgU'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgU',
		c = 'OpArgN'
	},
	{
		b = 'OpArgK',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgN'
	},
	{
		b = 'OpArgU',
		c = 'OpArgN'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgU',
		c = 'OpArgU'
	},
	{
		b = 'OpArgR',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgR'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgK',
		c = 'OpArgK'
	},
	{
		b = 'OpArgR',
		c = 'OpArgU'
	},
	{
		b = 'OpArgR',
		c = 'OpArgU'
	},
	{
		b = 'OpArgU',
		c = 'OpArgU'
	},
	{
		b = 'OpArgU',
		c = 'OpArgU'
	},
	{
		b = 'OpArgU',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgR',
		c = 'OpArgN'
	},
	{
		b = 'OpArgN',
		c = 'OpArgU'
	},
	{
		b = 'OpArgU',
		c = 'OpArgU'
	},
	{
		b = 'OpArgN',
		c = 'OpArgN'
	},
	{
		b = 'OpArgU',
		c = 'OpArgN'
	},
	{
		b = 'OpArgU',
		c = 'OpArgN'
	}
}
local function rd_int_basic(src, s, e, d)
	local num = 0;
	for i = s, e, d do
		local mul = 256 ^ math.abs(i - s)
		num = num + mul * string.byte(src, i, i)
	end;
	return num
end;
local function rd_flt_basic(f1, f2, f3, f4)
	local sign = (- 1) ^ bit.rshift(f4, 7)
	local exp = bit.rshift(f3, 7) + bit.lshift(bit.band(f4, 127), 1)
	local frac = f1 + bit.lshift(f2, 8) + bit.lshift(bit.band(f3, 127), 16)
	local normal = 1;
	if exp == 0 then
		if frac == 0 then
			return sign * 0
		else
			normal = 0;
			exp = 1
		end
	elseif exp == 127 then
		if frac == 0 then
			return sign * (1 / 0)
		else
			return sign * (0 / 0)
		end
	end;
	return sign * 2 ^ (exp - 127) * (1 + normal / 2 ^ 23)
end;
local function rd_dbl_basic(f1, f2, f3, f4, f5, f6, f7, f8)
	local sign = (- 1) ^ bit.rshift(f8, 7)
	local exp = bit.lshift(bit.band(f8, 127), 4) + bit.rshift(f7, 4)
	local frac = bit.band(f7, 15) * 2 ^ 48;
	local normal = 1;
	frac = frac + (f6 * 2 ^ 40) + (f5 * 2 ^ 32) + (f4 * 2 ^ 24) + (f3 * 2 ^ 16) + (f2 * 2 ^ 8) + f1;
	if exp == 0 then
		if frac == 0 then
			return sign * 0
		else
			normal = 0;
			exp = 1
		end
	elseif exp == 2047 then
		if frac == 0 then
			return sign * (1 / 0)
		else
			return sign * (0 / 0)
		end
	end;
	return sign * 2 ^ (exp - 1023) * (normal + frac / 2 ^ 52)
end;
local function rd_int_le(src, s, e)
	return rd_int_basic(src, s, e - 1, 1)
end;
local function rd_int_be(src, s, e)
	return rd_int_basic(src, e - 1, s, - 1)
end;
local function rd_flt_le(src, s)
	return rd_flt_basic(string.byte(src, s, s + 3))
end;
local function rd_flt_be(src, s)
	local f1, f2, f3, f4 = string.byte(src, s, s + 3)
	return rd_flt_basic(f4, f3, f2, f1)
end;
local function rd_dbl_le(src, s)
	return rd_dbl_basic(string.byte(src, s, s + 7))
end;
local function rd_dbl_be(src, s)
	local f1, f2, f3, f4, f5, f6, f7, f8 = string.byte(src, s, s + 7)
	return rd_dbl_basic(f8, f7, f6, f5, f4, f3, f2, f1)
end;
local float_types = {
	[4] = {
		little = rd_flt_le,
		big = rd_flt_be
	},
	[8] = {
		little = rd_dbl_le,
		big = rd_dbl_be
	}
}
local function stm_byte(S)
	local idx = S.index;
	local bt = string.byte(S.source, idx, idx)
	S.index = idx + 1;
	return bt
end;
local function stm_string(S, len)
	local pos = S.index + len;
	local str = string.sub(S.source, S.index, pos - 1)
	S.index = pos;
	return str
end;
local function stm_lstring(S)
	local len = S:s_szt()
	local str;
	if len ~= 0 then
		str = string.sub(stm_string(S, len), 1, - 2)
	end;
	return str
end;
local function cst_int_rdr(len, func)
	return function(S)
		local pos = S.index + len;
		local int = func(S.source, S.index, pos)
		S.index = pos;
		return int
	end
end;
local function cst_flt_rdr(len, func)
	return function(S)
		local flt = func(S.source, S.index)
		S.index = S.index + len;
		return flt
	end
end;

local OPCODES = {}
for i = 0, 37 do
	OPCODES[i] = {
		Type = OPCODE_T[i],
		Mode = OPCODE_M[i]
	}
end
local function stm_inst_list(S)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		local ins = S:s_ins()
		local op = bit.band(ins, 63)
		local desc = OPCODES[op]
		local data = {
			Id = i,
			Value = ins,
			Enum = op,
			Type = desc.Type,
			Mode = desc.Mode,
			A = bit.band(bit.rshift(ins, 6), 255),
			Next = i + 1
		}
		if desc.Type == 'ABC' then
			data.B = bit.band(bit.rshift(ins, 23), 511)
			data.C = bit.band(bit.rshift(ins, 14), 511)
		elseif desc.Type == 'ABx' then
			data.Bx = bit.band(bit.rshift(ins, 14), 262143)
		elseif desc.Type == 'AsBx' then
			data.sBx = bit.band(bit.rshift(ins, 14), 262143) - 131071
			data.Target = i + 1 + data.sBx
		end;
		UsedOps[op] = true
		list[i] = data
	end;
	return list
end;
local function stm_const_list(S)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		local tt = stm_byte(S)
		local k;
		if tt == 1 then
			k = stm_byte(S) ~= 0
		elseif tt == 3 then
			k = S:s_num()
		elseif tt == 4 then
			k = stm_lstring(S)
		end;
		list[i] = {
			Type = tt,
			Value = k
		}
	end;
	return list
end;
local function stm_sub_list(S, src)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		list[i] = stm_lua_func(S, src)
	end;
	return list
end;
local function stm_line_list(S)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		list[i] = S:s_int()
	end;
	return list
end;
local function stm_loc_list(S)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		list[i] = {
			varname = stm_lstring(S),
			startpc = S:s_int(),
			endpc = S:s_int()
		}
	end;
	return list
end;
local function stm_upval_list(S)
	local len = S:s_int()
	local list = table.create(len)
	for i = 1, len do
		list[i] = stm_lstring(S)
	end;
	return list
end;
local function BuildCFG(proto)
	local cfg = {}
	for i, ins in ipairs(proto.Instructions) do
		cfg[i] = {
			Id = i,
			Instruction = ins,
			Successors = {}
		}
		if ins.Target then
			table.insert(cfg[i].Successors, ins.Target)
		end;
		if proto.Instructions[i + 1] then
			table.insert(cfg[i].Successors, i + 1)
		end;
	end;
	return cfg
end;

function stm_lua_func(S, psrc)
	local proto = {}
	local src = stm_lstring(S) or psrc;
	proto.SourceName = src;
	proto.FirstLine = S:s_int()
	proto.LastLine = S:s_int()
	proto.Upvals = stm_byte(S)
	proto.Parameters = stm_byte(S)
	stm_byte(S)
	proto.MaxStack = stm_byte(S)
	proto.Instructions = stm_inst_list(S)
	proto.Constants = stm_const_list(S)
	proto.Protos = stm_sub_list(S, src)
	proto.Debug = {
		Lines = stm_line_list(S),
		Locals = stm_loc_list(S),
		UpvalueNames = stm_upval_list(S)
	}
	proto.CFG = BuildCFG(proto)
	proto.Metadata = {
		InstructionCount = #proto.Instructions,
		ConstantCount = #proto.Constants,
		ProtoCount = #proto.Protos
	}
	return proto
end;
function Deserialize(src)
	local rdr_func;
	local little;
	local size_int;
	local size_szt;
	local size_ins;
	local size_num;
	local flag_int;
	local stream = {
		index = 1,
		source = src
	}
	assert(stm_string(stream, 4) == '\27Lua', 'invalid Lua signature')
	assert(stm_byte(stream) == 81, 'invalid Lua version')
	assert(stm_byte(stream) == 0, 'invalid Lua format')
	little = stm_byte(stream) ~= 0;
	size_int = stm_byte(stream)
	size_szt = stm_byte(stream)
	size_ins = stm_byte(stream)
	size_num = stm_byte(stream)
	flag_int = stm_byte(stream) ~= 0;
	rdr_func = little and rd_int_le or rd_int_be;
	stream.s_int = cst_int_rdr(size_int, rdr_func)
	stream.s_szt = cst_int_rdr(size_szt, rdr_func)
	stream.s_ins = cst_int_rdr(size_ins, rdr_func)
	if flag_int then
		stream.s_num = cst_int_rdr(size_num, rdr_func)
	elseif float_types[size_num] then
		stream.s_num = cst_flt_rdr(size_num, float_types[size_num][little and 'little' or 'big'])
	else
		error('unsupported float size')
	end;
	return stm_lua_func(stream, '@virtual')
end;
return Deserialize
