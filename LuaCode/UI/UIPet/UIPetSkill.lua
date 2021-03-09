--region UIPetSkillScrollView.lua
--
--此文件由[HS]创建生成

UIPetSkill = {}
local P = UIPetSkill
P.Name = "UIPetSkill"
P.ShowSkillTip = Event()

--构造函数
function P:New()
	return self
end

function P:Init(go)
	self.gameObject = go
	local trans = go.transform
	local T = TransTool.FindChild
	
	self.Cells = {}
	for i=1, 4 do
		local target = string.format("Item%s", i)
		self.Cells[i] = UICellSkillUnlock.New(T(trans, target))
		self.Cells[i]:Init()
	end
	self:InitEvent()
end

function P:InitEvent()
	local E = UITool.SetLsnrSelf
	for i,v in ipairs(self.Cells) do
		E(v.gameObject, self.OnClickCells, self, nil, false)
	end
end

function P:UpdateData()
	self.List = PetMgr.AllSkillIDList
	self.Dic = PetMgr.AllSkillDic
	self:UpdateSKill()
end

function P:UpdateSKill()
	self:Clean()
	if not self.List then return end
	if not self.Dic then return end
	local len = #self.Cells
	for i=1, len do
		if self.List[i] then
			local id = self.List[i]
			local key = tostring(id)
			if self.Dic[key] then
				self:UpdateCell(i, self.Dic[key])
			end
		end
	end
end

--增加关联Cell
function P:UpdateCell(index, data)
	if not self.Cells[index] then return end
	self.Cells[index]:UpdateIcon(data.Icon)
	self.Cells[index]:IsUnlock(data.IsUnlock)
end

--点击ItemCell
function P:OnClickCells(go)
	local str = string.gsub(go.name, "Item", "")
	local index = tonumber(str)
	local id = self.List[index]
	if id then 
		local temp = SkillLvTemp[tostring(id)]
		if temp  then
			self.ShowSkillTip(temp)
		end
	end
end

function P:Clean()
	local len = #self.Cells
	for i=1,len do
		if self.Cells[i] then
			self.Cells[i]:Clean()
		end
	end
end

function P:Dispose()
	self.ShowSkillTip:Clear()
	if self.Cells then
		while #self.Cells > 0 do
			table.remove(self.Cells)
		end
	end
	self.Cells = nil
	self.gameObject = nil
	self.List = nil
	self.Dic = nil
end
--endregion
