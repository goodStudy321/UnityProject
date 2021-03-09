--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 1/15/2019, 11:27:53 AM
--=============================================================================

NetObserver = {Name="NetObserver"}

local My = NetObserver
-- ViaCarrier:移动网络
NetType = {None=0, ViaCarrier=1, Wifi=2}

function My:Init()
    self:SetType()
    self.eChange = Event()
    EventMgr.Add("NetChange",EventHandler(self.Change, self))
end

function My:SetType()
    local type = Device.NetType
    if type == "wifi" then
        self.type = NetType.Wifi
    elseif type == "4g" then
        self.type = NetType.ViaCarrier
    elseif type == "3g" then
        self.type = NetType.ViaCarrier
    elseif type == "2g" then
        self.type = NetType.ViaCarrier
    else
        self.type = NetType.None
    end
end

function My:Change(last,cur)
    self.eChange(last, cur)
end

function My:Clear()
    
end

return My