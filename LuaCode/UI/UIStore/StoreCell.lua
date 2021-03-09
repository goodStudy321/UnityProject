local GbjPool=Loong.Game.GbjPool.Instance
StoreCell=Super:New{Name="StoreCell"}

local My=StoreCell
My.eClick=Event()

function My:Init(go)
	local CT=ComTool.Get
	local TF=TransTool.FindChild
	
	self.trans=go.transform
	self.cell=ObjPool.Get(UIItemCell)
	self.cell:InitLoadPool(self.trans,0.8,nil,nil,nil,Vector3.New(-112.8,0,0))
	self.NameLab=CT(UILabel,self.trans,"NameLab",self.Name,false)
	self.DiscountLab=CT(UILabel,self.trans,"Discount",self.Name,false)
	self.PriceLab=CT(UILabel,self.trans,"PriceLab",self.Name,false)
	self.money=CT(UISprite,self.PriceLab.transform,"money",self.Name,false)
	self.limit=CT(UILabel,self.trans,"limit",self.Name,false)
	self.limitLv=CT(UILabel,self.trans,"limitLv",self.Name,false)
	self.Bg=TF(self.trans,"Bg")
	self.Light=TF(self.trans,"light")
	self.vip=CT(UISprite,self.trans,"vip",self.Name,false)
	self.can=TF(self.trans,"can")
	self.sell=TF(self.trans,"sell")
end

function My:ClickBg()
	UITool.SetLsnrClick(self.trans,"Bg",self.Name,self.OnClick,self)
end

function My:UpData(item,store,count)
	self.id=store.id
	self.cell:UpData(item)
	self.cell:UpBind(store.bind)
	self:SName(store)
	self:SDiscount(store)
	self:SPrice(store,count)
	self:SMoney(store)
	self:SVIP(store)
end

function My:OnClick(go)
	My.eClick(self.id)
	--点击
	self:SBg(true)
end

function My:SNum(store)
	local max=store.canPNum
	if (max==nil) and store.lvAstrict < 1 then 
		self:SetLimitGo(false, false)
	else
		self:SetLimitGo(true, false)
		local num = StoreMgr.limitDic[store.id]
		if(num==nil)then num=0 end
		self.limit.text=tostring(num).."/"..tostring(max)
		if(num==max)then 
			self.sell:SetActive(true) 
			return
		end
		local fD = FamilyMgr:GetFamilyData()
		if FamilyMgr:JoinFamily() and fD.Lv < store.lvAstrict then
			self:SetLimitGo(false, true)
			self.limitLv.text = string.format("道庭%s级可买", store.lvAstrict)
		end
	end	
	self.sell:SetActive(false)
end

function My:SetLimitGo(state1, state2)
	self.limit.gameObject:SetActive(state1)
	self.limitLv.gameObject:SetActive(state2)
end

function My:SName(store)
	self.NameLab.text=store.name
end

function My:SDiscount(store)
	if(store.discount~=nil)then
		self.DiscountLab.gameObject:SetActive(true)
		self.DiscountLab.text=store.discount
	else
		self.DiscountLab.gameObject:SetActive(false)
	end
end

function My:SPrice(store,count)
	local color = UIStore.CanBuy(store)
	self.PriceLab.text=color.. store.curPrice
end

function My:SMoney(store)	
	local id = store.priceTp
	if id==4 then id=3 end
	local icon = UIMisc.GetIcon(id)
	self.money.spriteName=icon
end

function My:SBg(state)
	-- self.Bg:SetActive(not state)
	self.Light:SetActive(state)
end

function My:SVIP(store)
	local vip = store.vipLv
	if(vip==nil)then self.vip.gameObject:SetActive(false) return end
	self.vip.gameObject:SetActive(true)
	self.vip.spriteName="vip".. vip
end

function My:ShowCan(store)	
	local vip = store.vipLv
	if(vip==nil)then self:SNum(store) return end
	if(VIPMgr.GetVIPLv()>=vip)then
		self.can:SetActive(false)
		self:SNum(store)
	else
		self.can:SetActive(true)
	end
end

function My:DestroyGo()
	if(self.trans~=nil)then
		self.trans.gameObject.name="StoreCell"
		GbjPool:Add(self.trans.gameObject) 
		self:SBg(false)
		self.trans=nil
	end
end

function My:Dispose()
	self.limitLv.text = ""
	self.sell:SetActive(false)
	self.id=0
	self.limit.gameObject:SetActive(false)
	self.can:SetActive(false)
	if(self.cell~=nil)then		
		self.cell:DestroyGo()
		ObjPool.Add(self.cell)
		self.cell=nil
	end
end






