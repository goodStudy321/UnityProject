--[[
好友聊天跟聊天基类  CanTalk,VoiceTalk
]]
require("UI/UIChat/Chat")
ChatBase=Super:New{Name="ChatBase"}
local My = ChatBase
--My.eSendVoice=Event()

function My:InitCustom(trans)
    local TF = TransTool.FindChild
    local CG = ComTool.Get
	local  U = UITool.SetLsnrClick
	local S = UITool.SetLsnrSelf

    self.CanTalk=TF(trans,"CanTalk")
    local talk = self.CanTalk.transform
	U(talk, "SendBtn", self.Name, self.OnSend, self)
	U(talk, "FeelBtn", self.Name, self.OnFeel, self)
	U(talk, "PosBtn", self.Name, self.OnSendPos, self)
	U(talk,"VoiceBtn",self.Name,self.OnVoice,self,false)
    self.Inport = CG(UIInput, talk, "Inport", self.Name, false)
    S(self.Inport.gameObject,self.OnPut,self,self.Name, false)
    
	self.chat=ObjPool.Get(Chat)
    self.chat:Init(TF(talk,"Chat"))
    

    self.VoiceTalk=TF(trans,"VoiceTalk")
    local voice=self.VoiceTalk.transform
	U(voice,"VoiceBtn",self.Name,self.OnVoiceTalk,self,false)
	local ClickVoice = TF(voice,"ClickVoice")
	UIEventListener.Get(ClickVoice).onPress = function(go,ispress) self:ChatVoice(go,ispress) end
    self.lab=CG(UILabel,voice,"ClickVoice/Label",self.Name,false)

end

--继承保留
function My:OnSend()
	-- local issend = ChatMgr.isSend[tostring(My.cTp)]
	-- if issend==false then
	-- 	UITip.Error("您发言真活跃，休息下再发吧")
	-- 	return 
	-- end
	-- local text = self.Inport.value
	-- if(StrTool.IsNullOrEmpty(text))then UITip.Log("聊天内容为空！") return end
	-- if(self:Filter(text)) then return end
	-- text=self:CheckUrl(text)
	-- if FamilyAnswerInfo.activState ~= 2 then
	-- 	text = MaskWord.SMaskWord(text)
	-- end
	-- ChatMgr.ReqText(My.cTp, 0, 0,text,idList,"")
	-- self.Inport.value = ""
	-- ListTool.Clear(idList)
	-- self.putPos=nil
end

function My:OnFeel(go)
	self.chat:Open()
end

--发送坐标位置--继承保留
function My:OnSendPos()
	-- local scenId= User.instance.SceneId
	-- local data = SceneTemp[tostring(scenId)]
	-- if data.type==3 then
	-- 	UITip.Error("该地图无法发送坐标")
	-- 	return
	-- end
	-- local pos = MapHelper.instance:GetOwnerPos()
	-- local str = tostring(pos.x).."_"..pos.z
	-- ChatMgr.ReqPos(My.cTp,0,str)
end

function My:OnVoice()
	self.CanTalk:SetActive(false)
	self.VoiceTalk:SetActive(true)
end

function My:OnPut()
	self.putPos=self.Inport.cursorPosition
	if self.putPos==nil then self.putPos=string.len( self.Inport.value )end
end

function My:OnVoiceTalk()
	self.CanTalk:SetActive(true)
	self.VoiceTalk:SetActive(false)
end

--语音
function My:ChatVoice(go,ispress)
	local text = ispress==true and "松开结束" or "按住说话"
	self:LabText(text)
	
	if ispress==true then --开始录音
		self.isSendVoice=true
		self.voicetp=nil
		self:CheckVoice()
		UIMgr.Open(UISendVoice.Name)
	else
		UIMgr.Close(UISendVoice.Name)
		self.isSendVoice=false
		if self.voicetp==1 then return end
		if App.platform == Platform.Android then 
			UITip.Log("结束录音")
			ChatVoiceMgr.RecordStopRequest() 
		end
	end
end

function My:CloseVoice()
	self:LabText("按住说话")
end

function My:LabText(text)
    self.lab.text=text
end

function My:CheckVoice()
	if App.platform == Platform.Android then 
		--语音权限拉起判断
		local sdk = Device.SysSDKVer
		if sdk<23 then
			UITip.Log("请检查您的语音权限是否开启")
			return
		end
		local tp=Activity.Instance:Check("RECORD_AUDIO")
		if tp==0 then --同意
			self.voicetp=0
			iTrace.Log("xiaoyu","0 同意")
			UITip.Log("请求开始录音")
			ChatVoiceMgr.RecordStartRequest()
		elseif tp==-1 then --拒绝
			self.voicetp=1
			iTrace.Log("xiaoyu","1 拒绝")
			MsgBox.ShowYes("您已拒绝录音权限，请在设置-应用 中修改权限")
			--Activity.Instance:Req("RECORD_AUDIO")
		elseif tp==-2 then --未知
			self.voicetp=2
			UITip.Log("请求开始录音")
			iTrace.Log("xiaoyu","2 未知")
			ChatVoiceMgr.RecordStartRequest()
		end	
	else
		UITip.Log("暂不支持非安卓平台下录音")
		--ChatVoiceMgr.RecordStartRequest()
	end
end

function My:Dispose()
    if self.chat then ObjPool.Add(self.chat) self.chat=nil end
    self:DisposeCustom()
end

function My:DisposeCustom()
    -- body
end