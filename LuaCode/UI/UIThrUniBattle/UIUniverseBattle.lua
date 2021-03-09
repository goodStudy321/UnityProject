require("Data/Rank/CampInfo")
require("Data/Rank/ThrUniBattle")
require("UI/UIThrUniBattle/RankInteg")
require("UI/UIThrUniBattle/RankRwd")
UIUniverseBattle = UIBase:New{Name = "UIUniverseBattle"}
local My = UIUniverseBattle
local TUB = ThrUniBattle;
local GO = UnityEngine.GameObject;
My.CampIconStr = {"仙","魔","佛"}
My.CampInfoLst = {}
--奖励格子加载完成计数
My.RewardLCN = 0;
My.NextScore = 0;
--奖励格子
My.RewardCells = {}

function My:InitCustom()
    local root = self.root;
    local name = "三界战场界面";
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;
    self.BatRankG = TF(root,"BattleRank",name);
    self.RankRwdG = TF(root,"BattleRanKRwd",name);
    self.BatRankG:SetActive(false);
    self.RankRwdG:SetActive(false);
    self.IntegralG = TF(root,"IntegralInfo",name);
    self.CurCmpIcom = CG(UILabel,root,"IntegralInfo/OwnerCampIcon",name,false);
    self.LeftTime = CG(UILabel,root,"IntegralInfo/TimeCount",name,false);
    self.CurRank = CG(UILabel,root,"IntegralInfo/CurRank",name,false);
    self.Integral = CG(UILabel,root,"IntegralInfo/Integral",name,false);
    self.IntegralDesc = CG(UILabel,root,"IntegralInfo/IntegralDesc",name,false);
    self.RewardTbl = CG(UITable,root,"IntegralInfo/RewardTable",name,false);
    self.ExitTipG = TF(root,"ExitTip",name);
    self.ExitTip = CG(UILabel,root,"ExitTip/TimeCount",name,false);
    self.ExitTipG:SetActive(false);
    self.RewardG = TF(root,"IntegralInfo/RewardTable",name);
    for i = 1,3 do
        local campInfo = CampInfo:New();
        local path = "IntegralInfo/Camp" .. tostring(i);
        local campSub = "/Camp";
        local campPath = path .. campSub;
        local peoSub = "/PeopleNum";
        local peoPath = path .. peoSub;
        local intgSub = "/CampIntegral";
        local intgPath = path .. intgSub;
        campInfo.campIcon = CG(UILabel,root,campPath,name,false);
        campInfo.campPeo = CG(UILabel,root,peoPath,name,false);
        campInfo.campIntg = CG(UILabel,root,intgPath,name,false);
        campInfo.campId = i;
        My.CampInfoLst[i] = campInfo;
    end
    UC(root,"IntegralInfo/RkRwdBtn",name,self.RkRwdC,self);
    UC(root,"IntegralInfo/IntegBtn",name,self.IntegC,self);
    UC(root,"ExitBtn",name,self.ExitC,self);
    self.ExitBtn = TF(root,"ExitBtn",name);
    self.IntgDone = TF(root,"IntegralInfo/IntegralDone",name);
    self.IntgDone.gameObject:SetActive(false);
    UITool.SetLiuHaiAnchor(root, "IntegralInfo", name, true)
    self:SetCurCmpIcom();
    
    self.RankRwd = RankRwd:New();
    self.RankInteg = RankInteg:New();
end

function My:AddLsnr()
    TUB.eTime:Add(self.SetLeftTime,self);
    TUB.eRank:Add(self.UpdateRankData,self);
    EventMgr.Add("GetPolyCard",EventHandler(self.GetPolyCard, self))
    ScreenMgr.eChange:Add(self.ScrChg,self);
    UIMainMenu.eHide:Add(self.SetBtnState,self);
    SceneMgr.eChangeEndEvent:Add(self.ChangeSceneEnd,self);
end

function My:RemoveLsnr()
    TUB.eTime:Remove(self.SetLeftTime,self);
    TUB.eRank:Remove(self.UpdateRankData,self);
    EventMgr.Remove("GetPolyCard",EventHandler(self.GetPolyCard, self))
    ScreenMgr.eChange:Remove(self.ScrChg,self);
    UIMainMenu.eHide:Remove(self.SetBtnState,self);
    SceneMgr.eChangeEndEvent:Remove(self.ChangeSceneEnd,self);
end

--设置掉落统计及退出按钮状态
function My:SetBtnState(value)
    if self.ExitBtn ~= nil then
        self.ExitBtn:SetActive(value);
    end
end

function My:OpenCustom()
    self:AddLsnr()
    self:UpdateRankData();
    if self.RewardTbl ~= nil then
        self.RewardTbl:Reposition();
    end
end

function My:CloseCustom()
    self:ClearDrop();
    self.NextScore = 0;
    self:RemoveLsnr();
end

function My:ChangeSceneEnd(isLoad)
    if isLoad == false then --重连时不清理
        return;
    end
    self:DisposeTimer();
end

--屏幕发生旋转
function My:ScrChg(orient)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, "IntegralInfo", nil, true)
	elseif orient == ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.root, "IntegralInfo", nil, true, true)
	end
end

function My:GetPolyCard(campName)
    -- iTrace.Error("GS","campName====",campName)
end

--点击查看排名奖励
function My:RkRwdC(go)
    self.RankInteg:CloseC();
    self.RankRwd:Open(self.RankRwdG);
end

--点击积分榜
function My:IntegC(go)
    self.RankRwd:CloseC();
    self.RankInteg:Open(self.BatRankG);
end

--退出地图
function My:ExitC(go)
    MsgBox.ShowYesNo("确定要退出吗？",self.YesCB,self);
end

function My:YesCB()
    self:EndCountDown();
end


--设置当前阵营
function My:SetCurCmpIcom()
    local ownerId = tostring(User.MapData.UID);
    local rank = TUB.ranks[ownerId];
    if rank == nil then
        return;
    end
    self.CurCmpIcom.text = My.CampIconStr[rank.campId];
end

--更新排行数据
function My:UpdateRankData()
    if self.active ~= 1 then
        return;
    end
    local ownerId = tostring(User.MapData.UID);
    local rank = TUB.ranks[ownerId];
    if rank == nil then
        return;
    end
    self:SetCurCmpIcom();
    self:SetCampsInfo();
    self:SetRank(rank.rank);
    self:SetIntegral(rank.score);
    self:SetReward(rank.score);
    self:SetScoreDone(rank.score);
end

--设置剩余时间
function My:SetLeftTime()
    if TUB.Timer == nil then
        return;
    end
    self.LeftTime.text = TUB.Timer.remain;
    if TUB.Timer.seconds > 0 then
        return;
    end
    self:ShowExitTip();
end

--显示退出提示
function My:ShowExitTip()
    self.ExitTipG:SetActive(true);
    if self.ExitTimer == nil then
        self.ExitTimer = ObjPool.Get(iTimer);
    end
    self.ExitTip.text = "30";
    self.ExitTimer.seconds = 30;
    self.ExitTimer.invlCb:Add(self.InvCountDown, self)
    self.ExitTimer.complete:Add(self.EndCountDown, self)
    self.ExitTimer:Start();
end

function My:InvCountDown()
    if self.ExitTimer == nil then
        return;
    end
    local time = self.ExitTimer:GetRestTime();
    time = math.floor(time + 0.5);
    self.ExitTip.text = string.format("%d秒",time);
end

--结束计时
function My:EndCountDown()
    self.ExitTipG:SetActive(false);
    self:DisposeTimer();
    SceneMgr:QuitScene();
end

--释放计时器
function My:DisposeTimer()
    if self.ExitTimer == nil then
        return;
    end
    self.ExitTimer:AutoToPool();
    self.ExitTimer = nil;
end

--设置排名
function My:SetRank(rank)
    if rank == nil then
        return
    end
    self.CurRank.text = string.format("第%s名", tostring(rank));
end

--设置积分
function My:SetIntegral(integral)
    if integral == nil then return end
    self.Integral.text = string.format("%s分",tostring(integral));
end

--设置奖励
function My:SetReward(integral)
    if integral == nil then return end
    local scoreInfo = self:GetNextScoreInfo(integral);
    if scoreInfo == nil then
        return;
    end
    local nextScore = scoreInfo.score;
    if self.NextScore == nextScore then return end
    self.NextScore = nextScore;
    local integ = nextScore;
    local text = string.format( "达到%s分可获得", integ);
    self.IntegralDesc.text = text;
    self:SetRewardUI(scoreInfo);
end

--设置积分完成图标
function My:SetScoreDone(integral)
    if integral == nil then return end
    local len = #BatScore;
    local info = BatScore[len];
    if integral >= info.score  then
        self.IntgDone.gameObject:SetActive(true);
    else
        self.IntgDone.gameObject:SetActive(false);
    end
end

--获取下一积分段
function  My:GetNextScoreInfo(integral)
    for k,v in pairs(BatScore) do
        if integral < v.score then
            return v;
        end
    end
    local len = #BatScore;
    local info = BatScore[len];
    return info;
end

--设置阵营积分信息
function My:SetCampsInfo()
    self:ClearCampInfoLst();
    for a,info in pairs(My.CampInfoLst) do
        for k,v in pairs(TUB.ranks) do
            if v.campId == info.campId then
                info.peoNum = info.peoNum + 1;
                info.integral = info.integral + v.score;
            end
        end
        info.campIcon.text = My.CampIconStr[info.campId];
        info.campPeo.text = string.format("%s人",info.peoNum);
        info.campIntg.text = string.format("%s分",info.integral);
    end
end

function My:ClearCampInfoLst()
    for k,v in pairs(My.CampInfoLst) do
        local info = My.CampInfoLst[v.campId];
        info:Clear();
    end
end

--加载奖励格子完成
function My:LoadCD(go)
    if self.active ~= 1 then
        GO.Destroy(go);
        return;
    end
    self.RewardLCN = self.RewardLCN + 1;
    if self.RewardLCN < self.RewardN then
        return;
    end
    self.RewardTbl:Reposition();
end

--设置奖励UI
function My:SetRewardUI(scoreInfo)
    self:ClearDrop();
    local drops = scoreInfo.drops;
    if drops == nil then
        return;
    end
    local len = #drops;
    self.RewardN = len;
    if scoreInfo.exp > 0 then
        local expNum = PropTool.GetExp(scoreInfo.exp) / 10000;
        local expStr = math.NumToStr(expNum);
        self.RewardN = len + 1;
        local exp = ObjPool.Get(UIItemCell);
        self.RewardCells[len+1] = exp;
        exp:InitLoadPool(self.RewardG.transform,0.55,self)
        exp:UpData(scoreInfo.expIcon,expStr);
    end
    if self.RewardN == 0 then
        return;
    end
    local it = nil;
    for i = 1, len do
        it = ObjPool.Get(UIItemCell);
        self.RewardCells[i] = it;
        it:InitLoadPool(self.RewardG.transform,0.55,self)
        it:UpData(drops[i].k,drops[i].v);
    end
end

--销毁奖励UI图片
function My:ClearDrop()
    self.RewardLCN = 0;
    if self.RewardCells == nil then
        return;
    end
    local length = #self.RewardCells;
    if length == 0 then
        return;
    end
    local dc = nil;
    for i = 1, length do
        dc = self.RewardCells[i];
        dc:DestroyGo();
        ObjPool.Add(dc);
        self.RewardCells[i] = nil;
    end
end

function My:Dispose()
    My.RewardLCN = 0;
    My.NextScore = 0;
    self:RemoveLsnr();
    TableTool.ClearUserData(self.RankRwd);
    TableTool.ClearUserData(self.RankInteg);
    self.IntgDone.gameObject:SetActive(false);
    self:ClearDrop();
end

return My