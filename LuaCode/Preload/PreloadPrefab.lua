--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-09-29 20:56:53
-- 预加载预制件(prefab)
--==============================================================================

PreloadPrefab = {Name = "PreloadPrefab"}

local My = PreloadPrefab

--持久化字典
--键:名称 值:bool
My.pstDic = {}

--加载数量字典
--键:名称 值:数量
My.muldic = {}

--加载完成回调
function My.Callback(obj)
  if obj == nil then return end
  My.AddPool(obj)
  local name = obj.name
  local pst = My.pstDic[name]
  My.pstDic[name] = nil
  pst = pst or false
  if pst then
    GbjPool:SetPersist(name, true)
    AssetMgr:SetPersist(name, ".prefab", true)
  end
end

function My.AddPool(obj)
  local name = obj.name
  local go = Instantiate(obj)
  if App.isEditor then
      ShaderTool.eResetGo(go)
    end
  go.name = name
  GbjPool:Add(name, go)
end

--添加预加载项
--name(string)名称
--pst(bool)true时设置持久化
function My.Add(name, pst)
  if type(name) ~= "string" then return end
  local multi =  1
  pst = pst or false
  My.pstDic[name] = pst
  My.muldic[name] = multi
end

--将预加载列表添加到资源列表中
function My.Execute()
  local cb = My.Callback
  for k, v in pairs(My.muldic) do
    AssetMgr:Add(k, ".prefab", ObjHandler(cb))
  end
  TableTool.ClearDic(My.muldic)
end

--通过名称判断是否Prefab
function My.IsPrefab(name)
  local beg = string.find(name,".prefab")
  do return beg end
end

return My
