ActvHelper = {Name="ActvHelper"}
local My = ActvHelper;
My.Days = {"一","二","三","四","五","六","日"}

function My:Init()

end

--获取活动时间字符串
function  My.GetActTime(activeId)
    local week = My.GetWeek(activeId);
    local time = My.GetTime(activeId);
    week = string.format("%s  %s",week,time);
    return week;
end

--获取星期
function My.GetWeek(activeId)
    local info = ActiveInfo[tostring(activeId)];
    if info == nil then
        return;
    end
    local len = #info.begDay;
    if len == 0 then
        return "";
    end
    local week = "周";
    for i = 1,len do
        local day = info.begDay[i];
        week = week .. My.Days[day];
        if i ~= len then
            week = week .. "、";
        end
    end
    return week;
end

--获取具体时间
function My.GetTime(activeId)
    local info = ActiveInfo[tostring(activeId)];
    if info == nil then
        return;
    end
    local time = "";
    local tmpTime = nil;
    len = #info.begTime;
    for i = 1,len do
        local min = nil;
        local hour = nil;
        local k = info.begTime[i].k;
        local v = info.begTime[i].v;
        hour = string.format("%02d",k);
        min = string.format("%02d",v);
        
        local lstTime = info.lastTime/3600;
        lstTime = math.modf(lstTime);
        local lstHour = k;
        lstHour = lstHour + lstTime;
        local lstMin = math.fmod(info.lastTime,3600);
        local lmin,rmin = math.modf(lstMin/60);
        if rmin > 0 then
            lmin = lmin + 1;
        end
        lstMin = lmin + v;
        lstTime = math.modf(lstMin/60);
        lstMin = math.fmod(lstMin,60);
        lstHour = lstHour + lstTime;
        lstHour = math.fmod(lstHour,24);
        lstHour = string.format("%02d",lstHour);
        lstMin = string.format( "%02d", lstMin);
        tmpTime = string.format("%s:%s-%s:%s",hour,min,lstHour,lstMin);
        if i == 1 then
            time = tmpTime;
        else
            time = string.format("%s,%s",time,tmpTime);
        end
    end
    return time;
end

--进入道庭守卫
function My.EnterFmlDft()
	local info = ActiveInfo["10003"];
	if info == nil then
		return false;
	end
	if info.needLv > User.MapData.Level then
		local str = string.format("等级不足,需要%s级",info.needLv);
		UITip.Log(str);
		return false;
	end
    local isOpen = ActivityMsg.ActIsOpen(10003);
    if isOpen == false then
        UITip.Log("守卫道庭未开放");
        return false;
    end
    local joinFml = FamilyMgr:JoinFamily();
    if joinFml == false then
        UITip.Log("请先加入道庭");
        return;
    end
    SceneMgr:ReqPreEnter(30003, true, true);
    return true;
end

--数字排名转字符
function My.RankToStr(rank)
    if rank == nil then
        return "";
    end
    local str = nil;
    if rank < 10 then
        str = string.format("0%s",rank);
    else
        str = tostring(rank);
    end
    return str;
end

function My:Clear()

end

function My:Dispose()

end

return My;