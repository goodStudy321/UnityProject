--[[
 	author 	    :Loong
 	date    	:2018-01-29 20:42:32
 	descrition 	:列表工具
--]]

ListTool = {Name = "ListTool"}

local My = ListTool

--交换列表中两个指定索引的引用
--lst(table)
--i,j(number):要交换的索引
function My.Swap(lst, i, j)
  if type(lst) ~= "table" then return end
  local len = #lst
  if i > len then return end
  if j > len then return end
  local temp = lst[i]
  lst[i] = lst[j]
  lst[j] = temp
end

--移除指定索引元素;将将要移除的元素和最后元素交换;移除最后元素
--lst(table)
--i(number):要移除的索引
function My.Remove(lst, i)
  if type(lst) ~= "table" then return end
  local len = #lst
  if i > len then return end
  if i ~= len then
    local temp = lst[i]
    lst[i] = lst[len]
    lst[len] = temp
  end
  local it = table.remove(lst)
  return it
end


--清理列表
function My.Clear(lst)
  if type(lst) ~= "table" then return end
  while #lst > 0 do
    table.remove(lst)
  end
end

--清理列表并将条目放入对象池
function My.ClearToPool(lst)
  if type(lst) ~= "table" then return end
  while #lst > 0 do
    local it = table.remove(lst)
    ObjPool.Add(it)
  end
end

--格式化列表
--return:string
function My.Format(lst)
  if type(lst) ~= "table" then return tostring(lst) end
  local len = #lst
  if len < 1 then return "{}" end
  local sb = ObjPool.Get(StrBuffer)
  sb:Apd("{")
  for i, v in ipairs(lst) do
    sb:Apd(v)
    if i < len then
      sb:Apd(",")
    end
  end
  sb:Apd("}")
  local str = sb:ToStr()
  ObjPool.Add(sb)
  return str
end

return My
