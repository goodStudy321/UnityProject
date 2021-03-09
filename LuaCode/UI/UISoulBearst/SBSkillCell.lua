SBSkillCell = Super:New{Name = "SBSkillCell"}

local M = SBSkillCell


M.eClick = Event()

function M:Ctor()
    self.texList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf

    self.go = go
    self.icon = G(UITexture, trans, "Icon")
    self.name = G(UILabel, trans, "Name")

    S(go, self.OnClick, self)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateIcon()
    self:UpdateName()
end


function M:UpdateIcon()
    AssetMgr:Load(self.data.texture, ObjHandler(self.SetIcon, self))
end

function M:SetIcon(tex)
    if self.data then
        self.icon.mainTexture = tex
        table.insert(self.texList, tex.name)
    else
        AssetTool.UnloadTex(tex.name)
    end
end


function M:UpdateName()
    self.name.text = self.data.name
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:OnClick()
    if self.data then
        self.eClick(self.data)
    end
end

function M:Dispose()
    self.data = nil
    AssetTool.UnloadTex(self.texList)
    TableTool.ClearUserData(self)
end

return M