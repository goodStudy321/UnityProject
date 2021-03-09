UISceneDes = Super:New{Name = "UISceneDes"}

local M = UISceneDes
local aMgr = Loong.Game.AssetMgr

function M:Ctor()
    self.scenelist = {}
end

function M:Init(go)
    self.root = go.transform
    self.root.localPosition = Vector3(180, 29, 0)
end


function M:LoadCb(go) 
    local trans = go.transform
    trans:SetParent(self.root)
    trans.localPosition = Vector3.zero
    trans.localScale = Vector3.one
    self.curGo = go
    local dd = ObjPool.Get(XDelayDestroy)
    dd:SetGoAndDelay(go, 5)
end

function M:Destroy()
    if LuaTool.IsNull(self.curGo) then return end
    AssetMgr:Unload(self.curGo.name, ".prefab", false)
    GameObject.DestroyImmediate(self.curGo)
    self.curGo = nil
end

function M:UpdateDes()
    self:Destroy()
    if self:hadShow(User.SceneId) then return end
    local prefab = SceneTemp[tostring(User.SceneId)].sceneDes 
    if not StrTool.IsNullOrEmpty(prefab) then
        if not LuaTool.IsNull(self.curGo) and self.curGo.name == prefab then return end
        aMgr.LoadPrefab(prefab,GbjHandler(self.LoadCb, self))
    end
end

function M:hadShow(sceneId)
    local list = self.scenelist
    local len = #list
    for i=1,len do
        if list[i] == sceneId then
            return true
        end
    end
    table.insert(list, sceneId)
    return false
end

function M:Clear(isReconnect)
    if isReconnect then return end
    self:Destroy()
    TableTool.ClearDic(self.scenelist)
end

function M:Dispose()
    self:Clear()
    TableTool.ClearUserData(self)
end

return M