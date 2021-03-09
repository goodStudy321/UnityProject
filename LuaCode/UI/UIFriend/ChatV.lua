--[[
聊天信息显示界面
--]]
require("UI/UIChat/Chat")
require("UI/UIChat/ChatBase")

local AssetMgr = Loong.Game.AssetMgr
ChatV = ChatBase:New{Name="ChatV"}
local My = ChatV
local chatList = {}
local idList={}
local urlList ={} --key: vector2 i.j value:名字

function My:Init(go)
	self.trans=go.transform
	self:InitCustom(self.trans)
	local CG=ComTool.Get
	local TF=TransTool.FindChild 
	local U = UITool.SetBtnClick


	-- self.VoiceTalk=TF(self.trans,"VoiceTalk")
	-- local vt=self.VoiceTalk.transform
	-- U(vt,"VoiceBtn",self.Name,self.OnVoiceTalk,self,false)
	-- local ClickVoice = TF(vt,"ClickVoice")
	-- UIEventListener.Get(ClickVoice).onPress = function(go,ispress) self:ChatVoice(go,ispress) end
	-- self.lab=CG(UILabel,vt,"ClickVoice/Label",self.Name,false)

	
	-- self.ClickChat=TF(self.trans,"ClickChat")
	-- local clickchat = self.ClickChat.transform
	-- U(clickchat,"Send",self.Name,self.OnSend,self)
	-- U(clickchat,"Autio",self.Name,self.self.OnVoice,self)
	-- U(clickchat,"Face",self.Name,self.self.OnFeel,self)
	-- U(clickchat,"posBtn",self.Name,self.OnSendPos,self)
	-- self.Inport=CG(UIInput,clickchat,"Input",self.Name,false)

	self.Title=CG(UILabel,self.trans,"Title",self.Name,false)
	self.Panel=CG(UIPanel,self.trans,"Panel",self.Name,false)
	self.scrollView = CG(UIScrollView, self.trans, "Panel", self.Name, false)
	self.PSIZEY = self.Panel:GetViewSize().y
	self.CT=TF(self.Panel.transform,"CT").transform
end

function My:SetEvent(fn)
	ChatMgr.eAddChat[fn](ChatMgr.eAddChat,self.OnChat,self)
	Emo.eEmo[fn](Emo.eEmo,self.AddEmo,self)
	Prop.eProp[fn](Prop.eProp,self.AddProp,self)
end

function My:UpDta(data)
	if not data then return end
	self:CleanData()
	self:Open()
	self.cId=data.ID
	self.Title.text="[808999]与[-][b1a495]"..data.Name.."[-][808999]对话[-]"
	
	local tb = ChatMgr.PrivateDic[tostring(self.cId)]
	if(tb~=nil)then
		local count = #tb
		for i,v in ipairs(tb) do
			count=count-1
			self:AddChat(i,v,1,count)
		end
	end
end

function My:OnChat(Tp, index, chatTb)
	if(Tp~=4)then return end
	local list = FriendMgr.FriendList
	for i,v in ipairs(list) do
		if v.ID==self.cId then
			if v.Online==false then UITip.Log("对方已下线，已帮您留言给对方")break end
		end
	end
	self:AddChat(Tp, chatTb)
end

function My:AddChat(index, chatTb,ismove,count)
	if(self.cId~=nil and self.cId~=tostring(chatTb.cId))then return end
	local path = nil
	local x =0
	if(chatTb.info.rId == tostring(User.instance.MapData.UID))then --是自己的消息
		path = "MyLab"
		x = 50
	else
		path = "OtherLab"
		x = -50
	end
	local del = ObjPool.Get(DelGbj)
	del:Adds(x, chatTb,ismove,count)
	del:SetFunc(self.LoadLab, self)
	AssetMgr.LoadPrefab(path, GbjHandler(del.Execute, del))
end

function My:LoadLab(go, x, chatTb,ismove,count)
	go.transform.parent=self.CT
	go:SetActive(false)
	go:SetActive(true)
	go.transform.localScale = Vector3.one
	go.transform.localPosition=Vector3.New(x,y,0)
	local chatInfo = ObjPool.Get(ChatInfo)
	chatInfo:Init(go)
	chatInfo:InitData(chatTb,300)
	local y = 0
	if(#chatList>0)then
		local last = chatList[#chatList]
		y=last.trans.localPosition.y-last.y-74
	end
	chatInfo.trans.localPosition=Vector3.New(x,y,0)
	chatList[#chatList+1]=chatInfo

	if ismove~=1 and chatInfo.trans.localPosition.y - chatInfo.y < - self.PSIZEY then 
		self.scrollView:ResetPosition();
		self.scrollView:SetDragAmount(0, 1, false);
	end
	if count==0 then 
		if(chatInfo.trans.localPosition.y - chatInfo.y < - self.PSIZEY)then 
			if not self.timer then 
				self.timer=ObjPool.Get(iTimer)
				self.timer.complete:Add(self.Complete,self)
			end
			self.timer:Start(0.1)		
		else
			self.scrollView:ResetPosition();
			self.Panel.transform.localPosition = Vector3.zero;
			self.Panel.clipOffset = Vector2.zero;	
		end
	end
end

function My:Complete()
	if LuaTool.IsNull(self.trans) then return end
	self.scrollView:ResetPosition();
	self.scrollView:SetDragAmount(0, 1, false);
end

--发送
function My:OnSend()
	local text = self.Inport.value
	if(StrTool.IsNullOrEmpty(text))then UITip.Log("聊天内容为空！") return end
	text=self:CheckUrl(text)
	text = MaskWord.SMaskWord(text)
	ChatMgr.ReqText(4, self.cId,0, text,idList)
	ListTool.Clear(idList)
	self.Inport.value = ""
end

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

-- --语音
-- function My:OnVoice()
-- 	self.ClickChat:SetActive(false)
-- 	self.VoiceTalk:SetActive(true)
-- end

-- --表情
-- function My:OnFeel()
-- 	self.chat:Open()		
-- end

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
	ChatMgr.ReqPos(4,self.cId,str)
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

function My:OnPut()
	putPos=self.Inport.cursorPosition
	if putPos==nil then putPos=string.len( self.Inport.value )end
end


function My:Open()
	self:SetEvent("Add")                
	self.trans.gameObject:SetActive(true)
	self.CanTalk:SetActive(true)
end

function My:Close()
	self:SetEvent("Remove")
	self.trans.gameObject:SetActive(false)
end

function My:CleanData()
	self.Title.text=""
	ListTool.ClearToPool(chatList)
	self.VoiceTalk:SetActive(false)
end

function My:Dispose()
	self:Close()
	self:CleanData()
	if self.timer then self.timer:AutoToPool() self.timer=nil end
	if self.chat then ObjPool.Add(self.chat) self.chat=nil end
end