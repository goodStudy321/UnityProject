UIMarryGivenIt = Super:New{Name = "UIMarryGivenIt"}

local My = UIMarryGivenIt

function My:Ctor()
    self.eClick = Event()
end

function My:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local US = UITool.SetLsnrSelf

    self.go = go
    self.boxCollider = ComTool.GetSelf(BoxCollider,trans,"UIMarryGivenIt")
    self.highlight = FC(trans, "Highlight","UIMarryGivenIt")
    self.isSelect = false
    US(go.gameObject,self.OnClickBtn, self, nil, false)
end

function My:UpdateData(data)
    self.data = data
    if not self.cell then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.go.transform)
    end
    self.cell:UpData(self.data.type_id)
    self:SetHighlight(false)
    self:SetBoxColState(false)
end

function My:OnClickBtn()
    local cntr = self.cntr
    local isMax = cntr:IsMaxSelect()
    if cntr.isShowSelect then
        self.isSelect = not self.isSelect
        self.eClick(self.isSelect, self.data)
        if self.isSelect == true and isMax then
            return
        end
        self:SetHighlight(self.isSelect)
    end
end

function My:SetBoxColState(state)
    self.boxCollider.enabled = state
end

function My:SetHighlight(state)
    self.isSelect = state
    self.highlight:SetActive(state)
end

function My:IsActive()
    return self.go.activeSelf
end

function My:SetActive(state)
    self.go:SetActive(state)
end

function My:Dispose()
    self.eClick:Clear()
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    self.cell = nil
    self.data = nil
    self.isSelect = false
    TableTool.ClearUserData(self)
end

return My