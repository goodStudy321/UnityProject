--[[
 	authors 	:Loong
 	date    	:2017-10-14 10:17:59
 	descrition 	:模板(GameObject)对象池
--]]

local Gbj = UnityEngine.GameObject

ModPool = Super:New{Name = "ModPool"}



local My = ModPool

--模板(GameObject)
My.mod = nil

--放入后的根结点(Transform)
My.iRoot = nil

--取出后的根结点(Transform)
My.oRoot = nil

--初始化
--modName:模板名称
function My:Init(modName)
  local root = self.root
  modName = modName or "item"
  self.mod = TransTool.FindChild(root, modName, modName)
  self.mod:SetActive(false)
  self.iRoot = TransTool.GetChild(root, "pool")
end

--获取
--返回(GameObject)
function My:Get()
  local mod = self.mod
  local name = mod.name
  local c = self.iRoot:Find(name)
  local go = nil
  local p = self.oRoot
  if c == nil then
    go = Gbj.Instantiate(mod)
    go.name = name
    c = go.transform

    c.parent = p
    c.localScale = Vector3.one
    --c.localPosition = Vector3.zero
  else
    c.parent = p
    go = c.gameObject
  end
  go:SetActive(true)
  return go
end

--添加
--c(GameObject or Transform)
function My:Add(c)
  if c == nil then return end
  local root = self.iRoot
  c.name = self.mod.name
  c.transform.parent = root
  c.gameObject:SetActive(false)
end

--清理
function My:Dispose()
  self.mod = nil
  self.iRoot = nil
  self.oRoot = nil
end
