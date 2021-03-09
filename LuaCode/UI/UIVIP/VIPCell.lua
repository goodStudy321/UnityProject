--[[
VIP格子
--]]
local AssetMgr=Loong.Game.AssetMgr
VIPCell=Super:New{Name="VIPCell"}
local My=VIPCell
My.eClick=Event()

function My:Ctor()
	self.cellList={}
end

function My:Init(pre,parent)
	local go=GameObject.Instantiate(pre)
	go:SetActive(true)
	go.transform.parent=parent
	go.transform.localPosition=Vector3.zero
	go.transform.localScale = Vector3.one

	self.trans=go.transform
	local CG=ComTool.Get
	local TF=TransTool.FindChild

	self.title=CG(UISprite,self.trans,"title",self.Name,false)	
	self.Price=CG(UILabel,self.trans,"Price",self.Name,false)	
	self.tip=CG(UILabel,self.trans,"tip",self.Name,false)
	self.yPrice=CG(UILabel,self.trans,"yPrice",self.Name,false)
	self.icon=CG(UITexture,self.trans,"icon",self.Name,false)
	self.discount=CG(UILabel,self.trans,"discount",self.Name,false)
	self.l=TF(self.trans,"l")
	UITool.SetLsnrSelf(go,self.OnClick,self,self.Name)

	VIPMgr.eBuy:Add(self.Buy,self)
end

function My:Buy(id)
	if self.vipId==tonumber(id) and self.state==false then
		--self:SGift(self.data)
	end
end

function My:OnClick()
	self:ShowLight(true)
	My.eClick(self.vipId) 
end

function My:ShowLight(active)
	self.l:SetActive(active)
end

function My:UpData(vipId)
	self.vipId=vipId
	self.trans.name=self.vipId
	local data=VIPBuy[tostring(self.vipId)]
	if(data==nil)then iTrace.Error("xiaoyu","VIP购买表为空 id:".. self.vipId)return end

	self.title.spriteName=data.icon	
	self.tip.text=tostring(data.day).."天\n有效"

	local store = StoreData[data.shopid]
	if not store then iTrace.Error("xiaoyu","商城表为空 id: "..data.shopid)return end
	self.Price.text=store.curPrice
	
	local dis = store.curPrice/data.fPrice
	local yPrice = 0
	if dis<1 then 
		local len = #(tostring(dis))-2
		if len==1 then
			dis=math.ceil(dis*10)
		end
		self.discount.text=UIMisc.NumToStr(dis,"折")
	end
	self.yPrice.text="原价:"..data.fPrice
	self.discount.gameObject:SetActive(store.curPrice/data.fPrice<1)

	local item = ItemData[store.PropId]
	if not item then iTrace.Error("xiaoyu","道具表为空 id: "..store.PropId)return end
	AssetMgr.Instance:Load(item.icon,ObjHandler(self.LoadIcon,self))
end

function My:LoadIcon(obj)
	self.icon.mainTexture=obj
end

--购买赠送VIP的礼包
function My:SGift(data)
	self:CleanCell()
	self.state=VIPMgr.firstBuy[tostring(self.vipId)] or false
	local list=nil
	if self.state==true then list=data.last 
	else list=data.list end
	for i,v in ipairs(list) do
		local id=v.id
		local val=v.val
		local cell=ObjPool.Get(UIItemCell)
		cell:InitLoadPool(self.grid.transform,0.7)
		cell:UpData(id,val)
		self.cellList[#self.cellList+1]=cell
	end
	self.grid:Reposition()
end

function My:CleanCell()
	while #self.cellList>0 do
		local cell = self.cellList[#self.cellList]
		cell:DestroyGo()
		ObjPool.Add(cell)
		self.cellList[#self.cellList]=nil
	end
end

function My:Dispose()
	VIPMgr.eBuy:Remove(self.Buy,self)
	self:CleanCell()
	if(self.cell~=nil)then ObjPool.Add(self.cell) self.cell=nil end
	if(self.trans~=nil)then self.trans.parent=nil GameObject.Destroy(self.trans.gameObject) end
	if self.mod then GameObject.Destroy(self.mod) self.mod=nil end
	TableTool.ClearUserData(self)
end