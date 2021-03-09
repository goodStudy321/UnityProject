--//求购列表条目
require("UI/Market/UIPriceItem")
UIMktWantList = Super:New{Name = "UIMktWantList"}

local M = UIMktWantList

function M:Init(gameObj)
    self.itemObj = gameObj
    self.rootTrans = self.itemObj.transform

    local root = self.rootTrans

    local tip = "UI市场求购物品条目"
    local C = ComTool.Get
    local T = TransTool.FindChild

    --//选择标志
    self.selSign = T(root,"SelSign")
    --//物品cell父节点
    self.cellParent = T(root,"NameCount/CellCont")
    --//总价控件物体
    self.apObj = T(root,"AllPriceCont")

    --//物体名称
    self.itemName = C(UILabel,root,"NameCount/ItemName",tip,false)
    --//求购者名称
    self.userName = C(UILabel,root,"NameCount/UserName",tip,false)
    --//物体等级
    self.itemLv = C(UILabel,root,"Lv",tip,false)

    --//总价控件
    self.apCont = ObjPool.Get(UIPriceItem)
    self.apCont:Init(self.apObj)

    --//初始化操作按钮
    self.handleBtn = T(root,"Handle/HandleBtn")
    self.handleLb = C(UILabel,root,"Handle/Label",tip,false)

    self.dataTbl = {}
    UIMktWBListPanel.eChangeBtn:Add(function(type) self:ChangeBtn(type); end);
end

function M:ChangeBtn(type)
    if type == 1 then
        self.handleLb.text = "撤销"
        UITool.SetLsnrSelf(self.handleBtn,self.ClickToCanel,self)
    else
        self.handleLb.text = "出售"
        UITool.SetLsnrSelf(self.handleBtn,self.ClickToHandle,self)
    end
end

--//初始化配置
function M:InitCfg(tbData)
    self.dataTbl = tbData
    local itemCfg = ItemData[tostring(self.dataTbl.typeId)]

    self.itemName.text = itemCfg.name
    local level =  itemCfg.useLevel or 1

    local lv = self:GetLv(level)
    self.itemLv.text = "Lv."..tostring(lv)
    self.userName.text = self.dataTbl.name

    local allPrice = self.dataTbl.totalPrice

    self.apCont:ShowStrData(allPrice, 1)

    if not self.cellCont then
        self.cellCont = ObjPool.Get(UIItemCell)
        self.cellCont:InitLoadPool(self.cellParent.transform, 0.8)
    end
	self.cellCont:TipWhat(self.dataTbl.itemCellData, self.dataTbl.itemCellData.num, true)
end

function M:GetLv(lv)
    local rolelv = GlobalTemp["90"].Value3
	if lv > rolelv then
		lv = lv - rolelv
		return string.format( "化神%s",lv)
	else
		return lv
	end
end

function M:ClickToHandle()
    local id = tostring(User.MapData.UID)
    local roleid = tostring(self.dataTbl.roleId)
    if roleid == id then
        UITip.Log("自己求购的物品不能出售")
    else
        local itemid = self.dataTbl.typeId
        local id = self.dataTbl.id
        local bagId = PropMgr.TypeIdById(itemid)
        if bagId == nil then
            UITip.Log("你没有满足条件的物品出售")
        else
            --MarketMgr:ReqMarketWantGoods(bagId,id)
            UIMktWBSellPanel:Open(self.dataTbl)
        end
    end
end

function M:ClickToCanel()
    local msg = "是否撤回求购"..self.itemName.text.."*"..self.dataTbl.num
    MsgBox.ShowYesNo(msg,self.YesCb,self)
end

function M:YesCb()
    local id = self.dataTbl.id
    MarketMgr:ReqMarketDownShelf(MarketMgr:GetOpenState(),id)
end

--//显示隐藏
function M:Show(isShow)
    self.itemObj:SetActive(isShow)
end

--//释放
function M:Dispose()
    UIMktWBListPanel.eChangeBtn:Remove(function(type) self:ChangeBtn(type); end);
    if self.apCont ~= nil then
        ObjPool.Add(self.apCont)
        self.apCont = nil
    end
    
    if self.cellCont ~= nil then
		self.cellCont:DestroyGo()
		ObjPool.Add(self.cellCont)
        self.cellCont = nil
    end
    TableTool.ClearDic(self.dataTbl)
    TableTool.ClearUserData(self)
end

return M