SpiritAdvInfo = Super:New{Name = "SpiritAdvInfo"}

local My = SpiritAdvInfo

function My:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find

    self.go = go

    self.itemRoot = F(trans, "ItemRoot")
    self.name = G(UILabel, trans, "Name")
    self.score = G(UILabel, trans, "Score")
    self.base = G(UILabel, trans, "Base")
    self.best = G(UILabel, trans, "Best")
end

function My:UpdateData(data,index)
    self.data = data
    self.index = index
    self:UpdateItem()
    self:UpdateName()
    self:UpdateScore()
    self:UpdateBase()
    self:UpdateBest()
end

function My:UpdateItem()
    if not self.cell then
        self.cell =  ObjPool.Get(SPCell)
        self.cell:InitLoadPool(self.itemRoot)
        self.cell:SetTip(false)
    end
    self.cell:UpdateData(self.data,self.index)
end

function My:UpdateName()
    local lv = self.data.level
    self.name.text = string.format("%s%s", UIMisc.LabColor(self.data.quality), self.data.name)
end

function My:UpdateScore()
    local index = self.index
    local str = ""
    if index == 1 then
        str = string.format("[F4DDBDFF]装备评分  [00FF00FF]%d", self.data.score)
    else
        str = string.format("[F4DDBDFF]装备评分  [00FF00FF]%d", self.data.nextScore)
    end
    self.score.text = str
end

function My:UpdateBase()
    self:CreateSB()
    local index = self.index
    local sb = self.sb
    local data =  SpiritGMgr:GetEquipBaseAttr(self.data,self.index)
    if data == 0 then
        self.base.text = "已满阶"
        return
    end
    local len = #data
    for i=1, len do
        local arg = ""
        local add = data[i].add
        if add > 0 and index == 2 then
            arg = string.format("[F4DDBDFF]%s  +%s[-]   [00FF00FF](+%s)", PropName[data[i].k].name, data[i].v,add)
        else
            arg = string.format("[F4DDBDFF]%s  +%s", PropName[data[i].k].name, data[i].v)
        end
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.base.text = str
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
    local index = self.index
    local len = #data
    for i=1, len do
        local add = 0
        local addStr = ""
        local propKey = data[i].id
        local propVal = data[i].val
        local propG = propGroups[i]
        add = SpiritGMgr:GetNexttProp(propG,propKey,propVal)
        local cfg = PropName[propKey]
        local str = cfg.show == 1 and string.format("%0.1f%%", propVal*0.01) or propVal
        if add > 0 then
            addStr = cfg.show == 1 and string.format("%0.1f%%", add*0.01) or add
            addStr = string.format("[00FF00FF](+%s)",addStr)
        end
        local flag = math.modf(propG/100)
        local color = ""
        if flag <= 2 then
            color = "[008ffc]"
        else
            color = "[b03df2]"
        end
        if index == 1 then
            addStr = ""
        end
        local arg = string.format("%s%s  %s[-]   %s", color , cfg.name, str,addStr)
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

--index----> 1 当前信息
--index----> 2 下阶信息
function My:Open(data,index)
    self:UpdateData(data,index)
    self:SetActive(true)
end

function My:Close()
    self:SetActive(false)
end

function My:Dispose()
    self.data = nil
    self.index = nil
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