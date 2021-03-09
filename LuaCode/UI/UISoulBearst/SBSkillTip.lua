SBSkillTip = Super:New{Name = "SBSkillTip"}

local M = SBSkillTip

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
    self.des = G(UILabel, trans, "Des")

    S(go, self.Close, self)
end

function M:UpdateData(data)
    self.data = data
    self:UpdateIcon()
    self:UpdateName()
    self:UpdateDes()
end

function M:UpdateDes()
    self.des.text = self.data.des
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

function M:Open(data)
    self:UpdateData(data)
    self:SetActive(true)
end

function M:Close()
    self:SetActive(false)
end

function M:Dispose()
    self.data = nil
    AssetTool.UnloadTex(self.texList)
    TableTool.ClearUserData(self)
end

return M