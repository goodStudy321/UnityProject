--region UIMissionGroupItem.lua
--任务面板 任务group条目基类
--此文件由[HS]创建生成
UIMissionGroupItem = Super:New{Name="UIMissionGroupItem"}
local M = UIMissionGroupItem
local mMgr = MissionMgr

M.StatusStr = {"[00FF00](可接取)[-]","[008ffc](进行中)[-]","[00FF00](已完成)[-]","[00FF00](已完成)[-]","(已失败)"}

--构造函数
function M:Init(go)
	self.Root = go
	local trans = self.Root.transform
	local name = "UIMissionGroupItem"
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.NameLab = C(UILabel, trans, "Name", name, false)
	self.Select = T(trans, "Select")
	self.Action = T(trans, "Action")
	self.StatusLab = C(UILabel, trans, "Status", name, false)
end

--更新任务数据
function M:UpdateData(mission)
	self.Miss = mission
	if not mission then return end
	local temp = mission.Temp 
	if not temp then return end
	local name = self.NameLab
	if name then name.text = temp.name end
	self:UpdateStatus(mission)
	self:UpdateAction(mission)
end

function M:UpdateStatus(mission)
	local status = self.StatusLab
	if status then 
		if mission.Temp.lv > User.MapData.Level then
			status.text = string.format("[FF0000]%s级开启[-]",mission.Temp.lv)
		else
			status.text = self.StatusStr[mission.Status] 
		end
	end
end

function M:UpdateAction(mission)
	self.Action:SetActive(mission.Status == MStatus.ALLOW_SUBMIT)
end

function M:ChangeLv()
	local miss = self.Miss
	if not miss then return end
	local mission = mMgr:GetMissionForID(miss.ID)
	self:UpdateData(mission)
end

function M:UpdateSelect(value)
	local select = self.Select
	if select then select:SetActive(value) end
end

function M:IsSelect()
	local select = self.Select
	if select then 
		return select.activeSelf  
	end
	return false
end

function M:SetActive(value)
	local go = self.Root
	if go then
		go:SetActive(value)
		if value == false then self:Clear() end
	end
end

function M:Clear()
	local name = self.NameLab
	local status = self.StatusLab
	if name then name.text = "" end
	if status then status.text = "" end
	self:UpdateSelect(false)
	self.Action:SetActive(false)
end

--销毁释放
function M:Dispose()
	self.Name = nil
	self.Status = nil
	self.Select = nil
	Destroy(self.Root)
	TableTool.ClearDic(self)
end
--endregion
