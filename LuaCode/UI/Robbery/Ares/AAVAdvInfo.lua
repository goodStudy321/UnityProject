AAVAdvInfo = Super:New{Name = "AAVAdvInfo"}

local M = AAVAdvInfo

function M:Ctor()
    self.proList = {}
end


function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local F = TransTool.Find
    local FC = TransTool.FindChild

    self.curLevel = G(UILabel, trans, "CurLevel")
    self.nextLevel = G(UILabel, trans, "NextLevel")
    self.itemRoot = F(trans, "ItemRoot")
    self.attr = G(UILabel, trans, "Attr")
    self.cost = G(UILabel, trans, "Cost")
    self.materialRoot = F(self.cost.transform, "ItemRoot")
    self.btn = F(trans, "Btn")
    self.btnName = G(UILabel, self.btn, "Name")
    self.redPoint = FC(self.btn, "RedPoint")

    self.materialCell = ObjPool.Get(UIItemCell)
    self.materialCell:InitLoadPool(self.materialRoot)
    self.materialCell:UpData("21")

    local progress = F(trans, "Progress")
    for i=1,10 do
        local obj = FC(progress, "Cur"..i)
        table.insert(self.proList, obj)
    end

    self.fxSuc = FC(trans, "FX/FX_qianghua_Succeed")
    self.fxQH = FC(trans, "FX/UI_Qh_01")
    self.fxBaoji = FC(trans, "FX/FX_baoji")
    self.fxAdv = FC(trans, "FX/UI_JinJieChengGong")

    UITool.SetLsnrSelf(self.btn, self.OnClick, self)
end

function M:OnClick()
    if self.data then
        if RoleAssets.AresCoin >= self.data.consume then
            AresMgr:ReqWarGodRefine(self.data.user, self.data.id)
        else
            UITip.Log("开光材料不足")
        end
    end
end

function M:UpdateData(data)
    self.data = data
    self:Refresh()
end

function M:UpdateAdvFx(isBaoji)
    self.fxQH:SetActive(false)
    self.fxSuc:SetActive(false)
    self.fxBaoji:SetActive(false)
    self.fxQH:SetActive(true)
    self.fxSuc:SetActive(true)
    self.fxBaoji:SetActive(isBaoji)
end

function M:UpdateSuitAdvFx()
    self.fxAdv:SetActive(false)
    self.fxAdv:SetActive(true)
end

function M:Reset()
    self.fxQH:SetActive(false)
    self.fxSuc:SetActive(false)
    self.fxBaoji:SetActive(false)
    self.fxAdv:SetActive(false)
end


function M:Refresh()
    self:UpdateCurLevel()
    self:UpdateNextLevel()
    self:UpdateCell()
    self:UpdateCost()
    self:UpdateBtnName()
    self:UpdateProgress()
    self:UpdateAttr()
    self:UpdateRedPoint()
end

function M:UpdateRedPoint()
    self.redPoint:SetActive(self.data.redPointState)
end

function M:UpdateCurLevel()
    self.curLevel.text = string.format("%s阶", self.data.level)
end

function M:UpdateNextLevel()
    local maxLevel = AresMgr:GetEquipMaxLevel(self.data.id)
    local nLv = self.data.level+1
    local level = nLv > maxLevel and maxLevel or nLv
    self.nextLevel.text = string.format("%s阶", level)
end

function M:UpdateCell()
    if not self.equipCell then
        self.equipCell = ObjPool.Get(AresCell)
        self.equipCell:InitLoadPool(self.itemRoot)
        self.equipCell.eClickCell:Add(self.OnEquipCell, self)
    end
    self.equipCell:UpdateData(self.data)
end

function M:OnEquipCell(data)
    AresMgr.eClickEquip(data)
end

function M:UpdateCost()
    local consume = self.data.level < self.data.maxLv and self.data.consume or 0
    local color = RoleAssets.AresCoin >= consume and "[00FF00FF]" or "[F21919FF]"
    self.cost.text = string.format("%s%s/%s", color, RoleAssets.AresCoin, consume)
end

function M:UpdateBtnName()
    self.btnName.text =  self.data.progress < 10  and "开光" or "升阶"
end

function M:UpdateProgress()
    local list = self.proList
    for i=1,#list do
        list[i]:SetActive(i<=self.data.progress)
    end
end

function M:UpdateAttr()
    local data = AresMgr:GetEquipNextAttr(self.data)
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()
    local sb = self.sb
    local len = #data
    for i=1, len do
        local arg = ""
        if  data[i].add > 0 then
            arg = string.format("[F4DDBDFF]%s:%d        [00FF00FF]+%d", PropName[data[i].k].name, data[i].v, data[i].add)
        else
            arg = string.format("[F4DDBDFF]%s:%d", PropName[data[i].k].name, data[i].v)
        end
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.attr.text = str
end

function M:Dispose()
    self.data = nil
    TableTool.ClearUserData(self)
    if self.equipCell then
        self.equipCell:DestroyGo()
        ObjPool.Add(self.equipCell)
        self.equipCell = nil
    end
    TableTool.ClearDic(self.proList)
    if self.sb then
        ObjPool.Add(self.sb)
        self.sb = nil
    end
    if self.materialCell then
        self.materialCell:DestroyGo()
        ObjPool.Add(self.materialCell)
        self.materialCell = nil
    end
end

return M