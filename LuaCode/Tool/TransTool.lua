--[[
 	authors 	:Loong
 	date    	:2017-09-08 15:24:03
 	descrition 	:变换组件工具
--]]

local Gbj = UnityEngine.GameObject

TransTool = {}

local My = TransTool
My.sb = StrBuffer:New{}

--return(GameObject)
--root(Transform):根结点
--path(string):路径
--tip(string):提示
function My.FindChild(root, path, tip)
  local c = My.Find(root, path, tip)
  if c == nil then return nil end
  return c.gameObject
end

--添加子变换
--p(Transform)
--c(Transform)
function My.AddChild(p, c)
  if p == nil then return end
  if c == nil then return end
  c:SetParent(p)
  c.localScale = Vector3.one
  c.localPosition = Vector3.zero
end

--获取指定名称的子变换
--如果不存在则创建
--return(transform)
function My.GetChild(p, cName)
  if p == nil then return end
  local c = p:Find(cName)
  if c then return c end
  local go = Gbj.New()
  go.name = cName
  c = go.transform
  My.AddChild(p, c)
  return c
end

--前置检查
function My.FindCheck(root, path, tip)
  if root == nil then
    iTrace.Error("Loong", tip .. "根结点为空,path:" .. path)
    return false
  end
  if #path < 1 then
    iTrace.Error("Loong", tip .. "路径为空")
    return false;
  end
  do return true end
end

--未发现提示
function My.FindNone(root, path, tip)
  local sb = My.sb
  sb:Apd(tip):Apd(",根节点:"):Apd(root.name);
  sb:Apd(",未发现路径为:"):Apd(path):Apd("的子物体");
  local str = sb:ToStr()
  sb:Dispose()
  iTrace.Error("Loong", str)
end

--return(Transform)
--root(Transform):根结点
--path(string):路径
--tip(string):提示
function My.Find(root, path, tip)
  if not My.FindCheck(root, path, tip) then return end
  local c = root:Find(path)
  if c == nil and tip then
    My.FindNone(root, path, tip)
    return nil
  end
  return c
end

--在根节点下搜索具有指定名称的子节点(包含非直接子节点)
--无特殊需求应该使用Find
--return(Transform)
function My.Search(root, name, tip)
  tip = tip or ""
  if not My.FindCheck(root, name, tip) then return end
  local ty = typeof(UnityEngine.Transform)
  local childs = root:GetComponentsInChildren(ty, true)
  local len = childs.Length - 1
  local child, res = nil, nil
  for i = 0, len do
    child = childs[i]
    if child.name == name then
      res = child
      break
    end
  end
  if res == nil then
    My.FindNone(root, name, tip)
  end
  return res
end

--清理子节点
function My.ClearChildren(p)
  if p == nil then return end
  while p.childCount > 0 do
    local c = p:GetChild(0)
    Gbj.DestroyImmediate(c.gameObject)
  end
end

--设置子游戏对象激活状态
function My.SetChildActive(root, path, active)
  local c = My.Find(root, path)
  active = active or false
  if c then
    c.gameObject:SetActive(active)
  end
end

--重命名子物体
--p(transform):父变换
--newName(string):新名称
--filder(string):子物体有此名称,则跳过
--cat(boolean):子物体激活状态
function My.RenameChildren(p, newName, filter, cat)
  if p == nil then return end
  newName = newName or "none"
  if cat == nil then cat = false end
  local len = p.childCount - 1
  for i = 0, len do
    local c = p:GetChild(i)
    local name = c.name
    if filter ~= name then
      c.name = newName
      c.gameObject:SetActive(cat)
    end
  end
end

--设置所有子物体激活状态
function My.SetChildrenActive(p, at)
  if p == nil then return end
  if at == nil then at = false end
  local len = p.childCount - 1
  for i = 0, len do
    local c = p:GetChild(i)
    c.gameObject:SetActive(at)
  end
end
