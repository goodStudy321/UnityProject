AMVAttrInfo = Super:New{Name = "AMVAttrInfo"}

local M = AMVAttrInfo

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick
    local FC = TransTool.FindChild
    
    self.baseAttr = G(UILabel, trans, "BaseAttr")
    self.aresAttr = G(UILabel, trans, "ScrollView/AresAttr")
    self.btnName = G(UILabel, trans, "BtnActive/Name")
    self.btnFx = FC(trans, "BtnActive/fx_gm")
    self.activeRedPoint = FC(trans, "BtnActive/RedPoint")
    self.decomposeRedPoint = FC(trans, "BtnDecompose/RedPoint")


    SC(trans, "BtnActive", self.Name, self.OnActive, self)
    SC(trans, "BtnDecompose", self.Name, self.OnDecompose, self)
end

function M:UpdateData(data)
    self.data = data
    self:Refresh()
end

function M:Refresh()
    self:UpdateBtnName()
    self:UpdateBaseAttr()
    self:UpdateAresAttr()
    self:UpdateRedPoint()
    self:UpdateDecomposeRedPoint()
end

function M:UpdateBtnName()
    self.btnName.text = self.data.state and "套装开光" or "激活套装"
end

function M:UpdateRedPoint()
    self.btnFx:SetActive(AresMgr:CanActiveSuit(self.data.id))
    self.activeRedPoint:SetActive(self.data.equipRedPointState)
end

function M:UpdateDecomposeRedPoint()
    self.decomposeRedPoint:SetActive(AresMgr:GetDecomposeRedPointStatus())
end

function M:UpdateBaseAttr()
    local data = self.data.curAttrList
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()
    local sb = self.sb
    local len = #data
    local color1, color2 = "[99886BFF]" , "[00FF00FF]"
    if not self.data.state  then
        color1, color2 = "[9C9C9CFF]", "[9C9C9CFF]"
    end
    for i=1, len do
        local name = PropName[data[i].k].name
        local arg = string.format("%s%s:        %s%s", color1, name, color2 ,data[i].v)
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.baseAttr.text = str
end

function M:UpdateAresAttr()
    local list = self.data.levelList
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()
    local sb = self.sb
    local len = #list
    for i=1,len do
        local temp = list[i]
        local prop = PropName[temp.attr.k]
        local val = temp.attr.v
        if prop.show == 1 then
            val = string.format("%s%%",val * 0.01) 
        end
        local str = "[00FF00FF](已激活)[-]"
        local color1, color2, color3 = "[F4DDBDFF]" , "[99886BFF]", "[00FF00FF]"
        if not self.data.state or  temp.level > self.data.level then
            str = "[F21919FF](未获得)[-]"
            color1, color2, color3= "[9C9C9CFF]", "[9C9C9CFF]", "[9C9C9CFF]"
        end
        local arg = string.format("%s开光%s阶(%s/%s)\n%s%s %s+%s%s", color1, temp.level, temp.curCount, temp.maxCount, color2 ,prop.name, color3, val, str)
        sb:Apd(arg)
        if i < len then
            sb:Line()
            sb:Line()
        end
    end
    self.aresAttr.text = sb:ToStr()
end

function M:OnActive()
    if self.data.state then
        AresMgr.eOpenView(AresMgr.AdvView, self.data.id)
    else
        local list = self.data.equipList
        local state = true
        for i=1,#list do
            if not list[i].state then
                state = false
                break
            end
        end
        if state then
            AresMgr:ReqWarGodActive(self.data.id)
        else
            UITip.Log("需激活全部部件方可激活套装")
        end
    end
end

function M:OnDecompose()
    AresMgr.eOpenView(AresMgr.DecompView)
end

function M:Dispose()
    self.data = nil
    TableTool.ClearUserData(self)
    if self.sb then
        ObjPool.Add(self.sb)
        self.sb = nil
    end
end

return M