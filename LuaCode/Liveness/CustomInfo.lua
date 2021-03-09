--[[
 	authors 	:Liu
 	date    	:2018-7-31 16:48:08
 	descrition 	:自定义信息
--]]

CustomInfo = Super:New{Name = "CustomInfo"}

local My = CustomInfo

--获取时间文本(开启时间，持续时间)
function My:GetTimeLab(openTime, existTime)
	if openTime == nil or existTime == nil then return end
	local hour = 0
	local min = 0
	for i,v in ipairs(openTime) do
		hour = v.k
		min = v.v
	end
	local hour1 = hour
	local min1 = (existTime / 60) + min
	if min1 >= 60 then
		hour1 = hour + math.floor(min1 / 60)
		min1 = min1 % 60
	end
	local str = (min < 10) and "0"..min or min
	local str1 = (min1 < 10) and "0"..math.floor(min1) or min1
	return hour..":"..str.."-"..hour1..":"..str1
end

--转换数字(万/亿)
function My:ConvertNum(num)
	if type(num) == "string" then iTrace.Error("参数必须为number类型") return end
	if num == nil then return end
	local str = ""
    if num > 10^4 and num < 10^7 then
		str = string.format("%.2f", num/10^4).."万"
	elseif num >= 10^7 and num < 10^8 then
		str = string.format("%.1f", num/10^4).."万"
    elseif num >= 10^8 then
		str = string.format("%.2f", num/10^8).."亿"
	else
		str = num
    end
    return str
end

--使秒数转换格式
function My:ConvertSec(sec, ty)
	if type(sec) ~= "number" then return end
	local min = math.floor(sec / 60)
	local hour = (min>=60) and math.floor(min/60) or 0
	local secs = math.floor(sec % 60)
	local newMin = math.floor(min % 60)
	local minStr = (newMin<10) and "0"..newMin or newMin
	local hourStr = (hour<10) and "0"..hour or hour
	local secsStr = (secs<10) and "0"..secs or secs
	local str = ""
	if ty == nil then ty = 0 end
	if ty == 0 then
		if hour ~= 0 then
			str = string.format("%s时%s分%s秒", hourStr, minStr, secsStr)
		else
			str = string.format("%s分%s秒", minStr, secsStr)
		end
	else
		if hour ~= 0 then
			str = string.format("%s:%s:%s", hourStr, minStr, secsStr)
		else
			str = string.format("%s:%s", minStr, secsStr)
		end
	end
	return str
end

--寻找导航位置
function My:FindNavPos(itName)
	if itName == nil then return end
	local go = GameObject.Find(itName)
	if go ~= nil then
        local pos = go.transform.localPosition
		return pos
	else
		iTrace.Error("SJ", "导航位置没有找到")
	end
	return nil
end

--判断是否已经加入帮派
function My:IsJoinFamily()
    if FamilyMgr:JoinFamily() then
        return true
    else
        UITip.Log("请先加入道庭")
        return false
    end
end

--判断该活动是否已开启
function My:IsOpen(id)
	local key = tostring(id)
	local cfg = ActiveInfo[key]
	if cfg == nil then iTrace.Error("SJ", "没有找到对应配置") return end
	local needLv = cfg.needLv
	if User.MapData.Level < needLv then
		UITip.Error("至少"..needLv.."级才能参与该活动")
		return false
	end
	return true
end

--判断是否成功购买（优先消耗绑元）
function My:IsBuySucc(count)
	local info = RoleAssets
    local max = info.BindGold + info.Gold
    if max < count then
        return false
    end
    return true
end

--判断是否成功购买（限定元宝）
function My:IsSucc(count)
	local info = RoleAssets
    if info.Gold < count then
        return false
    end
    return true
end

--获取剩余秒数（不超过一天）
function My:GetRemainSec(sec)
	local sHour = self:GetTime("HH")
	local sMinute = self:GetTime("mm")
	local sSec = self:GetTime("ss")
	local totalSec = (sHour * 60 * 60) + (sMinute * 60) + sSec
	return  sec - totalSec
end

--获取服务器时间
function My:GetTime(str)
	local sTime = math.floor(TimeTool.GetServerTimeNow()*0.001)
    local val = DateTool.GetDate(sTime)
	local temp = val:ToString(str)
	local time = tonumber(temp)
    return time
end

--获取剩余时间(秒)
function My:GetLeftTime(endTime)
	local sec =  endTime - TimeTool.GetServerTimeNow()*0.001
	local val = (sec < 0) and 0 or sec
	return val
end

--设置按钮状态
function My:SetBtnState(go, stete, num)
    local wdg = go:GetComponent(typeof(UIWidget))
    local box = go:GetComponent(typeof(BoxCollider))
    if box then box.enabled = stete end
	if wdg == nil then return end
	local color = wdg.color
	color.r = num or 1
	wdg.color = color
end

--设置Enabled
function My:SetEnabled(go, stete)
	local box = go:GetComponent(typeof(BoxCollider))
    if box then box.enabled = stete end
end

--是否有该道具
function My:IsHaveItem(id)
	local count = ItemTool.GetNum(id)
	if count > 0 then
		return true
	end
	return false
end

--字典转换为列表
function My:SwitchToList(dic)
	local list = {}
	for k,v in pairs(dic) do
		table.insert(list, v)
	end
	return list
end

return My