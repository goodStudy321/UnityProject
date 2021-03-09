BossRewardCell = Super:New{Name = "BossRewardCell"}

local M = BossRewardCell

function M:Ctor()
    self.texList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    
    self.go = go
    self.icon = G(UITexture, trans, "Icon")
end

function M:UpdateData(data)
    self.data = data
    self:UpdateIcon()
end

function M:SetActive(state)
    self.go:SetActive(state)
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

function M:Dispose()
    self.data = nil
    AssetTool.UnloadTex(self.texList)
end

return M