SPEquipInfo = Super:New{Name = "SPEquipInfo"}

local My = SPEquipInfo

local len = 4

function My:Ctor()
    self.cellList = {}
    self.texList = {}
end

function My:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.go = go


    local parent = F(trans, "EquipList")
    for i=1,len do
        local go = FC(parent, tostring(i))
        local cell = ObjPool.Get(SPEquipListCell)
        cell:Init(go)
        table.insert(self.cellList, cell)
    end

    -- self.btnTakeOff = FC(trans, "BtnTakeOff")
    -- S(self.btnTakeOff, self.OnTakeOff, self)
end

function My:UpdateData(data)
    self.data = data
    self:Refresh()
end

function My:Refresh()
    self:UpdateCell()
end

function My:UpdateBtnState()
    local condList = self.data.condList
    local state = false
    for i=1,#condList do
        if condList[i].isUse then
            state = true
            break
        end
    end
    if state then
        UITool.SetNormal(self.btnTakeOff)
    else
        UITool.SetGray(self.btnTakeOff)
    end   
end

function My:UpdateIconState()
    if self.data.state == 2 then
        UITool.SetNormal(self.icon)
    else
        UITool.SetGray(self.icon)
    end
end

function My:UpdateCell()
    local data = self.data.condList
    local list = self.cellList
    for i=1, #list do
        list[i]:UpdateData(data[i])
    end
end

function My:TakeOff()
    local list = self.cellList
    for i=1,#list do
        list[i]:SetActive(false)
    end
end

function My:Dispose()
    self.data = nil
    TableTool.ClearListToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return My