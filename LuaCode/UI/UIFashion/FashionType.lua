FashionType = Super:New{Name = "FashionType"}

local M = FashionType

M.eClickToggle = Event()

function M:Ctor()
    self.rPList = {}
end


function M:Init(root)
    self.go = root.gameObject;
    local S = UITool.SetLsnrSelf
    local FC = TransTool.FindChild
    local F = TransTool.Find
    
    self.grid = ComTool.Get(UIGrid, root, "ScrollView/Grid")

    for i=1,5 do
        local trans = F(root, string.format("ScrollView/Grid/%s", i))
        S(trans, self.OnChgToggle, self)
        local go = FC(trans, "RedPoint")
        self.rPList[i] = go
    end  
    self:UpdateRedPoint()
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:OnChgToggle(go)
    local _type = tonumber(go.name)
    FashionMgr:ResetSkinList()
    M.eClickToggle(_type)
end

function M:UpdateRedPoint()
    local list = self.rPList
    for i=1,#list do
        local go = list[i]
        local state = FashionMgr:GetTogRedPointState(i)
        go:SetActive(state)
    end 
end

function M:Dispose()
    TableTool.ClearDic(self.rPList)
    TableTool.ClearUserData(self)
end

return M