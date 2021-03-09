--[[
 	authors 	:Loong
 	date    	:2017-08-20 15:00:30
 	descrition 	:字符串工具
--]]

StrTool = {}
local My = StrTool

--字符串连接
function My.Concat(...)
  local len = select('#', ...)
  if len < 1 then return end
  local sb = ObjPool.Get(StrBuffer)
  local str = nil
  for i = 1, len do
    str = select(i, ...)
    sb:Apd(str)
  end
  local res = sb:ToStr()
  ObjPool.Add(sb)
  return res
end

--判断字符串为空或长度为0
function My.IsNullOrEmpty(str)
  if str == nil then return true end
  if(type(str) ~= "string") then return false end
  local res = (#str == 0) and true or false
  return res
end

--字符串分隔方法  
function My.Split(str,reps)
  local resultStrList = {}
  string.gsub(str,'[^'..reps..']+',function ( w )
      table.insert(resultStrList,w)
  end)
  return resultStrList
end

--// LY add begin

--// 字符串连接(传入Table)
function My.ConcatTbl(textTbl)
  if textTbl == nil then
    return "";
  end

  local len = #textTbl;
  if len < 1 then
    return "";
  end
  local sb = ObjPool.Get(StrBuffer);
  local str = nil;
  for i = 1, len do
    str = textTbl[i];
    sb:Apd(str);
  end
  local res = sb:ToStr();
  ObjPool.Add(sb);
  return res;
end

--// 拆分字符串到table
function My.SplitStrToTbl(str)
  local retTbl = {};
  if str == nil or #str <= 0 then
    return retTbl;
  end

  --for ch in string.gmatch(str, "[\0-\x7F\xC2-\xF4][\x80-\xBF]*") do
  for ch in string.gmatch(str, "[\\0-\127\194-\244][\128-\191]*") do
    retTbl[#retTbl + 1] = ch;
  end

  -- for i = 1, #retTbl do
  --   print("------  "..retTbl[i]);
  -- end

  return retTbl;
end

--// 只保留中文和数字
function My.OnlyChnAndNum(str)
  local strTbl = My.SplitStrToTbl(str);
  local tTbl = {};

  for i = 1, #strTbl do
    if #strTbl[i] ~= 1 then
      tTbl[#tTbl + 1] = strTbl[i];
    else
      if tonumber(strTbl[i]) then
        tTbl[#tTbl + 1] = strTbl[i];
      end
    end
  end

  return My.ConcatTbl(tTbl);
end

--// LY add end
--去除首尾空白
function My.Trim(str)
  do return (string.gsub(str, "^%s*(.-)%s*$", "%1")) end
end

function My.GetDes(key)
  local temp = DesTemp[key]
  if temp then 
    return temp.desCN
  end
  return ""
end

return My
