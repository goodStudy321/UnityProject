UICopyLoveSelectView = Super:New{Name = "UICopyLoveSelectView"}

require("UI/UICopy/UICopyLoveSelectItem")

local M = UICopyLoveSelectView
M.cellList = {}

function M:Init(go)
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local trans = go.transform

    self.go = go
    
    self.countDown = G(UILabel, trans, "CountDown")

    self.grid = G(UIGrid,trans ,"ScrollView/Grid")
    self.cell = FC(self.grid.transform, "Cell")
    self.cell:SetActive(false)
end

function M:UpdateData(data)
    if not data then return end
    for i=1,#data do
        local go = Instantiate(self.cell)
        TransTool.AddChild(self.cell.transform.parent, go.transform)
        local item = ObjPool.Get(UICopyLoveSelectItem)
        item:Init(go)
        item:SetActive(true)
        item:UpdateData(data[i])
        table.insert(self.cellList, item)
    end
    self.grid:Reposition()
end

function M:UpdateState(id)
    local list = self.cellList
    for i=1,#list do
        list[i]:UpdateState(list[i].data == id)
    end
end


function M:CreateTimer(sec)
    if not sec then return end
    local seconds = sec - TimeTool.GetServerTimeNow()*0.001
    if seconds > 0 then
        self:SetActive(true)
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
        end
        local timer = self.timer
        timer.seconds = seconds
        timer.fmtOp = 3
        timer.invlCb:Add(self.InvlCb, self)
        timer.complete:Add(self.CompleteCb, self)
        timer:Start()
        self:InvlCb()
    end
end

function M:StopTimer()
    if self.timer then
        self.timer:Stop()
    end
end

function M:InvlCb()
    self.countDown.text = string.format("[88f8ff]剩余选择时间：[f4ddbd]%s", self.timer.remain)
end

function M:CompleteCb()
    self:SetActive(false)
end


function M:SetActive(bool)
    self.go:SetActive(bool)
end

function M:Dispose()
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
    TableTool.ClearDicToPool(self.cellList)
    TableTool.ClearUserData(self)
end

return M