--region UIPetSkillScrollView.lua
--
--此文件由[HS]创建生成

UIPetSkillScrollView = baseclass(UIScrollViewBase)

--构造函数
function UIPetSkillScrollView:Ctor(go, callback)
	self.Name = "UIPetSkillScrollView"
	self.Callback = callback
	self.ScrollLimit = 4
	self.MinCount = 8
end

function UIPetSkillScrollView:Init()
	self:UpdateItems(self.MinCount)
end

function UIPetSkillScrollView:UpdateData(skillList, skillDic, isUnLocak)
	self:CleanCells()
	if not skillList or not skillDic then return end
	self.SkillIDList = skillList
	self.SkillDic = skillDic
	for i=1, #skillList do
		local id = skillList[i]
		local key = tostring(id)
		local index = i - 1
		if self.Items[tostring(index)] then 
			self.Items[tostring(index)]:UpdateIcon(skillDic[key].Icon)
			local skill = SkillLvTemp[tostring(skillDic[key].SkillID)]
			if skill then
				if isUnLocak then
					self.Items[tostring(index)]:IsUnlock(true)
				else
					self.Items[tostring(index)]:IsUnlock(skillDic[key].IsUnlock)
				end
			end
		end
	end
	--[[
	if not skillList then return end
	self.SkillList = skillList
	local total = skillList.Count - 1
	for i=0,total do
		if self.Items[tostring(i)] then 
			local skill = SkillLvTemp[tostring(skillList[i].SkillID)]
			if skill then
				self.Items[tostring(i)]:UpdateIcon(skillList[i].SkillID..".png")
				if isUnLocak then
					self.Items[tostring(i)]:IsUnlock(true)
				else
					self.Items[tostring(i)]:IsUnlock(skillList[i].IsUnlocak)
				end
			end
		end
	end
	]]--
end

--增加关联Cell
function UIPetSkillScrollView:AddCell(key, go)
	self.Items[key] = UICellSkillUnlock.New(go)
	self.Items[key]:Init()
end

--点击ItemCell
function UIPetSkillScrollView:OnClickItem(go)
	local str = string.gsub(go.name, "Item_", "")
	local index = tonumber(str) + 1
	if not self.SkillIDList or LuaTool.Length(self.SkillIDList) < index then return end
	if not self.SkillIDList[index] then return end
	local id = self.SkillIDList[index]
	local key = tostring(id)
	local skill = SkillLvTemp[key]
	if not skill then return end
	if self.Callback then self.Callback(skill) end
	--[[
	if not self.SkillList or self.SkillList.Count <= index then return end
	if not self.SkillList[index] then return end 
	local skill = SkillLvTemp[tostring(self.SkillList[index].SkillID)]
	if not skill then return end
	if self.Callback then self.Callback(skill) end
	]]--
end


function UIPetSkillScrollView:RemoveItems()
	while self.Grid:GetChildList().Count > target do
		local key = tostring(self.Grid:GetChildList().Count - 1)
		self:Super('RemoveItem',key)
		--self:RemoveItem(key)
	end
end
--endregion
