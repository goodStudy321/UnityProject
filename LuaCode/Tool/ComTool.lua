--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-09-08 15:23:40
-- 组件工具
--==============================================================================

ComTool = {Name = "ComTool"}

local My = ComTool

My.sb = StrBuffer:New{}

--获取类型
function My.GetType(ty, tip)
  if ty == nil then
    iTrace.Error("Loong", tip, "component type is null")
    return nil
  end
  local rty = typeof(ty)
  if rty == nil then
    iTrace.Error("Loong", "not find type:", tostring(ty))
    return nil
  end
  return rty
end

--获取组件
--ty:类型
--root(Transform):根结点
--path(string):路径
--tip(string):提示
--add(bool):true时,没有发现组件时添加
function My.Get(ty, root, path, tip, add)
  tip = tip or ""
  local rty = My.GetType(ty, tip)
  if rty == nil then return end

  local c = TransTool.Find(root, path, tip)
  if c == nil then return end

  local com = c:GetComponent(rty)
  add = add or false
  if add then
    if com == nil then
      com = c.gameObject:AddComponent(rty)
    end
  elseif com == nil and tip then
    local sb = My.sb
    sb:Apd(tip):Apd(",root:"):Apd(root.name);
    sb:Apd(",path:"):Apd(path):Apd(",not find:");
    sb:Apd(tostring(rty))
    local str = sb:ToStr()
    sb:Dispose()
    iTrace.Error("Loong", str)
  end
  return com
end

--在自身上获取组件
--ty:类型
--target(Transform or GameObject):对象
--tip(string):提示
function My.GetSelf(ty, target, tip)
  tip = tip or ""
  local rty = My.GetType(ty, tip)
  if rty == nil then return end
  if target == nil then
    iTrace.Error("Loong", tip, ", arg of target is null")
  end
  local com = target:GetComponent(rty)
  return com
end

--如果对象上已经存在组件,返回已经存在的,否则添加
--return ty
--target(Transform or GameObject)
--type：组件类型
function My.Add(target, ty)
  if target == nil then return end
  if ty == nil then return end
  local rty = typeof(ty)
  local com = target:GetComponent(rty)
  if com == nil then
    com = target.gameObject:AddComponent(rty)
  end
  return com
end
