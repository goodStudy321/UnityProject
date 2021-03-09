AvAdvInfo = Super:New{Name = "AvAdvInfo"}

local M = AvAdvInfo

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC= TransTool.FindChild
    local F = TransTool.Find


    self.itemRoot = F(trans, "ItemRoot")
    self.curLv = G(UILabel, trans, "CurLevel")
    self.nextLv = G(UILabel, trans, "NextLevel")
    self.curPro = G(UISprite, trans, "Progress/Cur")
    self.nextPro = G(UISprite, trans, "Progress/Next")
    self.proNum = G(UILabel, trans, "Progress/Num")
    self.attr = G(UILabel, trans, "Attr")
    self.tick = G(UIToggle, trans, "Tick")
    self.cost = G(UILabel, trans, "Cost")

    UITool.SetLsnrSelf(self.tick, self.OnToggle, self)
end

function M:UpdateData(data)
    self.data = data
    self:Refresh()
end

function M:Refresh()
    self:UpdateCurLv()
    self:UpdateNextLv()
    self:UpdateCell()
    self:UpdatePro()
    self:UpdateAttr()
    self:UpdateCost()
end

function M:UpdateExpAndGold(exp, cost)
    local data = SoulBearstMgr:GetResultLvCfg(self.data.level, self.data.advExp, exp)
    local lv = nil
    local attrList = nil
    if data then
        lv = data.lv
        attrList = PropTool.SwitchAttr(data)
    end
    self:UpdatePro(exp)
    self:UpdateNextLv(lv)
    self:UpdateAttr(attrList)
    self:UpdateCost(cost)
end

function M:UpdateCurLv()
    self.curLv.text = string.format( "+%s", self.data.level)
end

function M:UpdateNextLv(lv)
    lv = lv or self.data.level+1
    self.nextLv.text = string.format( "+%s", lv)
end

function M:UpdateCell()
    if not self.cell then
        self.cell = ObjPool.Get(SBCell)
        self.cell:InitLoadPool(self.itemRoot)
    end
    self.cell:UpdateData(self.data)
end


function M:UpdatePro(exp)
    exp = exp or 0
    local nextExp = SoulBearstMgr:GetNextLvAdvExp(self.data.level)
    if nextExp then
        self.curPro.fillAmount = self.data.advExp/nextExp
        self.nextPro.fillAmount = (self.data.advExp+exp)/nextExp
        self.proNum.text = string.format("[F4DDBDFF]%s  [00FF00FF]+%s[F4DDBDFF]/%s", self.data.advExp,  exp, nextExp)
    else
        self.curPro.fillAmount = 1
        self.nextPro.fillAmount = 0
        self.proNum.text = "[F4DDBDFF]已满级"
    end
end


function M:UpdateAttr(list)
    local result = SoulBearstMgr:GetEquipTotalBaseAttr(self.data)   
    local len = #result
    if list then
        for i=1,len do
            for j=1,#list do
                if result[i].type == list[j].k then 
                    result[i].add = list[j].v - result[i].base
                    break
                end
            end
        end
    end

    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()
    local sb = self.sb
    for i=1, len do
        local arg = string.format("[F4DDBDFF]%s:%d        [00FF00FF]+%d", PropName[result[i].type].name, result[i].all, result[i].add)
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.attr.text = str
end

function M:UpdateCost(cost)
    cost = cost or 0
    local state = SoulBearstMgr:GetGoldState()
    local color = state and "[F39800FF]" or "[F21919FF]"
    self.cost.text = string.format("%s%s", color, cost)
end

function M:OnToggle()
    SoulBearstMgr:SetDouble(self.tick.value)
end


function M:Dispose()
    self.data = nil
    if self.cell then
        self.cell:DestroyGo()
        ObjPool.Add(self.cell)
    end
    if self.sb then
        ObjPool.Add(self.sb)
    end
    self.sb = nil
    self.cell = nil
    TableTool.ClearUserData(self)
end

return M