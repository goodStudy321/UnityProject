UIDemonInfo = UIBase:New{Name = "UIDemonInfo"}

require("UI/UIDemon/DemonBuffView")
require("UI/UIDemon/DemonOccupyCell")
require("UI/UIDemon/DemonCurOccupyCell")
require("UI/UIDemon/DemonRewardView")

local M = UIDemonInfo

M.mCellList = {}
M.mSec = 0
M.mInterval = 1
M.mTipSec = 0

M.FTtarget = 0  --玩家攻击目标
M.Belonger = 0  --boss归属者

function M:InitCustom()
    local trans = self.root
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf

    self.mLeft = F(trans, "Left")
    self.mGrid = G(UIGrid, self.mLeft, "ScrollView/Grid")
    self.mPrefab = FC(self.mGrid.transform, "Cell")
    self.mRemainTime = G(UILabel, self.mLeft, "RemainTime")
    self.mCellBg = FC(self.mLeft, "CellBg")
    self.mPrefab:SetActive(false)

    self.mBtnRevenge = FC(trans, "BtnRevenge")
    self.mBtnQuit = FC(trans, "BtnQuit")
    self.mEndTime = G(UILabel, trans, "EndTime")
    self.mTips = G(UILabel, trans, "Tips")

    self.mBuffView = ObjPool.Get(DemonBuffView)
    self.mBuffView:Init(FC(trans, "BuffView"))

    self.mCurOccupy = ObjPool.Get(DemonCurOccupyCell)
    self.mCurOccupy:Init(FC(self.mLeft, "CurBelong"))

    self.mBtnReward = FC(trans, "BtnReward")
    self.mBtnRewardRP = FC(self.mBtnReward.transform, "RedPoint")

    DemonRewardView:Init(FC(trans, "RewardView"))

    S(self.mBtnRevenge, self.OnRevenge, self)
    S(self.mBtnQuit, self.OnQuit, self)
    S(self.mBtnReward, self.OnReward, self)

    self:UpdateRank()
    self:UpdateCurOccupy()
    self:UpdateCheer()
    self:CreateTimer()
    self:UpdateBtnRewardRP()
    self:ScreenChange(ScreenMgr.orient, true)
    self:SetLsnr("Add")
    self:SetEvent(EventMgr.Add)
end

function M:SetLsnr(key)
    DemonMgr.eUpdateCurOccupy[key](DemonMgr.eUpdateCurOccupy, self.UpdateCurOccupy, self)
    DemonMgr.eUpdateRank[key](DemonMgr.eUpdateRank, self.UpdateRank, self)
    DemonMgr.eUpdateCheer[key](DemonMgr.eUpdateCheer, self.UpdateCheer, self)
    DemonMgr.eUpdateDemonState[key](DemonMgr.eUpdateDemonState, self.CreateTimer, self)
    DemonMgr.eUpdateBossHpRewardStatus[key](DemonMgr.eUpdateBossHpRewardStatus, self.UpdateBossHpRewardStatus, self)
    UIMainMenu.eHide[key](UIMainMenu.eHide, self.SetMenuStatus, self)
    ScreenMgr.eChange[key](ScreenMgr.eChange, self.ScreenChange, self)
    AtkInfoMgr.eUpdateAtk[key](AtkInfoMgr.eUpdateAtk, self.UpdateAtk, self)
end

function M:SetEvent(func)
    func("ChgTmOrFml",  EventHandler(self.UpdateCellName, self))
    func("OnChangeFTtarget",  EventHandler(self.OnChangeFTtarget, self))
    func("ReLife",  EventHandler(self.ReLife, self))
    func("RefreshReviveData",  EventHandler(self.RefreshReviveData, self))
    func("BossBelonger",  EventHandler(self.BossBelonger, self))
    func("EnterSaveZone",  EventHandler(self.EnterSaveZone, self))
    -- func("ExitSaveZone",  EventHandler(self.ExitSaveZone, self))
end

function M:OpenCustom()
    DemonRewardView:Open()
end

function M:UpdateBtnRewardRP()
    local status = DemonMgr:HasBossHpReward()
    self.mBtnRewardRP:SetActive(status)
end


function M:UpdateBossHpRewardStatus(id)
    if DemonRewardView:IsActive() then
        if id then
            DemonRewardView:UpdateBossHpRewardStatus(id)
        else
            DemonRewardView:UpdateData()
        end
    end
    self:UpdateBtnRewardRP()
end

function M:EnterSaveZone()
    local data = DemonMgr:GetCurOccupyData()
    if data and data.RoleId == UIMisc.LongToNum(User.MapData.UID) then
        DemonMgr:ReqDemonBossEnterSafe()
    end
end

-- function M:ExitSaveZone()
--     local data = DemonMgr:GetCurOccupyData()
--     if data and data.RoleId == UIMisc.LongToNum(User.MapData.UID) then
        
--     end
-- end

function M:BossBelonger(id,level,name,teamId,familyId)
    M.Belonger = UIMisc.LongToNum(id)
    self:UpdateCellName()
end

function M:RefreshReviveData(killerName)
    self.mTips.gameObject:SetActive(true)
    self.mTips.text = string.format("您被[F21919FF]%s[-]击败了", killerName)
end


function M:ReLife()
    Hangup:SetSituFight(true)
end

function M:Update()
    self.mSec = self.mSec + Time.unscaledDeltaTime
    if self.mSec > self.mInterval then
        self.mSec = 0
        self:UpdateRankHp()
    end
end


function M:UpdateRankHp()
    local list = self.mCellList
    for i=1,#list do
        local cell = list[i]
        if cell:IsActive() then
            cell:UpdateHp()
        end
    end
end

function M:UpdateCellName()
    local data = DemonMgr:GetCurOccupyData()
    if data then
        self.mCurOccupy:UpdateName() 
    end
    local list = self.mCellList
    for i=1,#list do
        local cell = list[i]
        if cell:IsActive() then
            cell:UpdateName()
        end
    end
end

function M:OnChangeFTtarget(uid)
    M.FTtarget = UIMisc.LongToNum(uid)
    self:UpdateAtk()
end

function M:ScreenChange(orient, init)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.mLeft, nil, nil, true)
	elseif orient == ScreenOrient.Right then
		if not init then
			UITool.SetLiuHaiAnchor(self.mLeft, nil, nil, true, true)
		end
	end
end

function M:SetMenuStatus(bool)
    self.mBtnQuit:SetActive(bool)
    self.mBtnReward:SetActive(bool)
    if not bool then
        self.mBtnRevenge:SetActive(false)
    else
        self:UpdateCheer()
    end
end

function M:UpdateAtk()
    local data = DemonMgr:GetCurOccupyData()
    if data then
        self.mCurOccupy:UpdateCellState() 
    end
    local list = self.mCellList
    for i=1,#list do
        local cell = list[i]
        if cell:IsActive() then
            cell:UpdateCellState()
        end
    end
end

function M:UpdateCheer()
    local state = DemonMgr:CanBuyBuff()
    self.mBtnRevenge:SetActive(state)
    if not state then
        self.mBuffView:Close()
    end
end

function M:CreateTimer()
    local endTime = DemonMgr:GetEndTime()
    local sec = endTime - TimeTool.GetServerTimeNow()*0.001
    if sec <= 0 then 
        self:CompleteCb()
        return 
    end
    if not self.timer then
        self.timer = ObjPool.Get(DateTimer)
        self.timer.fmtOp = 3
        self.timer.apdOp = 1
        self.timer.invlCb:Add(self.InvlCb, self)
        self.timer.complete:Add(self.CompleteCb, self)
    end
    self.timer.seconds = sec
    self.timer:Stop()
    self.timer:Start()
    self:InvlCb()
end

function M:UpdateEndTime()
    local time = GlobalTemp["126"].Value2[1]
    if self.timer:GetRestTime() <= time then
        self.mEndTime.gameObject:SetActive(true)
        self.mEndTime.text = string.format("副本即将关闭：%s", self.timer.remain)
    else
        self.mEndTime.gameObject:SetActive(false)
    end
end

function M:UpdateTips()
    if not self.mTips or (not self.mTips.gameObject.activeSelf) then 
        self.mTipSec = 0
        return 
    end
    self.mTipSec = self.mTipSec + 1
    if self.mTipSec > 3 then
        self.mTipSec = 0
        self.mTips.gameObject:SetActive(false)
    end 
end

function M:InvlCb()
    self.mRemainTime.text = string.format("副本剩余时间：%s", self.timer.remain)
    self:UpdateEndTime()
    self:UpdateTips()
end

function M:CompleteCb()
    self.mRemainTime.text = "副本结束"
    self.mEndTime.gameObject:SetActive(false)
end

function M:UpdateCurOccupy()
    local data = DemonMgr:GetCurOccupyData()
    if not data then
        self.mCurOccupy:SetActive(false)
    else
        self.mCurOccupy:SetActive(true)
        self.mCurOccupy:UpdateData(data)
    end
end

function M:UpdateRank()
    local data = DemonMgr:GetRankInfo()
    local limit = GlobalTemp["125"].Value2[1]
    local len = #data > limit and limit or #data
    local list = self.mCellList
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
            local go = Instantiate(self.mPrefab)
            TransTool.AddChild(self.mGrid.transform, go.transform)
            local item = ObjPool.Get(DemonOccupyCell)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(list, item)
        end
    end
    self.mGrid:Reposition()
    self.mCellBg:SetActive(#data <= 3)
end

function M:OpenCb(name)
    local ui = UIMgr.Get(name)
    if ui then
       ui:UpdateData(DemonMgr:GetRewardData())
   end
end

function M:OnRevenge()
    self.mBuffView:Open()
end

function M:OnQuit()
    MsgBox.ShowYesNo("退出后当前数据将会被清空，是否确认退出？",self.YesCb,self) 
end

function M:OnReward()
    DemonRewardView:Open()
end

function M:YesCb()
    SceneMgr:QuitScene()
end

function M:ConDisplay()
	do return true end
end

function M:DisposeCustom()
    self:SetLsnr("Remove")
    self:SetEvent(EventMgr.Remove)
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    TableTool.ClearDicToPool(self.mCellList)
    ObjPool.Add(self.mBuffView)
    ObjPool.Add(self.mCurOccupy)
    DemonRewardView:Dispose()
    self.mBuffView = nil
    self.mCurOccupy = nil
    M.mSec = 0
    M.FTtarget = 0
    M.mTipSec = 0
    M.Belonger = 0
end

return M 
