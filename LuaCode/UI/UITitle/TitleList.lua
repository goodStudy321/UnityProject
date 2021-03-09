TitleList = Super:New{Name = "TitleList"}

require("UI.UITitle.TitleCell")

local M = TitleList

function M:Init(root)
    local G = ComTool.Get
    local FG = TransTool.FindChild

    self.cellList = {}

    self.eClickTitle = Event()

    self.own = G(UILabel, root, "Own")
    self.sView = G(UIScrollView, root, "ScrollView")
    self.grid = G(UIGrid, root, "ScrollView/Grid")
    self.cell = FG(self.grid.transform, "cell")
    self.cell:SetActive(false)

    self.totalAttr = FG(root, "TotalAttr")
    self.attr = G(UILabel, self.totalAttr.transform, "ScrollView/Attr")

    UITool.SetLsnrSelf(self.totalAttr, self.CloseAttr, self, nil, false)
    UITool.SetLsnrClick(root, "BtnAttr", "", self.OpenAttr, self)
end

function M:CreateCell(data)
    local go = Instantiate(self.cell)
    go.name = data.cfg.id
    TransTool.AddChild(self.grid.transform, go.transform)
    local titleCell = ObjPool.Get(TitleCell)
    titleCell:Init(go)
    titleCell:SetActive(true)
    titleCell:SetHandler(self.CellClick, self)
    titleCell:UpdateCell(data)
    table.insert(self.cellList, titleCell)
end

function M:UpdateCellData(data)
    local len = #data
    local list = self.cellList
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
    self.grid:Reposition()
    self.sView:ResetPosition()
end

function M:SetShowByIndex(index)
    if self.cellList[index] and self.cellList[index]:ActiveSelf() then
        self:CellClick(self.cellList[index].data.cfg.id)
    else
        self.eClickTitle(0)
    end
end

function M:SetShowById(id)
    local data = nil
    local list = self.cellList
    local len = #list
    for i=1,len do
        if list[i].data.cfg.id == id then
            data = list[i].data
            break
        end
    end
    if data and data.have ~= -1 then
        self:CellClick(id)
    else
        self:SetShowByIndex(1)
    end
end

function M:CellClick(id)
    self:SetHighlight(id)
    self.eClickTitle(id)
end

function M:SetHighlight(id)
    local list = self.cellList
    local len = #list
    for i=1,len do
        list[i]:SetHighlight(list[i].data.cfg.id == id)
    end
end

function M:UpdateOwnAttr(data)
    self:UpdateOwn(data)
    self:UpdateAttr(data)
end

function M:UpdateOwn(data)
    self.own.text = string.format("[b1a495]已激活称号：[-][f39800]%d[-]", #data)
end

function M:UpdateAttr(data)
    local len = #data
    local attack = 0
    local def = 0
    local life = 0
    local penetrate = 0

    local dic = {}
    for i=1,len do
        local cfg = data[i].cfg
        attack = cfg.atk + attack
        def = cfg.def + def
        life = cfg.hp + life
        penetrate = cfg.arm + penetrate
        if cfg.otherAttr then
            if not dic[cfg.otherAttr.k] then
                dic[cfg.otherAttr.k] = cfg.otherAttr.v
            else
                dic[cfg.otherAttr.k] = dic[cfg.otherAttr.k] + cfg.otherAttr.v
            end         
        end
    end
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    local sb = self.sb
    sb:Dispose()
    for i,v in pairs(dic) do
        local temp = PropName[i]
        local name = temp.name
        local value = v
        if temp.show == 1 then
            value = string.format("%s%%", value * 0.01) 
        end
        sb:Apd(string.format("[b1a495]%s[-]     [ffe9bd]%s[-]", name, value))
        sb:Line()
    end
    local str = string.format("[b1a495]攻  击[-]         [ffe9bd]%d[-]\n[b1a495]生  命[-]         [ffe9bd]%d[-]\n[b1a495]破  甲[-]         [ffe9bd]%d[-]\n[b1a495]防  御[-]         [ffe9bd]%d[-]" , attack, life, penetrate, def)
    if sb.Length > 0 then
        str = string.format("%s\n%s", str, sb:ToStr())
    end  
    self.attr.text = str
end

function M:OpenAttr()
    self.totalAttr:SetActive(true)
end

function M:CloseAttr()
    self.totalAttr:SetActive(false)
end

function M:Dispose()
    TableTool.ClearUserData(self)
    for k,v in pairs(self.cellList) do
        ObjPool.Add(v)
    end
    self.cellList = nil
    self.eClickTitle:Clear()
    self.eClickTitle = nil
    if self.sb then
        ObjPool.Add(self.sb)
        self.sb = nil
    end
end

return M