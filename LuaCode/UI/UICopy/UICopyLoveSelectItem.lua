UICopyLoveSelectItem = Super:New{Name = "UICopyLoveSelectItem"}

local M = UICopyLoveSelectItem

function M:Init(go)
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf
    local trans = go.transform

    self.go = go

    self.cellRoot = F(trans, "CellRoot")
    self.select = FC(trans, "Select")
    self.btnSelect = FC(trans, "BtnSelect")
    self.itemCell = ObjPool.Get(UIItemCell)

    S(self.btnSelect, self.OnClick, self, nil, false)
end

function M:UpdateData(data)
    self.data = data
    self.itemCell:InitLoadPool(self.cellRoot)
    self.itemCell:UpData(data)
end


function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:UpdateState(isSelect)
    if isSelect then
        self.btnSelect:SetActive(false)    
    else
        UITool.SetGray(self.btnSelect)     
    end
    self.select:SetActive(isSelect)
end

function M:OnClick()
    CopyMgr:ReqMarryCopySelect(self.data)
end

function M:Dispose()
    self.data = nil
    self.itemCell:DestroyGo()
    ObjPool.Add(self.itemCell)
    self.itemCell = nil
    TableTool.ClearUserData(self)
end

return M