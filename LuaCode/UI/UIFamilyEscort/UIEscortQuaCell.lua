UIEscortQuaCell = Super:New{Name = "UIEscortQuaCell"}

local M = UIEscortQuaCell

function M:Init(go, callBack)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf
    
    self.mGo = go
    self.mTrans = go.transform
    self.mCallBack = callBack
    self.mName = G(UILabel, trans, "Name")
    self.mIsTarget = FC(trans, "IsTarget")
    self.mSelect = FC(trans, "Select")
    self.mFx = FC(trans, "FX")
    self.mFx:SetActive(false)
    self.mFxRoot = F(trans, "Root")

    S(go, self.OnClick, self)
end

function M:UpdateData(data)
    if not data then return end
    self.Data = data
    self:UpdateName()
end

function M:OnClick()
    if self.Data and self.mCallBack then
        self.mCallBack(self.Data)
    end
end

function M:SetAdvFx(go)
    go:SetActive(false)
    go.transform.parent = self.mFxRoot
    go.transform.localPosition = Vector3(0,0,1)
    go:SetActive(true)
end

function M:SetSelectFx(go)
    go.transform.parent = self.mFxRoot
    go.transform.localPosition = Vector3(0,0,1)
    go:SetActive(true)
end

function M:UpdateName()
    self.mName.text = self.Data.Name
end

function M:UpdateTarget()
    local curEscortId = FamilyEscortMgr:GetCurEscortId()
    local state = self.Data.Id == curEscortId
    self.mIsTarget:SetActive(state)
    self.mFx:SetActive(state)
end

function M:UpdateSelect(bool)
    self.mSelect:SetActive(bool)
end

function M:Dispose()
    self.Data = nil
    self.mCallBack = nil
    TableTool.ClearUserData(self)
end

return M