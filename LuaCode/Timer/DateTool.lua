--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-08-21 20:04:02
-- 日期工具
--==============================================================================


DateTool = {Name = "DateTool"}

local My = DateTool
My.sb = {}
local TimeSpan = System.TimeSpan
local DateTime = System.DateTime

local minuThold = 60
local hourThold = minuThold * minuThold
local dayThold = 24 * hourThold
My.dayThold=dayThold;
My.hourThold=hourThold;
local beg = TimeTool.Beg

--通过秒数时间 格式化
--sec(number):秒数
--op(number):格式化选项,如下:
--(0:00天00时00分00秒,1:00D00H00M00S,2:00d00h00m00s,3:00:00:00:00)
--apdOp:位数选项0:无, 1:至少分数两位 2:至少小时两位,3:至少天数两位 4:保持两位
--d2h(boolean):true,天转换成小时

--当前时间已经除以1000
function My.GetServerTimeSecondNow()
  return TimeTool.GetServerTimeNow()*0.001;
end

function My.FmtSec(sec, op, apdOp, d2h)
  op = op or 0
  d2h = d2h or false
  apdOp = apdOp or 0
  local dd, hh, mm, ss = My.GetFmt(op)
  return My.Format(sec, d2h, dd, hh, mm, ss, apdOp)
end

--毫秒
function My.FmtSS(ss)
  local x,xx=math.modf(ss/1000)
  local str = My.FmtSec(x,3,1)
  local sStr = math.floor( xx*1000 )
  return string.format( "%s.%s",str,sStr)
end

--获取格式化字符
function My.GetFmt(op)
  local m, s = My.GetLastTwo(op)
  if op == 0 then
    return "天", "时", m, s
  elseif op == 1 then
    return "D", "H", m, s
  elseif op == 2 then
    return "d", "h", m, s
  else
    return ":", ":", m, s
  end
end

function My.GetLast(op)
  if op == 0 then return "秒"
  elseif op == 1 then return "S"
  elseif op == 2 then return "s"
  else return "" end
end

function My.GetLastTwo(op)
  if op == 0 then return "分", "秒"
  elseif op == 1 then return "M", "S"
  elseif op == 2 then return "m", "s"
  else return ":", "" end
end

--格式化时间跨度
--d2h(boolean):秒数
--dd(string):天字符
--hh(string):时字符
--mm(string):分字符
--ss(string):秒字符
function My.Format(sec, d2h, dd, hh, mm, ss, apdOp)
  local sb = My.sb
  dd = dd or "天"
  hh = hh or "时"
  mm = mm or "分"
  ss = ss or "秒"
  if d2h == nil then d2h = false end
  ListTool.Clear(sb)
  local DivAndMod = My.DivAndMod
  local day, hour, minu, remain = 0, 0, 0, 0
  day, remain = DivAndMod(sec, dayThold)
  hour, remain = DivAndMod(remain, hourThold)
  minu, remain = DivAndMod(remain, minuThold)
  --print("minu:", minu, "remain:", remain)
  sec = remain
  if d2h then
    if (day > 0) then
      hour = day * 24 + hour
    end
  elseif day > 0 then
    if (apdOp > 2) and (hour < 10) then
      sb[#sb + 1] = 0
    end
    sb[#sb + 1] = day
    sb[#sb + 1] = dd
  end

  if (#sb > 0) or (hour > 0) then
    if apdOp > 1 and (hour < 10) then
      sb[#sb + 1] = 0
    end
    sb[#sb + 1] = hour
    sb[#sb + 1] = hh
  elseif (apdOp > 1) and (apdOp < 4) then
    sb[#sb + 1] = "00"
    sb[#sb + 1] = hh
  end

  if (#sb > 0) or (minu > 0) then
    if apdOp > 0 and (minu < 10) then
      sb[#sb + 1] = 0
    end
    sb[#sb + 1] = minu
    sb[#sb + 1] = mm
  elseif (apdOp > 0) and (apdOp < 4) then
    sb[#sb + 1] = "00"
    sb[#sb + 1] = mm
  end

  if (#sb > 0) or (sec > 0) then
    if apdOp > 0 and (sec < 10) then
      sb[#sb + 1] = 0
    end
    sb[#sb + 1] = sec
    sb[#sb + 1] = ss
  end
  local str = table.concat(sb)
  return str
end

function My.GetDay(sec)
  return My.DivAndMod(sec, dayThold)
end

function My.GetHour(sec)
  return My.DivAndMod(sec, hourThold)
end

function My.GetMinu(sec)
  return My.DivAndMod(sec, minuThold)
end

--求时间商和余数
--sec(number):总时间
--thold(number):阈值
function My.DivAndMod(sec, thold)
  local res, remain = 0, 0
  if sec < thold then
    remain = math.round(sec)
  else
    res = math.floor(sec / thold)
    remain = sec - res * thold
    remain = math.round(remain)
  end
  return res, remain
end

--通过时间戳(秒) 获取目标日期
--返回(DateTime)
--sec:(时间戳)秒数
function My.GetDate(sec)
  local v = TimeSpan.FromSeconds(sec)
  local e = beg + v
  return e
end

--通过时间戳 获取当月总天数
function My.DaysInMonth(sec)
  local dt = My.GetDate(sec)
  local days = DateTime.DaysInMonth(dt.Year, dt.Month)
  return days
end

--获取今天时间戳(秒)
function My.GetTimestamp()
  local today = os.date("*t")
  local timeTbl = {day=today.day, month=today.month,year=today.year, hour=today.hour, minute=today.min, second=today.sec}
  local todaySecs = os.time(timeTbl)
  return todaySecs;
end

--是否是今天
function My.IsToday(timestamp)
  local today = os.date("*t")
  local timeTbl = {day=today.day, month=today.month,year=today.year, hour=0, minute=0, second=0}
  local todaySecs = os.time(timeTbl)
  if timestamp >= todaySecs and timestamp < todaySecs + 24 * 60 * 60 then
      return true
  else
      return false
  end
end

--时间戳差值（eg:周二11：00-周一9：00之间的时间差值）
--day,hour,min 到 hDay,hHour,hMin 之间的差值
function My.SecondsLerp(day,hour,min,second,hDay,hHour,hMin,hSecond)
  local lerpDay ,lerpHour,lerpMin,lerpSecond=0,0,0,0
  if day>hDay then 
    lerpDay =  7-day+hDay           
  else
    lerpDay = hDay - day
  end
  if hour > hHour then 
    lerpHour = -(hour - hHour)
  else
    lerpHour = hHour - hour
  end
  if min > hMin then 
    lerpMin = -(min - hMin);
  else
    lerpMin = hMin - min;
  end
  if second > hSecond then 
    lerpSecond = -(second - hSecond);
  else
    lerpSecond = hSecond - second;
  end
  return lerpDay*24*3600+lerpHour*3600+lerpMin*60+lerpSecond
end

return My
