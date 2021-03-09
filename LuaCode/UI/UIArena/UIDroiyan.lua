require("UI/UIArena/DroiyanInfo")
require("UI/UIArena/UIRankRwd")
require("UI/UIArena/UIDroiyanTip")
require("UI/UIArena/AddInspire")
UIDroiyan = ArenaBase:New{Name = "UIDroiyan"}
local My = UIDroiyan;
local Players = UnityEngine.PlayerPrefs
My.RoleInfoList = {}

function My:Open(go)
    local root = go.transform;
    local name = name;
    self.root = root;
    local CG = ComTool.Get;
    local UC = UITool.SetLsnrClick;
    local TF = TransTool.FindChild;
    local UCS = UITool.SetLsnrSelf;

    UC(root,"HnStoreBtn",name,self.HnStoreC,self);
    UC(root,"RankRwdBtn",name,self.RankRwdC,self);
    UC(root,"BuyTime",name,self.BuyTimeC,self);
    UC(root,"ChangeBtn",name,self.ChangeC,self);
    UC(root,"ChallengeBtn",name,self.ChallengeC,self);
    UC(root,"AddInspireBtn",name,self.AddInspireC,self);

    self.MyRank = CG(UILabel,root,"MyRank",name,false);
    self.MyFight = CG(UILabel,root,"MyFight",name,false);
    self.Challenge = CG(UILabel,root,"ChallTime",name,false);
    self.SkipTog = CG(UIToggle,root,"SkipBtn",name,false);
    self.SkipTog.gameObject:SetActive(false)
    self.RankRwdLbl = CG(UILabel,root,"RankRwdBtn/Label",name,false);
    self.RankRwdEff = TF(root,"RankRwdBtn/RwdEffect",name);
    self.vipLab = CG(UILabel,root,"vipLab",name,false);
    self.vipLab.gameObject:SetActive(false)--隐藏跳过战斗显示
    
    local droiyanTipP = TF(root,"TipPanel",name)
    droiyanTipP.gameObject:SetActive(false)
    self.droiyanTip = UIDroiyanTip:New()
    self.droiyanTip:Init(droiyanTipP)

    self.AddInspire = TF(root,"AddInspire",name);
    self.AddInspire:SetActive(false);

    for i = 1,5 do
        local path = "RoleItem" .. i;
        local rlItm = TF(root,path,name);
        local item = DroiyanInfo:New();
        local challenger = nil;
        if Droiyan.Challgers ~= nil and #Droiyan.Challgers == 5 then
            challenger = Droiyan.Challgers[i];
        end
        item:Init(rlItm,challenger);
        My.RoleInfoList[i] = item;
        UCS(rlItm,self.SelectRole,self,path, false);
        if i == 5 then
            local mopBtnPath = path .. "/mopBtn"
            local mopBtn = TF(root,mopBtnPath,name);
            UCS(mopBtn,self.SelectMopRole,self,path, false);
        end
    end
    self:RefreshInfo();
    self:ShowSelect()
    self:SetVipLab()
    self.CountChange = EventDelegate.Callback(self.Select, self)
    EventDelegate.Add(self.SkipTog.onChange, self.CountChange)
end

--设置跳过战斗vip显示
function My:SetVipLab()
    local vipLv = VIPMgr.GetVipSkip()
    local tipStr = string.format("Vip%s以上可直接跳过战斗，秒杀低战力玩家",vipLv)
    self.vipLab.text = tipStr
end

--显示跳过战斗状态
function My:ShowSelect()
    if Players.HasKey("valueStr") then
        local togIndex = Players.GetInt("valueStr")
        if togIndex == 1 then
            self.SkipTog.value = true
        else
            self.SkipTog.value = false
        end
    end
end

--设置跳过战斗状态
function My:Select()
    if (LuaTool.IsNull(self.SkipTog)) then return end
    local needVip = 4
    local userVip = VIPMgr.vipLv
    if userVip < needVip then
        local tipStr = string.format("VIP%s可跳过战斗",needVip)
        UITip.Error(tipStr)
        self.SkipTog.value = false
        Players.SetInt("valueStr", 0)
        return
    end
    local state = self.SkipTog.value
    if state == false then
        Players.SetInt("valueStr", 0)
    else
        Players.SetInt("valueStr", 1)
    end
end

--发送打开面板
function My.SendOpen()
    Droiyan.OpenSlPanel(1);
    Droiyan.ReqOfflineInfo();
end

--发送关闭面板
function My.SendClose()
    Droiyan.OpenSlPanel(0);
end

function  My:Close()
    self.root = nil;
    self.MyRank = nil;
    self.MyFight = nil;
    self.Challenge = nil;
    self.SelectRank = nil;
    self.SelectRoleId = nil;
    self.SelectFight = nil;
    --self:ClearSlTog();
    self:RemoveEvent();
    My.ClearList();
end

--[[
function My:ClearSlTog()
    if self.SelectTgl == nil then
        return;
    end
    self.SelectTgl:Set(false,false)
    self.SelectTgl = nil;
end
]]--

function My.ClearList()
    for k,v in pairs(My.RoleInfoList) do
        v:Clear();
        My.RoleInfoList[k] = nil;
    end
end

function My:SelectRole(go)
    for k,v in pairs(My.RoleInfoList) do
        if v.root.name == go.name then
            if v.Challenger ~= nil then
                self.SelectRank = v.Challenger.rank;
                self.SelectRoleId = v.Challenger.role_id;
                self.SelectFight = v.Challenger.power;
                --self.SelectTgl = v.UIToggle;
                self:ChallengeC(nil);
                return;            
            end
        end
    end
end

function My:SelectMopRole(go)
    go = go.transform.parent
    for k,v in pairs(My.RoleInfoList) do
        if v.root.name == go.name then
            if v.Challenger ~= nil then
                self.SelectRank = v.Challenger.rank;
                self.SelectRoleId = v.Challenger.role_id;
                self.SelectFight = v.Challenger.power;
                self:MopChallengeC(nil);
                return;            
            end
        end
    end
end

function My:InitEvent()
    Droiyan.eOffline:Add(self.RefreshInfo,self);
    Droiyan.eResult:Add(self.SetResult,self);
    Droiyan.eChangeTime:Add(self.SetChallgTime,self);
    Droiyan.eIsRwd:Add(self.SetIsRwd,self);
    Droiyan.eInspire:Add(self.InspireSuc,self);
end

function My:RemoveEvent()
    Droiyan.eOffline:Remove(self.RefreshInfo,self);
    Droiyan.eResult:Remove(self.SetResult,self);
    Droiyan.eChangeTime:Remove(self.SetChallgTime,self);
    Droiyan.eIsRwd:Remove(self.SetIsRwd,self);
end

function My:RefreshInfo()
    --数据刷新清除选择信息
    self.SelectRank = nil;
    --self:ClearSlTog();

    self:SetIsRwd();
    self:SetLabel();
    self:SetChallgTime();
    self:SetRoleItem();
end

function My:SetRoleItem()
    if Droiyan.Challgers == nil then
        return;
    end
    local len = #Droiyan.Challgers;
    if len == 0 then
        return;
    end
    for i = 1,len do
        local info = My.RoleInfoList[i];
        if info ~= nil then
            info:SetChallenger(Droiyan.Challgers[i]);
        end
    end
end

function My:SetResult()
    self:SetLabel();
end

function My:SetChallgTime()
    if self.Challenge == nil then
        return;
    end
    self.Challenge.text = tostring(Droiyan.ChallgTime);
end

function My:SetLabel()
    if self.MyRank == nil then
        return;
    end
    self.MyRank.text = tostring(Droiyan.Rank);
    self:SetFightVal();
    self.Challenge.text = tostring(Droiyan.ChallgTime);
end

function My:SetFightVal()
    if self.MyFight ~= nil then
        local fValue = User.MapData.AllFightValue;
        --local fightVal = Droiyan.GetInspireFightVal(fValue);
        local fightVal = math.NumToStrCtr(fValue);
        self.MyFight.text = fightVal;
    end
end

--荣誉商店点击
function My:HnStoreC(go)
    StoreMgr.OpenStore(6)
end

--排行奖励点击
function My:RankRwdC(go)
    if Droiyan.IsReward == true then
        UIRankRwd:Open(OffLRankRwd)
    else
        Droiyan.ReqOfflRwd();
    end
end

--设置是否领取奖励按钮
function My:SetIsRwd()
    if Droiyan.IsReward == true then
        self.RankRwdLbl.text = "排行奖励";
        self.RankRwdEff:SetActive(false);
    else
        self.RankRwdLbl.text = "领取奖励";
        self.RankRwdEff:SetActive(true);
    end
end

--购买挑战次数
function My:BuyTimeC(go)
    self.droiyanTip:OpenC()
    
    -- if Droiyan.LeftBuyTime == 0 then
    --     local msg = "今天购买次数已经用完,无法购买!";
    --     UITip.Log(msg);
    -- else
    --     self.droiyanTip:OpenC()
    -- end
end

function My:YesCB()
    local coinNum = 10;
    if RoleAssets.IsEnoughAsset(3,coinNum) == true then
        Droiyan.ReqBuyChallenge(); 
    else
        local msg = "元宝不足!";
        UITip.Log(msg);
    end
end

--换一批点击
function  My:ChangeC(go)
    Droiyan.ReqOfflineInfo();
end

--挑战点击
function My:ChallengeC(go)
    -- local isCanChallge = Droiyan.IsCanChallg
    -- if isCanChallge == false then
    --     UITip.Log("挑战点击频率过快")
    --     return
    -- end
    if self.SelectRank == nil then
        local msg = "请选择挑战英雄!";
        UITip.Log(msg);
        return;
    end
    local leftBuyT = Droiyan.LeftBuyTime
    if Droiyan.ChallgTime == 0 then
        if leftBuyT > 0 then
            self.droiyanTip:OpenC()
        else
            local msg = "挑战次数已用完";
            UITip.Log(msg);
        end
        return;
    end
    Droiyan.ReqChallenge(self.SelectRank);

    -- local vipLv = VIPMgr.vipLv
    -- local vipCfg = VIPLv[vipLv+1]
    -- local isSkip = vipCfg.skipDroiyan
    -- self.SkipTog.value = false
    -- if isSkip >= 1 then --跳过战斗
    --     self.SkipTog.value = true
    --     return
    -- end


    -- if self.SkipTog.value == true then
    --     return;
    -- end
    -- local roleId = tonumber(self.SelectRoleId);
    -- EventMgr.Trigger("ChallengeRole",roleId,self.SelectFight);
    --SceneMgr:ReqPreEnter(20901, true, true);
end

--扫荡挑战点击
function My:MopChallengeC(go)
    if self.SelectRank == nil then
        local msg = "请选择挑战英雄!";
        UITip.Log(msg);
        return;
    end
    local leftBuyT = Droiyan.LeftBuyTime
    if Droiyan.ChallgTime == 0 then
        if leftBuyT > 0 then
            self.droiyanTip:OpenC()
        else
            local msg = "挑战次数已用完";
            UITip.Log(msg);
        end
        return;
    end
    Droiyan.ReqModChallenge(self.SelectRank);
end

--增加鼓舞buff
function My:AddInspireC(go)
    AddInspire:Open(self.AddInspire);
end

--鼓舞成功
function My:InspireSuc()
    self:SetFightVal();
    AddInspire:SetContext();
end