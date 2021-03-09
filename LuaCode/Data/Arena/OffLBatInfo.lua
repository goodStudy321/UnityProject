OffLBatInfo = { Name = "OffLBatInfo" }
local My = OffLBatInfo;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

--初始化数据
function My:InitData(roleId,name,ctgry,level,maxHp,fightVal)
    self.roleId = tostring(roleId);
    self.name = name;
    self.ctgry = ctgry;
    self.level = level;
    self.maxHp = maxHp;
    self.fightVal = fightVal;
end