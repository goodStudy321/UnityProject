--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 11/1/2018, 10:45:26 AM
-- 标记基类
--=============================================================================

Flag = Super:New{Name="Flag"}

local My = Flag

function My:Init()
    --true:红点显示
    self.red = false
    --改变事件,会传递red的值
    self.eChange = Event()
    self:Update()
end

--更新
function My:Update()
    
end

function My:Dispose()
    self.red = false
    self.eChange:Clear()
end

return My
