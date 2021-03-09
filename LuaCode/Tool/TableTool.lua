--[[
 	authors 	:Loong
 	date    	:2017-08-20 15:07:27
 	descrition 	:表工具
--]]

TableTool = {}
local My = TableTool

--重置表
--将数字类型设为0
--将字符串类型设为空
--将用户数据类型设为nil
--recurve:true递归表格
function My.Reset(tbl, recurve)
  if type(tbl) ~= "table" then return end
  if recurve == nil then recurve = false end
  local ty = nil
  for k, v in pairs(tbl) do
    ty = type(v)
    if ty == "number" then
      tbl[k] = 0
    elseif ty == "string" then
      if k ~= "Name" then
        tbl[k] = ""
      end
    elseif ty == "userdata" then
      tbl[k] = nil
    elseif ty == "table" then
      if recurve then My.Reset(v) end
    end
  end
end

--设置表中所有数字的值
--tbl(table)
--var(值):默认为0
function My.SetNums(tbl, val)
  My.SetFields(tbl, "number", val)
end

--设置表中所有字符串的值
function My.SetStrs(tbl, val)
  My.SetFields(tbl, "string", val)
end

--清空表中的用户数据
function My.ClearUserData(tbl)
  My.SetFields(tbl, "userdata")
end

--设置表中所有某数据类型的值
--tbl(table)
--ty(string):数据类型
--val:值
function My.SetFields(tbl, ty, val)
  if type(tbl) ~= "table" then return end
  if ty == nil then return end
  local nty = nil
  for k, v in pairs(tbl) do
    nty = type(v)
    if ty == nty then
      tbl[k] = val
    end
  end
end

--清理表中所有具有指定名称字段的值
--self(table):表/对象
--name(string):名称
function My.ClearFieldsByName(self,name)
  for k,v in pairs(self) do 
    if v.Name and (v.Name == name) then
      self[k] = nil
      ObjPool.Add(v)
    end
  end
end

--获取字典长度
function My.GetDicCount(dic)
  if type(dic) ~= "table" then return 0 end
  local cnt = 0
  for k, v in pairs(dic) do
    cnt = cnt + 1
  end
  return cnt
end


--清理字典
function My.ClearDic(dic)
  if type(dic) ~= "table" then return end
  for k, v in pairs(dic) do
    dic[k] = nil
  end
end

--清理字典并将值放入对象池
function My.ClearDicToPool(dic)
  if type(dic) ~= "table" then return end
  for k, v in pairs(dic) do
    ObjPool.Add(v)
    dic[k] = nil
  end
end


--格式化字典
--return:string
function My.FmtDic(dic)
  if type(dic) ~= "table" then return tostring(dic) end
  local sb = ObjPool.Get(StrBuffer)
  sb:Apd("{")
  for k, v in pairs(dic) do
    sb:Apd("{"):Apd(tostring(k)):Apd(",")
    sb:Apd(tostring(v)):Apd("} ")
  end
  sb:Apd("}")
  local str = sb:ToStr()
  ObjPool.Add(sb)
  return str
end

--格式化输出表
function My.print(obj)
  local str = My.FmtDic(obj)
  iTrace.Log("Loong",str)
end

--清理itemCell
function My.ClearListToPool(list)
  if type(list) ~= "table" then return end
  local len = #list
  for i=1,len do
    if list[i] and list[i].DestroyGo then
      list[i]:DestroyGo()
    end
    ObjPool.Add(list[i])
    list[i] = nil
  end
end

--拼接list
function My.CombList( ... )
  local list = {}
  local arg = {...}
  for i=1,#arg do
    local tmp = arg[i]
    if tmp then
      for i=1,#tmp do
        table.insert(list, tmp[i])
      end 
    end 
  end
  return list
end

--列表是否包含 value
function My.Contains(list, value, key)
  local index = -1
  if not list then return index end
  local len = #list
  for i=1,len do
    if not key then
      if list[i] == value then
        index = i
        break
      end
    else
      if type(value) == "table" then
        if list[i][key] == value[key] then
          index = i
          break
        end
      else
        if list[i][key] == value then
          index = i
          break
        end
      end
    end
  end
  return index
end

--移除list中的value
function My.Remove(list, value, key)
  local index = My.Contains(list, value, key) 
  if index ~= -1 then
    return table.remove(list, index)
  end
end

--list不存在value就添加
function My.Add(list, value, key)
  local index = My.Contains(list, value, key)
  if index == -1 then
    table.insert(list, value)
  end
end

--随机排序
function My.RandSort(tbl)
	local n = #tbl
	for i = 1, n do
			local j = math.random(i, n)
			if j > i then
					tbl[i], tbl[j] = tbl[j], tbl[i]
			end
	end
end


--将dic转换为list
function My.DicToList(dic, sortFunc, obj)
    local list = {}
    for k,v in pairs(dic) do
        table.insert(list, v)
    end 

    if sortFunc and obj then
        table.sort(list, function(a, b) return obj.sortFunc(obj, a, b) end)
    elseif sortFunc then
        table.sort(list, function(a, b) return sortFunc(a, b) end)
    end

    return list
end

return My
