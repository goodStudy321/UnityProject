--[[
聊天表情信息
--]]
local AssetMgr=Loong.Game.AssetMgr
EmoInfo=Super:New{Name="EmoInfo"}
local My = EmoInfo

function My:Ctor()
	self.list={}
end

function My:Init(go,emoPre)
	local C = ComTool.Get
	local T = TransTool.FindChild
	local trans = go.transform
	self.go=go
	self.tp=C(UISprite,trans,"tp",self.Name,false)
	self.ChatLab=C(UILabel,trans,"ChatLab",self.Name,false)
	self.emoPre=emoPre
	self.voice=T(trans,"ChatLab/voice")
	local voice = self.voice.transform
	self.voiceLab=C(UILabel,voice,"lab",self.Name,false)

	UITool.SetLsnrSelf(self.ChatLab.gameObject,self.ClickChat,self,self.Name,false)
end

function My:ClickChat(go)
    local tp = go.transform.parent.name
    ChatMgr.OpenChat(tp)
end

function My:InitData(tp,msg,voice)
	self.tp.spriteName="tp"..tp
	if voice~=nil and voice~=0 then
		self.ChatLab.text=msg
		local pos = self.ChatLab.printedSize
		self.voice:SetActive(true)
		self.voice.transform.localPosition=Vector3.New(pos.x,-9,0)
		self.voiceLab.text=tostring(voice).."秒"
	else
		self.voice:SetActive(false)
		EmoMgr.SetEmo(self.ChatLab,msg,"   ") --过滤文字
		self:ShowEmo()
	end
end

function My:ShowEmo()
	local list = EmoMgr.PosList
	local emoList = EmoMgr.EmoList
	local count = list.Count
	if count==0 then return end
	local add = Vector3.zero
	for i=0,count-1 do
		local pos = list[i]
		local emo = emoList[i]
		local go = GameObject.Instantiate(self.emoPre)
		go:SetActive(true)
		go.transform.parent=self.ChatLab.transform
		go.transform.localScale=Vector3.one
		--local add = Vector3.New(0,10,0)	
		
		local spr = go:GetComponent(typeof(UISprite))
		spr.spriteName=emo
		go.transform.localPosition=pos+Vector3.New(spr.width/2,spr.height/2,0)
		self.list[#self.list+1]=go
	end
end

function My:Clean()
	while #self.list>0 do
		local emo=self.list[#self.list]
		Destroy(emo)
		self.list[#self.list]=nil
	end
end

function My:Dispose( ... )
	self:Clean()
	Destroy(self.go)
end