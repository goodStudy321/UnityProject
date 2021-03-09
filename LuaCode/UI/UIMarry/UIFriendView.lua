UIFriendView = Super:New{Name = "UIFriendView"}

require("UI/UIMarry/FriendCell")

local M = UIFriendView

function M:Ctor()
    self.cellList = {}
    self.temp = CopyTemp["30018"]
end

function M:Init(go)
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf
    local trans = go.transform

    self.go = go

    self.grid = G(UIGrid, trans, "ScrollView/Grid")
    self.cell = FC(self.grid.transform, "Cell")
    self.cell:SetActive(false)

    S(go, self.OnClickSelf, self, nil, false)
end

function M:Refresh()
    local data = self:GetNewData()
    if  #data == 0 then
        UITip.Log("没有找到合适的异性好友")
        return
    end
    self:UpdateData(data)
    self:SetActive(true)
end

function M:UpdateData(data)
    local len = #data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateCell(data[i],self.temp)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            self:CreateCell(data[i])
        end
    end
    self:Reposition()
end

function M:CreateCell(data)
    local go = Instantiate(self.cell)
    TransTool.AddChild(self.grid.transform, go.transform)
    local cell = ObjPool.Get(FriendCell)
    cell:Init(go)
    cell:SetActive(true)
    cell:UpdateCell(data, self.temp)
    table.insert(self.cellList, cell)
end

function M:GetNewData()
    local data = FriendMgr.FriendList
    local len = #data
    local temp = {}
    for i=1,len do
        if data[i].Online and data[i].Sex ~= User.MapData.Sex  and data[i].Level >= self.temp.lv then
            table.insert(temp, data[i])
        end
    end
    return temp
end

function M:UpdateCellList(id)
    local list = self.cellList
    for i=1, #list do
        if list[i]:ActiveSelf() then
            list[i]:SetActive(list[i].data.ID ~= id)
        end
    end

    local state = self:NeedOpen(list)
    if state then
        self:Reposition()
    else
        self:SetActive(state)
    end
end

function M:NeedOpen(list)
    local state = false
    for i=1,#list do
        if list[i]:ActiveSelf() then
            state = true
            break
        end
    end    
    return state
end

function M:Reposition()
    self.grid:Reposition()
end

function M:OnClickSelf()
    self:SetActive(false)
end

function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:ActiveSelf()
    return self.go.activeSelf
end

function M:Dispose()
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M