WBRcvHp = {Name = "WBRcvHp"}
local My = WBRcvHp;
My.rcvHpPer = 0;
My.costGold = 0;
My.rcvCount = 0;
My.rcvCd = 0;
My.eChgCount = Event();

--回血CD计时器
My.RcvTimer = nil;

function My:Init()
    self:AddLsnr();
    My.RefreshData();
end

--刷新数据
function My.RefreshData()
    local info = GlobalTemp["132"];
    if info == nil then
        return;
    end
    local values = info.Value2;
    local rcvHpPer = values[1];
    if rcvHpPer ~= nil then
        My.rcvHpPer = rcvHpPer;
    end

    local rcvCd = values[3];
    if rcvCd ~= nil then
        My.rcvCd = rcvCd;
    end

    My.RefreshCost();
end

--刷新消耗
function My.RefreshCost()
    local info = GlobalTemp["132"];
    if info == nil then
        return;
    end
    local values = info.Value2;
    local nextCount = My.rcvCount + 4;
    local costGold = values[nextCount];
    if costGold == nil then
        local len = #values;
        costGold = values[len];
    end
    if costGold ~= nil then
        My.costGold = costGold;
    end
end

function My:AddLsnr()
    local PA =  ProtoLsnr.AddByName;
    PA("m_world_boss_hp_recover_toc",self.RcvHp,self)
    PA("m_world_boss_hp_recover_num_toc",self.RcvCount,self);
end

--世界boss单位购买血量返回
function My:RcvHp(msg)
    local errCode = msg.err_code;
    if errCode ~= 0 then
        local err = ErrorCodeMgr.GetError(errCode);
        UITip.Log(err)
        return;
    end
    local str = string.format( "已恢复%d%%血量",My.rcvHpPer);
    UITip.Log(str);
    self:RcvCount(msg);
    self:StartTimer();
end

--恢复次数
function My:RcvCount(msg)
    My.rcvCount = msg.hp_recover_num;
    My.RefreshCost();
    My.eChgCount();
end

--请求血量恢复
function My:ReqRcvHp()
    local gold = RoleAssets.GetCostAsset(2);
    if My.costGold > gold then
        UITip.Log("元宝不足")
        return;
    end
    local msg = ProtoPool.Get("m_world_boss_hp_recover_tos")
    ProtoMgr.Send(msg);
end

--开始计时
function My:StartTimer()
    if My.RcvTimer == nil then
        My.RcvTimer = ObjPool.Get(iTimer);
    end
    My.RcvTimer:Stop();
    My.RcvTimer.seconds = My.rcvCd;
    My.RcvTimer:Start();
end

--获取恢复CD时间
function My.GetRcvCD()
    local timer = My.RcvTimer;
    if timer == nil then
        return 0;
    end
    return timer.pro;
end

--是否在cd中
function My.RcvRunning()
    local timer = My.RcvTimer;
    if timer == nil then
        return false;
    end
    return timer.running;
end