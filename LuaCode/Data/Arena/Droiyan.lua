Droiyan = {Name = "Droiyan"}
local My = Droiyan;
My.ChallgTime = nil;
My.LeftBuyTime = nil;
My.IsReward = nil;
My.Rank = nil;
My.Challgers = nil;
My.IsSucc = nil;
My.OppPower = nil;
My.InspireNum = nil;
My.IsCanChallg = true

My.eOffline = Event();
My.eResult = Event();
My.eChangeTime = Event();
My.eIsRwd = Event();
My.eInspire = Event();
My.eRedFlag = Event()

--主界面红点显示
My.eMainRed = Event()

function My:Init()
    self:AddLsnr();
end

--添加协议监听
function My:AddLsnr()
    ProtoLsnr.AddByName("m_offline_solo_detail_toc",self.RespOfflDetail,self);
    ProtoLsnr.AddByName("m_offline_solo_info_toc",self.RespOfflineInfo,self);
    ProtoLsnr.AddByName("m_offline_solo_challenge_toc",self.ChallengeResult,self);
    ProtoLsnr.AddByName("m_offline_solo_mop_toc",self.MopChallengeResult,self);
    ProtoLsnr.AddByName("m_offline_solo_buy_challenge_toc",self.BuyChallgTime,self);
    ProtoLsnr.AddByName("m_offline_solo_reward_toc",self.RespIsRwd,self);
    ProtoLsnr.AddByName("m_offline_solo_bestir_toc",self.RespInspire,self);
end

-- Client-->Server
function My.OpenSlPanel(openType)
    local msg = ProtoPool.Get("m_offline_solo_panel_tos");
    msg.type = openType;
    ProtoMgr.Send(msg);
end

--请求离线1v1信息
function My.ReqOfflineInfo()
    local msg = ProtoPool.Get("m_offline_solo_info_tos");
    ProtoMgr.Send(msg);
end

--1请求领取奖励
function My.ReqOfflRwd()
    local msg = ProtoPool.Get("m_offline_solo_reward_tos");
    ProtoMgr.Send(msg);
end

--购买挑战次数
function My.ReqBuyChallenge(num)
    local msg = ProtoPool.Get("m_offline_solo_buy_challenge_tos");
    msg.buy_times = num
    ProtoMgr.Send(msg);
end

--请求挑战
function My.ReqChallenge(rank)
    My.IsCanChallg = false
    local msg = ProtoPool.Get("m_offline_solo_challenge_tos");
    msg.rank = rank;
    ProtoMgr.Send(msg);
end

--请求扫荡挑战
function My.ReqModChallenge(rank)
    My.IsCanChallg = false
    local msg = ProtoPool.Get("m_offline_solo_mop_tos");
    msg.rank = rank;
    ProtoMgr.Send(msg);
end

--购买鼓舞
function My.ReqInspire()
    local msg = ProtoPool.Get("m_offline_solo_bestir_tos");
    ProtoMgr.Send(msg);
end

--请求退出离线1v1
function My.ReqExitOffL()
    local msg = ProtoPool.Get("m_offline_solo_quit_tos");
    ProtoMgr.Send(msg);
end

-- Sever-->Client
--返回离线挑战详细信息
function My:RespOfflDetail(msg)
    My.ChallgTime = msg.challenge_times;
    My.LeftBuyTime = msg.buy_times;
    My.IsReward = msg.is_reward;
    My.InspireNum = msg.bestir_times;
    if My.IsReward == false or My.ChallgTime > 0 then
        My.eMainRed(true)
    elseif My.IsReward == true and My.ChallgTime <= 0 then
        My.eMainRed(false)
    end
    My.eIsRwd();
    My.eRedFlag();
end

--返回离线挑战信息
function My:RespOfflineInfo(msg)
    My.Rank = msg.my_rank;
    self:SetChallengers(msg.challengers);
    My.eOffline();
end

--设置挑战者信息
function My:SetChallengers(challengers)
    if challengers == nil then
        return;
    end
    local len = #challengers;
    if len == 0 then
        return;
    end
    My.Challgers = {}
    for i = 1, len do
        local challenger = {};
        challenger.rank = challengers[i].rank;
        challenger.role_id = challengers[i].role_id;
        challenger.role_name = challengers[i].role_name;
        challenger.sex = challengers[i].sex;
        challenger.category = challengers[i].category;
        challenger.level = challengers[i].level;
        challenger.power = challengers[i].power;
        challenger.skinList = {};
        local skLen = #challengers[i].skin_list;
        if skLen > 0 then
            for j = 1, skLen do
                challenger.skinList[j] = challengers[i].skin_list[j];
            end
        end
        My.Challgers[i] = challenger;
    end
end

--返回挑战结果
function My:ChallengeResult(msg)
    self.IsCanChallg = false
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err);
        self.IsCanChallg = true
        return;
    end
    My.IsSucc = msg.is_success;
    My.OppPower = msg.power;
    My.AddExp = msg.add_exp;
    My.Rank = msg.new_rank;
    My.ChallgTime = msg.new_challenge_times;
    My.AddHonor = msg.add_honor;
    My.TarName = msg.dest_name;
    My.eResult();
    My.eRedFlag();
    if My.ChallgTime > 0 then
        My.eMainRed(true)
    else
        My.eMainRed(false)
    end
    -- UIMgr.Open(UIOffLBat.Name);
    --self:ShowReward()
    self.IsCanChallg = true
end

--返回扫荡挑战结果
function My:MopChallengeResult(msg)
    self.IsCanChallg = false
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err);
        self.IsCanChallg = true
        return;
    end
    My.IsSucc = msg.is_success;
    My.OppPower = msg.power;
    My.AddExp = msg.add_exp;
    My.Rank = msg.new_rank;
    My.ChallgTime = msg.new_challenge_times;
    My.AddHonor = msg.add_honor;
    My.TarName = msg.dest_name;
    My.eResult();
    My.eRedFlag();
    if My.ChallgTime > 0 then
        My.eMainRed(true)
    else
        My.eMainRed(false)
    end
    -- UIMgr.Open(UIOffLBat.Name);
    self:ShowReward()
    self.IsCanChallg = true
    self:ReqOfflineInfo()
end

--检查是否跳过战斗
function My:CheckSkip()
    local isCanSkip = false
    local vipLv = VIPMgr.vipLv
    local vipCfg = VIPLv[vipLv+1]
    local isSkip = vipCfg.skipDroiyan
    if isSkip >= 1 then --跳过战斗
        isCanSkip = true
    end
    return isCanSkip
end

--修改获取奖励
function My:ShowReward()
    -- local isSkip = self:CheckSkip()
    -- if isSkip == true then
        UIMgr.Open(UIGetRewardPanel.Name, self.OnShowReward, self)
    -- end
end

function My:OnShowReward(name)
    local honorId = 11;
    local expId = 100;
    local addExp = RoleAssets.LongToNum(My.AddExp);
    addExp = math.NumToStrCtr(addExp,0);
    local addHonor = RoleAssets.LongToNum(My.AddHonor);
    addHonor = math.NumToStrCtr(addHonor,0);
    local list = {{k = honorId,v = addHonor,b = false},{k = expId,v = addExp,b = false}}
    local ui = UIMgr.Dic[name]
    if ui then
		if list then
			ui:UpdateData(list)
		else
			ui:Close()
		end
	end
end

--返回购买挑战次数
function  My:BuyChallgTime(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err);
        return;
    end
    My.ChallgTime = msg.new_challenge_times;
    My.LeftBuyTime = msg.new_buy_times;
    My.eChangeTime();
    My.eRedFlag();
    if My.ChallgTime > 0 then
        My.eMainRed(true)
    else
        My.eMainRed(false)
    end
end

--返回离线奖励领取
function My:RespIsRwd(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err);
        return;
    end
    My.IsReward = msg.is_reward;
    if My.IsReward == false then
        My.eMainRed(true)
    else
        My.eMainRed(false)
    end
    My.OffHonor = msg.add_honor
    My.eIsRwd();
    My.eRedFlag();
    -- local str = string.format( "获得%s荣誉",msg.add_honor);
    -- UITip.Log(str);
    local honor = My.OffHonor
    if honor == nil or honor <= 0 then
        return
    end
    self:ShowHonorReward()
end

--显示离线荣誉奖励
function My:ShowHonorReward()
    UIMgr.Open(UIGetRewardPanel.Name, self.OnShowHonorReward, self)
end

function My:OnShowHonorReward(name)
    local honorId = 11;
    local honor = My.OffHonor
    local honor = RoleAssets.LongToNum(honor);
    honor = math.NumToStrCtr(honor,0);
    local list = {{k = honorId,v = honor,b = false}}
    local ui = UIMgr.Dic[name]
    My.OffHonor = nil
    if ui then
		if list then
			ui:UpdateData(list)
		else
			ui:Close()
		end
    end
end

--鼓舞返回
function My:RespInspire(msg)
    if msg.err_code ~= 0 then
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err);
        return;
    end
    My.InspireNum = msg.bestir_times;
    My.eInspire();
    UITip.Log("鼓舞成功");
end

--获取鼓舞后的战力
function My.GetInspireFightVal(fValue)
    local inspireNum = Droiyan.InspireNum;
    if inspireNum == nil then
        inspireNum = 0
    end
    local addValPst = GlobalTemp["66"].Value3;
    local fightVal = fValue;
    fightVal = fightVal + fightVal * inspireNum * addValPst * 0.01;
    return fightVal;
end

function My:Clear()
    My.ChallgTime = nil;
    My.LeftBuyTime = nil;
    My.IsReward = nil;
    My.Rank = nil;
    My.Challgers = nil;
    My.IsSucc = nil;
    My.OppPower = nil;
    My.IsCanChallg = true
end

function My:Dispose()
    self:Clear();
end

return My