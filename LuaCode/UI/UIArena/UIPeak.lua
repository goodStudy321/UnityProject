require("UI/UIArena/UIPeakRank")
require("UI/UIArena/EntRwdInfo")
require("UI/UIArena/UIPeakMatch")
require("UI/UIArena/UIPeakMatchSucc")
UIPeak = ArenaBase:New{Name = "UIPeak"}
local My = UIPeak;
My.RwdBoxLst = {}
My.RewardItems = {}
My.Week = {"一","二","三","四","五","六","日"}

function My:Open(go)
    local root = go.transform;
    local name = name;
    self.root = root;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    local TF = TransTool.FindChild;

    UC(root,"HonorStore",name,self.HnStoreC,self);
    UC(root,"PresStore",name,self.PresStoreC,self);
    UC(root,"RankBtn",name,self.RankBtnC,self);
    UC(root,"RewardBtn",name,self.RewardBtnC,self);
    self.WinPersent = CG(UILabel,root,"WinPersent",name,false);
    self.EntCAll = CG(UILabel,root,"EnterCAll",name,false);
    self.HadGetExp = CG(UILabel,root,"HadGetExp",name,false);
    self.DanSpr = CG(UISprite,root,"DanIcon",name,false);
    self.DanDesc = CG(UILabel,root,"DanDesc",name,false);
    self.ActTime = CG(UILabel,root,"ActTime",name,false);
    self.UITable = CG(UITable,root,"RwdTable",name,false);
    self.curSeasonLab = CG(UILabel,root,"SeasonLab/curSeason",name,false);
    self.seasonTime = CG(UILabel,root,"SeasonLab/seasonTime",name,false);
    self.seasonDes = CG(UILabel,root,"SeasonLab/des",name,false);
    UC(root,"DescBtn",name,self.DescBtnC,self);
    UC(root,"DanRwdBtn",name,self.DescBtnC,self);
    UC(root,"MatchBtn",name,self.MatchBtnC,self);
    self.MatchBtn = CG(UIButton,root,"MatchBtn",name,false);
    self.ScoreSlider = CG(UISlider,root,"ScoreSlider",name,false);
    self.ScoreSldLbl = CG(UILabel,root,"ScoreSlider/Label",name,false);
    self.EntC = CG(UILabel,root,"EnterC",name,false);
    self.RwdBox = TF(root,"RwdBox",name);
    self.RwdBox:SetActive(false);
    self.EntCSlider = CG(UISlider,root,"EnterSlider",name,false);
    self:InitOtherPanel(root);
    self:InitData();
    self.PeakRank:SetActive(false);
end

--初始化其他面板
function My:InitOtherPanel(root)
    local name = root.name;
    local TF = TransTool.FindChild;
    self.PeakRank = TF(root,"PeakRank",name);
    self.MatchTip = TF(root,"MatchTip",name);
    self.BeforeEnter = TF(root,"BeforeEnter",name);
end

function My:InitData()
    self:SetWinPersent();
    self:SetEntCAll();
    self:SetExp();
    self:SetEntTime();
    self:SetActTime();
    self:SetHonorInfo();
    self:SetRwdBox();
    self:SetMatchBtn();
    self:PeakActSet();
    self:SetRewardIts();
    self:ReshBoxRed()
    self:SetSeason()
end

function My:SetSeason()
    local seasonTimes = Peak.RoleInfo.season
    if seasonTimes == nil then
        seasonTimes = 0
    end
    local isSingle = false
    if seasonTimes == 0 then
        isSingle = true
    end
    local cur = ""
    local time = ""
    local des = ""
    local day = GlobalTemp["176"].Value2[1]
    -- local worldLv = GlobalTemp["164"].Value3
    if day == nil then
        day = 7
    end
    if isSingle then
        cur = ""
        time = ""
        -- des = string.format("开服第%s天后、且世界等级%s达到%s级开启跨服赛季",day,"\n",worldLv)
        des = string.format("开服第%s天后开启跨服赛季",day)
    else
        local info = Peak.MyRank
        local serverTime = TimeTool.GetServerTimeNow()*0.001
        local seasonStart = Peak.RoleInfo.seasonStartTimes
        local seasonEnd = Peak.RoleInfo.seasonStopTimes
        local seasonTimes = Peak.RoleInfo.season
        serverTime = os.date("%Y", serverTime)
        seasonStart = os.date("%Y-%m-%d", seasonStart)
        seasonEnd = os.date("%Y-%m-%d", seasonEnd)
        cur = string.format("%s第%s赛季",serverTime,seasonTimes)
        time = string.format("%s - %s",seasonStart,seasonEnd)
    end
    self.curSeasonLab.text = cur
    self.seasonTime.text = time
    self.seasonDes.text = des
end

--设置奖励
function My:SetRewardIts()
    local actId = 10002;
    local info = ActiveInfo[tostring(actId)];
    if info == nil then
        return;
    end
    if info.rewards == nil then
        return;
    end
    local len = #info.rewards;
    for i = 1, len do
        local iconId = info.rewards[i];
        local coinCell = ObjPool.Get(UIItemCell);
        coinCell:InitLoadPool(self.UITable.transform,0.65,self);
        coinCell:UpData(iconId);
        self.RewardItems[i] = coinCell;
    end
end

--加载奖励格子完成
function My:LoadCD(go)
    -- if self.isOpen == false then 
    --     GO.Destroy(go);
    --     return;
    -- end
    self.UITable:Reposition();
end

--清除奖励格子
function My:ClearRwdIts()
    if self.RewardItems == nil then
        return;
    end
    local length = #self.RewardItems;
    if length == 0 then
        return;
    end
    local dc = nil;
    for i = 1, length do
        dc = self.RewardItems[i];
        dc:DestroyGo();
        ObjPool.Add(dc);
        self.RewardItems[i] = nil;
    end
end

--设置赛季参赛胜率
function My:SetWinPersent()
    if self.WinPersent == nil then
        return;
    end
    local ssnEtT = Peak.RoleInfo.seasonEntTimes;
    if ssnEtT == nil then
        return;
    end
    if ssnEtT == 0 then
        self.WinPersent.text = "100%";
        return;
    end
    local ssnWinT = Peak.RoleInfo.seasonWinTimes;
    if ssnWinT == nil then
        return;
    end
    local persent = ssnWinT/ssnEtT;
    persent = persent * 100;
    local text = string.format("%2d%s",persent,"%");
    self.WinPersent.text = text;
end

--设置赛季总进入次数
function My:SetEntCAll()
    if self.EntCAll == nil then
        return;
    end
    local ssnEtT = Peak.RoleInfo.seasonEntTimes;
    if ssnEtT == nil then
        return;
    end
    self.EntCAll.text = tostring(ssnEtT);
    self:SetWinPersent();
end

--设置已获得经验
function My:SetExp()
    if self.HadGetExp == nil then
        return;
    end
    local exp = Peak.RoleInfo.exp
    if exp == nil then
        return
    end
    local text = math.NumToStr(exp);
    self.HadGetExp.text = text;
end

--设置参与次数
function My:SetEntTime()
    local entTime = tostring(Peak.RoleInfo.enterTime);
    local entAllT = self.GetMaxTime();
    local text = string.format("今日已参与[00ff00](%s/%s)[-]场",entTime,entAllT);
    self.EntC.text = text;
    entTime = Peak.RoleInfo.enterTime
    if entTime == nil then
        entTime = 0
    end
    self.EntCSlider.value = entTime/entAllT;
end

--设置活动时间
function My:SetActTime()
    local text = UIArena.GetActTime();
    self.ActTime.text = text;
end

--获取最参与奖励次数
function My.GetMaxTime()
    local len = #OvORwd;
    return OvORwd[len].times;
end

--设置段位荣誉信息
function My:SetHonorInfo()
    local score = Peak.RoleInfo.score;
    local danHnRwd = self.GetDanInfoByScr(score);
    self.DanSpr.spriteName = danHnRwd.danIcon;
    self.DanDesc.text = danHnRwd.danName;
    local nxtDanHnRwd = self.GetNextDanByScr(score);
    local nxtScore = nil;
    if nxtDanHnRwd ~= nil then
        nxtScore = nxtDanHnRwd.score;
    else
        nxtScore = danHnRwd.score;
    end
    self.ScoreSldLbl.text = string.format("%s/%s",Peak.RoleInfo.score,nxtScore);
    self.ScoreSlider.value = Peak.RoleInfo.score/nxtScore;
end

--获取段位荣誉奖励
function My.GetDanHnRwd()
    local score = Peak.RoleInfo.score;
    local info = nil;
    for k,v in pairs(OvODanRwd) do
        if score < v.score then
            return v;
        end
        info = v;
    end
    return info;
end

--根据积分获取下一段位信息
function My.GetNextDanByScr(score)
    score = score or 0
    local len = #OvODanRwd;
    for i = 1, len do
        if score < OvODanRwd[i].score then
            return OvODanRwd[i];
        end
    end
    return nil;
end

--根据积分获取段位信息
function My.GetDanInfoByScr(score)
    score = score or 0
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

function My:InitEvent()
    Peak.ePeakActiv:Add(self.PeakActSet,self);
    Peak.eScore:Add(self.SetHonorInfo,self);
    Peak.eSWinTimes:Add(self.SetWinPersent,self);
    Peak.eSEntTimes:Add(self.SetEntCAll,self);
    Peak.eExp:Add(self.SetExp,self);
    Peak.eMatch:Add(self.SetMatchBtn,self);
    Peak.eMatchSucc:Add(self.SetMatchSucc,self);
    Peak.eEntRwdChange:Add(self.RefreshRwdBox);
    Peak.eRankInfo:Add(self.ShowRank,self);
    Peak.eEnterTime:Add(self.ReshEntTime,self);
    PropMgr.eGetAdd:Add(self.OpenRwdBoxTip,self);
    Peak.eBoxRed:Add(self.ReshBoxRed,self);
end

function My:RemoveEvent()
    Peak.ePeakActiv:Remove(self.PeakActSet,self);
    Peak.eScore:Remove(self.SetHonorInfo,self);
    Peak.eSWinTimes:Remove(self.SetWinPersent,self);
    Peak.eSEntTimes:Remove(self.SetEntCAll,self);
    Peak.eExp:Remove(self.SetExp,self);
    Peak.eMatch:Remove(self.SetMatchBtn,self);
    Peak.eMatchSucc:Remove(self.SetMatchSucc,self);
    Peak.eEntRwdChange:Remove(self.RefreshRwdBox);
    Peak.eRankInfo:Remove(self.ShowRank,self);
    Peak.eEnterTime:Remove(self.ReshEntTime,self);
    PropMgr.eGetAdd:Remove(self.OpenRwdBoxTip,self);
    Peak.eBoxRed:Remove(self.ReshBoxRed,self);
end

function My:ReshBoxRed()
    local redTab = Peak.ReBoxRed
    local boxTab = My.RwdBoxLst
    for i = 1,#OvORwd do
        if redTab[i] ~= nil then
            boxTab[i]:SetRed(true)
        else
            if boxTab[i] == nil then
                return
            end
            boxTab[i]:SetRed(false)
        end
    end
end

function My:PeakActSet()
    if Peak.PeakIsOpen == true then
        self.MatchBtn.isEnabled = true;
    else
        self.MatchBtn.isEnabled = false;
        UIPeakMatch:Close();
    end
end

--设置匹配按钮
function My:SetMatchBtn()
    if Peak.PeakIsOpen == false then
        return;
    end
    local bMatch = Peak.RoleInfo.bMatch
    if bMatch == true then
        self.MatchBtn.isEnabled = false;
        UIPeakMatch:Open(self.MatchTip);
    else
        self.MatchBtn.isEnabled = true;
        UIPeakMatch:Close();
    end
end

function My:SetMatchSucc()
    UIPeakMatchSucc:Open(self.BeforeEnter);
end

function My:ShowRank()
    --接收到排行数据后显示排行界面
    -- UIPeakRank:Open(self.PeakRank);
    local index = self.clickIndex
    UIArena.PVPanel:Open(index)
end

function My:ReshEntTime()
    self:SetEntTime();
end

function My:ShowFResult()

end

function My:SetRwdBox()
    --从奖励表中获取奖励，分配宝箱位置
    local CG = ComTool.Get;
    local bgSprt = CG(UISprite,self.EntCSlider.transform,"Background",self.EntCSlider.name,false);
    local sldW = bgSprt.width;
    for k,v in pairs(OvORwd) do
        local rwdInfo = My.RwdBoxLst[k];
        if rwdInfo == nil then
            local item = EntRwdInfo:New();
            item:SetData(self.RwdBox,self.EntCSlider.transform,sldW,v.times,v.sprName);
            My.RwdBoxLst[k] = item;
        end
    end
    self:RefreshRwdBox();
end

--打开宝箱奖励提示
function My:OpenRwdBoxTip(action,dic)
    if action == 10011 then
        self.dic = dic;
        UIMgr.Open(UIGetRewardPanel.Name,self.RwdBCB,self);
    end
end

--打开UI提示返回
function My:RwdBCB(name)
    local ui = UIMgr.Get(name);
    if ui then
        ui:UpdateData(self.dic);
    end
end

function My:RefreshRwdBox()
    for k,v in pairs(My.RwdBoxLst) do
        local rwdBox = Peak.RecEntLst[v.times];
        if rwdBox == nil then
            v:SetClose();
        else
            v:SetOpen();
        end
    end
end

--荣誉商店点击
function  My:HnStoreC(go)
    StoreMgr.OpenStore(6)
end

--威望商店点击
function My:PresStoreC(go)
    StoreMgr.OpenStore(24)
end

--排行榜点击
function My:RankBtnC(go)
    -- if self.PeakRank.activeSelf == true then
    --     return;
    -- end
    self.clickIndex = 1
    Peak.ReqSoloRank();
    -- self.PeakRank:SetActive(true);
end

--点击奖励
function My:RewardBtnC()
    self.clickIndex = 2
    Peak.ReqSoloRank();
end

--玩法描述点击
function My:DescBtnC(go)
    UIArena.OpenActDesc();
end

--匹配点击
function My:MatchBtnC(go)
    Peak.ReqSoloMatch(1);
end

function My:Close()
    if self.PeakRank then
        self.PeakRank:SetActive(false);
    end
    self:RemoveEvent();
    My.ClearRwdBoxLst();
    self:ClearRwdIts()
end

function My.ClearRwdBoxLst()
    for k,v in pairs(My.RwdBoxLst) do
        v:Clear();
        My.RwdBoxLst[k] = nil;
    end
end