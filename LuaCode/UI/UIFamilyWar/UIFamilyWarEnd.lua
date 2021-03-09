UIFamilyWarEnd = UIBase:New{Name = "UIFamilyWarEnd"}

require("UI/UIFamilyWar/FamWarEndCell")

local M = UIFamilyWarEnd

function M:InitCustom()
    self.cellList = {}
    self:InitUserData()
end

function M:InitUserData()
    local root = self.root
    local G = ComTool.Get
    local FG = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf

    local btnOk = F(root, "BtnOk")
    S(btnOk, self.OnOk, self)


    self.win = FG(root, "Win")
    self.lose = FG(root, "Lose")
    self.grid = G(UIGrid, root, "WarInfoList/ScrollView/Grid")
    self.cell = FG(self.grid.transform, "Cell")
    self.cell:SetActive(false)
    self.time = G(UILabel, root, "Time")
end

function M:UpdateData(data)
    if not data then return end
    local list = data.list
    local len = #list
    local cell = self.cell
    local parent = self.grid.transform
    local cellList = self.cellList
    for i=1,len do
        local go = Instantiate(cell)
        go:SetActive(true)
        TransTool.AddChild(parent, go.transform)
        local famWarEndCell = ObjPool.Get(FamWarEndCell)
        famWarEndCell:Init(go)
        famWarEndCell:UpdateData(list[i])
        table.insert(cellList, famWarEndCell)
    end
    self.grid:Reposition()

    self.win:SetActive(data.isWin)
    self.lose:SetActive(not data.isWin)
    self:CreateTimer()
end

function M:CreateTimer()
    self.timer = ObjPool.Get(DateTimer) 
    local timer = self.timer
    timer.seconds = GlobalTemp["36"].Value2[4]
    timer.fmtOp = 2
    timer.invlCb:Add(self.TimerCb, self)
    timer.complete:Add(self.OnOk, self)
    timer:Start()
    self:TimerCb()
end

function M:TimerCb()
    self.time.text = string.format( "[99886b]([f4ddbd]%s[-]后自动关闭)[-]",self.timer.remain)
end

function M:OnOk()
    SceneMgr:QuitScene()
    self:Close()
end

function M:Clear()
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M