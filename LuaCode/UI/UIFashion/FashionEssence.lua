FashionEssence = Super:New{Name = "FashionEssence"}

require("UI/UIFashion/EssenceCell")

local M = FashionEssence

function M:Init(root)
    self.go = root.gameObject
    self.cellList = {}
    self.selectList = {}
 
    local G = ComTool.Get
    local FG = TransTool.FindChild
    local SC =  UITool.SetLsnrClick

    self.attrGrid = G(UIGrid, root, "TotalAttr/Grid")
    local trans = self.attrGrid.transform
    self.attr1 = G(UILabel, trans, "Attr_1")
    self.attr2 = G(UILabel, trans, "Attr_2")
    self.attr3 = G(UILabel, trans, "Attr_3")
    self.attr4 = G(UILabel, trans, "Attr_4")
    self.attr5 = G(UILabel, trans, "Attr_5")
    self.nAttr1 = G(UILabel, trans, "Attr_1/NAttr_1")
    self.nAttr2 = G(UILabel, trans, "Attr_2/NAttr_2")
    self.nAttr3 = G(UILabel, trans, "Attr_3/NAttr_3")
    self.nAttr4 = G(UILabel, trans, "Attr_4/NAttr_4")
    self.nAttr5 = G(UILabel, trans, "Attr_5/NAttr_5")

    self.progress = G(UISlider, root, "TotalAttr/Progress")
    self.labPg = G(UILabel, self.progress.transform, "Label")

    self.scorllView = G(UIScrollView, root, "CellList/ScrollView")
    self.grid = G(UIGrid, root, "CellList/ScrollView/Grid")
    self.cell = FG(self.grid.transform, "Cell")
    self.cell:SetActive(false)
    
    self.toggle = G(UIToggle, root, "BtnSelect")
    self.getCount = G(UILabel, root, "GetCount")

    local ED = EventDelegate
    local EC = ED.Callback
    local ES = ED.Set
    ES(self.toggle.onChange, EC(self.OnTogChg, self))

    SC(root, "BtnClose", "", self.OnClose, self)
    SC(root, "BtnDecompose", "", self.OnDecompose, self)
end

function M:OnTogChg()
    self:UpdateSelect(self.toggle.value)
end

function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:Open(_type, baseId)
    self:SetActive(true)
    self:UpdateData(_type, baseId)
end

function M:UpdateData(_type, baseId)
    self:Clear()
    self:UpdateCell(_type)
    self:UpdateAttr(_type)
    self:UpdateExp()
end

function M:UpdateAttr(_type)
    local data = FashionMgr:GetEssenceData(_type)
    if not data then return end

    local cfg = data.cfg
    if not cfg then return end
    local nCfg = data.nCfg
    local state = nCfg ~= nil
    local name = FashionMgr.FashionType[_type].name

    self.attr1.text = string.format("[f4ddbd]%s等级：[-]   [f39800]%d级[-]", name, data.level)
    self.attr2.text = string.format("[f4ddbd]%s攻击：[-]   [f39800]%d%%[-]", name, cfg.atk)
    self.attr3.text = string.format("[f4ddbd]%s生命：[-]   [f39800]%d%%[-]", name, cfg.hp)
    self.attr4.text = string.format("[f4ddbd]%s防御：[-]   [f39800]%d%%[-]", name, cfg.def)
    self.attr5.text = string.format("[f4ddbd]%s破甲：[-]   [f39800]%d%%[-]", name, cfg.arm)

    if state then
        self.nAttr1.text = string.format("%d级", data.level+1)
        self.nAttr2.text = string.format("%d%%", nCfg.atk-cfg.atk)
        self.nAttr3.text = string.format("%d%%", nCfg.hp-cfg.hp)
        self.nAttr4.text = string.format("%d%%", nCfg.def-cfg.def)
        self.nAttr5.text = string.format("%d%%", nCfg.arm-cfg.arm)
        self.progress.value = data.exp/cfg.needExp
        self.labPg.text = string.format("升级(%d/%d)", data.exp, cfg.needExp)
    else
        self.progress.value = 1
        self.labPg.text = "已满级"
    end

    self.attr2.gameObject:SetActive(cfg.atk > 0 or (state and nCfg.atk > 0))
    self.attr3.gameObject:SetActive(cfg.hp > 0 or (state and nCfg.hp > 0))
    self.attr4.gameObject:SetActive(cfg.def > 0 or (state and nCfg.def > 0))
    self.attr5.gameObject:SetActive(cfg.arm > 0 or (state and nCfg.arm > 0))
    self.nAttr1.gameObject:SetActive(state)
    self.nAttr2.gameObject:SetActive(state and (nCfg.atk - cfg.atk > 0))
    self.nAttr3.gameObject:SetActive(state and (nCfg.hp - cfg.hp > 0))
    self.nAttr4.gameObject:SetActive(state and (nCfg.def - cfg.def > 0))
    self.nAttr5.gameObject:SetActive(state and (nCfg.arm - cfg.arm > 0))
    self.attrGrid:Reposition()
end

function M:HideCell()
    local list = self.cellList
    local len = #list
    for i=1,len do
        list[i]:SetActive(false)
    end
end


function M:UpdateCell(_type)
    -- if not FashionMgr:CanDepcompose(baseId) then return end
    -- local data = PropMgr.GetGoodsByTypeId(baseId*100)
    -- if not data then return end
    local data = FashionMgr:GetAllDepcompose(_type)
    local list = self.cellList
    local len = #data
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max

    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            list[i]:UpdateCell(data[i])
        elseif i <= count then
            list[i]:SetActive(false)
        else
            self:CreateCell(data[i])
        end
    end
    self.scorllView:ResetPosition()
    self.grid:Reposition()
    self.selectList = {}
end

function M:CreateCell(data)
    local go = Instantiate(self.cell)
    TransTool.AddChild(self.grid.transform, go.transform)
    local cell = ObjPool.Get(EssenceCell)
    cell:CreateCell(go, 1)
    cell:SetHandler(self.Handler, self)
    cell:UpdateCell(data)
    table.insert(self.cellList, cell)
end

function M:Handler(data, isSelect)
    if isSelect then
        self:AddId(data.id)
    else
        self:RemoveId(data.id)
    end
    self:UpdateExpNum(data.type_id, isSelect)
end

function M:UpdateExpNum(typeId, isSelect)
    local baseId = math.modf(typeId/100)
    local data = FashionMgr:GetFashionData(baseId)
    if isSelect then
        self.exp = self.exp + data.worth
    else
        self.exp = self.exp - data.worth
    end
    self:UpdateExp()
end

function M:UpdateExp()
    self.getCount.text = string.format("[f4ddbd]获得经验：[-][66c34e]%d[-]",self.exp)
end

function M:UpdateSelect(bool)
    local list = self.cellList
    for i=1,#list do
        if list[i]:ActiveSelf() then
            list[i]:UpdateSelect(bool)
        end
    end
end

function M:AddId(goodId)
    local list = self.selectList
    for i=1,#list do
        if list[i] == goodId then
            return
        end
    end
    table.insert(list, goodId)
end

function M:RemoveId(goodId)
    local list = self.selectList
    for i=1,#list do
        if list[i] == goodId then
            table.remove(list, i)
            return
        end
    end
end

function M:OnClose()
    self:Clear()
    self:SetActive(false)
end

function M:OnDecompose()
    if #self.selectList == 0 then 
        UITip.Log("请选择时装")
        return 
    end
    FashionMgr:ReqFashionDecompose(self.selectList)
end

function M:Clear()
    self:HideCell()
    self.toggle.value = false
    self.exp = 0
end

function M:Dispose()
    TableTool.ClearUserData(self)
    TableTool.ClearDic(self.selectList)
    TableTool.ClearListToPool(self.cellList)
    self.exp = nil
end

return M