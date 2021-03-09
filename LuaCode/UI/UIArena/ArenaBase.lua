ArenaBase = {Name = "ArenaBase"}
local My = ArenaBase;

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    o:InitEvent();
    return o;
end

function My:Open(go)

end

function My:Close()
    self:RemoveEvent();
end

function My:InitEvent()

end

function My:RemoveEvent()

end