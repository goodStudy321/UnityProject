--region UIDialog.lua
--Date
--此文件由[HS]创建生成

require("UI/UIDialog/UIDialogItem")

UIDialog = UIBase:New{Name ="UIDialog"}

local M = UIDialog

--注册的事件回调函数
local Error = iTrace.Error
local NPCMgr = NPCMgr.instance

function M:InitCustom()
	self.Persitent = true;
	local name = "lua�Ի�����"
	local trans = self.root
	local T = TransTool.FindChild
	self.TalkIndex = 0
	self.Talk = UIDialogItem.New(T(trans, "Base"))
	self.Talk:Init()
	self.SmallTalk = UIDialogItem.New(T(trans, "Small"))
	self.SmallTalk:Init()

	self.TimerTool = ObjPool.Get(DateTimer)
	self.TimerTool.complete:Add(self.EndTimer, self)
	self.IsCountDown = false
	self.IsClick = true
	local EH = EventHandler
	self.OnUpdateUIDialog = EH(self.UpdateUIDialog, self)
   	self.OnUpdateDataUIDialog = EH(self.UpdateDataUIDialog, self)
	self.OnUpdateData = EH(self.UpdateData, self)
	  
	self:AddEvent()
end

function M:AddEvent()
	local E = UITool.SetLsnrSelf
	local M = EventMgr.Add
	if self.gbj then
		E(self.gbj, self.OnClick, self, nil, false)
	end
	M("UpdateUIDialog", self.OnUpdateUIDialog)
	M("UpdateDataUIDialog",self.OnUpdateDataUIDialog)
	M("UpdateDataUIDialogList", self.OnUpdateData)
end

function M:RemoveEvent()
	local M = EventMgr.Remove
	M("UpdateUIDialog", self.OnUpdateUIDialog)
	M("UpdateDataUIDialog",self.OnUpdateDataUIDialog)
	M("UpdateDataUIDialogList", self.OnUpdateData)
end

--�����հ�λ��
function M:OnClickBlank(gameObject)
	if not self.IsClick then return end
	self:Close()
end

--�����Ի����屳��
function M:OnClick(gameObject)
	local Data = nil
	if self.TalkList then 
		if self.TalkList.Count > self.TalkIndex then
			self.TimerTool:Stop()
			self.IsCountDown = false
			Data = self.TalkList[self.TalkIndex]
			self:UpdateView(Data.left, Data.name, Data.text, Data.modelName, Data.style)
			self.TalkIndex = self.TalkIndex + 1
			if self.IsCountDown  or Data.timer == 0 then return end
    		if self.TimerTool then 
				self.IsCountDown = true
				self.TimerTool.seconds = Data.timer
    			self.TimerTool:Start()
   			end
			return
		end
	end
	if not self.IsClick then return end
	self:Close()
end

--����������Ϣ
function M:UpdateData(Dialogs, o)
	self.IsClick = o or true
	self.TalkList = Dialogs
	self:OnClick(nil)
end
--[[
function M:UpdateUIDialog(npcid, missionid)
	self.NTemp = NPCTemp[tostring(npcid)]
	self.MTemp = MissionTemp[tostring(missionid)]
	if not self.NTemp then 
   		Error("hs", string.format("NPCTemp数据为空 id: ",npcid))
		return
	end
	if not self.MTemp then 
   		Error("hs", string.format("MissionTemp数据为空 id: ",missionid))
		return
	end
	self.RTemp = RoleBaseTemp[tostring(self.NTemp.modeID)]
	if not self.RTemp then 
   		Error("hs", string.format("RoleBaseTemp数据为空 id: ",self.NTemp.modeID))
		return
	end
	self:UpdateView(2, self.NTemp.name, self.MTemp.talk, self.RTemp.icon, 0)
end
]]--
function M:UpdateDataUIDialog(npcInfo, missionData, nodeName)
	self.NpcInfo = npcInfo 
	self.MissionData = missionData
	local talk = User:GetMissionTalk(self.NpcInfo.id, self.MissionData)
end

function M:UpdateView(isLeft, name, talk, path, t)
	self:Clean()
	if StrTool.IsNullOrEmpty(name) then
		name = "神秘人"
	end
	if StrTool.IsNullOrEmpty(talk) then
		talk = "没有配对话"
	end
	
	if self.Cur then
		self.Cur:SetActive(false)
	end
	if t == 0 then
		self.Cur = self.Talk
	else
		self.Cur = self.SmallTalk
	end
	self.Cur:UpdateData(isLeft, name, talk, path)
	self.Cur:SetActive(true)
end

function M:EndTimer()
	--self:Close()
	self:Close()
end


function M:Clean( )
	self.TalkIndex = 0
	self.Cur = nil
    if self.TimerTool then self.TimerTool:Stop() end
	self.IsCountDown = false
	if self.Talk then self.Talk:Clean() end
	if self.SmallTalk then self.SmallTalk:Clean() end
	if self.TalkList then self.TalkList:Clear() end
end

function M:OpenCustom()
	EventMgr.Trigger("IsShowUIDialog", true)
end

function M:CloseCustom()
	self:Clean()
	NPCMgr:CloaseUI()
	EventMgr.Trigger("IsShowUIDialog", false)
end

function M:DisposeCustom()
	self:RemoveEvent()
	if self.TimerTool then
		self.TimerTool:AutoToPool()
		self.TimerTool = nil
	end
	if self.Talk then self.Talk:Dispose() end
	self.Talk = nil
	if self.SmallTalk then self.SmallTalk:Dispose() end
	self.SmallTalk = nil
end

function M:CanRecords()
	do return false end
end

return UIDialog
--endregion
