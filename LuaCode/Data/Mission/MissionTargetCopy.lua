--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetCopy = baseclass(MissionTarget)
local M = MissionTargetCopy
local Error = iTrace.Error

--构造函数
function M:Ctor()
	self.SceneTemp = nil			--场景配置
	self.CopyTemp = nil				--副本配置
	self.OnIsShowUIDialog = nil
end

--更新任务配置表
function M:UpdateMTemp(temp)
	self:Super("UpdateMTemp", temp)
	self.IsEndFlowChart = self.Tree == nil
end

--更新目标数据
function M:UpdateTarData(tar)
	self.TID = tar[1] 			--SceneId
	self.SID = tar[2]
	self.LNum = tar[3] 		--次数
	self:Super("UpdateTarData", tar)
end

function M:UpdateTabelData()
	local key = tostring(self.SID)
	self.SceneTemp = SceneTemp[key]
	self.CopyTemp = CopyTemp[key]
	if not self.SceneTemp and not self.CopyTemp then 
   		Error("hs", string.format("场景ID||副本ID：%s 不存在！！", self.SID))
   		return
   	end
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	self.Execute = execute
	local t = nil
	local tarType = self.TID
	if tarType == 0 then
		self:EnterCopy()
	else
		self:OpenUIView()
	end
end

function M:EnterCopy()
	local copy = self.CopyTemp
	local scene = self.SceneTemp
	if copy then
		MsgBox.CloseOpt = MsgBoxCloseOpt.No
		MsgBox.ShowYesNo(string.format("是否进入%s进行挑战",copy.name),self.OKBtn, self, nil, self.NoBtn, self, nil, copy.preTime)
		return
	end
end

function M:OKBtn()
	if not self.CopyTemp then return end
    SceneMgr:ReqPreEnter(self.CopyTemp.id, true, false)
end

function M:NoBtn()
	Hangup:ClearAutoInfo()
end

function M:OpenUIView()
	local name = ""
	local type = self.TID
	if type == CopyType.Exp	then
		name = UICopy.Name
	elseif type == CopyType.Glod then
		name = UICopy.Name
	elseif type == CopyType.Equip then
		name = UICopy.Name
	elseif type == CopyType.Tower then
		name = UICopyTowerPanel.Name
	elseif type == CopyType.PBoss then
		name = UIBoss.Name
	elseif type == CopyType.SingleTD then
		name = UICopy.Name
	elseif type == CopyType.Five then
		SMSControl:OpenCopyUI()
		return
	end
	if StrTool.IsNullOrEmpty(name) then return end
	UIMgr.Open(name, self.OpenUI, self)
end

function M:OpenUI(name)
	local ui = nil
	if name == UICopy.Name then
		ui = UIMgr.Dic[UICopy.Name]
		if ui then
			-- local id = 0
			-- if self.TID == CopyType.Exp then
			-- 	id = 2
			-- elseif self.TID == CopyType.Glod then
			-- 	id = 8
			-- elseif self.TID == CopyType.SingleTD then
			-- 	id = 4
			-- end
			ui:SetPage(self.TID)
		end
	end
end

--任务描述
function M:TargetDes()
	local des = ""
	local tarName = "副本名字"
	if self.SceneTemp or self.CopyTemp then tarName = self:GetSceneName() end
	des = string.format("[c8d0e3]通关[%s]%s[-](%s/%s)", "%s", tarName, self.Num, self.LNum) 
	return des
end

function M:GetSceneName()
	local scene = self.SceneTemp
	local copy = self.CopyTemp
	if scene and scene.mapchildtype then
		return scene.name
	end
	if copy then
		if copy.diff ~=0 then
			return string.format( "%s[%s]", copy.name, GetDiffTypeName(copy.diff))
		else
			return copy.name
		end
	end
	return nil
end

--释放或销毁
function M:Dispose(isDestory)
	local E = EventMgr.Remove
	E("IsShowUIDialog",self.OnIsShowUIDialog)
	self.OnIsShowUIDialog  = nil
	self.NTemp = nil			
	self.NPCPos = nil		
	self:Super("Dispose", isDestory)
end
--endregion
