UICellsShow = UIBase:New{Name = "UICellsShow"}

local M = UICellsShow

M.mCellList = {}

function M:InitCustom()
    local trans = self.root
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf

    self.mBtnClose = FC(trans, "BtnClose")
    self.mGrid = G(UIGrid, trans, "RewardList/ScrollView/Grid")
    S(self.mBtnClose, self.Close, self)
    self:UpdateData() 
end

function M:Show(data)
    self.data = data
    UIMgr.Open(self.Name)
end

function M:UpdateData()
    if not self.data then return end
    local data = self.data
    local len = #data
    local list = self.mCellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    local parent = self.mGrid.transform
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpData(data[i].id, data[i].val)
        elseif i <= count then
            list[i]:SetActive(false)
        else  
            local cell = ObjPool.Get(UIItemCell)   
            cell:InitLoadPool(parent)      
            cell:UpData(data[i].id, data[i].val)
            table.insert(list, cell)
        end
    end
end

function M:DisposeCustom()
    self.data = nil
    TableTool.ClearListToPool(self.mCellList)
end

return M