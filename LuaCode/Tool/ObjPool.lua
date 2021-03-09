--[[
 	authors 	:Loong
 	date    	:2017-09-20 09:48:54
 	descrition 	:lua对象池
              对象必须具有字段 Name:用以区分类型
              对象必须具有方法 New:当对象池中不存在时,可以调用New创建一个
--]]

ObjPool = {}

local My = ObjPool

-- 对象字典 键:对象名称(Name字段) 值:对象列表
My.dic = {}

--检查对象有效性
function My.Check(obj)
  if obj == nil then return end
  if(type(obj) ~= "table") then
    iTrace.Error("Loong", "lua中对象类型必须是表(table)")
    return false
  end
  if type(obj.Name) ~= "string" then
    iTrace.Error("Loong", "lua中往对象池添加的对象(table)必须有Name(string)字段")
    return false
  end
  if type(obj.New) ~= "function" then
    iTrace.Error("Loong", "lua中往对象池添加的对象(table)必须有New(function)方法")
    return false
  end
  return true
end

--添加
--obj(table) 必须具有Name字段 用以识别类型
--添加成功后会自动调用Dispose对象方法
function My.Add(obj)
  if not My.Check(obj) then return end
  if obj.isRefByPool == true then return end
  obj.isRefByPool = true
  local name = obj.Name
  local list = My.dic[name]
  if list == nil then
    list = {}
    My.dic[name] = list
  end
  if type(obj.Dispose) == "function" then
    obj:Dispose()
  end
  table.insert(list, obj)
end

--获取
--obj(table) 必须具有Name字段 用以识别类型
--必须具有New字段,对象池中不存在时,可以调用New创建一个
function My.Get(obj)
  if not My.Check(obj) then return end
  local t = nil
  local name = obj.Name
  local list = My.dic[name]
  if list == nil then
    t = obj:New()
  elseif #list == 0 then
    t = obj:New()
  else
    t = table.remove(list)
  end
  t.isRefByPool = false
  do return t end
end

--释放
function My.Dispose()
  for k, v in pairs(My.dic) do
    while #v > 0 do
      v.isRefByPool = false
      table.remove(v)
    end
  end
end
