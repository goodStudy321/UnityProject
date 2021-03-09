--[[
不是VIP界面
--]]
require("UI/UIVIP/VIPCell")
NoVIP=Super:New{Name="NoVIP"}
local My=NoVIP
--My.eVip=Event()
-- local 
-- local vipId=1
-- local clickVip=nil

function My:Ctor()
	self.cellList={}
end

function My:Init(go)
	self.trans=go.transform
	local CG=ComTool.Get
	local TF=TransTool.FindChild

	for i=1,3 do
		if not self.list then self.list={} end
		self.list[i]=TF(self.trans,"S"..i)
	end
	self.grid=CG(UIGrid,self.trans,"Panel/Grid",self.Name,false)
	self.grid.onCustomSort=self.SortName
	self.pre=TF(self.trans,"c")
	self.desPanel=CG(UIScrollView,self.trans,"bg/Panel",self.Name,false)

	--self.des=CG(UILabel,self.desPanel.transform,"Label",self.Name,false)

	self.Lb = TF(self.desPanel.transform,"Lb")
	self.Spr = TF(self.desPanel.transform,"spr")
	self.LbRoot = TF(self.desPanel.transform,"LbRoot")
	self.SprRoot = TF(self.desPanel.transform,"sprRoot")

	self.eff=TF(self.trans,"Btn/fx_gm")
	self.eff:SetActive(true)
	UITool.SetBtnClick(self.trans,"Btn",self.Name,self.OnClick,self)

	VIPCell.eClick:Add(self.VIPClick,self)
	self:VIPCard()
	
end

function My.SortName(a,b)
	local num1 = tonumber(a.name)
	local num2 = tonumber(b.name)
	if(num1<num2)then
		return 1
	elseif (num1>num2)then
		return -1
	else
		return 0
	end
end

--开通
function My:OnClick()
	local buy = VIPBuy[self.id]
	local store = StoreData[buy.shopid]
	local cost = store.curPrice
	local isEnough=RoleAssets.IsEnoughAsset(2,cost)
	if isEnough==true then
		local tip="是否花费"..cost.."元宝购买"..buy.name.."？"
		MsgBox.ShowYesNo(tip, self.QuickCb,self)		
	else
		StoreMgr.JumpRechange()
	end
end

function My:QuickCb()
	VIPMgr.ReqBuy(tonumber(self.id))
end

function My:VIPClick(id)
	if self.id==id then return end
	if self.id then 
		local cell = self.cellList[self.id]
		cell:ShowLight(false)
		self:SState(false)
	end
	self.desPanel:ResetPosition()
	self.id=id
	local vipbuy = VIPBuy[id]
	local lv = vipbuy.lv
	local data = VIPLv[lv+1]
	if not data then iTrace.Error("xiaoyu","VIP等级表为空 id: "..lv)return end
	local textList = VIP.GetVIPDes(data,true)

	if not self.DesLB then
        self.DesLB = ObjPool.Get(VIPContent)
        self.DesLB:Init()
	end
	self.DesLB:Clean()
    for i,v in ipairs(textList) do
        self.DesLB:CreateLb(self.LbRoot,v,self.Lb,2,true,self.SprRoot,self.Spr)
    end
	--self.des.text=text

	self:SState(true)
end

function My:SState(active)
	local index = tonumber(self.id)-210000
	local s = self.list[index]
	if s then
		s:SetActive(active)
	end
end

function My:VIPCard()
	local max = nil
	for k,v in pairs(VIPBuy) do
		local cell=ObjPool.Get(VIPCell)
		cell:Init(self.pre,self.grid.transform)
		cell:UpData(k)
		self.cellList[k]=cell
		if not max then 
			max=tonumber(k)
		else 
			if tonumber(k)>max then max=tonumber(k) end
		end
	end
	self.grid:Reposition()
	if max then
		local ce = self.cellList[tostring(max)]
		ce:OnClick()
	end
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:Close()
	self.trans.gameObject:SetActive(false)
end

function My:Dispose()
	self.id=nil
	VIPCell.eClick:Remove(self.VIPClick,self)
	TableTool.ClearDicToPool(self.cellList)
	 TableTool.ClearUserData(self)
	 if self.DesLB then
        ObjPool.Add(self.DesLB)
        self.DesLB = nil
	end
	
end