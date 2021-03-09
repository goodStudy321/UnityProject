require("UI/UIV4Panel/VIPContent")
UIV4Panel = UIBase:New{Name = "UIV4Panel"}

local M = UIV4Panel
local aMgr = Loong.Game.AssetMgr

function M:InitCustom()
    local C = ComTool.Get
    local T = TransTool.FindChild
    local US = UITool.SetLsnrClick

    local root = self.root

    self.modName = C(UILabel,root,"all/left/modName",self.Name,false)
    self.modRoot = T(root,"all/left/mod")
    self.cell = T(root,"cell")

    self.smallMod1 = T(root,"all/center/mod1")
    self.smallMod2 = T(root,"all/center/modRoot2")

    local right = T(root,"all/right").transform
    self.desSV = T(right,"desSV")
    self.desRoot = T(self.desSV.transform,"desRoot")
    self.desLb = C(UILabel,self.desSV.transform,"desLb",self.Name,false)
    self.sprRoot = T(self.desSV.transform,"SprRoot")
    self.spr = T(self.desSV.transform,"Spr")
    self.Rcell = T(right,"cell")
    self.RcellName = C(UILabel,right,"cellName",self.Name,false)
    self.priceLb = C(UILabel,right,"priceLb",self.Name,false)
    self.newPriceLb = C(UILabel,right,"newPriceLb",self.Name,false)
    self.needPriceLb = C(UILabel,right,"needPriceLb",self.Name,false)

    US(right,"goBtn","",self.ClickToDredge,self)
    US(right,"moreVipLb","",self.ClickToGo,self)

    US(root,"closeBtn","",self.OnClose,self)

    self:SetLsner("Add")
end

function M:SetLsner(func)
    VIPMgr.eCloseV4[func](VIPMgr.eCloseV4,self.OnClose,self)
end

function M:OnClose()
    UIMgr.Close(self.Name)
    JumpMgr.eOpenJump()
end

function M:ClickToDredge()
    local isenough = RoleAssets.IsEnoughAsset(2,self.newPrice)
    if isenough==true then
        MsgBox.ShowYesNo("是否花费[67cc67]"..self.newPrice.."元宝[-]购买天帝卡？",M.yesCb)
    else
        StoreMgr.JumpRechange()
    end
end

function M.yesCb()
    local vip = VIPMgr.GetVIPLv()
    local dic = VIPMgr.firstBuy
    if vip == 0 and dic then
        VIPMgr.ReqBuy(V4Data[1].cardId)
        return
    end
    VIPMgr.ReqVIPDirect()
end

function M:ClickToGo()
    VIPMgr.OpenVIP()
end

-- 初始化两个道具格子
function M:InitCell()
    if not self.Cell then
        self.Cell = ObjPool.Get(UIItemCell)
        self.Cell:InitLoadPool(self.cell.transform)
    end
    local id1 = V4Data[1].id
    self.Cell:UpData(id1)

    if not self.RCell then
        self.RCell=ObjPool.Get(Cell)
        self.RCell:InitLoadPool(self.Rcell.transform)
    end
    local id2 = V4Data[1].cardId
    self.RCell:UpData(id2,"",false)
    self.RCell.Qua.enabled = false
end

-- 显示模型以及称号
function M:ShowModel()
    local name1 = V4Data[1].mod1
    local name2 = V4Data[1].mod2
    local name3 = V4Data[1].mod3
    aMgr.LoadPrefab(name1,GbjHandler(self.SetLeftModel,self))
    aMgr.LoadPrefab(name2,GbjHandler(self.SetCenterModel,self))
    aMgr.LoadPrefab(name3,GbjHandler(self.SetTitle,self))
end

function M:SetLeftModel(go)
    self:ClearModel(self.curLeftMod)
   self:SetModel(go,self.curLeftMod,self.modRoot)
end

function M:SetCenterModel(go)
    self:ClearModel(self.curCenterMod)
    self:SetModel(go,self.curCenterMod,self.smallMod1)
end

function M:SetTitle(go)
    self:ClearModel(self.curTitle)
    self:SetModel(go,self.curTitle,self.smallMod2)
    go:AddComponent(typeof(UIEffBinding))
    go.transform.localScale = Vector3.New(0.8,0.8,0.8)
    go.transform.localPosition = Vector3.New(160,-172,0)
end

function M:SetModel(go,curMod,root)
    AssetMgr:SetPersist(go.name, ".prefab",true)
    curModel = go
    go.transform:SetParent(root.transform)
    go.transform.localPosition = Vector3.zero
    go.transform.localScale = Vector3.one
    go.transform.localRotation = Quaternion.Euler(0,0,0)
end

function M:ClearModel(go)
    if go then
        AssetMgr:Unload(go.name, ".prefab", false)
        Destroy(go)
        go = nil
    end
end


-- 显示文本
function M:ShowLb()
    local modName = V4Data[1].name
    if self.modName then
        self.modName.text = modName
    end

    local id = tostring(V4Data[1].cardId)
    local cardName = VIPBuy[id].name
    local day = VIPBuy[id].day
    if self.RcellName then
        self.RcellName.text = cardName.."("..day.."天有效)"
    end
    
    local price = VIPBuy[id].fPrice
    self.newPrice = VIPBuy[id].price
    if self.priceLb then
        self.priceLb.text = price
    end
    if self.newPriceLb then
        self.newPriceLb.text = self.newPrice
    end

    local vipDes = VIPLv[5]
    local desList = VIP.GetVIPDes(vipDes,true)
    if not self.DesLB then
        self.DesLB = ObjPool.Get(VIPContent)
        self.DesLB:Init()
    end
    for i,v in ipairs(desList) do
        self.DesLB:CreateLb(self.desRoot,v,self.desLb.gameObject,2,true,self.sprRoot,self.spr)
    end
end

-- 判断是否购买过真仙卡或者仙尊卡，且玩家VIP等级处于VIP1-VIP3时
function M:IsBuyCard()
    local vip = VIPMgr.GetVIPLv()
    self.toV4Id=0
	local istip = false
	local id1 = "210001"
	local id2 = "210002"
	local id4 = "210003"
	local buyDic = VIPMgr.firstBuy
	if buyDic[id4]~=true then
		local vipBuy4 = VIPBuy[id4]
		local vipbuy=nil
		if buyDic[id2]==true and vip>=1 and vip<=3 then 
			vipbuy = VIPBuy[id2]	
			self.toV4Id=id2		
		elseif buyDic[id1]==true and vip>=1 and vip<=3 then
			vipbuy = VIPBuy[id1]
			self.toV4Id=id1
		end
        if not vipbuy then return false end
        self.newPrice = vipBuy4.price-vipbuy.price
		return true
	end
	return istip
end

function M:ShowPrice()
    local isShow = self:IsBuyCard()
    if isShow == false then
        self.needPriceLb.gameObject:SetActive(false)
    else
        self.needPriceLb.gameObject:SetActive(true)
        self.newPriceLb.text = self.newPrice
        self.needPriceLb.text = self.newPrice.."直升V4"
    end
end

-- 显示数据
function M:ShowData()
    self:InitCell()
    self:ShowModel()
    self:ShowLb()
    self:ShowPrice()
end


function M:OpenCustom()
    self:ShowData()
end

function M:Clear()
    self:SetLsner("Remove")
    self:ClearModel(self.curLeftMod)
    self:ClearModel(self.curCenterMod)
    self:ClearModel(self.curTitle)
    if self.Cell then
        self.Cell:DestroyGo()
        ObjPool.Add(self.Cell)
        self.Cell = nil
    end
    if self.RCell then
        if LuaTool.IsNull(self.RCell.Qua)~=true then 
            self.RCell.Qua.enabled = true 
        end
        self.RCell:DestroyGo()
        ObjPool.Add(self.RCell)
        self.RCell = nil
    end

    if self.DesLB then
        ObjPool.Add(self.DesLB)
        self.DesLB = nil
    end
    
end

return M