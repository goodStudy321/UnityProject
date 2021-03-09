MvAttrInfo = Super:New{Name = "MvAttrInfo"}

require("UI/UISoulBearst/SBSkillCell")
require("UI/UISoulBearst/SBSkillTip")

local M = MvAttrInfo

function M:Ctor()
    self.cellList = {}
end

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf
    local F = TransTool.Find

    self.go = go

    self.btnActive = FC(trans, "BtnActive")
    self.btnName = G(UILabel, self.btnActive.transform, "Name")
    self.btnFx = FC(self.btnActive.transform, "fx_gm")

    self.grid = G(UIGrid, trans, "SkillList/Grid")
    self.prefab = FC(self.grid.transform, "Skill")
    self.prefab:SetActive(false)

    self.attr = G(UILabel, trans, "Attr")

    self.skillTip = ObjPool.Get(SBSkillTip)
    self.skillTip:Init(FC(trans, "SkillTip"))

    S(self.btnActive, self.OnActive, self)

    self:SetLsnr("Add")
end

function M:SetLsnr(key)
    SBSkillCell.eClick[key](SBSkillCell.eClick, self.OnSkillCell, self)
end

function M:UpdateData(data)
    self.data = data
    self:Refresh()
end

function M:Refresh()
    self:UpdateSkill()
    self:UpdateAttr()
    self:UpdateBtnState()
end

function M:UpdateBtnState()
    local state = self.data.state
    if state == 0 then
        UITool.SetGray(self.btnActive)
        self.btnName.text = "激活魂兽"
        self.btnFx:SetActive(false)
    elseif state == 1 then
        UITool.SetNormal(self.btnActive)
        self.btnName.text = "激活魂兽"
        self.btnFx:SetActive(true)
    elseif state == 2 then
        UITool.SetNormal(self.btnActive)
        self.btnName.text = "取消激活"
        self.btnFx:SetActive(false)
    end
end

function M:UpdateAttr()
    local data = self.data.attrList
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()
    local sb = self.sb
    local len = #data
    local color1, color2 = "[F4DDBDFF]" , "[00FF00FF]"
    if self.data.state ~= 2 then
        color1, color2 = "[9C9C9CFF]", "[9C9C9CFF]"
    end
    for i=1, len do
        local add = data[i].add
        local name = PropName[data[i].type].name
        local base = data[i].base
        local arg = ""
        if add > 0 then
            arg = string.format("%s%s:%d        %s+%d", color1, name, base, color2,add)
        else
            arg = string.format("%s%s:%d", color1, name, base)
        end
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.attr.text = str
end

function M:UpdateSkill()
    local data = self.data.skillList
    local len = #data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
  
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateData(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
          local go = Instantiate(self.prefab)
          TransTool.AddChild(self.grid.transform, go.transform)
          local item = ObjPool.Get(SBSkillCell)
          item:Init(go)
          item:SetActive(true)
          item:UpdateData(data[i])
          table.insert(list, item)
        end
    end
    self.grid:Reposition()
end

function M:SetActive(state)
    self.go:SetActive(state)
end

function M:Close()
    self:SetActive(false)
end

function M:Open(data)
    self:UpdateData(data)
    self:SetActive(true)
end


function M:OnSkillCell(data)
    self.skillTip:Open(data)
end

function M:OnActive()
    if self.data then
        local state = self.data.state
        if state ~= 0 then
            SoulBearstMgr:ReqMythicalEquipStatus(self.data.id, 3-state)
        end
    end
end

function M:Dispose()
    self:SetLsnr("Remove")
    if self.sb then
        ObjPool.Add(self.sb)
    end
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
    self.sb = nil
    self.data = nil
end

return M