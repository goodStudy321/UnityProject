--[[
 	authors 	:Liu
 	date    	:2019-07-01 16:30:00
 	descrition 	:限定活动信息
--]]

LimitActivInfo = {Name = "LimitActivInfo"}

local My = LimitActivInfo

function My:Init()
	--兑换列表
	self.buyList = {}
end

--设置兑换列表
function My:SetBuyList(id, val)
	for i,v in ipairs(self.buyList) do
		if v.id == id then
			v.val = val
			return
		end
	end
	local data = {}
	data.id = id
	data.val = val
	table.insert(self.buyList, data)
end

--更新兑换次数
function My:UpBuyCount(id)
	if self:IsExist(id) == false then
		self:SetBuyList(id, 1)
		return
	end
	for i,v in ipairs(self.buyList) do
		if v.id == id then
			local num = v.val + 1
			local val = (num < 0) and 0 or num
			v.val = val
		end
	end
end

--是否存在列表
function My:IsExist(id)
	if #self.buyList < 1 then return false end
	local isExist = false
	for i,v in ipairs(self.buyList) do
		if v.id == id then
			isExist = true
		end
	end
	return isExist
end

--根据id获取兑换次数
function My:GetCount(id)
	for i,v in ipairs(self.buyList) do
		if v.id == id then
			return v.val
		end
	end
	return 0
end

--清理缓存
function My:Clear()
	ListTool.Clear(self.buyList)
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My