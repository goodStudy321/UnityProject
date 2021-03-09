MyGbjPool = Super:New{Name = "MyGbjPool"}

local M = MyGbjPool

function M:Ctor()
  self.list = {}
end

function M:Add(obj)
    if not obj then return end
    table.insert(self.list, obj)
    obj:SetActive(false)
end

function M:Get(name)
  local list = self.list
  local len = #list
  local index = nil
  for i=1,len do
    if list[i].name == name  then
      index = i
      break
    end
  end
  if index then
    local go = table.remove(self.list, index)
    go:SetActive(true)
    return go
  end
end

--释放
function M:Dispose()
  local list = self.list
  local len = #list
  for i=1,len do
    AssetMgr:Unload(list[i].name, ".prefab", false)
    GameObject.DestroyImmediate(list[i])
    list[i] = nil
  end
end

return M
