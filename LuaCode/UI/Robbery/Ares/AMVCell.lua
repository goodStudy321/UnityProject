AMVCell = Super:New{Name = "AMVCell"}

local M = AMVCell

function M:Ctor()
    self.eClick = Event()
    self.texList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild

    self.go = go
    self.icon = G(UITexture, trans, "Icon")
    self.name = G(UILabel, trans, "Name")
    self.score = G(UILabel, trans, "Score")
    self.highlight = FC(trans, "Highlight")
    self.redPoint = FC(trans, "RedPoint")

    UITool.SetLsnrSelf(go, self.OnClick, self, self.Name, false)
end

function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:OnClick()
    if self.data then
        self.eClick(self.data)
    end
end

function M:UpdateData(data)
    self.data = data
    self:UpdateIcon()
    self:UpdataName()
    self:UpdateScore()
    self:UpdateRedPoint()
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

function M:UpdataName()
    self.name.text = self.data.name
end

function M:UpdateScore()
    if not self.data.state then  --未激活
        self.score.text = "[F21919FF]未获得"
    else  --激活
        self.score.text = string.format("[00FF00FF]开光%s阶", self.data.level)
    end
end

function M:UpdateHighlight(state)
    self.highlight:SetActive(state)
end

function M:UpdateRedPoint()
    self.redPoint:SetActive(self.data.redPointState)
end

function M:Dispose()
    self.data = nil
    self.eClick:Clear()
    AssetTool.UnloadTex(self.texList)
    TableTool.ClearUserData(self)
end

return M