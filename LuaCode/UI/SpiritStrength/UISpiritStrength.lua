UISpiritStrength = UIBase:New{Name = "UISpiritStrength"}

require("UI/SpiritStrength/SpiritAdvEquipCell")
require("UI/SpiritStrength/SpiritStrengthInfo")
require("UI/SpiritStrength/SpEquipCell")

local My = UISpiritStrength
local SMIT = UIListSpModItem

function My:InitCustom(go)
    local root = self.root
    local name = self.Name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local USBC = UITool.SetLsnrSelf
    local TFC = TransTool.FindChild

    self.gridItem = CG(UIGrid,root,"mods/Grid",name)
    self.item = TF(root,"mods/Grid/item",name)
    self.item.gameObject:SetActive(false)
    self.items = {}

    self.equipCell = ObjPool.Get(SpiritAdvEquipCell)
    self.equipCell:Init(TFC(root,"equipMdes"))

    self.strengthInfo = ObjPool.Get(SpiritStrengthInfo)
    self.strengthInfo:Init(TFC(root,"strength"))

    self.btnClose = TFC(root, "CloseBtn",name)
    
    self.isCurSp = false

    USBC(self.btnClose, self.CloseBtn, self)
    self:SetEvent("Add")
    
    self:InitSpiriteItem()
    local curSpId = SpiritGMgr:GetCurSPId()
    if curSpId == nil or curSpId == 0 then
        self:OnClickItem(self.items["10101"].root)
    else
        self:OnClickItem(self.items[tostring(curSpId)].root)
    end
    self:RefreshRed()
end

function My:SetEvent(fn)
    local mgr = SpiritGMgr
    SpEquipCell.eUpdateAdv[fn](SpEquipCell.eUpdateAdv, self.UpdateAdv, self)
    mgr.eUpdateStrengthInfo[fn](mgr.eUpdateStrengthInfo, self.UpdateStrengthInfo, self)
    mgr.eUpdateEquipRedInfo[fn](mgr.eUpdateEquipRedInfo, self.RefreshRed, self)
end

function My.OpenUIByData()
    local spId,equipId = SpiritGMgr:GetSpIdAndEquipId()
    UISpiritStrength.curSecSpId = spId
    UISpiritStrength.curEquipId = equipId
    UIMgr.Open(UISpiritStrength.Name)
end

function My:RefreshRed()
    self:RefreshSpRed()
    self:RefreshEquipRed()
end

function My:RefreshEquipRed()
    local equipList = self.equipCell.cellList
    local redInfo = SpiritGMgr.EquipRedInfo
    local len = #equipList
    for i=1,len do
        for j,l in pairs(redInfo) do
            if equipList[i].data.id == j then
                equipList[i]:SetRed(l)
            end
        end
    end
end

function My:RefreshSpRed()
    local redInfo = SpiritGMgr.StrSpRedInfo --j：战灵id  l:红点状态
    local spItemTab = self.items
    for k,v in pairs(spItemTab) do
        for j,l in pairs(redInfo) do
            if k == j then
                v:SetRed(l)
            end
        end
    end
end

function My:InitSpiriteItem()
    local item = self.item
    local Inst = GameObject.Instantiate
    local robSevInfo = RobberyMgr.SpiriteInfoTab
    local tabTemp = {}
    for k,v in pairs(SpiriteCfg) do
        table.insert(tabTemp,v)
    end
    table.sort(tabTemp,function(a,b) return a.spiriteId < b.spiriteId end)
    local len = #tabTemp
    for i = 1,len do
        local go = Inst(item)
        local date = tabTemp[i]
        self:AddItem(date,go,robSevInfo)
    end
    self.gridItem:Reposition()
end

function My:AddItem(info,go,robSevInfo)
    if go == nil then return end
    local trans = go.transform
    local it = ObjPool.Get(SMIT)
    it:Init(go)
    it.root.name = info.spiriteId
    go.gameObject:SetActive(true)
    local modId = tostring(info.spiriteId)
    self.items[modId] = it
    TransTool.AddChild(self.gridItem.transform,trans)
    UITool.SetLsnrSelf(trans, self.OnClickItem, self, nil, false)
    it:InitData(info)
    if robSevInfo.spiriteTab ~= nil and robSevInfo.spiriteTab[info.spiriteId] ~= nil then
        it:SetLock(false)
    end
end

function My:OnClickItem(go)
    local key = go.name
	local item = self.items[key]
	if not item then return end
    self.curSpId = tonumber(key)
    SpiritGMgr:SetCurSPId(self.curSpId)
    local isLockSp = RobberyMgr:IsLockCurSp()
    if isLockSp == true then
        UITip.Error("请解锁该战灵")
        return
    end
    local spId = tostring(self.curSpId)
    local spEquipData = SpiritGMgr.SpiritDic[spId]
    if spEquipData then
        local num = self:GetEquipNum(spEquipData)
        if num == 0 then
            -- self.strengthInfo.strengthInfo:SetActive(false)
            UITip.Error("请穿戴灵饰")
            return
        end
        self.equipCell:UpdateData(spEquipData)
        if self.curEquipId == nil or self.curEquipId == 0 then
            self.equipCell:SetSelect(spEquipData.id)    
        else
            self.equipCell:SetSelect(self.curEquipId) 
        end
        -- self.equipCell:SetSelect(spEquipData.id)
        self.strengthInfo.itemRoot.gameObject:SetActive(num > 0)
        self:RefreshEquipRed()
    end
    if self.SelectItem then
        self.SelectItem:IsSelect(false)
    end
    self.SelectItem = item
    self.SelectItem:IsSelect(true)
end

--获取已经装备的数量
function My:GetEquipNum(spEquipData)
    local index = 0
    local conds = spEquipData.condList
    for i=1,#conds do
        if conds[i].isUse then
            index = index + 1
        end
    end
    return index
end

function My:UpdateAdv(data)
    self.strengthInfo:UpdateData(data)
end

function My:UpdateStrengthInfo()
    self.strengthInfo:Refresh()
    self.equipCell:UpdateCell()
end

function My:UpdateEquipCell()

end

function My:Clear()
    if self.items then
        for k,v in pairs(self.items) do
            v:Dispose()
            ObjPool.Add(v)
            self.items[k] = nil
        end
    end
end

-- function My:CloseCustom()

-- end

function My:CloseBtn()
    JumpMgr.eOpenJump()
    self:Close()
end

function My:DisposeCustom()
    ObjPool.Add(self.equipCell)
    ObjPool.Add(self.strengthInfo)
    self.equipCell = nil
    self.strengthInfo = nil
    self.curSecSpId = nil
    self.curEquipId = nil
    self.SelectItem = nil
    self:SetEvent("Remove")
    self:Clear()
    -- TableTool.ClearUserData(self)
end

return My