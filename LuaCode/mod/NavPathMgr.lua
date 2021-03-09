--设备信息扩展
NavPathMgr = {Name = "NavPathMgr"}


local My = NavPathMgr

function My:Init()
  self.eNavPathEnd = Event()
  local e = EventHandler(self.NavEnd,self)
  EventMgr.Add("NavPathComplete", e)
end

function My:NavEnd(type,id)
  self.eNavPathEnd(type,id)
end

function My:Clear()

end

return My
