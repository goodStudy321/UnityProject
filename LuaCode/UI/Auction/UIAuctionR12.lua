UIAuctionR12 = Super:New{Name = "UIAuctionR12"}

require("UI/Auction/RItem12")

local M = UIAuctionR12

M.mCellList = {}
M.mMaxIndex = 3

function M:Init(go)
    local C = ComTool.Get
    local T = TransTool.FindChild
    local US = UITool.SetLsnrClick
    local tip = "拍卖行右侧面板2"
    self.go = go
    local trans = go.transform

    self.sv = C(UIScrollView,trans,"SV",tip,false)
    self.panel = C(UIPanel, trans, "SV")
    self.wrap = C(UIWrapContent, trans, "SV/wrap")
    self.prefab = T(trans, "SV/wrap/Grid")
    self.prefab:SetActive(false)
    self.noTip = T(trans,"Tip")

    self.wrap.onInitializeItem = UIWrapContent.OnInitializeItem(self.OnUpdateItem,self)
    self:SetLsner("Add")
end

function M:SetLsner(key)
    AuctionMgr.eUpGoods[key](AuctionMgr.eUpGoods,self.ShowData,self)
end

function M:OnUpdateItem(go, index, realIndex)
    realIndex = 1-realIndex
    local data = AuctionMgr:GetGoodsByIndex(realIndex)
    if not data then return end
    local list = self.mCellList
    local cell = list[index+1] 
    if not cell then return end
    cell:UpdateData(data)
end

function M:UpdateWrapContentIndex(len)
    local minIndex = (1-len) > 0 and 0 or (1-len)
    ------iTrace.Error("minIndex", minIndex)
    self.wrap.minIndex = minIndex
    self.wrap.maxIndex = 0
end

function M:IsActive()
    return self.go.activeSelf
end


function M:ShowData()
    if not self:IsActive() then return end
    local data = AuctionMgr:GetGoods() 
    if not data then return end
    local len = #data
    local num = len > self.mMaxIndex and self.mMaxIndex or len
    local list = self.mCellList
    local count = #list
    local max = count >= num and count or num
    local min = count + num - max
    self.noTip:SetActive(len <= 0)
    self:UpdateWrapContentIndex(len)
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i], RItem12)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            go.name = i
            TransTool.AddChild(self.wrap.transform, go.transform)
            local item = ObjPool.Get(RGridItem)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i], RItem12)
            table.insert(list, item)
        end
    end
    self.wrap:SortAlphabetically()
    self:ResetPosition()
    local firId = AuctionMgr:GetFirId()
    local val = AucFristType[firId].isPJ or 0
    UIAuction:OpenFilterCout(val == 1,true)
    UIAuction:OpenSearch(true)
end

function M:ResetPosition()
    self.sv:ResetPosition()
    self.sv.transform.localPosition = Vector2(0,0)
    self.panel.clipOffset = Vector2(0,0)
end


function M:Open()
    self.go:SetActive(true)
end

function M:Close()
    self.go:SetActive(false)
end

function M:Dispose()
    self:SetLsner("Remove")
    TableTool.ClearDicToPool(self.mCellList)
    TableTool.ClearUserData(self)
end

return M