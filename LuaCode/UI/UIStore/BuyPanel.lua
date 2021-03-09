BuyPanel=Super:New{Name="BuyPanel"}
local My=BuyPanel
local AssetMgr=Loong.Game.AssetMgr

function My:Init(go)
	local TF=TransTool.FindChild
	local CG=ComTool.Get
	local U = UITool.SetLsnrClick

	self.trans=go.transform

	local L1=TF(self.trans,"L1").transform
	self.NumLab=CG(UILabel,L1,"NumLab/Label",self.Name,false)

	
	U(L1,"ABtn",self.Name,self.OnClick,self)
	U(L1,"RBtn",self.Name,self.OnClick,self)

	local L2=TF(self.trans,"L2").transform
	self.ComLab=CG(UILabel,L2,"ConsumeLab",self.Name,false)
	self.Icon=CG(UISprite,self.ComLab.transform,"money",self.Name,false)

	self.panel=CG(UIScrollView,self.trans,"Panel",self.Name,false)
	self.des=CG(UILabel,self.trans,"Panel/des",self.Name,false)
	self.des.spacingY=5
	U(self.trans,"BuyBtn",self.Name,self.OnClick,self)
	
	self.Cell=ObjPool.Get(StoreCell)
	self.Cell:Init(TF(self.trans,"StoreCell"))

	self.HasNum=CG(UILabel,self.trans,"HasNum",self.Name,false)

	self.num=1
	self:AddE()

	U(L1,"NumLab",self.Name,self.OnCNum,self)
	self.numStr=ObjPool.Get(StrBuffer)
	self.str=ObjPool.Get(StrBuffer)
	--EventDelegate.Add(self.NumLab.onChange,EventDelegate.Callback(self.OnCNum,self))
end

function My:OnCNum()
	UIMgr.Open(PricePanel.Name)
end

function My:OnNum(name)
	self.numStr:Apd(name)
	local str = tonumber(self.numStr:ToStr())
	if str>999 then 
		UITip.Log("最多可购买999个") 
		self.num=999 
	elseif str==0 then
		UITip.Log("数量最少为1")
		return
	else
		self.num=str
	end
	self:ShowNum()
end

function My:OnConfirm()
	self.numStr:Dispose()
end

function My:OnClear()
	self.numStr:Dispose()
	self.num=1
	self:ShowNum()
end

function My:AddE()
	StoreCell.eClick:Add(self.UpData,self)
	RoleAssets.eUpAsset:Add(self.PropChg,self);
	StoreMgr.eBuyResp:Add(self.ShowHasNum,self)
	StoreMgr.eLimit:Add(self.OnLimit,self)
	PropMgr.eGetAdd:Add(self.OnAdd,self)
	
	PricePanel.eNum:Add(self.OnNum,self) 
	PricePanel.eConfirm:Add(self.OnConfirm,self)
	PricePanel.eClear:Add(self.OnClear,self)
end

function My:ReE()
	StoreCell.eClick:Remove(self.UpData,self)
	RoleAssets.eUpAsset:Remove(self.PropChg,self);
	StoreMgr.eBuyResp:Remove(self.ShowHasNum,self)
	StoreMgr.eLimit:Remove(self.OnLimit,self)
	PropMgr.eGetAdd:Remove(self.OnAdd,self)

	PricePanel.eNum:Remove(self.OnNum,self) 
	PricePanel.eConfirm:Remove(self.OnConfirm,self)
	PricePanel.eClear:Remove(self.OnClear,self)
end

--属性改变
function My:PropChg(ty)
    if self.store ==nil then return end	
	self.Cell:SPrice(self.store,self.num)
	self:ShowNum()
end

function My:OnLimit()
	self.Cell:SNum(self.store)
end

function My:OnAdd(action,dic)
	if action==10003 then
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

function My:ActiveState(state)
	self.trans.gameObject:SetActive(state)
end

function My:OnClick(go)
	if(go.name=="ABtn")then
		self:AddNum()		
	elseif(go.name=="RBtn")then
		self:RuNum()
	elseif(go.name=="BuyBtn")then
		self.numStr:Dispose()
		local vip = self.store.vipLv
		if(vip~=nil)then
			local nowVIP = VIPMgr.GetVIPLv()
			if(nowVIP<vip)then 
				if nowVIP<4 then
					self:UpVIPLv()
				else
					UITip.Log("达到Vip".. vip.."才可以购买")
				end
				return
			end
		end
		local lNum =StoreMgr.limitDic[self.id] or 0
		if self.maxNum then 		
			if(self.num>self.maxNum-lNum)then 
				self.num=self.maxNum-lNum 
				if self.num==0 then UITip.Log("物品已售完!") self.num=1 self:ShowNum() return end
				UITip.Log("最多可购买"..self.num.."个")
			end
		end
		StoreMgr.ReqBugGoods(self.id,self.num)
		self.num=1
		self:ShowNum()
	end
end

function My:UpVIPLv()
	local msg = "当前VIP等级不足,是否前往升级VIP?"
	MsgBox.ShowYesNo(msg,self.UpVIPCb,self,"升级VIP")
end

function My:UpVIPCb()
	UIMgr.Open(UIV4Panel.Name)
end

function My:UpData(id)
	self.id=id

	self.store=StoreData[tostring(id)]
	if(self.store==nil)then iTrace.Error("xiaoyu","商城表为空 id:"..tostring(id))return end
	self.type_id=self.store.PropId
	local item=ItemData[tostring(self.type_id)]
	if(item==nil)then iTrace.Error("xiaoyu","道具表为空 id:".. self.type_id)return end	
	self.maxNum=self.store.canPNum
	self:ActiveState(true)

	--StoreCell
	self.Cell:UpData(item,self.store,self.num)
	self.Cell:SPrice(self.store)
	self.Cell:SVIP(self.store)
	self:OnLimit()
	--
	self:ShowMoney(self.store)
	self:ShowDes(item)
	self:ShowHasNum()

	self.panel:ResetPosition()

	self:OnClear()
end

function My:AddNum()
	local lNum =StoreMgr.limitDic[self.id] or 0
	if(self.maxNum==nil or self.num<self.maxNum-lNum)then self.num=self.num+1 end
	self:ShowNum()	
end

function My:RuNum()
	if(self.num>1)then self.num=self.num-1 end
	self:ShowNum()
end

function My:ShowNum()
	if self.num<1 then self.num=1 end
	if self.num>999 then self.num=999 end
	self.NumLab.text=tostring(self.num)

	local color = UIStore.CanBuy(self.store,self.num)
	self.ComLab.text=color.. (self.store.curPrice*self.num)
end

function My:ShowDes(item)
	local uFx = item.uFx or 0
	local itemDes = item.des or ""
	self:AddAttDes(uFx,tostring(item.id),itemDes)
	self.des.text=self.str:ToStr()
end

--属性描述
function My:AddAttDes(uFx,type_id,itemDes)
	self.str:Dispose()
	local id=tonumber(type_id)
	local temp = nil
	if uFx==31 then --宝石
		self.str:Apd("镶嵌后加成：[67cc67]\n")
		temp=GemData[type_id]
	elseif uFx==60 then --神兽装备
		temp=SBEquipCfg[type_id]
	elseif uFx==8 then --坐骑时装 
		temp=BinTool.Find(MountChangeLvCfg,id)
	elseif uFx==12 then --宠物时装 
		temp=BinTool.Find(PetChangeLvCfg,id)
	elseif uFx==9 then --法宝时装 
		temp=BinTool.KeyFind(MWSkinCfg,id,"acPropId")
	elseif uFx==10 then --神兵时装 
		temp=BinTool.Find(GWSkinCfg,id)
	elseif uFx==11 then --翅膀时装 
		temp=BinTool.Find(WingSkinCfg,id)
	elseif uFx==41 then --时装 
		temp=FashionAdvCfg[type_id]
	elseif uFx==38 then --称号
		temp=TitleCfg[tostring(self.item.uFxArg[1])]
	elseif uFx==96 then --宝座皮肤 
		temp=BinTool.Find(ThroneChangeLvCfg,id)
	end
	if temp then
		for i,pro in ipairs(PropName) do
			local v=pro.nLua
			if v then 
				local val = temp[v] or 0
				if val~=0 then
					self.str:Apd(PropTool.GetName(v)):Apd("+"):Apd(PropTool.GetValByNLua(v,val)):Apd("\n")
				end
			end
		end
	end
	local newText = string.gsub( itemDes,"#",self.str:ToStr())
	self.str:Dispose()
	self.str:Apd(newText)
end

--获取途径描述
function My:GetWayDes()
	local way=self.item.getwayList
	if way then
		self.str:Line()
		self.str:Apd("【获得途径】")
		self.str:Line()
		self.str:Apd("[67cc67]")
		for i,v in ipairs(way) do
			local data = GetWayData[tostring(v)]
			if not data then iTrace.eError("xiaoyu","获取表为空 id: "..v)return end
			local text = data.des
			self.str:Apd(text)
			if i~=#way then self.str:Apd("、") end
		end
	end
end

function My:ShowMoney(store)
	local id = store.priceTp
	if id==4 then id=3 end
	local icon = UIMisc.GetIcon(id)
	self.Icon.spriteName=icon
end


function My:ShowHasNum()
	local numm = PropMgr.TypeIdByNum(self.type_id)
	self.HasNum.text="已拥有:".. numm
end

function My:Dispose()
	self.num=1
	self:ReE()
	if(self.Cell~=nil)then ObjPool.Add(self.Cell)end
	if self.numStr then ObjPool.Add(self.numStr) self.numStr=nil end
	if self.str then ObjPool.Add(self.str) self.str=nil end
	TableTool.ClearUserData(self)
end