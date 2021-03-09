--[[
 	authors 	:Liu
 	date    	:2018-12-13 10:00:00
 	descrition 	:结婚时间项
--]]

UIMarryFeastIt = Super:New{Name = "UIMarryFeastIt"}

local My = UIMarryFeastIt

function My:Init(root, index, list)
	local des = self.Name
	local CG = ComTool.Get
	local CGS = ComTool.GetSelf
	local SetS = UITool.SetBtnSelf
	local FindC = TransTool.FindChild

	self.lab1 = CG(UILabel, root, "timeLab")
	self.box = CGS(BoxCollider, root, des)
	self.spr1Go = FindC(root, "sprs/spr1", des)
	self.spr2Go = FindC(root, "sprs/spr2", des)
	self.spr3Go = FindC(root, "sprs/spr3", des)
	self.select = FindC(root, "spr", des)

	self.index = index
	self.list = list

	SetS(root, self.OnClick, self, des)
	self:InitState()
end

--点击自身
function My:OnClick()
	self:UpSelectState()
end

--初始化状态
function My:InitState()
	local index = self.index
	local str = ""
	if index == 24 then
		str = string.format("00:00\n00:15")
	else
		str = string.format("%s:00\n%s:15", index, index)
	end
	self.lab1.text = str
	local isOverdue = self:IsOverdue()
	if isOverdue then
		self:SetState(false, false, true)
	else
		self:SetState(true, false, false)
		self.isCanAppoint = true
	end
end

--更新状态
function My:UpState()
	local isOverdue = self:IsOverdue()
	if isOverdue then
		self:SetState(false, false, true)
		self.isCanAppoint = false
	else
		self:SetState(false, true, false)
		self.box.enabled = false
		self.isCanAppoint = false
	end
end

--判断是否是过期的
function My:IsOverdue()
	local sHour = SignInfo:GetTime("HH")
	local sMinute = SignInfo:GetTime("mm")
	self.box.enabled = false
	if sHour >= self.index then
		return true
	elseif sHour >= (self.index - 1) then
		if sMinute > 50 then
			return true
		end
	end
	self.box.enabled = true
	return false
end

--设置状态
function My:SetState(state1, state2, state3)
	self.spr1Go:SetActive(state1)
	self.spr2Go:SetActive(state2)
	self.spr3Go:SetActive(state3)
end

--更新选中状态
function My:UpSelectState()
	for i,v in ipairs(self.list) do
		if i == self.index then
			v.select:SetActive(true)
		else
			v.select:SetActive(false)
		end
	end
end

--清理缓存
function My:Clear()
    self.isCanAppoint = false
end
    
--释放资源
function My:Dispose()
    self:Clear()
end
    
return My