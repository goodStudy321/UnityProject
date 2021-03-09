UIAuctionR4 = Super:New{Name = "UIAuctionR4"}

require("UI/Auction/RItem4")

local M = UIAuctionR4

M.mCellList = {}
M.mMaxIndex = 3
M.mData = {}
M.mSeleclDic = {}
M.mCellList = {}
M.mPriceList ={}
function M:Init(go)
    local C = ComTool.Get
    local T = TransTool.FindChild
    local US = UITool.SetLsnrClick
    local tip = "拍卖行右侧面板4"
    self.go = go
    local trans = go.transform

    self.sv = C(UIScrollView,trans,"SV",tip,false)
    self.panel = C(UIPanel, trans, "SV")
    self.wrap = C(UIWrapContent, trans, "SV/wrap")
    self.prefab = T(trans, "SV/wrap/Grid")
    self.prefab:SetActive(false)
    self.noTip = T(trans,"Tip")
    self.cost = C(UILabel, trans, "Cost")

    US(trans, "BtnUse", tip, self.OnUse, self)
    US(trans, "BtnPutOn", tips, self.OnPutOn, self)
    US(trans, "BtnPutOnTip", tip, self.OnPutOnTip, self)

    self.wrap.onInitializeItem = UIWrapContent.OnInitializeItem(self.OnUpdateItem,self)
    self:SetLsner("Add")
end

function M:SetLsner(key)
    PropMgr.eAdd[key](PropMgr.eAdd, self.PropAdd, self)
    PropMgr.eRemove[key](PropMgr.eRemove, self.PropRemove, self)
    PropMgr.eUpNum[key](PropMgr.eUpNum, self.PropUpNum, self)
    RItem4.eUpdatePrice[key](RItem4.eUpdatePrice, self.UpdatePrice, self)
end

function M:UpdatePrice()
    --local list = self.mCellList
    local price = 0
    -- for i=1,#list do
    --     local cell = list[i]
    --     if cell:IsActive() then
    --         price = price + cell:GetPrice()
    --     end
    -- end
    local list = self.mPriceList;
    if #list > 0 then 
        for i,v in ipairs(list) do
            if v.isSelect == true then
                price = price + self:GetCellPrice(v.id);
            end
        end
    end
    self.cost.text = price
end


function M:ChangeNum(id,num)
    local list = self.mPriceList;
    for i,v in ipairs(list) do
        if v.id == id then
            v.curNum = num;
        end
    end
end

function M:GetCellPrice(id)
    local list = self.mPriceList;
    for i,v in ipairs(list) do
        if v.id == id then
            return v.curNum * v.startPrice;
        end
    end
    return ;
end

function M:PropAdd(tb,action,tp)
    if tp == 1 or tp == 5 then
        self:UpdateData()
    end
end

function M:PropRemove(id,tp,type_id,action,index)
    if tp == 1 or tp == 5 then
        self:UpdateData()
    end
end

function M:PropUpNum(tb,tp,num,action)
    if tp == 1 or tp == 5 then
        self:UpdateData()
    end
end

function M:UpdateSelectDic()
    TableTool.ClearDic(self.mSeleclDic)
    local dic = self.mSeleclDic
    --local list = self.mCellList
    self.mLen =0
    -- for _,v in ipairs(list) do
    --     if v:IsActive() then
    --         local cells = v.Cells
    --         for _,cell in ipairs(cells) do
    --             if cell:IsActive() and cell.Data and cell.CurNum > 0 and cell.IsSelect then
    --                 dic[tostring(cell.Data.id)] = cell.CurNum
    --                 self.mLen = self.mLen + 1
    --             end
    --         end
    --     end
    -- end
    local list = self.mData;
    for _,v in ipairs(list) do
        for _,cell in ipairs(v) do
            if cell.isSelect then
                dic[tostring(cell.id)] = self:GetCellNum(cell.id);
                self.mLen = self.mLen + 1
            end
        end
    end
end

function M:GetCellNum(id)
    local list = self.mPriceList;
    for i,v in ipairs(list) do
        if v.id == id then
           return v.curNum;
        end
    end
    return 0;
end

function M:SetIsSelect(id)
    local list = self.mData;
    for _,v in ipairs(list) do
        for _,cell in ipairs(v) do
            if cell.id ==id then
                cell.isSelect = not cell.isSelect;
            end
        end
    end
    local list2 = self.mPriceList
    for _,v in ipairs(list2) do
        if v.id ==id then
            v.isSelect = not v.isSelect;
        end
    end
end

function M:GetIsSelect(id)
    local list = self.mData;
    for _,v in ipairs(list) do
        for _,cell in ipairs(v) do
            if cell.id == id then
                return cell.isSelect;
            end
        end
    end
    return;
end

function M:OnUse()
    self:UpdateSelectDic()
    if self.mLen > 0 then
        MsgBox.ShowYesNo("使用后选中物品将无法上架拍卖行，是否确认使用？", self.YesUseCb, self)
    else
        UITip.Log("未选择任何拍品道具")
    end
end

function M:YesUseCb()
    AuctionMgr:ReqUseSelf(self.mSeleclDic)
end

function M:OnPutOn()
    self:UpdateSelectDic()
    if self.mLen > 0 then
        MsgBox.ShowYesNo("是否以底价上架选中的所有道具？", self.YesShelfCb, self)
    else
        UITip.Log("未选择任何拍品道具")
    end
end

function M:YesShelfCb()
    AuctionMgr:ReqOnShelf(self.mSeleclDic)
end

function M:OnPutOnTip()
    local cfg = InvestDesCfg["19"]
    if not cfg then return end
    UIComTips:Show(cfg.des, Vector3(-533,-270,0), nil, nil, nil, nil, UIWidget.Pivot.BottomLeft)
end

function M:OnUpdateItem(go, index, realIndex)
    local data = self.mData[1-realIndex]
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

function M:UpdateAuctionItems()
    local items = PropMgr.GetCanAuctionItems()
    local data = self.mData
    TableTool.ClearDic(data)
    TableTool.ClearDic(self.mPriceList);
    for i=1,#items do
        local index = math.ceil(i/4)
        if not data[index] then
            data[index] = {}
        end
        items[i].isSelect = true;
        table.insert(data[index], items[i])

        local tab = {
                    isSelect = items[i].isSelect;
                    id = items[i].id;
                    curNum = items[i].num;
                    startPrice = ItemData[tostring(items[i].type_id)].startPrice;
                    }
        table.insert(self.mPriceList, tab);
    end
end

function M:UpdateData()
    if not self:IsActive() then return end
    self:UpdateAuctionItems()
    self:UpdatePrice();
    local data = self.mData
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
            list[i]:UpdateData(data[i], RItem4)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            go.name = i
            TransTool.AddChild(self.wrap.transform, go.transform)
            local item = ObjPool.Get(RGridItem)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i], RItem4)
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
    self.sv.transform.localPosition = Vector2(0,0)
    self.panel.clipOffset = Vector2(0,0)
end


function M:Open()
    self.go:SetActive(true)
    self:UpdateData()
    -- self:UpdatePrice()
end

function M:Close()
    self.go:SetActive(false)
end

function M:Dispose()
    self.mNeedSortAlphabetically = false
    self:SetLsner("Remove")
    TableTool.ClearDic(self.mSeleclDic)
    TableTool.ClearDic(self.mData)
    TableTool.ClearDic(self.mPriceList)
    TableTool.ClearDicToPool(self.mCellList)
    TableTool.ClearUserData(self)
end

return M