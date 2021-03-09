SBEquipTip = Super:New{Name = "SBEquipTip"}

local M = SBEquipTip

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find

    self.go = go

    self.itemRoot = F(trans, "ItemRoot")
    self.name = G(UILabel, trans, "Name")
    self.score = G(UILabel, trans, "Score")
    self.totalScore = G(UILabel, trans, "TotalScore")
    self.putOn = FC(trans, "PutOn")
    self.base = G(UILabel, trans, "Base")
    self.best = G(UILabel, trans, "Best")
    self.bg = G(UISprite, trans, "Bg")
end

function M:UpdateData(data)
    self.data = data
    self:UpdateItem()
    self:UpdateName()
    self:UpdateScore()
    self:UpdateTotalScore()
    self:UpdatePutOn()
    self:UpdateBase()
    self:UpdateBest()
    self:UpdateBg()
end

function M:UpdateBg()
    local name = self.data.quality > 0 and string.format("cell_a0%d", self.data.quality)  or "cell_a01"
    self.bg.spriteName = name 
end

function M:UpdateItem()
    if not self.cell then
        self.cell =  ObjPool.Get(SBCell)
        self.cell:InitLoadPool(self.itemRoot)
        self.cell:SetTip(false)
    end
    self.cell:UpdateData(self.data)
end

function M:UpdateName()
    local lv = self.data.level
    if lv > 0 then
        self.name.text = string.format("%s%s  [00FF00FF]+%d", UIMisc.LabColor(self.data.quality),self.data.name, self.data.level)
    else
        self.name.text = string.format("%s%s", UIMisc.LabColor(self.data.quality), self.data.name)
    end
end

function M:UpdateScore()
    self.score.text = string.format("[F4DDBDFF]装备评分  [00FF00FF]%d", self.data.score)
end

function M:UpdateTotalScore()
    self.totalScore.text = string.format("[F4DDBDFF]综合评分  [00FF00FF]%d", self.data.totalScore)
end

function M:UpdatePutOn()
    self.putOn:SetActive(self.data.user~=0)
end

function M:UpdateBase()
    self:CreateSB()
    local sb = self.sb
    local data =  SoulBearstMgr:GetEquipBaseAndAdvAttr(self.data)
    local len = #data
    for i=1, len do
        local arg = ""
        if data[i].add > 0 then
            arg = string.format("[99886BFF]%s  %d [00FF00FF](强化 +%d)", PropName[data[i].k].name, data[i].v, data[i].add)
        else
            arg = string.format("[99886BFF]%s  %d", PropName[data[i].k].name, data[i].v)
        end
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.base.text = str
end

function M:CreateSB()
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()
end

function M:UpdateBest()
    self:CreateSB()
    local sb = self.sb
    local data = self.data.attrList
    local len = #data
    for i=1, len do
        local cfg = PropName[data[i].id]
        local str = cfg.show == 1 and string.format("%0.1f%%", data[i].val*0.01) or data[i].val
        local color = "[008ffc]"
        if i<= self.data.purpleNum then
            color = "[b03df2]"
        end
        local arg = string.format("%s%s  %s", color , cfg.name, str)
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.best.text = str
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
    if self.sb then
        ObjPool.Add(self.sb)
    end
    self.sb = nil

    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    self.cell = nil
    TableTool.ClearUserData(self)
end

return M