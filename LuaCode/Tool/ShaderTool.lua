--[[
 	authors 	:Loong
 	date    	:2017-09-29 22:19:29
 	descrition 	:着色器工具
--]]

ShaderTool = {}

local Shader = UnityEngine.Shader
local Renderer = UnityEngine.Renderer

local My = ShaderTool

--重置材质球
--mat(材质球)
function My.ResetMat(mat)
  if mat == nil then return end
  local osd = mat.shader
  if osd == nil then return end
  local nsd = Shader.Find(osd.name)
  if nsd == nil then return end
  mat.shader = nsd
end

--编辑器下重置材质球
function My.eResetMat(mat)
  if App.isEditor then
    My.ResetMat(mat)
  end
end

--重置材质球数组
function My.ResetMats(mats)
  if mats == nil then return end
  local sz = mats.Length - 1
  for i = 0, sz do
    local mat = mats[i]
    My.ResetMat(mat)
  end
end

--编辑器下重置材质球数组
function My.eResetMats(mats)
  if App.isEditor then
    My.ResetMats(mats)
  end
end

--重置游戏对象
--go(Transform or GameObject)
function My.ResetGo(go)
  if LuaTool.IsNull(go) then return end
  local rty = typeof(Renderer)
  local rss = go:GetComponentsInChildren(rty, true)
  if rss == nil then return end
  local sz = rss.Length - 1
  for i = 0, sz do
    local rs = rss[i]
    local mats = rs.sharedMaterials
    My.ResetMats(mats)
  end
end

--编辑器下重置游戏对象
function My.eResetGo(go)
  if App.isEditor then
    My.ResetGo(go)
  end
end

--重置天空材质球
function My.ResetSkybox()
  My.ResetMat(UnityEngine.RenderSettings.skybox)
end

--编辑器下重置天空材质球
function My.eResetSkybox()
  if App.isEditor then
    My.ResetSkybox()
  end
end
