SPEquipTip = Super:New{Name = "SPEquipTip"}

local My = SPEquipTip

function My:Init(go)
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
    self.strength = G(UILabel, trans, "Strength")
    self.best = G(UILabel, trans, "Best")
    self.lab2Gbj = FC(trans, "Lab2")
    self.lab3Gbj = FC(trans, "Lab3")
    self.strengthLv = G(UILabel, trans, "Lab3/lab")
    self.bg = G(UISprite, trans, "Bg")
end

function My:SetLabAct(ac)
    self.lab2Gbj:SetActive(not ac)
    self.lab3Gbj:SetActive(not ac)
end

function My:UpdateData(data)
    self.data = data
    self:UpdateItem()
    self:UpdateName()
    self:UpdateScore()
    self:UpdateTotalScore()
    self:UpdatePutOn()
    self:UpdateBase()
    self:UpdateStrength()
    self:UpdateBest()
    self:UpdateBg()
    self:SetLabAct(data.other)
end

function My:UpdateBg()
    local name = self.data.quality > 0 and string.format("cell_a0%d", self.data.quality)  or "cell_a01"
    self.bg.spriteName = name 
end

function My:UpdateItem()
    if not self.cell then
        self.cell =  ObjPool.Get(SPCell)
        self.cell:InitLoadPool(self.itemRoot)
        self.cell:SetTip(false)
    end
    self.cell:UpdateData(self.data)
end

function My:UpdateName()
    local lv = self.data.level
    if lv > 0 then
        self.name.text = string.format("%s%s  [00FF00FF]+%d", UIMisc.LabColor(self.data.quality),self.data.name, self.data.level)
    else
        self.name.text = string.format("%s%s", UIMisc.LabColor(self.data.quality), self.data.name)
    end
end

function My:UpdateScore()
    self.score.text = string.format("[F4DDBDFF]装备评分  [00FF00FF]%d", self.data.score)
end

function My:UpdateTotalScore()
    self.totalScore.text = string.format("[F4DDBDFF]综合评分  [00FF00FF]%d", self.data.totalScore)
end

function My:UpdatePutOn()
    self.putOn:SetActive(self.data.user~=0)
end

function My:UpdateBase()
    self:CreateSB()
    local sb = self.sb
    local data =  SpiritGMgr:GetEquipBaseAttr(self.data,1)
    local len = #data
    for i=1, len do
        local arg = ""
        arg = string.format("[F4DDBDFF]%s  %d[-]      [00FF00FF](%s阶+%s)",PropName[data[i].k].name,data[i].v,data[i].step,data[i].baseAdd)
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.base.text = str
end

function My:UpdateStrength()
    self:CreateSB()
    local sb = self.sb
    local data =  SpiritGMgr:GetEquipTotalBaseAttr(self.data)
    local strengthLvs = self.data.level
    if strengthLvs == 0 then
        self.strengthLv.text = ""
        self.strength.text = ""
        return
    end
    self.strengthLv.text = string.format("+%s",strengthLvs)
    if data == nil then
        return
    end
    local len = #data
    for i=1, len do
        local arg = ""
        arg = string.format("[F4DDBDFF]%s  %d[-]",PropName[data[i].type].name,data[i].all)
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.strength.text = str
end

function My:CreateSB()
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()
end

function My:UpdateBest()
    self:CreateSB()
    local sb = self.sb
    local data = self.data.attrList
    local propGroups = self.data.bestGroups
    local step = self.data.step

    local len = #data
    for i=1, len do
        local add = 0
        local addStr = ""
        local propKey = data[i].id
        local propVal = data[i].val
        local propG = propGroups[i]
        add = SpiritGMgr:GetBestProp(propG,propKey,propVal)
        local cfg = PropName[propKey]
        if cfg == nil then
            return
        end
        local str = cfg.show == 1 and string.format("%0.2f%%", propVal*0.01) or propVal
        if add > 0 then
            addStr = cfg.show == 1 and string.format("%0.2f%%", add*0.01) or add
            addStr = string.format("[00FF00FF](%s阶+%s)",step,addStr)
        end
        local index = math.modf(propG/100)
        local color = ""
        if index <= 2 then
            color = "[008ffc]"
        else
            color = "[b03df2]"
        end
        local arg = string.format("%s%s  %s[-]      %s", color , cfg.name, str,addStr)
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.best.text = str
end

function My:SetActive(state)
    self.go:SetActive(state)
end

function My:Open(data)
    self:UpdateData(data)
    self:SetActive(true)
end

function My:Close()
    self:SetActive(false)
end

function My:Dispose()
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

return My