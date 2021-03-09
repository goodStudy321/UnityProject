--[[
 	authors 	:Loong
 	date    	:2017-09-09 10:33:51
 	descrition 	:层级工具
--]]

LayerTool = {}

local My = LayerTool

--设置游戏对象和所有子对象的层级
--target(GameObject or Transform)
--layer(number):层级
function My.Set(target, layer)
  if target == nil then return end
  if type(layer) ~= "number" then return end
  local ty = typeof(UnityEngine.Transform)
  local arr = target:GetComponentsInChildren(ty, true)
  local len = arr.Length - 1
  for i = 0, len do
    local a = arr[i]
    a.gameObject.layer = layer
  end
end
