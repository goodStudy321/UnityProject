UICopyInfoXM = UICopyInfoBase:New{Name = "UICopyInfoXM"}

local M = UICopyInfoXM

M.items = {}

function M:InitSelf()
    local G = ComTool.Get
    local S =  UITool.SetLsnrSelf
    local FC = TransTool.FindChild

    local trans = self.left
    self.lblName = G(UILabel, trans, "Name")
    self.lblTarge = G(UILabel, trans, "Target")
    self.lblDes = G(UILabel, trans, "Des")
    self.grid = G(UIGrid,trans,"Grid")
end

function M:SetLsnrSelf(key)
    TreaFeverMgr.eUpdateFeverRewawrd[key](TreaFeverMgr.eUpdateFeverRewawrd, self.UpdateFeverRewawrd, self)
end

function M:InitData()  
    local temp = self.Temp
    self.lblName.text = temp.name
    self.lblDes.text = temp.des
    local data = nil
    if temp.type == CopyType.XM then
        data = temp.sor0[1]
    elseif temp.type == CopyType.Fever then
        data = TreaFeverMgr:GetCopyAward()
    end
    self:InitCellList(data)
    self:UpdateCur()
end


function M:InitCellList(list)
    if not list then return end
    local num = #list
    local trans = self.grid.transform
    for i=1,num do
        local item = ObjPool.Get(UIItemCell)
        item:InitLoadPool(trans)
        item:UpData(list[i].k,list[i].v)
        table.insert(self.items, item)
    end
end

function M:UpdateFeverRewawrd()
    local temp = self.Temp 
    if not temp then return end
    if temp.type ~= CopyType.Fever then return end
    local data = TreaFeverMgr:GetCopyAward()
    self:InitCellList(data)
end


function M:UpdateCur()
    local temp = self.Temp
    local info = CopyMgr.CopyInfo
    local mt = MonsterTemp[tostring(temp.eParam[1])]  
    local name = mt and mt.name or "怪物"
    if temp.eType ~= CopyEType.GUARD then
        self.lblTarge.text = string.format("击败[00FF00FF]%s[-] %d/%d", name, info.Cur or 0, info.totalWave)
    else
        self.lblTarge.text = string.format("守护[00FF00FF]%s[-]", name)
    end
end

function M:DisposeSelf()
    TableTool.ClearListToPool(self.items)
end

return M