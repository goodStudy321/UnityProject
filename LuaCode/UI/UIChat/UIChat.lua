--[[
聊天
--]]
local AssetMgr = Loong.Game.AssetMgr
require("UI/UIChat/Chat")
require("UI/UIChat/Emo")
require("UI/UIChat/Prop")
require("UI/UIChat/ChatInfo")
require("UI/UIChat/SysInfo")
require("UI/UIChat/PlayerTip")

UIChat = UIBase:New{Name = "UIChat"}
local My = UIChat
My.eSet=Event()
My.eIgnore=Event()
My.eOpen=Event()

local isLock = false
My.cTp = nil
local PSIZEY = 0
local putPos=nil
local updateBar = true

local togDic = {}
local chatList = {}
local sysList = {}
local lastSysY = 0
local lastSysH = 0
local str=ObjPool.Get(StrBuffer)
local urlList ={} --key: vector2 i.j value:名字
local idList = {}

function My:InitCustom()
	local CG = ComTool.Get
	local TF = TransTool.FindChild
	self.trans = TF(self.root,"xyz/w").transform
	local  U = UITool.SetLsnrClick
	local S = UITool.SetLsnrSelf
	local US = UITool.SetBtnClick

	self.Panel = CG(UIPanel, self.trans, "Msg/Panel", self.Name, false)
	-- self.Panel.onClipMove=function(panel) self:OnMove(panel) end
	
	self.scrollView = self.Panel:GetComponent(typeof(UIScrollView))
	self.clipheight=self.scrollView.panel.baseClipRegion.w;
	self.boundheight=self.scrollView.bounds.size.y;
	self.scrollView.onDragFinished=function() self:DragFinished() end

	PSIZEY = self.Panel:GetViewSize().y
	self.Parent = TF(self.Panel.transform, "Parent").transform
	US(self.trans, "CloseBtn", self.Name, self.Move, self)
	US(self.trans, "SetBtn", self.Name, self.OnSet, self)

	self.ignoreBtn = TF(self.trans, "Ignore");

	self.CanTalk = TF(self.trans, "CanTalk").transform
	U(self.CanTalk, "SendBtn", self.Name, self.OnSend, self)
	U(self.CanTalk, "FeelBtn", self.Name, self.OnFeel, self)
	U(self.CanTalk, "PosBtn", self.Name, self.OnSendPos, self)
	self.VoiceTalk=TF(self.trans,"VoiceTalk")
	local vt=self.VoiceTalk.transform
	UITool.SetLsnrClick(self.CanTalk,"VoiceBtn",self.Name,self.OnVoice,self,false)
	UITool.SetLsnrClick(vt,"VoiceBtn",self.Name,self.OnVoiceTalk,self,false)
	local ClickVoice = TF(vt,"ClickVoice")
	UIEventListener.Get(ClickVoice).onPress = function(go,ispress) self:ChatVoice(go,ispress) end
	self.lab=CG(UILabel,vt,"ClickVoice/Label",self.Name,false)

	self.Inport = CG(UIInput, self.CanTalk, "Inport", self.Name, false)
	S(self.Inport.gameObject,self.OnPut,self,self.Name, false)
	S(self.ignoreBtn,self.OnIgnore,self,self.Name)

	self.noTalkLab = CG(UILabel, self.trans, "NoTalk", self.Name, false)
	self.tweenPos = self.trans:GetComponent(typeof(TweenPosition))



	--道庭答题
	self.topParent = TF(self.trans, "Msg/TopPanel/Parent")
	self.topBtn = TF(self.trans, "Msg/TopPanel/topBtn")
	self.topMsg = CG(UILabel, self.topParent.transform, "topMsg", self.Name, false)
	self.topSpr = CG(UISprite, self.topParent.transform, "spr", self.Name, false)
	self.topTimer = CG(UILabel, self.trans, "Msg/TimerPanel/lab")
	self.anchor = TF(self.trans, "Msg/Panel/Parent/anchor")
	self.isSort = true

	self.lock=TF(self.trans,"lock")
	self.unLock=TF(self.trans,"unLock")

	S(self.lock,self.OnUnLock,self,self.Name)
	S(self.unLock,self.OnLock,self,self.Name)
	S(self.topBtn,self.OnTopBtn,self,self.Name)

	local tgGrid = TF(self.trans,"Grid").transform
	for i = 0, 6 do
		if(i~=4)then 
			local val = CG(UIToggle,tgGrid,"Tg".. i,self.Name,self)
			S(val.gameObject,self.OnTog,self,self.Name)
			togDic[tostring(i)]=val
		end
	end
	self:Talk(true)

	self.chat=ObjPool.Get(Chat)
	self.chat:Init(TF(self.CanTalk,"Chat"))

	self.PlayerTip=ObjPool.Get(PlayerTip)
	self.PlayerTip:Init(TF(self.root,"Player"))

	My:InitTopTimerGo()

	self:SetEvent("Add")

	U(self.root, "transBg", self.Name, self.Close, self)
end

function My:DragFinished()
	if(Mathf.Abs(self.scrollView.transform.localPosition.y-0+self.clipheight)< self.boundheight)then
		if doLock~=true and isLock~=true then self:OnLock(false) end
	else
		self.scrollView:ResetPosition();
		self.boundheight = self.scrollView.bounds.size.y;
		if(self.boundheight>self.clipheight)then
			self.scrollView:SetDragAmount(0, 1, false);
		end
		if doLock~=true then self:OnUnLock(false) end
	end
end

function My:SetTween(isRight)
	if(isRight == true)then
		self.tweenPos.from = Vector3.New(320, 0, 0)
		self.tweenPos.to = Vector3.New(-300, 0, 0)
		self.tweenPos.enabled = true
	else
		self.tweenPos.from = Vector3.New(-300, 0, 0)
		self.tweenPos.to = Vector3.New(320, 0, 0)
		self.tweenPos.enabled = true
	end
end

function My:SetEvent(fn)
	ChatMgr.eAddChat[fn](ChatMgr.eAddChat,self.AddChat, self)
	ChatMgr.eSys[fn](ChatMgr.eSys,self.OnAddSys,self)
	Emo.eEmo[fn](Emo.eEmo,self.AddEmo, self)
	Prop.eProp[fn](Prop.eProp,self.AddProp, self)
	ChatMgr.eRemove[fn](ChatMgr.eRemove,self.ReChat, self)
	ChatMgr.eTop[fn](ChatMgr.eTop,self.UpQues, self)
	ChatMgr.eDelTop[fn](ChatMgr.eDelTop,self.DelQues, self)
	EventMgr.Add("RecordStopRequest",EventHandler(self.RecordStopRequest,self))
	FamilyAnswerMgr.eAnswerTime[fn](FamilyAnswerMgr.eAnswerTime,self.UpAnswerTime, self)
	--EventMgr.Add("onPermissionsResult",My.OnPermissionsResult)
	--ChatMgr.eSkinChange:Add(self.OnSkinChange,self)
	UserMgr.eUpdateData[fn](UserMgr.eUpdateData,self.UpdateChaData, self)
end

function My:Update()
	local count = #chatList
	if count==0 then return end
	for i,v in ipairs(chatList) do
		if not v.Update then iTrace.eError("xioayu","   no update  ") end
		v:Update()
	end
end

function My:AddChat(Tp, index, chatTb,ismove,count)
	if(Tp ~= My.cTp)then return end
	local path=""
	if not chatTb.info then
		self:AddSys(Tp,chatTb.msg,1)
		return
	elseif chatTb.info and tonumber(chatTb.info.rId) == 2 or tonumber(chatTb.info.rId) == 1 then
		self:AddSys(Tp,chatTb.msg,1)
		return
	end
	if(chatTb.info.rId == tostring(User.instance.MapData.UID))then --是自己的消息
		--测试
		path = "MyLab"
	else
		path = "OtherLab"
	end
	local del = ObjPool.Get(DelGbj)
	del:Adds(chatTb,ismove,count)
	del:SetFunc(self.LoadLab, self)
	AssetMgr.LoadPrefab(path, GbjHandler(del.Execute, del))
end

function My:OnAddSys(tp,index)
	if(My.cTp ~= tp)then return end
	local msg = nil
	local name = "sys"
	if tp==0 then 
		local tb = ChatMgr.SysList[index]
		msg=tb.k
		name=tostring(tb.v)
	else 
		msg=ChatMgr.TeamList[index]
	end
	self:AddSys(tp,msg,name)
end

function My:AddSys(tp,msg,name)
	local pos = Vector3.zero
	local del = ObjPool.Get(DelGbj)
	del:Adds(tp,msg,name,ismove,count)
	del:SetFunc(self.LoadSysLab, self)
	AssetMgr.LoadPrefab("SysLab", GbjHandler(del.Execute, del))
end

function My:LoadSysLab(go,tp,msg,name,ismove,count)
	go.transform.parent = self.Parent
	go:SetActive(false)
	go:SetActive(true)
	go.transform.localScale = Vector3.one

	local chatInfo = ObjPool.Get(SysInfo)
	chatInfo:Init(go)
	chatInfo:InitData(tp,msg)

	local y = 0
	if(#chatList>0)then 
		local lastTb=chatList[#chatList]
		if lastTb.Name==SysInfo.Name then 
			y=lastTb.trans.localPosition.y-lastTb.y-10
		else
			if lastTb.y>30 then --多行
				y=lastTb.trans.localPosition.y-lastTb.y-50
			else
				y=lastTb.trans.localPosition.y-lastTb.y-60
			end
		end
		
	end
	go.transform.localPosition=Vector3.New(-228.3,y,0)
	go:SetActive(true)
	go.name=name 
	table.insert( chatList, chatInfo )

	self:PanelView(chatInfo,count,ismove)
end

function My:AddEmo(emo)
	self:AddVal(emo)
end

function My:AddProp(id)
	if #urlList==3 then UITip.Log("最多发送三个物品链接") return end
	local tb = PropMgr.tbDic[id]
	local type_id=tostring(tb.type_id)
	local name=ItemData[type_id].name
	local pos=string.len(self.Inport.value)+1
	self:AddVal(name)
	local endPos=string.len(self.Inport.value)

	local vec=Vector3.New(pos,endPos)

	local kv = ObjPool.Get(KV)
	kv:Init(id,name,vec)
	urlList[#urlList+1]=kv
end

--TODO
function My:AddVal(add)
	local val=self.Inport.value
	self:OnPut()
	self.Inport:ShowCaret(add,val,putPos)
	--putPos=self.Inport.cursorPosition
	
end

function My:ReChat(Tp)
	if(Tp ~= My.cTp)then return end
	local chatInfo = chatList[1]
	if(chatInfo ~= nil)then
		ObjPool.Add(chatInfo)
		table.remove(chatList,1)
	end

	for i,v in ipairs(chatList) do
		local lastTb = chatList[i-1]
		local chatInfo = chatList[i]
		local x = (chatInfo.trans.name=="MyLab" or chatInfo.trans.name=="OtherLab") and 0 or -228.3
		if(lastTb == nil)then
			local isOpen = (FamilyAnswerInfo.activState == 2) and true or false
			local openV3 = Vector3.New(x, -40, 0)
			local endV3 = Vector3.New(x, 0, 0)
			local v3 = (isOpen and self.ctp == 2) and openV3 or endV3
			chatInfo.trans.localPosition = v3
		else
			if lastTb.Name=="SysInfo" then --上一条是系统消息得话
				local y = lastTb.trans.localPosition.y - lastTb.y-22
				chatInfo.trans.localPosition = Vector3.New(x, y, 0)
			else
				local y = lastTb.trans.localPosition.y - lastTb.y - 80
				chatInfo.trans.localPosition = Vector3.New(x, y, 0)
			end	
		end
	end
end

function My:LoadLab(go,chatTb,ismove,count)
	go.transform.parent = self.Parent
	go:SetActive(false)
	go:SetActive(true)
	go.transform.localScale = Vector3.one


	local chatInfo = ObjPool.Get(ChatInfo)
	chatInfo:Init(go)
	chatInfo:InitData(chatTb,300)
	local lastTb = chatList[#chatList]
	if(lastTb == nil)then
		local isOpen = (FamilyAnswerInfo.activState == 2) and true or false
		local openV3 = Vector3.New(0, -40, 0)
		local endV3 = Vector3.New(0, 0, 0)
		local v3 = (isOpen and self.ctp == 2) and openV3 or endV3
		chatInfo.trans.localPosition = v3
	else
		if lastTb.Name=="SysInfo" then --上一条是系统消息得话
			local y = lastTb.trans.localPosition.y - lastTb.y-22
			chatInfo.trans.localPosition = Vector3.New(0, y, 0)
		else
			local y = lastTb.trans.localPosition.y - lastTb.y - 80
			chatInfo.trans.localPosition = Vector3.New(0, y, 0)
		end	
	end
	-- if chatTb.mark then
	-- 	go.transform.localPosition = Vector3(-228.3, go.transform.localPosition.y, 0)
	-- end
	table.insert( chatList,chatInfo )

	self:PanelView(chatInfo,count,ismove)
end

function My:PanelView(chatInfo,count,ismove)
	if ismove~=1 and isLock==false and chatInfo.trans.localPosition.y - chatInfo.y < - PSIZEY then 
		self.scrollView:ResetPosition();
		self.scrollView:SetDragAmount(0, 1, false);
	end
	if count==0 then 
		if(chatInfo.trans.localPosition.y - chatInfo.y < - PSIZEY)then 
			self.scrollView:ResetPosition();
			self.scrollView:SetDragAmount(0, 1, false);
		end
	end
end

function My:OnTog(go)
	local tp = tonumber(string.sub(go.name,3))
	self:SwatchTg(tp)
end

--0系统消息 1世界频道 2家族 3队伍 4私聊 5组队
function My:SwatchTg(tp)
	My.eOpen(tp)
	if(tp==My.cTp)then return end
	if My.cTp then 
		ChatMgr.writeRecord[tostring(My.cTp)]=self.Inport.value
	end
	self.Panel.transform.localPosition = Vector3.zero;
    self.Panel.clipOffset = Vector2.zero;
	local write=ChatMgr.writeRecord[tostring(tp)] or ""
	ChatMgr.writeRecord[tostring(tp)]=write
	self.Inport.value=write
	local tog = togDic[tostring(tp)]
	tog.value=true
	self:OnUnLock(false)
	self.ignoreBtn:SetActive(tp==6)

	if(tp == 0)then  --系统
		self:Talk(false, "切换到其他频道可以聊天")		
	elseif(tp == 1)then --世界
		local limitLv = GlobalTemp["41"].Value3 --世界频道发言等级要求
		if User.instance.MapData.Level<limitLv then 
			local text = "等级未达到"..limitLv.."级"
			self:Talk(false,text)		
		else
			self:Talk(true)		
		end
	elseif(tp == 2)then --道庭
		if(FamilyMgr:JoinFamily() == false)then
			self:Talk(false, "您还没有加入道庭")
		else
			self:Talk(true)
		end		
	elseif(tp == 3)then --队伍
		if(LuaTool.Length(TeamMgr.TeamInfo.Player) == 0)then
			self:Talk(false, "您还没有加入队伍")
		else
			self:Talk(true)
		end			
	elseif(tp == 5)then --组队
		self:Talk(false, "切换到其他频道可以聊天")	
	elseif(tp == 6)then --区域
		local limitLv = GlobalTemp["165"].Value3 --跨服频道发言等级要求
		if User.instance.MapData.Level<limitLv then 
			local text = "等级未达到"..limitLv.."级"
			self:Talk(false,text)		
		else
			self:Talk(true)		
		end
	end	
	self:ChatRecord(tp)
	self:WriteRecord()
end

function My:ResetPanel()
	self.Panel.clipOffset=Vector2.zero
	self.Panel.transform.localPosition = Vector3.zero
end

function My:WriteRecord(tp)
	local text = ChatMgr.writeRecord[tostring(tp)]
	if StrTool.IsNullOrEmpty(text) then return end
	self.Inport.value=text
end

local doLock = false
function My:OnLock(state)
	doLock=state~=false and true or false
	self.lock:SetActive(true)
	self.unLock:SetActive(false)
	isLock=true
end

function My:OnUnLock(state)
	doLock=state~=false and true or false
	self.lock:SetActive(false)
	self.unLock:SetActive(true)
	isLock=false
end

function My:OnPut()
	putPos=self.Inport.cursorPosition
	if putPos==nil then putPos=string.len( self.Inport.value )end
end

function My:ChatRecord(tp)
	self:CleanList()
	My.cTp = tp
	--显示道庭答题题目
	self:ShowQues(My.cTp)
	if tp==0 then --系统
		local count = #ChatMgr.SysList
		for i,v in ipairs(ChatMgr.SysList) do
			count=count-1
			self:AddSys(tp,v.k,tostring(v.v),1,count)
		end
	elseif tp==5 then --组队
		local count = #ChatMgr.TeamList
		for i,v in ipairs(ChatMgr.TeamList) do
			count=count-1
			self:AddSys(tp,v,1,count)
		end
	else --其他聊天
		local tb = ChatMgr.MsgDic[tostring(tp)]
		if tb then 
			local count = #tb
			for i,v in ipairs(tb) do
				count=count-1
				self:AddChat(tp,i,v,1,count)
			end
		end
	end
end

function My:Move()
	self:SetTween(false)
	self:Close()
end

function My:OnSet()
	My.eSet()
end

--发送坐标位置
function My:OnSendPos()
	local scenId= User.instance.SceneId
	local data = SceneTemp[tostring(scenId)]
	if data.type==3 then
		UITip.Error("该地图无法发送坐标")
		return
	end
	local pos = MapHelper.instance:GetOwnerPos()
	local str = tostring(pos.x).."_"..pos.z
	ChatMgr.ReqPos(My.cTp,0,str)
end


function My:OnIgnore()
	My.eIgnore()
end

--其它接口文本
function My:Filter(text)
	local suc = false
	if text == nil then return end
	local str = string.lower(text)
	if suc then self:Close() end
	do return suc end
end

function My:OnSend()
	local issend = ChatMgr.isSend[tostring(My.cTp)]
	if issend==false then
		UITip.Error("您发言真活跃，休息下再发吧")
		return 
	end
	local text = self.Inport.value
	if(StrTool.IsNullOrEmpty(text))then UITip.Log("聊天内容为空！") return end
	if(self:Filter(text)) then return end
	text=self:CheckUrl(text)
	if FamilyAnswerInfo.activState ~= 2 then
		text = MaskWord.SMaskWord(text)
	end
	ChatMgr.ReqText(My.cTp, 0, 0,text,idList,"")
	self.Inport.value = ""
	ListTool.Clear(idList)
	putPos=nil
end

function My:OnFeel(go)
	self.chat:Open()
end

function My:OnVoice()
	self.CanTalk.gameObject:SetActive(false)
	self.VoiceTalk.gameObject:SetActive(true)
end

function My:OnVoiceTalk()
	self.CanTalk.gameObject:SetActive(true)
	self.VoiceTalk.gameObject:SetActive(false)
end

function My:CloseVoice()
	self:LabText("按住说话")
end

--语音
function My:ChatVoice(go,ispress)
	--UITip.Log("功能暂未开启")
	local text = ispress==true and "松开结束" or "按住说话"
	self:LabText(text)
	
	if ispress==true then --开始录音
		UIMgr.Open(UISendVoice.Name)
		self.isSendVoice=true
		self.voicetp=nil
		self:CheckVoice()
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

-- --arg1代码权限的完整名称,arg2：0:同意 -1:拒绝 -2:未知
-- function My:OnPermissionsResult(arg1,arg2)
-- 	if arg1=="RECORD_AUDIO" and arg2==0 then
-- 		iTrace.Log("xiaoyu","   arg1: "..arg1.."  arg2: "..arg2)
-- 	end
-- end

local namelist= {}
function My:CheckUrl(text)
	ListTool.Clear(namelist)
	while #urlList>0 do
		local kv = urlList[#urlList]
		local name=string.sub(text,kv.b.x,kv.b.y)
		if name==kv.v then  
			kv.v=kv.k..kv.v
			local x1=string.sub(text,1,kv.b.x-1)
			local x2=string.sub(text,kv.b.y+1)
			text=x1..kv.v..x2
			--newStr:Apd(x1):Apd(kv.v):Apd(x2)
			table.insert( idList, 1,tonumber(kv.k))
			table.insert( namelist, name )
		end
		ObjPool.Add(kv)
		urlList[#urlList]=nil
	end
	for i,v in ipairs(namelist) do
		text=string.gsub(text,v,"$#$#",1)
	end
	return text
end

function My:Talk(isTalk, text)
	if(isTalk == true)then
		self.CanTalk.gameObject:SetActive(true)
		self.noTalkLab.gameObject:SetActive(false)
	else
		self.noTalkLab.gameObject:SetActive(true)
		self.CanTalk.gameObject:SetActive(false)
		self.noTalkLab.text = text
	end
	self.VoiceTalk:SetActive(false)
end

--响应更新题目
function My:UpQues(ctp)
    if ChatMgr.TopDic["2"] and ctp == 2 then
        local list = ChatMgr.TopDic["2"]
		if My.cTp == 2 then
			self:AddTopMsg("道庭答题", list[#list])
		end
    end
end

--响应删除题目
function My:DelQues()
	FamilyAnswerInfo.isEnd = true
    self:ResetTopMsg()
end

--停止录音并上传
function My:RecordStopRequest(time,recordPath,url,msg)
	if time<1000 then UITip.Error("录音时间不足1秒")return end --之后放到c#判断
	if time>60000 then UITip.Error("录音时间超过60秒")return end
	--ChatVoiceMgr.UploadFileRequest(recordPath); --上传语音文件
	time=math.ceil(time/1000)
	iTrace.Log("xiaoyu"," url:  "..url)
	-- if self.isSendVoice==false then return end
	-- self.isSendVoice=false
	ChatMgr.ReqText(My.cTp, 0, time,msg,idList,url)
end

--添加置顶消息
function My:AddTopMsg(title, msg)
	self:UpTopGoState(true)
	self:SetTopMsg(title, msg)
end

--设置置顶消息
function My:SetTopMsg(title, msg)
	local lab = self.topMsg
	lab.text="[FB7F3BFF]["..title.."][-] "..msg
	local spr = self.topSpr
	local sprGo = spr.gameObject
	local labPos = lab.transform.localPosition
	sprGo:SetActive(true)
	self.topMsg.gameObject:SetActive(true)
	spr.width = lab.width + 10
	spr.height = lab.height + 10
	sprGo.transform.localPosition = Vector3.New(sprGo.transform.localPosition.x, labPos.y + 10, 0)
	if self.isSort then
		self:UpPanelSize(false)
		self.isSort = false
	end
end

--重置置顶消息
function My:ResetTopMsg()
	self:UpTopGoState(false)
	self.topTimer.gameObject:SetActive(false)
	self:UpPanelSize(true)
end

--更新顶部物体状态
function My:UpTopGoState(state)
	local topSpr = self.topSpr
	local topMsg = self.topMsg
	topSpr.gameObject:SetActive(state)
	topMsg.gameObject:SetActive(state)
	if User.SceneId ~= 30007 then
		self.topBtn:SetActive(state)
	end
	local x1 = (User.SceneId ~= 30007) and -45 or 0
	local x2 = (User.SceneId ~= 30007) and 165 or 210
	topSpr.transform.localPosition = Vector3(x1, topSpr.transform.localPosition.y, 0)
	topMsg.transform.localPosition = Vector3(x2, topMsg.transform.localPosition.y, 0)
end

--更新self.Panel的尺寸
function My:UpPanelSize(isReset)
	local lab = self.topMsg
	local yPos = lab.localSize.y + 80
	local PSIZEX = self.Panel:GetViewSize().x
	local tran = self.Panel.transform
	local topTran = self.topParent.transform.parent
	local topTranX = topTran.localPosition.x
	local topTranY = topTran.localPosition.y
	local newY = -(yPos/2)
	if isReset then
		self.Panel:SetRect(0, 0, PSIZEX, PSIZEY)
		tran.localPosition = topTran.localPosition
		self.Panel.clipOffset = Vector2.zero
		self.isSort = true
	else
		self.Panel:SetRect(0, newY, PSIZEX - 22, PSIZEY-yPos + 44)
		tran.localPosition = Vector3.New(topTranX, newY - 62, 0)
		self.Panel.clipOffset = Vector2.New(0, math.abs(newY) + math.abs(topTranY) + 74)
	end
	self.topTimer.gameObject:SetActive(not isReset)
end

--显示道庭答题题目
function My:ShowQues(ctp)
	self.ctp = ctp
	local info = FamilyAnswerInfo
	if info.activState == 2 then
		if ctp == 2 then
			if ChatMgr.TopDic["2"] then
				local list = ChatMgr.TopDic["2"]
				self:AddTopMsg("道庭答题", list[#list])
				if FamilyAnswerInfo.isEnd then
					self:ResetTopMsg()
				end
			else
				self:ResetTopMsg()
			end
		else
			self:ResetTopMsg()
		end
	elseif info.activState == 3 then
		self:ResetTopMsg()
	end
end

--更新答题时间
function My:UpAnswerTime(sec)
	self.topTimer.text = string.format("[F4DDBDFF]%s秒后自动跳过", math.floor(sec))
end

function My:OpenTabByIdx(name,id)
	self:SwatchTg(name)
end

--查看玩家信息
function My:UpdateChaData()
	JumpMgr:InitJump(UIChat.Name,My.cTp)
    UIMgr.Close(UIChat.Name)
	UIMgr.Open(UIOtherInfoCPM.Name)
end

--初始化答题时间物体
function My:InitTopTimerGo()
	self.topTimer.gameObject:SetActive(not FamilyAnswerMgr.isHide)
end

--点击置顶按钮
function My:OnTopBtn()
	if CustomInfo:IsJoinFamily() then
		UIMgr.Open(UIFamilyAnswerIt.Name)
	end
end

--更新气泡或者
-- function My:OnSkinChange(rId)
-- 	for i,v in ipairs(chatList) do
-- 		if v.chatTb.rId==rId then
-- 			v:InitData(v.chatTb,v.maxW)
-- 		end
-- 	end
-- end

function My:CleanList()
	while(#chatList>0)do
		local chat = chatList[#chatList]
		ObjPool.Add(chat)
		chatList[#chatList]=nil
	end
end

function My:DisposeCustom()
	ChatMgr.writeRecord[tostring(My.cTp)]=self.Inport.value
	self:CleanList()
	self:SetEvent("Remove")
	if self.chat then ObjPool.Add(self.chat) self.chat=nil end
	if self.tpPanel then ObjPool.Add(self.tpPanel) self.tpPanel=nil end
	if self.PlayerTip then ObjPool.Add(self.PlayerTip) self.PlayerTip=nil end
	My.cTp=nil
	putPos=nil
	TableTool.ClearDic(urlList)
end

return My
