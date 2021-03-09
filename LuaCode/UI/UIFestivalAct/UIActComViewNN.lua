--[[
 	authors 	:Liu
 	date    	:2019-2-14 15:00:00
 	descrition 	:你侬我侬模块
--]]

UIActComViewNN = Super:New{Name = "UIActComViewNN"}

local My = UIActComViewNN

require("UI/UIFestivalAct/UIActNNItem")
require("UI/UIFestivalAct/UIActNNCondItem")

function My:Init(go)
    local root = go.transform
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local str1 = "Container/Scroll View/Grid"
    local str2 = "countBg/Scroll View/Grid"

    self.go = go
    self.itList = {}
    self.condList = {}
    self.grid = CG(UIGrid, root, str1)
    self.explain = CG(UILabel, root, "spr/lab")
    self.countDown = CG(UILabel, root, "Countdown")
    self.lab = CG(UILabel, root, "countBg/titleBg/lab")
    self.item = FindC(root, str1.."/Cell", des)
    self.condGrid = CG(UIGrid, root, str2)
    self.condItem = FindC(root, str2.."/item", des)
end

--更新数据
function My:UpdateData(data)
    self.data = data
    self:InitAwardItems()
    self:InitExplainLab()
    self:UpTitleLab()
    self:InitCondItems()
    self:UpActTime()
end

--更新奖励项列表
function My:UpdateItemList()
    for i,v in ipairs(self.itList) do
        v:SetBtnState()
    end
    self.grid:Reposition()
end

--初始化奖励项
function My:InitAwardItems()
    if #self.itList > 0 then return end
    local itemData = self.data.itemList
    if itemData == nil then return end
    local Add = TransTool.AddChild
    for i,v in ipairs(itemData) do
        local go = Instantiate(self.item)
        local tran = go.transform
        Add(self.grid.transform, tran)
        local it = ObjPool.Get(UIActNNItem)
        it:Init(tran, v)
        table.insert(self.itList, it)
    end
    self.item:SetActive(false)
    self.grid:Reposition()
end

--初始化条件项
function My:InitCondItems()
    local itemData = FestivalActInfo.condList
    if itemData == nil then return end
    local Add = TransTool.AddChild
    for i,v in ipairs(itemData) do
        local go = Instantiate(self.condItem)
        local tran = go.transform
        Add(self.condGrid.transform, tran)
        local it = ObjPool.Get(UIActNNCondItem)
        it:Init(tran, v)
        table.insert(self.condList, it)
    end
    self.condItem:SetActive(false)
    self.condGrid:Reposition()
end

--更新标题文本
function My:UpTitleLab()
    local info = FestivalActInfo
    local str = string.format("[EE9A9EFF]当前%s：[F78706FF]%s", info.keyword, info.money)
    self.lab.text = str
end

--初始化说明文本
function My:InitExplainLab()
    self.explain.text = self.data.explain
end

--打开
function My:Open(data)
    self:SetActive(true)
    self:UpdateData(data)
end

--关闭
function My:Close()
    self:SetActive(false)
end

--设置状态
function My:SetActive(state)
    self.go:SetActive(state)
end

--更新活动时间
function My:UpActTime()
    local eDate = self.data.eDate
    local seconds =  eDate-TimeTool.GetServerTimeNow()*0.001
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.invlCb:Add(self.InvlCb, self)
            self.timer.complete:Add(self.CompleteCb, self)
            self.timer.apdOp = 3
        else
            self.timer:Stop()
        end
        self.timer.seconds = seconds
        self.timer:Start()
        self:InvlCb()
    end
end

--间隔倒计时
function My:InvlCb()
    if self.countDown then
        self.countDown.text = string.format("活动结束倒计时：%s", self.timer.remain)
    end
end

--结束倒计时
function My:CompleteCb()
    self.countDown.text = "活动结束"
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--清理缓存
function My:Clear()
    self:ClearTimer()
end

-- 释放资源
function My:Dispose()
    self:Clear()
    ListTool.ClearToPool(self.itList)
    ListTool.ClearToPool(self.condList)
end

return My