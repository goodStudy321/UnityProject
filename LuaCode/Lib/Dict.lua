--[[
 	author 	    :Loong
 	date    	:2018-01-18 17:13:26
 	descrition 	:字典
--]]

Dict = Super:New{Name = "Dict"}

local My = Dict

function My:Ctor()
  self.buf = {}
  self.Count = 0
end

--返回值
function My:Get(k)
  local v = self.buf[k]
  return v
end

--添加
function My:Add(k, v)
  if k == nil then return end
  if v == nil then return end
  local buf = self.buf
  local val = buf[k]
  if not val then
    self.count = self.count + 1
  end
  buf[k] = v
end

--移除
function My:Remove(k)
  if k == nil then return end
  local buf = self.buf
  if buf[k] then
    self.count = self.count - 1
  end
  buf[k] = nil
end

--清理,当需要将值放入对象池时,需要自己处理
function My:Clear()
  TableTool.ClearDic(self.buf)
  self.Count = 0
end

--释放
function My:Dispose()
  self:Clear()
end


return My
