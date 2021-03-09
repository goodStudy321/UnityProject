PeakRankInfo = {Name = "PeakRankInfo"}
local My = PeakRankInfo;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:SetData(rank,roleId,roleName,roleScore,rolePower,roleServer,category)
    self.rank = rank;
    self.roleId = roleId;
    self.roleName = roleName;
    self.roleScore = roleScore;
    self.rolePower = rolePower;
    self.roleServer = roleServer;
    self.roleCate = category;
end