local Wrapper = {}

local function randomName(length)
	local chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
	local out = {}

	for i = 1, length do
		local r = math.random(1, #chars)
		out[i] = chars:sub(r, r)
	end

	return table.concat(out)
end

function Wrapper.process(code)
	local wrapperName = randomName(math.random(12, 24))

	return string.format([[
local function %s(...)
%s
end
return %s(...)
]], wrapperName, code, wrapperName)
end

return Wrapper
