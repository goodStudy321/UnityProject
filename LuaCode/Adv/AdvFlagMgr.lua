local GetErr = ErrorCodeMgr.GetError

AdvFlagMgr = Super:New{Name = "AdvFlagMgr"}

local My = AdvFlagMgr

function My:Init()
    self.isFullQual = nil
end

function My:Reset()
    self.isFullQual = nil
end

function My:Clear()
  self:Reset()
end


return My
