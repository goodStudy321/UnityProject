require("Data/Arena/PeakRankInfo")
Peak = {Name = "Peak"}
local My = Peak;

My.PeakIsOpen = false;
My.RoleInfo = {}
My.DanRwdLst = {}
My.RecEntLst = {}
My.MyRank = nil;
My.Ranks = {}
My.PlayerRanks = {}
My.FightResult = {}
My.ReBoxRed = {}
My.eMatch = Event();
My.eMatchSucc = Event();
My.eEntRwdChange = Event();
My.eRankInfo = Event();
My.eEnterTime = Event();
My.ePeakActiv = Event();
My.eScore= Event();
My.eSWinTimes = Event();
My.eSEntTimes = Event();
My.eExp = Event();
My.eDanRwdList = Event();
My.eRedFlag = Event()
My.eBoxRed = Event()

--主界面倒计时
My.eUpTimer = Event()
My.eEndTimer = Event()

function My:New(o)
    o = o or {}
    setmetatable(o,self);
    self.__index = self;
    return o;
end

function My:Init()
    --创建计时器
    self:CreateTimer()
    self:AddLsnr();
end

function My:AddLsnr()
    ProtoLsnr.AddByName("m_solo_role_info_toc",self.RespRoleInfo,self);
    ProtoLsnr.AddByName("m_solo_role_info_update_toc",self.RespRoleInfoUpdate,self);
    ProtoLsnr.AddByName("m_solo_rank_info_toc",self.RespSoloRank,self);
    ProtoLsnr.AddByName("m_solo_match_toc",self.RespMatch,self);
    ProtoLsnr.AddByName("m_solo_enter_reward_toc",self.RespEntRwd,self);
    ProtoLsnr.AddByName("m_solo_match_ready_toc",self.RespSoloMSucc,self);
    ProtoLsnr.AddByName("m_solo_result_toc",self.RespResult,self);
    ProtoLsnr.AddByName("m_solo_step_reward_toc",self.RespDanRwd,self);
end

function My:RemoveLsnr()
    ProtoLsnr.RemoveByName("m_solo_role_info_toc",self.RespRoleInfo,self);
    ProtoLsnr.RemoveByName("m_solo_role_info_update_toc",self.RespRoleInfoUpdate,self);
    ProtoLsnr.RemoveByName("m_solo_rank_info_toc",self.RespSoloRank,self);
    ProtoLsnr.RemoveByName("m_solo_match_toc",self.RespMatch,self);
    ProtoLsnr.RemoveByName("m_solo_enter_reward_toc",self.RespEntRwd,self);
    ProtoLsnr.RemoveByName("m_solo_match_ready_toc",self.RespSoloMSucc,self);
    ProtoLsnr.RemoveByName("m_solo_result_toc",self.RespResult,self);
    ProtoLsnr.RemoveByName("m_solo_step_reward_toc",self.RespDanRwd,self);
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown,self)
    timer.complete:Add(self.EndCountDown,self)
end

--间隔倒计时
function My:InvCountDown()
    local time = self.timer:GetRestTime()
    time = math.floor(time)
    self.eUpTimer(time)
end

--结束倒计时
function My:EndCountDown()
    self.eEndTimer()
end

--1v1匹配请求
function My.ReqSoloMatch(type)
    local msg = ProtoPool.Get("m_solo_match_tos");
    msg.type = type;
    ProtoMgr.Send(msg);
end

--1v1进入次数奖励请求
function My.ReqSoloEnterRwd(type)
    local msg = ProtoPool.Get("m_solo_enter_reward_tos");
    msg.type = type;
    ProtoMgr.Send(msg);
end

--请求排行榜信息
function My.ReqSoloRank()
    local msg = ProtoPool.Get("m_solo_rank_info_tos");
    ProtoMgr.Send(msg);
end

--请求段位奖励领取
function My.ReqSoloDanRwd(danId)
    local msg = ProtoPool.Get("m_solo_step_reward_tos");
    msg.step = danId;
    ProtoMgr.Send(msg);
end

--1v1pk信息推送
function My:RespRoleInfo(msg)
    My.RoleInfo.score = msg.score; --当前积分
    My.RoleInfo.seasonWinTimes = msg.season_win_times; --赛季胜利场次
    My.RoleInfo.seasonEntTimes = msg.season_enter_times; --赛季参与次数
    My.RoleInfo.enterTime = msg.enter_times; --今天参与次数
    My.RoleInfo.bMatch = msg.is_matching; --是否在匹配中
    My.RoleInfo.exp = RoleAssets.LongToNum(msg.exp); --当天获得经验
    self:SetEntRwdLst(msg.enter_reward_list);--当天已经领取参与奖励列表
    self:SetDanRwdLst(msg.step_reward_list); --段位奖励

    My.RoleInfo.seasonStartTimes = msg.start_time --赛季开始时间
    My.RoleInfo.seasonStopTimes = msg.stop_time --赛季结束时间,0代表是在单服
    My.RoleInfo.season = msg.season --赛季次数,0代表是在单服

    self:BoxRedState()
end

--1v1pk信息更新
function My:RespRoleInfoUpdate(msg)
    local len = #msg.kb_list;
    for i = 1,len do
        local item = msg.kb_list[i];
        if item.id == 5 then
            self:SetMatch(item.val);
        end
    end
    len = #msg.kl_list;
    for i = 1,len do
        local item = msg.kl_list[i];
        if item.id == 4 then
            self:SetEntRwdLst(item.list);
        elseif item.id == 9 then
            self:SetDanRwdLst(item.list);
        end
    end
    len = #msg.kv_list;
    for i = 1,len do
        local item = msg.kv_list[i];
        local id = tonumber(item.id);
        local val = tonumber(item.val);
        if id == 1 then
            My.RoleInfo.score = val;
            My.eScore();
        elseif id == 3 then
            self:RespEntTime(val);
        elseif id == 6 then
            My.RoleInfo.seasonEntTimes = val;
            My.eSEntTimes();
        elseif id == 7 then
            My.RoleInfo.seasonWinTimes = val;
            My.eSWinTimes();
        elseif id == 8 then
            My.RoleInfo.exp = val;
            My.eExp();
        end
    end
    self:BoxRedState()
end

--设置段位奖励列表
function My:SetDanRwdLst(list)
    if list == nil then
        return;
    end
    local len = #list;
    for i = 1,len do
        local danId = list[i];
        My.DanRwdLst[danId] = 1;
    end
    My.eDanRwdList();
end

--设置进入奖励列表
function My:SetEntRwdLst(list)
    if list == nil then
        return;
    end
    local len = #list;
    for i = 1,len do
        My.RecEntLst[list[i]] = 1;
    end
    My.eEntRwdChange();
end

--匹配返回
function My:RespMatch(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err)
        return;
    end
    if msg.type == 1 then
        self:SetMatch(true);
    else
        self:SetMatch(false);
    end
end

--设置匹配
function My:SetMatch(val)
    My.RoleInfo.bMatch = val;
    My.eMatch();
end

--匹配成功
function My:RespSoloMSucc()
    My.eMatchSucc();
end

--进入次数奖励
function My:RespEntRwd(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err)
        return;
    end
    self:SetEntRwdLst(msg.enter_list);
    self:BoxRedState()
end

--领取单位奖励返回
function My:RespDanRwd(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err)
        return;
    end
    local id = My.DanRwdLst[msg.step];
    if id ~= nil then
        return;
    end
    My.DanRwdLst[msg.step] = 1;
    My.eDanRwdList();
end

--排行信息返回
function My:RespSoloRank(msg)
    self:SetMyRank(msg.my_rank);
    self:SetRanks(msg.ranks);
    My.eRankInfo();
end

--设置自己排行
function My:SetMyRank(myRank)
    if myRank == nil then
        return;
    end
    if My.MyRank == nil then
        My.MyRank = PeakRankInfo:New();
    end
    My.MyRank:SetData(myRank.rank,myRank.role_id,myRank.role_name,myRank.score,myRank.power,myRank.server_name,myRank.category);
end

--设置总排行
function My:SetRanks(rankLst)
    local len = #rankLst;
    My.PlayerRanks = rankLst
    for i = 1, len do
        local roleId = tostring(rankLst[i].role_id);
        local rank = My.Ranks[roleId];
        if rank == nil then
            rank = PeakRankInfo:New();
            My.Ranks[roleId] = rank;
        end
        rank:SetData(rankLst[i].rank,rankLst[i].role_id,rankLst[i].role_name,rankLst[i].score,rankLst[i].power,rankLst[i].server_name,rankLst[i].category);
    end
end

--进入次数返回
function My:RespEntTime(entTime)
    if entTime == nil then
        entTime = 0;
    end
    My.RoleInfo.enterTime = entTime;
    My.eEnterTime();
end

--奖励box红点
function My:BoxRedState()
    self:ClearReTab()
    local boxRed = {}
    local enterTime = My.RoleInfo.enterTime
    local rewardTab = My.RecEntLst
    for i = 1,#OvORwd do
        local cfg = OvORwd[i]
        local time = cfg.times
        if enterTime >= time and rewardTab[time] == nil then
            boxRed[i] = 1
        end
    end
    My.ReBoxRed = boxRed
    My.eBoxRed()
end


--战斗结果返回
function My:RespResult(msg)
    local result = My.FightResult;
    result.IsSucc = msg.is_success;
    result.soloRoleId = msg.solo_role_id;
    result.soloRName = msg.solo_role_name;
    local newScore = msg.new_score;
    result.AddScore = newScore - My.RoleInfo.score;
    result.NewScore = newScore;
    result.AddExp = msg.add_exp;
    My.RoleInfo.score = newScore;
    My.eScore();
    UIMgr.Open(UIPeakResult.Name);
end

--即时1v1活动状态
function My.RespPeakActiv(isOpen,endTime)
    if isOpen == 2 then
        My.PeakIsOpen = true;
        local sTime = math.floor(TimeTool.GetServerTimeNow()/1000)
		local leftTime = endTime - sTime
		My.timer:Restart(leftTime, 1)
    elseif isOpen == 3 then
        My.PeakIsOpen = false;
    end
    My.eRedFlag()
    My.ePeakActiv();
end

--根据积分获取段位信息
function My:GetDanInfoByScr(score)
    local len = #OvODanRwd;
    if score >= OvODanRwd[len].score then
        return OvODanRwd[len];
    end
    for i = 1, len do
        if OvODanRwd[i].score <= score and score < OvODanRwd[i+1].score then
            return OvODanRwd[i];
        end
    end
    return nil;
end

--获取排行奖励
--type:1:单服奖励    2：跨服奖励
function My:GetPVPRankRe(type)
    local cfg = PVPRankReCfg
    local temp = {}
    for i = 1,#cfg do
        local data = cfg[i]
        if data.type == type then
            table.insert(temp,data)
        end
    end
    return temp
end

function My:ClearReTab()
    for k,v in pairs(My.ReBoxRed) do
        My.ReBoxRed[k] = nil
    end
end

function My:Clear()
    My.PeakIsOpen = false;
    My.RoleInfo = {}
    My.RecEntLst = {}
    My.MyRank = nil;
    My.Ranks = {}
    My.PlayerRanks = {}
    My.FightResult = {}
    My.ReBoxRed = {}
    --停止计时器
    if My.timer then My.timer:Stop() end
end

function My:Dispose()
    My.PeakIsOpen = nil;
    My.RoleInfo = nil;
    My.RecEntLst = nil;
    My.MyRank = nil;
    My.Ranks = nil;
    My.PlayerRanks = nil
    My.FightResult = nil;
    My.ReBoxRed = nil
    self:RemoveLsnr();
end

return My