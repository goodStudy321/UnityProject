--[[
 	authors 	:Liu
 	date    	:2018-12-18 19:16:00
 	descrition 	:结婚副本动画
--]]

UIMarryAnim = UIBase:New{Name = "UIMarryAnim"}

local My = UIMarryAnim

function My:InitCustom()
    --开始播放流程树动画
    FlowChartMgr.Start("Wedding")
    EventMgr.Add("FlowChartEnd", EventHandler(self.FlowChartEnd, self))
end

--监听流程树动画结束
function My:FlowChartEnd()
    self:Close()
end

--清理缓存
function My:Clear()
    EventMgr.Remove("FlowChartEnd", EventHandler(self.FlowChartEnd, self))
end

--释放资源
function My:DisposeCustom()
    self:Clear()
end

return My