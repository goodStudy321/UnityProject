UIAuctionR21 = Super:New{Name = "UIAuctionR21"}

require("UI/Auction/RItem21")

local M = UIAuctionR21

M.mCellList = {}
M.mMaxIndex = 3
--M.mSelectDic = {};
--M.SelectLen = 0;
M.mSelectItem = nil;

function M:Init(go)
    local C = ComTool.Get
    local T = TransTool.FindChild
    local US = UITool.SetLsnrClick
    local tip = "拍卖行右侧面板3"
    local trans = go.transform
    local US = UITool.SetLsnrClick;

    self.go = go
    self.sv = C(UIScrollView,trans,"SV",tip,false)
    self.panel = C(UIPanel, trans, "SV")
    self.wrap = C(UIWrapContent, trans, "SV/wrap")
    self.prefab = T(trans, "SV/wrap/gird")
    self.prefab:SetActive(false)

    US(trans, "PutDownBtn", tip, self.OnPutDown, self);
    self.wrap.onInitializeItem = UIWrapContent.OnInitializeItem(self.OnUpdateItem,self)
    self.allPriceLb = C(UILabel,trans,"allPrice",tip,false)

    self.noTip = T(trans,"Tip")
    self:SetLsner("Add")
end

function M:SetLsner(key)
    AuctionMgr.eUpGoods[key](AuctionMgr.eUpGoods,self.ShowData,self)
end

function M:OnPutDown()
    self:UpdateSeletDic();
    -- if M.SelectLen > 0 then
    --     MsgBox.ShowYesNo("下架后不可二次上架，是否确认下架？", self.YesBtnCb, self);
    -- else
    --     UITip.Log("未选择任何拍品道具");
    -- end
    if M.mSelectItem ~= nil then
        MsgBox.ShowYesNo("下架后不可二次上架，是否确认下架？", self.YesBtnCb, self);
    else
        UITip.Log("未选择任何拍品道具");
    end
end

function M:YesBtnCb()
    --AuctionMgr:ReqPutDown(self.mSelectDic);
    AuctionMgr:ReqPutDown(self.mSelectItem);
end

--选择的物品
function M:UpdateSeletDic()
    -- TableTool.ClearDic(self.mSelectDic);
    -- local dic = self.mSelectDic;
    -- M.SelectLen = 0;
    M.mSelectItem = nil;
    local list = self.mCellList;
    for k,v in ipairs(list) do
        if v:IsActive() then
            local cells = v.Cells
            for k,v in ipairs(cells) do 
                if v:IsActive() and v.data and v.IsSelect then
                    M.mSelectItem = v;
                end
            end
        end
    end

end



function M:OnUpdateItem(go, index, realIndex)
    realIndex = 1-realIndex
    local data = AuctionMgr:GetGoodsSelfByIndex(realIndex)
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
    local data = AuctionMgr:GetgoodsSelfList()
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
            list[i]:UpdateData(data[i], RItem21)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            go.name = i
            TransTool.AddChild(self.wrap.transform, go.transform)
            local item = ObjPool.Get(RGridItem)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i], RItem21)
            table.insert(list, item)
        end
    end
    self.wrap:SortAlphabetically()
    self:ResetPosition()
    self:UpdatePrice()
end

function M:UpdatePrice()
    local data = AuctionMgr:GetMyGoods()
    if not data then return end
    local price = 0
    local index = VIPMgr.GetVIPLv() + 1
    local Ratio = VIPLv[index].arg22*0.0001
    local ratio = 1 - Ratio
    for i=1,#data do
        if data[i].aucId ~= "0"  and data[i].cur_gold then
            price = price + math.floor(data[i].cur_gold *ratio)
        end
    end
    self.allPriceLb.text = price
end

function M:ResetPosition()
    self.sv:ResetPosition()
    self.sv.transform.localPosition = Vector2(0,0)
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
    self:SetLsner("Remove")
    TableTool.ClearDicToPool(self.mCellList)
    TableTool.ClearUserData(self)

    M.mSelectItem = nil;
    --M.SelectLen = 0;
    --TableTool.ClearDic(self.mSelectDic);
end

return M