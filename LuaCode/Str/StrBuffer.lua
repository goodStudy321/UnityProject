--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-08-31 18:04:12
-- 可变字符串
--==============================================================================

StrBuffer = Super:New{Name = "StrBuffer"}

local My = StrBuffer

My.Length = 0

--自定义构造
function My:Ctor()
  self.tbl = {}
end

--添加
function My:Apd(arg)
  local tbl = self.tbl
  tbl[#tbl + 1] = tostring(arg)
  self:SetLen(arg)
  return self
end

--添加行
function My:Line()
  local tbl = self.tbl
  tbl[#tbl + 1] = "\n"
  return self
end

--释放
function My:Dispose()
  ListTool.Clear(self.tbl)
  self.Length = 0
end

--返回字符
function My:ToStr()
  local str = table.concat(self.tbl)
  return str
end

--设置长度
function My:SetLen(arg)
  local len = 0
  if type(arg) == "string" then
    len = #arg
  else
    local str = tostring(arg)
    len = #str
  end
  self.Length = self.Length + len
end

return My
