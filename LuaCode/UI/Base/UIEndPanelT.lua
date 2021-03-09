UIEndPanelT = UIBase:New{Name = "UIEndPanelT"}

local M = UIEndPanelT

M.mCellList = {}

M.mCanClick = true

function M:InitCustom()
    local trans = self.root
    local G = ComTool.Get
    local F = TransTool.Find
    local FC = TransTool.FindChild
    
    self.mSuccess = FC(trans, "Success")
    self.mFail = FC(trans, "Fail")
    self.mDes = G(UILabel, trans, "Des")
    self.mCountdown = G(UILabel, trans, "Countdown")
    self.mGrid = G(UIGrid, trans, "ScrollView/Grid")
    self.mBtnQuit = FC(trans, "BtnQuit")
    UITool.SetLsnrSelf(self.mBtnQuit, self.OnQuit, self)

    -----道庭Boss
    self.fbGo = FC(trans, "FamilyBoss")
    self.labGo = FC(trans, "FamilyBoss/title1/lab")
    self.lab1 = G(UILabel, trans, "FamilyBoss/lab1")
    self.lab2 = G(UILabel, trans, "FamilyBoss/lab2")
    self.grid1 = F(trans, "FamilyBoss/title1/Scroll View1/Grid")
    self.grid2 = F(trans, "FamilyBoss/title2/Scroll View2/Grid")

    self:SetEvent(EventMgr.Add)
end

function M:SetEvent(fn)
    fn("ChangeSceneFail",  EventHandler(self.ChangeSceneFail, self))
end

function M:ChangeSceneFail()
    M.mCanClick = true
end

function M:UpdateData(data)
    if not data then return end
    for i=1,#data do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.mGrid.transform)
        cell:UpData(data[i].id, data[i].val)
        table.insert(self.mCellList, cell)
    end
    self.mGrid:Reposition()
end

--更新道庭Boss结算数据
function M:UpFamilyBossData(data)
    if not data then return end
    self.fbGo:SetActive(true)
    self.labGo:SetActive(false)
    self.grid1.parent.gameObject:SetActive(true)
    self.lab1.text = string.format("[F4DDBDFF]您的道庭伤害排名：[00FF00FF]%s", data.rank)
    self.lab2.text = string.format("[F4DDBDFF]道庭参与人数：[00FF00FF]%s", data.joinCount)
    self:UpItemData(data.award1, self.grid1)
    self:UpItemData(data.award2, self.grid2)
end

--更新奖励数据
function M:UpItemData(award, grid)
    for i,v in ipairs(award) do
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(grid, 0.8)
        cell:UpData(v.type_id, v.num)
        table.insert(self.mCellList, cell)
    end
end

function M:UpdateDes(des)
    self.mDes.text = des
end

function M:UpdateSuccess(state)
    self.mSuccess:SetActive(state)
    self.mFail:SetActive(not state)
end

function M:UpdateTimer(sec)
    if not sec then return end
    if not self.timer then 
        self.timer = ObjPool.Get(DateTimer)
        self.timer.invlCb:Add(self.InvlCb, self)
        self.timer.complete:Add(self.CompleteCb, self)
    end
    self.timer.seconds = sec
    self.timer:Start()
    self:InvlCb()
end

function M:InvlCb()
    self.mCountdown.text = string.format("%s后退出副本", self.timer.remain)
end

function M:CompleteCb()
    self:OnQuit()
end

function M:OnQuit()
    if not M.mCanClick then return end
    M.mCanClick = false
    if self.timer then
        self.timer:Stop()
    end
    SceneMgr:QuitScene()
end

function M:ConDisplay()
	return true 
end

function M:DisposeCustom()
    M.mCanClick = true
    self:SetEvent(EventMgr.Remove)
    TableTool.ClearDicToPool(self.mCellList)
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
end

return M