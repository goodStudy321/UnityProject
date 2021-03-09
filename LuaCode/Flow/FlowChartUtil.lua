--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019/6/27 下午8:43:43
--=============================================================================


FlowChartUtil = Super:New{ Name = "FlowChartUtil" }

local My = FlowChartUtil


----BEG PUBLIC

function My:Init()
    local Add, EH = EventMgr.Add, EventHandler
    Add("FlowChartStart", EH(self.Start, self))
    Add("FlowChartEnd", EH(self.End, self))
    --启动事件
    self.eStart = Event()
    --结束事件
    self.eEnd = Event()
end

----END PUBLIC

--流程树开始
function My:Start(name)
    self.eStart(name)
end

--流程树结束
function My:End(name, win, changeScene)
    self.eEnd(name, win, changeScene)
end


My:Init()


return My