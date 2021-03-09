XDelayDestroy = Super:New{Name = "XDelayDestroy"}

local M = XDelayDestroy


function M:SetGoAndDelay(go, delay)
    self.go = go
    if not self.timer then
        self.timer = ObjPool.Get(iTimer)
        self.timer.complete:Add(self.Complete, self)
    end 
    self.timer:Start(delay)
end

function M:Complete()
    self.timer:Stop()
    if not LuaTool.IsNull(self.go) then 
        AssetMgr:Unload(self.go.name, ".prefab", false)
        GameObject.DestroyImmediate(self.go)
        self.go = nil
    end
    ObjPool.Add(self)
end

function M:Dispose()
    self.go = nil
    if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
end

return M