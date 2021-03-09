require("UI/Auction/RItem22")
UIAuctionR22 = Super:New{Name = "UIAuctionR22"}

local M = UIAuctionR22

M.mCellList = {}
M.mMaxIndex = 6

function M:Init(go)
    local C = ComTool.Get
    local T = TransTool.FindChild
    local US = UITool.SetLsnrClick
    local tip = "拍卖行右侧面板4"
    self.go = go
    local trans = go.transform

    self.sv = C(UIScrollView,trans,"SV",tip,false)
    self.svPos = self.sv.transform.localPosition
    self.panel = C(UIPanel, trans, "SV")
    self.wrap = C(UIWrapContent, trans,"SV/wrap",tip,false)
    self.prefab = T(trans, "SV/wrap/Item_99")
    self.prefab:SetActive(false)
    self.noTip = T(trans,"Tip")
    self.wrap.onInitializeItem = UIWrapContent.OnInitializeItem(self.OnUpdateItem,self)
    self:SetLsner("Add")
end

function M:SetLsner(key)
    --AuctionMgr.eUpGoods[key](AuctionMgr.eUpGoods,self.ShowData,self)
end

function M:OnUpdateItem(go, index, realIndex)
    realIndex = 1-realIndex
    local data = self.data
    if not data then return end
    local info = data[realIndex]
    if not info then return end
    local list = self.mCellList
    local cell = list[index+1] 
    if not cell then return end
    cell:InitItem(info)
end

function M:UpdateWrapContentIndex(len)
    local minIndex = (1-len) > 0 and 0 or (1-len)
    ------iTrace.Error("minIndex", minIndex)
    self.wrap.minIndex = minIndex
    self.wrap.maxIndex = 0
end

function M:ShowData()
    local firId = AuctionMgr:GetFirId()
    local data = nil
    if firId == "2" then
        data = AuctionMgr:GetSellLogs()
    elseif firId == "3" then
        data = AuctionMgr:GetbuyLogs()
    elseif firId == "4" then
        data = AuctionMgr:GetFamilyLogs()
    end
    if not data then return end
    self.data = data
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
            list[i]:InitItem(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            go.name = i         
            TransTool.AddChild(self.wrap.transform, go.transform)
            local item = ObjPool.Get(RItem22)
            item:Init(go)
            item:SetActive(true)
            item:InitItem(data[i])
            table.insert(list, item)
        end
       
    end
    -- self.wrap:SortAlphabetically()
    self.mNeedSortAlphabetically = true
    self:ResetPosition()
end

function M:LateUpdate()
    if self.mNeedSortAlphabetically then
        self.mNeedSortAlphabetically = false
        self.wrap:SortAlphabetically()
    end
end


function M:ResetPosition()
    self.sv:ResetPosition()
    self.sv.transform.localPosition = self.svPos
    self.panel.clipOffset = Vector2(0,0)
end

function M:Open()
    self.go:SetActive(true)
    self:ShowData()
end

function M:Close()
    self.go:SetActive(false)
end

function M:Dispose()
    self.data = nil
    self.mNeedSortAlphabetically = false
    self:SetLsner("Remove")
    TableTool.ClearDicToPool(self.mCellList)
end

return M