SPSuitCell = Super:New{Name = "SPSuitCell"}

local My = SPSuitCell

function My:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf
    self.go = go

    self.name = G(UILabel,trans,"Lab")
    self.base = G(UILabel,trans,"Base")
end

function My:SetActive(state)
    self.go:SetActive(state)
end

function My:UpdateData(data,equipNum,suitNum)
    self.data = data
    self.equipNum = equipNum
    self.suitNum = suitNum
    self:UpdateName()
    self:UpdateBase()
end

function My:UpdateName()
    local equipNum = self.equipNum
    local color = "[CC2500FF]"
    if equipNum >= 4 then
        color = "[00FF00FF]"
    end
    self.name.text = string.format("%s:  4                %s%s/4", self.data.desName,color,equipNum)
end

function My:UpdateBase()
    self:CreateSB()
    local sb = self.sb
    local data =  PropTool.SwitchAttr(self.data)
    local len = #data
    local color = "[F4DDBDFF]"
    if self.equipNum >= 4 then
        color = "[00FF00FF]"
    end
    for i=1, len do
        local arg = ""
        local key = data[i].k
        local val = data[i].v
        local cfg = PropName[key]
        local value = cfg.show == 1 and string.format("%0.1f%%", val*0.01) or val
        local space = cfg.show == 1 and "           " or "                 "
        arg = string.format("[F4DDBDFF]%s[-]%s%s+%s",cfg.name,space,color,value)
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

function My:Dispose()
    self.data = nil
    if self.sb then
        ObjPool.Add(self.sb)
    end
    self.sb = nil
    TableTool.ClearUserData(self)
end

return My