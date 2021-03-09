AresEquipTip = Super:New{Name = "AresEquipTip"}

local M = AresEquipTip

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf

    self.go = go

    local parent = F(trans, "SelectTip")
    self.name = G(UILabel, parent, "Name")
    self.score = G(UILabel, parent, "Score")
    self.lab1 = G(UILabel, parent, "Lab1")
    self.lab2 = G(UILabel, parent, "Lab2")
    self.itemRoot = F(parent, "ItemRoot")
    self.base = G(UILabel, parent, "Base")
    self.best = G(UILabel, parent, "Best")
    self.bg = G(UISprite, parent, "Bg")

    self.btnActive = FC(trans, "BtnActive")
    self.btnPutOn = FC(trans, "BtnPutOn")

    S(self.btnActive, self.OnActive, self)
    S(self.btnPutOn, self.OnPutOn, self)

    UITool.SetLsnrClick(trans, "BtnClose", self.Name, self.OnClose, self)
end

function M:UpdateData(data)
    self.data = data
    self:SetActive(true)
    self:UpdateName()
    self:UpdateSocre()
    self:UpdateCell()
    self:UpdateBase()
    self:UpdateBest()
    self:UpdateBtn()
    self:UpdateLab1()
    self:UpdateLab2()
end

function M:UpdateBg()
    local name = self.data.quality > 0 and string.format("cell_a0%d", self.data.quality)  or "cell_a01"
    self.bg.spriteName = name 
end

function M:UpdateName()
    self.name.text = string.format("%s%s", UIMisc.LabColor(self.data.quality), self.data.name)
end

function M:UpdateSocre()
    self.score.text = self.data.state and string.format("[00FF00FF]开光%s阶", self.data.level) or "[F21919FF]未激活"
end

function M:UpdateCell()
    if not self.cell then
        self.cell = ObjPool.Get(AresCell)
        self.cell:InitLoadPool(self.itemRoot)
    end
    self.cell:UpdateData(self.data)
end

function M:UpdateBase()
    if self.data.state then
        local data = self.data.attrList
        if not self.sb then
            self.sb = ObjPool.Get(StrBuffer)
        end
        self.sb:Dispose()
        local sb = self.sb
        local len = #data
        local color1, color2 = "[F4DDBDFF]" , "[00FF00FF]"
        if not self.data.state then
            color1, color2 = "[9C9C9CFF]", "[9C9C9CFF]"
        end
        for i=1, len do
            local name = PropName[data[i].k].name
            local arg = string.format("%s%s:%s%d", color1, name, color2, data[i].v)
            sb:Apd(arg)
            if i<len then
                sb:Line()
            end
        end
        local str = sb:ToStr()
        self.base.text = str
    else
        local count = AresMgr:GetMaterialCount(self.data.materialId)
        local color = count >= self.data.needCount and "[00FF00FF]" or "[F21919FF]"
        self.base.text = string.format( "[F4DDBDFF]%s    %s%s/%s", self.data.materialName, color, count, self.data.needCount )
    end
end

function M:UpdateBest()
    self.best.text = self.data.getPath
end

function M:UpdateBtn()
    self.btnActive:SetActive(not self.data.state)
    self.btnPutOn:SetActive(self.data.state)
end

function M:UpdateLab1()
    self.lab1.text = self.data.state and "开光加成属性" or "激活条件"
end

function M:UpdateLab2()
    self.lab2.text = self.data.state and "开光材料获取途径" or "碎片获取途径"
end

function M:OnClose()
    self:SetActive(false)
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:OnActive()
    AresMgr:ReqWarGodPieceActive(self.data.user, self.data.id)
    self:OnClose()
end

function M:OnPutOn()
    local unit = AresMgr:GetAresById(self.data.user)
    if unit.state then
        AresMgr.eOpenView(AresMgr.AdvView, self.data.user, self.data.id)    
    else
        UITip.Log("需激活套装方可进行部件开光")
    end
    self:OnClose()
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