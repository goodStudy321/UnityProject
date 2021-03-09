CampInfo = {}
local My = CampInfo;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    o:SetProper();
    return o;
end

function My:SetProper()
    self.campIcon = nil;
    self.campPeo = nil;
    self.campIntg = nil;

    self.peoNum = 0;
    self.integral = 0;
    self.campId = nil;
end

function My:Clear()
    self.peoNum = 0;
    self.integral = 0;
end