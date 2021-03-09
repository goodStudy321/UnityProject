require("Data/Rank/BatRankInfo")
ThrUniBattle = {Name="ThrUniBattle"}
local My = ThrUniBattle
My.eTime = Event();
My.eRank = Event();
My.ranks = {}
My.ThrIsOpen = false;

My.eUpTimer = Event()
My.eEndTimer = Event()
My.eRedFlag = Event()

function My:Init()
    self.Timer = ObjPool.Get(DateTimer)
	self.Timer.invlCb:Add(self.InvCountDown, self)
    self.Timer.complete:Add(self.EndCountDown, self)
    self:AddEvent();
end

function My:AddEvent()
    ProtoLsnr.AddByName("m_battle_rank_info_toc",self.RspBatRank, self);
    ProtoLsnr.AddByName("m_battle_combo_kill_toc",self.RspBatComKill, self);
    ProtoLsnr.AddByName("m_battle_end_combo_kill_toc",self.RspBatEndCKill, self)
end

function My:BatTimeInfo(infoList)
    local time = infoList.end_time;
    local sTime = math.floor(TimeTool.GetServerTimeNow()/1000);
    local leftTime = time - sTime;
    if leftTime > 0 then
        My.ThrIsOpen = true
    else
        My.ThrIsOpen = false
    end
    self.Timer.seconds = leftTime;
    self.Timer:Start();
    My.eRedFlag()
    My.eTime();
end

--战场排行信息
function My:RspBatRank(msg)
    local count = #msg.ranks;
    if count == 0 then
        return;
    end
    self:ClearRanks();
    local ranks = msg.ranks;
    for i = 1,count do
        local rank = BatRankInfo:New();
        rank:SetInfo(ranks[i].rank,ranks[i].role_id,ranks[i].role_name,ranks[i].role_level,ranks[i].score,ranks[i].power,ranks[i].camp_id);
        local roleId = tostring(ranks[i].role_id);
        My.ranks[roleId] = rank;
    end
    My.eRank();
end

function My:RspBatComKill(msg)
    local tipInfo = self.GetBatKillInfo(msg.kill_num);
    if tipInfo == nil then
        return;
    end
    local msg = string.format( "%s%s", msg.role_name, tipInfo.killTip);
    UITip.Log(msg);
end

function My:RspBatEndCKill(msg)
    local tipInfo = self.GetBatKillInfo(msg.kill_num);
    if tipInfo == nil then
        return;
    end
    local msg = string.format("%s%s被%s终结！",msg.killed_role_name ,tipInfo.endKillNum, msg.kill_role_name);
    UITip.Log(msg);
end

function My.GetBatKillInfo(killNum)
    local len = #BatKillTip;
    if killNum >= BatKillTip[len].killNum then
        return BatKillTip[len];
    end
    for k,v in pairs(BatKillTip) do
        if killNum >= v.killNum and killNum < BatKillTip[k+1].killNum then
            return v;
        end
    end
    return nil;
end

function My:InvCountDown()
    local time = My.Timer:GetRestTime()
    time = math.floor(time)
    My.eUpTimer(time)
    My.eTime();
end

function My:EndCountDown()
    My.eEndTimer()
    My.eTime();
end

function My:ClearRanks()
    for k,v in pairs(My.ranks) do
        v:Dispose();
        My.ranks[k] = nil;
    end
end

function My:Clear()
    My.ThrIsOpen = false
    self.ClearRanks();
    if self.Timer then self.Timer:Stop() end
end

function My:Dispose()
    self.Clear();
    My.ThrIsOpen = nil
    My.ranks = nil;
end

return My