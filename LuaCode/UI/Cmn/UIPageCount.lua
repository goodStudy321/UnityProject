--region UIPageCount.lua
--Date
--此文件由[HS]创建生成

UIPageCount = Super:New{Name="UIPageCount"}
local M = UIPageCount

M.eCountChange = Event()

M.MaxCount = 999
M.MinCount = 0
M.Count = 0

function M:Ctor()
end

function M:Init(go)
	self.root = go
	local name = "翻页计数"
	local trans = self.root.transform
	local C = ComTool.Get
	local T = TransTool.FindChild
	
	self.Input = C(UIInput, trans, "Input", name, false)
	self.AddBtn = T(trans, "Add")
	self.ReduceBtn = T(trans, "Reduce")

	self:Event()
end

function M:Event()
	local E = UITool.SetLsnrSelf
	if self.AddBtn then
		E(self.AddBtn, self.AddCount, self)
	end
	if self.ReduceBtn then
		E(self.ReduceBtn, self.ReduceCount, self)
	end
	self.CountChange = EventDelegate.Callback(self.OnCountChange, self)
	self:SetDelegate(EventDelegate.Add)
end

function M:SetDelegate(E)
	if self.Input then
		E(self.Input.onChange, self.CountChange)
	end
end

function M:AddCount()
	if self.Count == nil then  self.Count = 0 end
	if self.Count + 1 > self.MaxCount then
		UITip.Error("数量已经达到上限")
		return
	end
	self.Count = self.Count + 1
	self:UpdateCount()
end

function M:ReduceCount()
	if self.Count == nil then  self.Count = 0 end
	if self.Count - 1 < self.MinCount then
		UITip.Error("数量已经达到下限")
		return
	end
	self.Count = self.Count - 1
	self:UpdateCount()
end

function M:UpdateCount(event)
	if self.Input then
		self.Input.value = tostring(self.Count)
	end
	if event == false then return end
	self.eCountChange()
end

function M:OnCountChange()
	if self.Input then
		local count = tonumber(self.Input.value)
		if count == nil then count = 0 end
		self.Count = count
	end
	self.eCountChange()
end

function M:SetCount(count)
	if count == nil then count = 0 end
	self.Count = count
	self:UpdateCount(false)
end

function M:Reset()
	self.Count = 0
	self:UpdateCount()
end

function M:Dispose()
	self.MaxCount = 999
	self.MinCount = 0
	self.Count = 0
	TableTool.ClearDic(self)
end
--endregion
