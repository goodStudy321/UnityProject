--[[
 	author 	    :Loong
 	date    	:2018-01-30 21:00:40
 	descrition 	:数学扩展
--]]

local My = math
math.randomseed(os.time())

--四舍五入
function My.round(val)
	val = val or 0
	val = val + 0.5
	val = math.floor(val)
	return val
end
--agr是否不保留两位小数,为nil时候保留2位
function My.NumToStr(val, agr)
	if agr==nil then
		agr=2
	else 
		agr=0
	end
	local retStr = My.NumToStrCtr(val, agr)
	return retStr
end
--控制小数的转换
-- cNum：需要转换数字
-- dNum：需要保留小数位数（最多为3位）
--如果传入nil则默认为整数
function My.NumToStrCtr(val, dNum)
		if val == nil or type(val) ~= "number" then
			val = tostring(val)
			val = tonumber(val)
			if val == nil or type(val) ~= "number" then
		     iTrace.Error("soon", "val is not number type "..type(val))
	   	   return ""
			end
	  end
	  if dNum==nil then dNum=0  end
	  local retStr = "";
	  local pla = 1
	  local str = ""
	  if val >= 10000000000000 then
		pla=1000000000000
		str="万亿"
	  elseif val >= 1000000000 then
		pla=100000000
		str="亿"
	  elseif val >= 100000 then
		pla=10000
		str="万"
	  else
		retStr = tostring(val)
	  end
	  local num = val/pla
	  local y, yy = math.modf(num)
	  if yy < 0.1^dNum then
		retStr = tostring(y);
	  else
	   retStr = My.ReDec(num, dNum)
	  end
	  retStr = retStr..str
	  return retStr
	end

--// 保留小数（最多3位）
function My.ReDec(val, dNum)
	if dNum < 0 then
	  dNum = 0;
	elseif dNum > 3 then
	  dNum = 3;
	end
	local retStr = "";
	if dNum == 0 then
	  retStr = string.format("%.0f", val);
	elseif dNum == 1 then
	  retStr = string.format("%.1f", val);
	elseif dNum == 2 then
	  retStr = string.format("%.2f", val);
	elseif dNum == 3 then
	  retStr = string.format("%.3f", val);
	end
  
	return retStr;
	end
	
	--64位转32数字
function My.LongToNum(value)
	if value == nil then
			return 0;
	end
	local val = tostring(value);
	val = tonumber(val);
	return val;
end
