TopThrDemon = {Name = "TopThrDemon"}
local My = TopThrDemon;
local GO = UnityEngine.GameObject;
My.RewardCells = {};

function My:Open(go)
    self.isOpen = true;
    local root = go.transform;
    local name = name;
    self.root = root;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    local TF = TransTool.FindChild;
    self.RnkRwdBtn = TF(root,"RankRwdBtn",name);
    UC(root,"RankRwdBtn",name,self.RRBtnC,self);
    UC(root,"DescBtn",name,self.DescBtnC,self);
    UC(root,"EnterBtn",name,self.EnterC,self);
    self.ActTime = CG(UILabel,root,"ActTime",name,false);
    self.Bgs = {};
    for i = 1, 3 do
        local bgStr = string.format("Bg%s",i);
        local bg = TF(root,bgStr,name);
        bg:SetActive(false);
        self.Bgs[i] = bg;
    end
    self.UITable = CG(UITable,root,"RwdTable",name,false);
    self:SetBg();
    self:SetRnkRwdBtn();
    self:SetActTime();
    self:SetRewards();
end

--获取活动Id
function My.GetActiveId()
    local index = UIArena.index;
    local actId = UIArena.ActiveIds[index];
    return actId;
end

--设置背景图
function My:SetBg()
    local index = UIArena.index;
    for i = 1, 3 do
        if i+2 == index then
            self.Bgs[i]:SetActive(true);
        else
            self.Bgs[i]:SetActive(false);
        end
    end
end

--设置活动时间
function My:SetActTime()
    if self.ActTime == nil then
        return;
    end
    local actTime = UIArena.GetActTime();
    if actTime == nil then
        return;
    end
    self.ActTime.text = actTime;
end

--设置排行奖励按钮
function My:SetRnkRwdBtn()
    if self.RnkRwdBtn == nil then
        return;
    end
    if UIArena.index == 3 then
        self.RnkRwdBtn:SetActive(false);
    else
        self.RnkRwdBtn:SetActive(true);
    end
end

--设置奖励
function My:SetRewards()
    local actId = self.GetActiveId();
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
        self.RewardCells[i] = coinCell;
    end
end

--加载奖励格子完成
function My:LoadCD(go)
    if self.isOpen == false then 
        GO.Destroy(go);
        return;
    end
    self.UITable:Reposition();
end

--清除奖励格子
function My:ClearRwds()
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

--点击设置排行奖励
function My:RRBtnC(go)
    local index = UIArena.index;
    if index == 4 then
        UIRankRwd:Open(ThrRankRwd);
    elseif index == 5 then
        UIRankRwd:Open(DmnLRankRwd);
    end
end

--点击活动描述
function My:DescBtnC(go)
    UIArena.OpenActDesc();
end

--点击进入按钮
function My:EnterC(go)
    local actId = self.GetActiveId();
    if actId == nil then
        return;
    end
    if actId == 0 then
        return;
    end
    local info = ActiveInfo[tostring(actId)];
    if info == nil then
        iTrace.Error("ljf",string.format("活动配置表不存在活动ID:%s",actId));
        return;
    end
    local level = User.MapData.Level;
    if level < info.needLv then
        UITip.Log("等级不足！");
        return;
    end
    if info.sceneId == nil or info.sceneId == 0 then
        iTrace.Error("ljf",string.format("活动ID：%s 没有配置活动地图ID",actId));
        return;
    end
    local isOpen = ActivityMsg.ActIsOpen(actId);
    if isOpen == false then
        UITip.Log("活动未开启！");
        return;
    end
    SceneMgr:ReqPreEnter(info.sceneId, true, true);
end

function My:Close()
    self.isOpen = false;
    self:ClearRwds();
    TableTool.ClearUserData(self);
end

function My:Dispose()

end