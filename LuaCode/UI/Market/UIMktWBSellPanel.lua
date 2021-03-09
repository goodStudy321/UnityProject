UIMktWBSellPanel = Super:New{Name = "UIMktWBSellPanel"}

require("UI/Market/UIMktWBSellCell")
local M = UIMktWBSellPanel

function M:Init(panelObject)
    self.obj = panelObject
    self.objTrans=self.obj.transform

    local C = ComTool.Get
    local T = TransTool.FindChild

    self.items = {}

    self.sellId = nil
    self.bagId = nil

    self.itemGrid = C(UIGrid,self.objTrans,"Scroll View/Grid")

    self.item = T(self.objTrans,"Scroll View/Grid/Cell")

    self.yesBtn=T(self.objTrans,"yesBtn")
    UITool.SetLsnrSelf(self.yesBtn,self.ClickToYes,self)
    
    self.closeBtn=T(self.objTrans,"CloseBtn")
	UITool.SetLsnrSelf(self.closeBtn,self.Close,self)
end

function M:Open(data)
    self.obj:SetActive(true)
    self:ShowData(data)
end

function M:Close()
    self.obj:SetActive(false)
    self:Clear()
end

function M:ShowData(data)
    self.data = data
    self.sellId = self.data.id
    self.itemid = self.data.typeId
    self.bagIdList = PropMgr.typeIdDic[tostring(self.itemid)]
    local num = #self.bagIdList
    if num == nil or num == 0 then
        self:RenewItemNum(0)
    end
    self:RenewItemNum(num)
    
    for i,bagid in ipairs(self.bagIdList) do
        local tb = PropMgr.tbDic[tostring(bagid)]
        self.items[i]:InitCfg(tb, function() self:ClickSelItem(tb.id) end)
    end
end

function M:ClickSelItem(bagid)
    self.bagId = bagid
    for i,v in ipairs(self.bagIdList) do
        local tb = PropMgr.tbDic[tostring(v)]
        if self.bagId == tb.id then
            self.items[i]:Select(true)
        else
            self.items[i]:Select(false)
        end
    end
end

function M:CloneItem()
    local cloneObj = GameObject.Instantiate(self.item)
    cloneObj.transform.parent = self.item.transform.parent
	cloneObj.transform.localPosition = self.item.transform.localPosition
	cloneObj.transform.localRotation = self.item.transform.localRotation
	cloneObj.transform.localScale = self.item.transform.localScale
    cloneObj:SetActive(true)
    
    local cloneItem = ObjPool.Get(UIMktWBSellCell)
    cloneItem:Init(cloneObj)

	self.items[#self.items + 1] = cloneItem
	return cloneItem
end

--//重置条目数量
function M:RenewItemNum(num)
    local len = #self.items
    for i=1,len do
        self.items[i]:Dispose()
        self.items[i]:Show(false)
    end
    local realNum = num
    if realNum <= len then
        for i=1,realNum do
            self.items[i]:Show(true)
        end
    else
        for i=1,len do
            self.items[i]:Show(true)
        end

        local needNum = realNum - len
        for i=1,needNum do
            self:CloneItem()
        end
    end

    self.itemGrid:Reposition()
end

function M:ClickToYes()
    if self.bagId == nil or self.sellId == nil then
        UITip.Log("请选择一件出售")
    else
        MarketMgr:ReqMarketWantGoods(self.bagId,self.sellId)
        self.obj:SetActive(false)
    end
end

function M:Clear()
    self.sellId = nil
    self.bagId = nil
end

function M:Dispose()
    self:Clear()
    TableTool.ClearDic(self.items)
end

return M