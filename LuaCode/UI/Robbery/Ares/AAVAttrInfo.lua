AAVAttrInfo = Super:New{Name = "AAVAttrInfo"}

local M = AAVAttrInfo

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get

    self.attr = G(UILabel, trans, "Attr")
    self.condition = G(UILabel, trans, "Condition")
    self.tips = G(UILabel, trans, "Tips")

    self.tips.text = InvestDesCfg["1700"].des
end

function M:UpdateData(data)
    self.data = data
    self:Refresh()
end

function M:Refresh()
    self:UpdateAttr()
    self:UpdateCond()
end

function M:UpdateAttr()
    local nAttr = AresMgr:GetAresNextLvAttr(self.data.id, self.data.level)
    if nAttr then
        local data = PropName[nAttr.k]
        local val = nAttr.v
        if data.show == 1 then
            val = string.format("%s%%", val * 0.01) 
        end
        self.attr.text = string.format("[F4DDBDFF]%s：+[00FF00FF]%s", data.name, val)
    else
        self.attr.text = "[00FF00FF]已满阶"
    end
end

function M:UpdateCond()
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()
    local sb = self.sb
    local equipList = self.data.equipList
    local maxLv = #self.data.levelList
    local nextLv = self.data.level+1
    nextLv = nextLv <= maxLv and nextLv or maxLv
    local len = #equipList
    for i=1, len do
        local equip = equipList[i]
        local str = equip.level < nextLv and "[F21919FF](未达成)[-]" or "[00FF00FF](已达成)[-]"
        sb:Apd(string.format("[F4DDBDFF]%s开光%s阶%s", equip.name, nextLv, str))
        if i < len then
            sb:Line()
        end
    end
    self.condition.text = sb:ToStr()
end

function M:Dispose()
    self.data = nil
    TableTool.ClearUserData(self)
end

return M