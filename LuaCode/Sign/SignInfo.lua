--[[
 	authors 	:Liu
 	date    	:2018-5-15 18:28:08
 	descrition 	:签到信息
--]]

SignInfo = {Name = "SignInfo"}

local My = SignInfo

function My:Init()
	--字符串列表
	self.strList = {"一", "二", "三", "四", "五", "六", "七", "八", "九", "十"}
	--今天是否已签到
	self.isSign = false
	--奖励列表
	self.SignAwardList = {}
	--签到次数
	self.SignCount = 0
end

--是否已经领取过累签奖励
function My:IsGetAward(id)
	for i,v in ipairs(self.SignAwardList) do
		if v == id then
			return true
		end
	end
	return false
end

--获取签到次数
function My:GetSignCount()
	local temp = self.SignCount % 30
    local num = (temp==0) and 30 or temp
    local isEnd = (not self.isSign) and (num == 30)
	local count = (isEnd) and 0 or num
	return count
end

--清空列表
function My:ClearList()
	ListTool.Clear(self.SignAwardList)
end

--获取活动时间
function My:GetActivTime(days)
	local time = ""
	local index = 0
    local dayList = self.strList
	if #days == 0 then
		time = "每天"
	else
		for i,v in ipairs(days) do
			if v == 8 then
				time = "每天"
				break
			else
				index = index + 1
				if i == #days then
					if v == 7 then
						time = "周"..time.."日"
					else
						time = "周"..time..dayList[v]
					end
				else
					time = time..dayList[v].."、"
				end
			end
		end
	end
	if index >= 7 then time = "每天" end
    return time
end

--获取服务器时间
function My:GetTime(str)
	local sTime = math.floor(TimeTool.GetServerTimeNow()/1000)
    local val = DateTool.GetDate(sTime)
	local time = val:ToString(str)
	local day = tonumber(time)
    return day
end

--判断活动是否开启
function My:IsActivOpen(lastTime ,hour, minute, isSec)
    local lastMinute = lastTime / 60
    local sHour = self:GetTime("HH")
    local sMinute = self:GetTime("mm")
    --根据当前时间判断活动是否开启
    local h = hour
    local min = minute + lastMinute
	if min >= 60 then
		h = h + math.floor(min / 60)
		min = min % 60
    end
    local sTime = hour + (minute / 100)  		--开始时间
    local eTime = h + (min / 100)              	--结束时间
	local nTime = sHour + (sMinute / 100)       --当前时间
	-- iTrace.Log("sTime = "..sTime.." eTime = "..eTime.." nTime = "..nTime)
	if nTime >= sTime and nTime < eTime then--活动开启中
		if isSec then--获取活动剩余时间(秒)
			local sSec = self:GetTime("ss")
			local rHour = h - sHour
			local rMin = (rHour * 60) + (min - sMinute)
			local rSec = (rMin * 60) + (60 - sSec)
			return 1,rSec
		else
			return 1
		end
    elseif nTime >= eTime then--活动已结束
        return 2
    else--活动未开启
        return 0
    end
end

--清理缓存
function My:Clear()
	self.isSign = false
	self.SignCount = 0
	self:ClearList()
end

--释放资源
function My:Dispose()
	self:Clear()
end

return My