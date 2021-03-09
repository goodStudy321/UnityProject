--[[ 	
  authors 	:Loong
 	date    	:2017-08-31 15:14:10
 	descrition 	:Binary Search Tool
--]]
BinTool = {}

local My = BinTool

--arr 要搜索的数组
--id 要搜索的唯一ID的值
--idName 要搜索的唯一ID属性的名称
--返回值为条目和索引，未搜索到返回nil ,-1
function My.Find(arr, id, idName)
	if type(arr) ~= "table" then return nil, - 1 end
	if type(id) ~= "number" then return nil, - 1 end
	idName = idName or "id"
	local beg = 1
	local mid = 0
	local res = 0
	local conf = nil
	local last = #arr
	while beg <= last do
		mid =(beg + last) * 0.5
		mid = math.ceil(mid)
		conf = arr[mid]
		res = conf[idName]
		if type(res) ~= "number" then return - 1 end
		if id == res then
			return arr[mid], mid
		elseif id > res then
			beg = mid + 1
		elseif id < res then
			last = mid - 1
		end
	end
	return nil, - 1
end

function My.FindProName(arr, id, idName)
	if type(arr) ~= "table" then return nil, - 1 end
	if type(id) ~= "number" then return nil, - 1 end
	idName = idName or "id"
	local beg = 1
	local mid = 0
	local res = 0
	local conf = nil
	local last = #arr
	while beg <= last do
		conf = arr[beg]
		res = conf[idName]
		if type(res) ~= "number" then return - 1 end
		if id == res then
			return arr[beg], beg
		else
			beg = beg + 1
		end
	end
	return nil, - 1
end

function My.KeyFind(arr, id, idName)
	local temp = nil
	for i,v in ipairs(arr) do
		if v[idName]==id then 
			temp=v
		end
	end
	return temp
end
