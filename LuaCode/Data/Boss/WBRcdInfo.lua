WBRcdInfo = { Name = "WBRcdInfo" }
local My = WBRcdInfo;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

--设置数据
function My:SetData(roleId,roleName,mapId,monsTypeId,itemTypeId,time)
    self.roleId = roleId;
    self.roleName = roleName;
    self.mapId = mapId;
    self.monsTypeId = monsTypeId;
    self.itemTypeId = itemTypeId;
    self.time=time
end 