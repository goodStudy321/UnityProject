--[[
	AU:Loong
	TM:2017.05.09
	BG:Lua工具
--]]

LuaTool = {}

--判断Unity对象是否为空
function LuaTool.IsNull(obj)
	if obj == nil then return true end
	if obj.Equals ~= nil then
		if obj:Equals(nil) then return true end
	end
	return false
end

--获取无序tabel长度
function LuaTool.Length(tab)
	if tab == nil then return 0 end
	local len = 0
	if tab then
		for k, v in pairs(tab) do
			len = len + 1
		end
	end
	return len
end

--取整
function LuaTool.GetIntPart(value)
	if value <= 0 then
		return math.ceil(value)
	end
	if math.ceil(value) == value then
		value = math.ceil(value)
	else
		value = math.ceil(value) - 1
	end
	return value
end


function LuaTool.TableDestory(table)
	local c1 = collectgarbage("count")
	--print("==============> 内存1   ",type(table))
	--print("==============> 内存1   ",c1)
	if type(table) ~= 'table' then return end
	for k, v in pairs(table) do
		--print("####################> table.k ",k)
		--print("--------------------> table.k ",type(v))
		if type(v) == 'table' then
			LuaTool.TableDestory(table[k])
		end
		table[k] = nil
	end
	table = nil
	c1 = collectgarbage("count")
	--print("==============> 内存2   ", c1)
end

function LuaTool.FormatNum(num)
	num = tonumber(num)
	if num < 10000 then
		return num
	end

	if num < 100000000 then 
		local value = num/10000
		local x, y = math.modf(value)
		local val = LuaTool.Bit(x)
		if val == 1 then
			return string.format("%.3f万", value)
		elseif val == 2 then
			return string.format("%.2f万", value)
		else
			return string.format("%.1f万", value)
		end
	end

	local value = num/100000000
	local x, y = math.modf(value)
	local val = LuaTool.Bit(x)
	if val == 1 then
		return string.format("%.3f亿", value)
	elseif val == 2 then
		return string.format("%.2f亿", value)
	elseif val == 3 then
		return string.format("%.1f亿", value)
	else
		return string.format("%.0f亿", value)
	end
end

function LuaTool.Bit(num)
	local bit = 0
	while num > 0 do 
		num = math.floor(num/10)
		bit = bit+1
	end
	return bit
end
