--[[
 	authors 	:Liu
 	date    	:2019-07-01 12:00:00
 	descrition 	:商店模块
--]]

UIActivSD = Super:New{Name = "UIActivSD"}

local My = UIActivSD

require("UI/UILimitActiv/UIActivSDIt")

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local str = "Container/ScrollView/Grid"

    self.go = root.gameObject
    self.itList = {}
    self.grid = CG(UIGrid, root, str)
    self.countDown = CG(UILabel, root, "Countdown")
    self.item = FindC(root, str.."/item")
    self.item:SetActive(false)

    self:InitItems()
    self:UpActTime()
end

--初始化商品项
function My:InitItems()
    local cfgList = LimitActivStoreCfg
    local saveList = self.itList
    local class = UIActivSDIt
    CustomMod:InitItems(cfgList, self.item, self.grid, saveList, class)
end

--更新商品项数据
function My:UpItemData()
    for i,v in ipairs(self.itList) do
        v:UpData()
    end
end

--更新显示
function My:UpShow(state)
    self.go:SetActive(state)
end

--更新活动时间
function My:UpActTime()
    local info = LivenessInfo:GetActInfoById(1035)
    if info == false then return end
    local eDate = info.eTime
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
end

return My