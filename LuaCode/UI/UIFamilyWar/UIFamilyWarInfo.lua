UIFamilyWarInfo = UIBase:New{Name = "UIFamilyWarInfo"}

require("UI/UIFamilyWar/OccupyBar")
require("UI/UIFamilyWar/ScoreBar")
require("UI/UIFamilyWar/OccupyInfo")
require("UI/UIFamilyWar/StartTimer")
require("UI/UIFamilyWar/OccupyPoint")

local M = UIFamilyWarInfo

function M:InitCustom()
    local F = TransTool.Find
    local root = self.root

    self.scoreBar = ObjPool.Get(ScoreBar)
    self.scoreBar:Init(F(root, "ScoreBar"))

    self.occupyBar = ObjPool.Get(OccupyBar) 
    self.occupyBar:Init(F(root, "OccupyBar"))

    self.occupyInfo = ObjPool.Get(OccupyInfo)
    self.occupyInfo:Init(F(root, "OccupyInfo"))

    self.startTimer = ObjPool.Get(StartTimer)
    self.startTimer:Init(root)

    self.occupyPoint = ObjPool.Get(OccupyPoint)
    self.occupyPoint:Init()

    self.btnQuit = TransTool.FindChild(root, "BtnQuit")

    UITool.SetLsnrSelf( self.btnQuit, self.OnQuit, self, "" , false)

    self:SetLsnr("Add")
    self:SetEvent(EventMgr.Add)
end

function M:SetLsnr(key)
    local mgr = FamilyWarMgr
    mgr.eUpdateInfo[key](mgr.eUpdateInfo, self.UpdateInfo, self)
    mgr.eUpdateTrend[key](mgr.eUpdateTrend, self.UpdateTrend, self)
    mgr.eUpdateRegion[key](mgr.eUpdateRegion, self.UpdateRegion, self)
    mgr.eUpdatePass[key](mgr.eUpdatePass, self.UpdatePass, self)
    mgr.eReadyTimeEnd[key](mgr.eReadyTimeEnd, self.ReadyTimeEnd, self)
    UIMainMenu.eUpdateFight[key](UIMainMenu.eUpdateFight, self.UpdateFight, self)
    ScreenMgr.eChange[key](ScreenMgr.eChange, self.ScreenChange, self)
    UIMainMenu.eHide[key](UIMainMenu.eHide, self.UpdateHide, self)
end

function M:SetEvent(fn)
    local EH = EventHandler
    fn("OccupPlayerEnter", EH(self.PlayerEnter, self))
    fn("OccupPlayerExit", EH(self.PlayerExit, self))
end

function M:ReadyTimeEnd()
    self.occupyInfo:StartNav()
end

function M:UpdateHide(value)
    self.btnQuit:SetActive(value)
end

function M:ScreenChange(orient)
    if self.occupyInfo then
        self.occupyInfo:ScreenChange(orient)
    end
end

function M:Update()
    if self.occupyBar then
        self.occupyBar:Update()
    end
    if  self.startTimer then
        self.startTimer:Update()
    end
end


function M:UpdateFight(value)
    if self.startTimer then
        self.startTimer:UpdateFight(value)
    end
end

function M:PlayerEnter(index)
    FamilyWarMgr:SetCurPoint(index)
    FamilyWarMgr:ReqFamilyWarPass(index, 1)
end

function M:PlayerExit(index)
    self:SetOccupyActive(false)
    FamilyWarMgr:SetCurPoint(0)
    FamilyWarMgr:ReqFamilyWarPass(index, 0)
end

function M:SetOccupyActive(bool)
    if self.occupyBar then
        self.occupyBar:SetActive(bool) 
    end
end

--初始化界面信息
function M:InitWarInfo()
    self.occupyInfo:InitInfo()
    self.scoreBar:InitInfo()
    self.startTimer:CreateTimer()
    self.occupyPoint:InitEff()
end

function M:UpdatePass()
    self:SetOccupyActive(true)
end

function M:UpdateRegion(camp, index)
    if self.occupyPoint then
        self.occupyPoint:UpdateEff(camp, index)
    end
    if self.occupyInfo then
        self.occupyInfo:UpdateMapInfo()
    end
end

--更新双方分数和占领点数量
function M:UpdateInfo()
    if self.scoreBar then
        self.scoreBar:UpdateScore()
    end
    if self.occupyInfo then
        self.occupyInfo:UpdateOccupy()
    end
end

--更新双方占领进度
function M:UpdateTrend()
    if self.occupyBar then
        self.occupyBar:UpdateTrend()
    end
end

function M:OnQuit()
    MsgBox.ShowYesNo("确定要离开地图吗？", self.OkCb, self) 
end

function M:OkCb()
    SceneMgr:QuitScene()
    FamilyWarMgr:Clear()
    self:Close()
end


--持续显示 ，不受配置tOn == 1 影响
function M:ConDisplay()
	return true
end


function M:DisposeCustom()
    self:SetLsnr("Remove")
    self:SetEvent(EventMgr.Remove)
    ObjPool.Add(self.scoreBar)
    ObjPool.Add(self.occupyBar)
    ObjPool.Add(self.occupyInfo)
    ObjPool.Add(self.startTimer)
    ObjPool.Add(self.occupyPoint)
    self.scoreBar = nil
    self.occupyBar = nil
    self.occupyInfo = nil
    self.startTimer = nil
    self.occupyPoint = nil
end

return M