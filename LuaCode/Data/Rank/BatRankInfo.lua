BatRankInfo = {}
local My = BatRankInfo

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    o:SetProper();
    return o;
end

function My:SetProper()
    self.rank = nil;
    self.roleId = nil;
    self.roleName = nil;
    self.level = nil;
    self.score = nil;
    self.fightVal = nil;
    self.campId = nil;
end

function My:SetInfo(rank,roleId,roleName,level,score,fightVal,campId)
    self.rank = rank;
    self.roleId = roleId;
    self.roleName = roleName;
    self.level = level;
    self.score = score;
    self.fightVal = fightVal;
    self.campId = campId;
end

function My:Dispose()
    self:SetProper();
end

return My