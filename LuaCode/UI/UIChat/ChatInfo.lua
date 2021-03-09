--[[
聊天信息条目
--]]
ChatInfo=Super:New{Name="ChatInfo"}
local My=ChatInfo
My.eClick=Event()
My.pos=nil
My.eToLab=Event()
local emoWidth = 22
local qipao = "chat_02B"
local touxiang = "ty_a20"


function My:Ctor()
	self.emoList={} --key:位置 value:名字
	self.list={} 
end

function My:Init(go)
	self.trans=go.transform
	if(go.name=="MyLab")then
		self.isself=true
	else
		self.isself=false
	end
	local CG=ComTool.Get
	local TF=TransTool.FindChild 
	
	self.ChatLab=CG(UILabel,self.trans,"ChatLab",self.Name,false)
	self.voice=TF(self.trans,"voice")
	self.voice2=TF(self.trans,"voice/voice2")
	self.voice3=TF(self.trans,"voice/voice3")
	self.emo=TF(self.trans,"emo")
	self.atlas=self.emo:GetComponent(typeof(UISprite)).atlas.spriteList
	UITool.SetLsnrSelf(self.ChatLab.gameObject,self.ClickUrl,self,self.Name)


	self.Bg=CG(UISprite,self.trans,"Bg",self.Name,false)
	self.SkinBg=CG(UITexture,self.trans,"SkinBg",self.Name,false)
	self.iconBg=TF(self.trans,"iconBg")
	self.skinIconBg=CG(UITexture,self.trans,"skinIconBg",self.Name,false)
	self.Icon=CG(UISprite,self.trans,"Icon",self.Name,false)
	self.NameLab=CG(UILabel,self.trans,"Name",self.Name,false)
	self.vip=CG(UISprite,self.trans,"vip",self.Name,false)
    self.Lv=CG(UILabel,self.trans,"Lv",self.Name,false)
	self.God=CG(UILabel,self.trans,"God",self.Name,false)
	UITool.SetLsnrSelf(self.Icon.gameObject,self.ClickPlayer,self,self.Name)

	
	self.isClick=false
end

function My:OnImSpeechStopResp()
	-- body
end

function My:ClickUrl(go)
	if self.ChatLab then
		local url=self.ChatLab:GetUrlAtPosition(UICamera.lastWorldPosition)
		NoticeMgr.DealUrl(go.name,url)
	end
end

function My:DealOpenEquipTipCb(name)
	local ui = UIMgr.Get(name)
 	if(ui)then 
 		ui:UpData(self.type_id)
 		ui:BtnState(false)
 	end
end

function My:DealOpenPropTipCb(name)
	local ui=UIMgr.Get(name)
 	if(ui)then 
		ui:UpData(self.item)
 		ui:BtnState(false)
 	end
end

function My:ClickPlayer(go)
    if tostring(User.instance.MapData.UID)==tostring(self.chatTb.rId) then return end
	My.pos=self.Icon.transform.position
	My.eClick(self.chatTb.info)
end

--文字内容
function My:InitData(chatTb,maxW)
	self.chatTb=chatTb
	self.maxW=maxW
	local time = chatTb.voice
	if time==0 or time==nil then --文字
		--头像气泡框
		self:MBg(chatTb)

		self.voice:SetActive(false)
		self:MChatLab(maxW)
		if self.isSkinBg then
			self:SetSkinAnchor()
		else
			self:SetBgAnchor()
		end	
	else --语音
		self.ChatLab.gameObject:SetActive(false)
		self:InitVoice()
	end
		
	local tb = self.chatTb.info
	self:MIcon(tb.cg)
	self:MName(tb.rN,tb.server)
	self:MVIPLv(tb.vip)
	self:MLv(tb.lv)	
end

function My:MBg(chatTb)
	local color=Vector3.New(255,255,255)
	local skin=chatTb.info.skinList
	local isSkinBg,isIconBg= false,false
	for i,v in ipairs(skin) do
		local chat = FashionChat[tostring(v)]
		local item = ItemData[tostring(chat.propId)]
		if not item then iTrace.eError("xiaoyu","道具表为空  id: "..chat.propId)return end
		local tx = item.icon
		if chat.type==1 then
			AssetMgr:Load(tx,ObjHandler(self.LoadSkinBg,self))
			isSkinBg=true
			self.isSkinBg=isSkinBg
			color = chat.color	
		else
			AssetMgr:Load(tx,ObjHandler(self.LoadSkinIcon,self))
			isIconBg=true
			if iconBg=="touxiang5a" or iconBg=="touxiang6a" then wh=106 end
		end
	end
	self.ChatLab.color=Color.New(color.x/255,color.y/255,color.z/255)	
	-- if self.chatTb.mark then return end--仙盟答题过滤
	self.SkinBg.gameObject:SetActive(isSkinBg==true)
	self.Bg.gameObject:SetActive(isSkinBg==false)
	self.iconBg:SetActive(isIconBg==false)
	self.skinIconBg.gameObject:SetActive(isIconBg==true)
end

function My:LoadSkinBg(obj)
	self.SkinBg.mainTexture=obj
end

function My:LoadSkinIcon(obj)
	self.skinIconBg.mainTexture=obj
end

function My:SetBgAnchor()
	local isoneline = self.ChatLab.height<=30 and true or false
	--设置文本对齐方式
	local anchor = isoneline==true and self.ChatLab.printedSize.x+20 or 320
	if self.trans.name=="MyLab" then
		local align = isoneline==true and NGUIText.Alignment.Right or NGUIText.Alignment.Left
		self.ChatLab.alignment = align
		self.Bg.leftAnchor.absolute=-anchor
	else
		--self.ChatLab.alignment = NGUIText.Alignment.Left
		self.Bg.rightAnchor.absolute=anchor
	end
end

function My:SetSkinAnchor()
	local isoneline = self.ChatLab.height<=30 and true or false
	if self.trans.name=="MyLab" then
		local anchor = isoneline==true and self.ChatLab.printedSize.x+30 or 340
		local align = isoneline==true and NGUIText.Alignment.Right or NGUIText.Alignment.Left
		self.ChatLab.alignment = align
		self.SkinBg.leftAnchor.absolute=-anchor
	else
		local anchor = isoneline==true and self.ChatLab.printedSize.x+100 or 400
		self.SkinBg.leftAnchor.absolute=-anchor
	end
end

--语音内容
function My:InitVoice()
	local time = self.chatTb.voice
	self.y=40
	local CG=ComTool.Get
	local TF=TransTool.FindChild 
	self.voiceLab=CG(UILabel,self.trans,"voice/lab",self.Name,false)
	local bg = TF(self.trans,"voice/Bg")

	UITool.SetLsnrSelf(bg,self.ClickVoice,self,self.Name)
    UIEvent.Get(bg).onPress= UIEventListener.BoolDelegate(self.ShowToLab, self)

	self.voice:SetActive(true)
	
	self.voiceLab.text=tostring(time).."秒"

end

function My:ShowToLab(go,ispress)
	if ispress==true then 
		self.countTime=TimeTool.GetServerTimeNow()*0.001		
	else
		local lerp = TimeTool.GetServerTimeNow() * 0.001 - self.countTime
		if lerp>=1 then
			VoiceToLab.info=self
			My.eToLab()
		end
	end
end

-- --语音转文字
function My:OnVoiceToLab()
	if StrTool.IsNullOrEmpty(self.chatTb.msg) then 
		UITip.Log("无法转为文字")
		return 
	end
	--头像气泡框
	self:MBg(self.chatTb)

	self.voice:SetActive(false)
	self:MChatLab(self.maxW)
	if self.isSkinBg then
		self:SetSkinAnchor()
	else
		self:SetBgAnchor()
	end	
end

--点击语音播放内容
function My:ClickVoice(go)
	if App.platform == Platform.Android then 
		local url = self.chatTb.voiceUrl

		if self.isClick==true then --正在播放再次点击则是取消播放
			self.isClick=false 
			self.voice2:SetActive(true)
			self.voice3:SetActive(true)

			ChatVoiceMgr.RecordStopPlayRequest()
		else
			self.isClick=true
			self.voiceTime=self.chatTb.voice
			ChatVoiceMgr.RecordStartPlayRequest(url)
		end
	end
end

function My:Update()
	if self.isClick==false then return end
	self.voiceTime=self.voiceTime-Time.deltaTime
	if self.voiceTime<=0 then self.isClick=false self.voice2:SetActive(true) self.voice3:SetActive(true)return end
	if not self.time then self.time=9 end
	self.time=self.time-1
	if self.time==6 then 
		self.voice2:SetActive(true)
	elseif self.time==3 then
		self.voice3:SetActive(true)
	elseif self.time==0 then
		self.time=9
		self.voice2:SetActive(false)
		self.voice3:SetActive(false)
	end
end

--显示文本信息（过滤表情之后的文字）
function My:MChatLab(maxW)
	local msg =self.chatTb.msg
	self.ChatLab.gameObject:SetActive(true)

	self.maxW=maxW
	-- if not self.chatTb.mark then
	-- 	self.ChatLab.width=maxW
	-- end
	--msg=self:CalculateEmoIndex(msg,1)
	EmoMgr.SetEmo(self.ChatLab,msg,"　　") --过滤文字
	self:ShowEmo()
	self.y=self.ChatLab.height
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
		local go = GameObject.Instantiate(self.emo)
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

--筛选过滤掉表情并用五个空格代替，
--并且记录下在字符串当中的位置 index: X Y
function My:CalculateEmoIndex(text,start)
	local pos=string.find(text,"#%d",start)
	if pos then
		local next = string.sub(text,pos)
		if #next>=3 then 
			local emo=string.sub(text,pos,pos+2)
			if emo then
				local result = self:HasEmo(emo)
				if result==true then
					text=string.gsub(text,emo,"　　",1)
					local xy = pos
					local kv = ObjPool.Get(KV)
					kv:Init(xy,emo)
					self.emoList[#self.emoList+1]=kv				
				end
				return self:CalculateEmoIndex(text,pos)
			else
				return text
			end		
		else
			return text
		end
	else
		return text
	end
end

function My:HasEmo(emo)
	local list = self.atlas
	for i=0,list.Count-1 do
		if list[i].name==emo then return true end
	end
	return false
end

function My:MIcon(cg)
	local icon = "TX_0"..cg
	self.Icon.spriteName=icon
end

function My:MName(name,server)
	if server then 
		if self.trans.name=="MyLab" then
			self.NameLab.text=server.."  "..name
		else
			self.NameLab.text=name.."  "..server
		end
	else
		self.NameLab.text=name
	end
end

function My:MVIPLv(vip)
	local path = nil
	if(vip==nil or vip==0)then 
		self.vip.gameObject:SetActive(false) 
	else 
		-- if self.chatTb.mark then return end--仙盟答题过滤
		self.vip.gameObject:SetActive(true) 
		self.vip.spriteName="vip"..vip 
		self.vip:MakePixelPerfect()
	end
	
end

function My:MLv(lv)
	local isGod = UserMgr:IsGod(lv)
	local text = UserMgr:GetToLv(lv)
	if isGod==true then
		self.God.text=text
	else
		self.Lv.text=text
	end
	-- if self.chatTb.mark then return end--仙盟答题过滤
	self.Lv.gameObject:SetActive(isGod==false)
	self.God.gameObject:SetActive(isGod==true)
end

function My:Dispose()
	self.Bg.gameObject:SetActive(false)
	self.SkinBg.gameObject:SetActive(false)
	self.isClick=false
	TableTool.ClearDicToPool(self.emoList)
	while #self.list>0 do
		local go = self.list[#self.list]	
		GameObject.Destroy(go)	
		self.list[#self.list]=nil
	end
	GbjPool:Add(self.trans.gameObject)
end
