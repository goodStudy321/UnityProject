

UIFightTreasure = UIBase:New{Name = "UIFightTreasure"}

local M = UIFightTreasure

local ftMgr = FightTreasureMgr
local rewards = GlobalTemp["128"]

function M:InitCustom()
	local name = "打宝提示"
	local trans = self.root
	local C = ComTool.Get
    local T = TransTool.FindChild
    
    self.CloseBtn = T(trans, "Close")
    self.Btn = C(UIButton, trans, "Button", name, false)
    self.Lab = C(UILabel, trans, "Button/Label", name, false)
    self.Action = T(trans, "Button/Action")

    self.Grid = C(UIGrid, trans, "Grid", name, false)

    self.Items = {}

    self.IsOpen = false
    local E = UITool.SetLsnrSelf
    E(self.CloseBtn, self.Close, self)
    E(self.Btn, self.ClickBtn, self)
end

function M:UpdateData()
    self:UpdateOpenStatus()
    self:UpdateBtn()
    self:UpdateReward()
end

function M:ChangeData()
    self:UpdateOpenStatus()
    self:UpdateBtn()
end

function M:UpdateOpenStatus()
    self.IsOpen = OpenMgr:IsOpenForType(ActivityMgr.BOSS)
end

function M:UpdateBtn()
    local status = ftMgr.ReceiveStatus
    local isOpen = self.IsOpen
    local lab = self.Lab
    if LuaTool.IsNull(lab) == false then
        if isOpen == false then
            lab.text = "继续主线升级"
        else
            lab.text = "领取奖励"
        end
    end
    local btn = self.Btn
    if LuaTool.IsNull(btn) == false then
        btn.Enabled = status == true
    end
    local action = self.Action
    if action then
        action:SetActive(isOpen == true and status == true)
    end
end

function M:UpdateReward()
    if rewards == nil then return end
    local grid = self.Grid
    if LuaTool.IsNull(grid) then return end
    local list = rewards.Value1
    for i=1,#list do
        local info = list[i]
        if info then
            local item = ItemData[tostring(info.id)]
            local num = info.value
            if item then
                local cell = ObjPool.Get(UIItemCell)
                cell:InitLoadPool(grid.transform)
                table.insert(self.Items, cell)
                cell:UpData(item, num)
            end
        end
    end
    grid:Reposition()
end

function M:ClickBtn()
    local isOpen = self.IsOpen
    if isOpen == false then
        local main = MissionMgr.Main
        Hangup:SetAutoHangup(true);
        if main and main.Temp and main.Temp.lv <= User.MapData.Level then
            MissionMgr:AutoExecuteActionOfType(MissionType.Main)
        else
            MissionMgr:AutoExecuteAction(MExecute.ClickItem)
        end
        self:Close()
    else
        ftMgr:ReqReceiveRewardTos()
    end
end
function M:SetEvent(fn)
    UserMgr.eLvEvent[fn](UserMgr.eLvEvent, self.ChangeData, self)
    OpenMgr.eOpen[fn](OpenMgr.eOpen, self.ChangeData, self)
    ftMgr.eChangeStatus[fn](ftMgr.eChangeStatus, self.UpdateBtn, self)
end

function M:OpenCustom()
	self:SetEvent("Add")
    self:UpdateData()
end

function M:CloseCustom()
	self:SetEvent("Remove")
    self:Clear()
end

--清理缓存
function M:Clear()
    local items = self.Items
    local len = #items
    while len > 0 do
        local cell = items[len]
        table.remove(items, len)
        if cell then
			cell:Destroy()
			ObjPool.Add(cell)
			cell = nil
        end
        len = #items
    end
end

--重写释放资源
function M:DisposeCustom()
end

return M