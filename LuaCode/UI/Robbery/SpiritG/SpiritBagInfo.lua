SpiritBagInfo = Super:New{Name = "SpiritBagInfo"}

local My = SpiritBagInfo
local len = 4

My.eClick = Event()

function My:Ctor()
    self.cellList = {}
end

function My:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick
    local EA = EventDelegate.Add
    local EC = EventDelegate.Callback
    local F = TransTool.Find
    local FC = TransTool.FindChild

    local getLab = G(UILabel, trans, "getLab", des)
    getLab.text = "[67cc67][u]前往获取[-][-]"

    self.getLabR = FC(trans, "getLab", des)
    self.getLabR:SetActive(false)
    self.getLabBox = G(BoxCollider, trans, "getLab", des)

    self.go = go

    self.sView = G(UIScrollView, trans, "ScrollView")
    self.grid = G(UIGrid, trans, "ScrollView/Grid")
    UITool.SetLsnrSelf(self.getLabBox, self.OnGetClick, self)

    -- SC(trans, "BtnDel", self.Name, self.OnEquipCompose, self)
    -- SC(trans, "BtnStren", self.Name, self.OnEquipStrength, self)
end

function My:OnGetClick()
    UIMgr.Open(UIGetWay.Name, self.OpenGetWayCb1 ,self)
end

function My:OpenGetWayCb1(name)
	local ui = UIMgr.Get(name)
	ui:SetPos(Vector3(120,30,0))
	ui:CreateCell("幽冥地界", self.OnClickGetWayItem, self)
end

function My:OnClickGetWayItem(name)
    -- local other,isOpen = CopyMgr:GetCurCopy("18")
    if name == "幽冥地界" then
        -- if isOpen then
            JumpMgr:InitJump(UIRobbery.Name,3)
            BossHelp.OpenBoss(4)
        -- else
            -- UITip.Error("系统未开启")
        -- end
	end
end

function My:UpdateData(data)
    local len = #data
    self.getLabR:SetActive(len <= 0)
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
            local item = ObjPool.Get(SPCell)
            item:InitLoadPool(self.grid.transform)
            item:SetTip(true, true, true)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self:ResetPosition()
end

function My:ResetPosition()
    self.grid:Reposition()
    self.sView:ResetPosition()
end

function My:Refresh()
    local data = nil
    if not self.part then
        data = SpiritGMgr:GetAllBagEquip()
    else
        data = SpiritGMgr:GetBagEquipPQ(self.part, self.curQuality)
    end
    self:UpdateData(data)
end

function My:TryOpen(part, quality)
    self.part = part
    self.curQuality = quality
    local data = SpiritGMgr:GetBagEquipPQ(part, quality)
    if #data > 0 then
        self:UpdateData(data)
        self:SetActive(true)
        return true
    end
    return false
end

function My:Open(quality, star) 
    self.part = nil
    self:Refresh()
    self:SetActive(true)
end

-- --点击灵饰强化
-- function My:OnEquipStrength()
--     JumpMgr:InitJump(UIRobbery.Name,3)
--     UIMgr.Open(UISpiritStrength.Name)
-- end

-- --点击灵饰分解
-- function My:OnEquipCompose()
--     UIMgr.Open(UISpiritCompose.Name)
-- end

function My:Close()
    self.part = nil
    self:SetActive(false)
end

function My:SetActive(state)
    self.go:SetActive(state)
end

function My:Dispose()
    self.curQuality = 0
    self.curStar = 0
    self.part = nil
    TableTool.ClearListToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return My