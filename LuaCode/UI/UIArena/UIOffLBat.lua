require("UI/UIArena/OffLHead")
require("UI/UIArena/OffLBatUISet")
UIOffLBat = UIBase:New{ Name = "UIOffLBat" }
local My = UIOffLBat

My.HeadInfos = {}

function My:InitCustom()
    local root = self.root;
    local name = "离线1v1战斗界面";
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;

    local go = TF(root,"LeftHead",name);
    My.SetHeadItem(go,1);
    go = TF(root,"RightHead",name);
    My.SetHeadItem(go,2);
    self:RfHeadItem();

    self.EndFightG = TF(root,"EndFight",name);
    self.EndFightG:SetActive(false);
    self.ResultWin = TF(root,"EndFight/ResultSuccess",name);
    self.ResultFail = TF(root,"EndFight/ResultFailed",name);
    self.ResultWin:SetActive(false);
    self.ResultFail:SetActive(false);
    self.Table = CG(UITable,root,"EndFight/RwdTable",name,false);
    self.KillDes = CG(UILabel,root,"EndFight/KillDes",name,false);
    self.CurRank = CG(UILabel,root,"EndFight/CurRank",name,false);
    UC(root,"EndFight/ExitBtn",name,self.ExitBtnC,self);
    UC(root,"QuitBtn",name,self.QuitC,self);
    self:AddLsnr();
    OffLBatUISet.SetMMUI();
    Hangup:SetSituFight(true);
end

--添加协议监听
function My:AddLsnr()
    EventMgr.Add("ChangeOffLInfo",EventHandler(self.ChangeInfo,self));
    OffLBat.eRefresh:Add(self.RfHeadItem,self);
    Droiyan.eResult:Add(self.SetEndUI,self);
end

--移除监听
function My:RemoveLsnr()
    EventMgr.Remove("ChangeOffLInfo",EventHandler(self.ChangeInfo,self));
    OffLBat.eRefresh:Remove(self.RfHeadItem,self);
    Droiyan.eResult:Remove(self.SetEndUI,self);
end

--检查跳过
function My:CheckSkip()
    local curAct = UIArena.CurAct;
    if curAct == nil then
        return false;
    end
    if curAct.SkipTog == nil then
        return false;
    end
    if curAct.SkipTog.value == false then
        return false;
    end
    return true;
end

--设置头像对象信息
function My.SetHeadItem(go,i)
    local item = ObjPool.Get(OffLHead);
    item:InitUIInfo(go);
    My.HeadInfos[i] = item;
end

--刷新头像条
function My:RfHeadItem()
    if OffLBat.HeadDatas == nil then
        return;
    end
    local id = User.instance.MapData.UID;
    id = tostring(id);
    for k,v in pairs(OffLBat.HeadDatas) do
        if v.roleId == id then
            My.HeadInfos[1]:RefreshUI(v);
        else
            My.HeadInfos[2]:RefreshUI(v);
        end
    end
end

--点击退出
function My:QuitC()
    local msg = "确定退出当前战斗？";
    MsgBox.ShowYesNo(msg,self.YesCb, self, "确定");
end

--确定回调
function My:YesCb()
    Droiyan.ReqExitOffL();
end

--点击退出
function My:ExitBtnC(go)
    self:ClearRwds();
    OffLBat.Clear();
    SceneMgr:QuitScene();
end

--设置结束UI
function My:SetEndUI()
    self.EndFightG:SetActive(true);
    local addExp = RoleAssets.LongToNum(Droiyan.AddExp);
    addExp = math.NumToStrCtr(addExp,0);
    local addHonor = RoleAssets.LongToNum(Droiyan.AddHonor);
    addHonor = math.NumToStrCtr(addHonor,0);
    local killDes = nil;
    local chgerName = Droiyan.TarName;
    if Droiyan.IsSucc == true then
        self.ResultWin:SetActive(true);
        self.ResultFail:SetActive(false);
        killDes = string.format("恭喜您击败[ff0000]%s[-]",chgerName);
    else
        self.ResultWin:SetActive(false);
        self.ResultFail:SetActive(true);
        killDes = string.format("很遗憾您被[ff0000]%s[-]击败",chgerName);
    end
    self:SetKillDes(killDes);
    self:SetRank(Droiyan.Rank);
    self:SetRewards(addHonor,addExp);
end

--改变信息
--isEnd在这不使用（护送战斗使用）
function My:ChangeInfo(isEnd,roleId,curHp)
    local len = #My.HeadInfos;
    for i = 1, len do
        local info = My.HeadInfos[i];
        local tmpId = tostring(info.roleId);
        roleId = tostring(roleId);
	    if tmpId == roleId then
		    info:RefreshHp(curHp);
		    return;
	    end
    end
end

function My:CloseCustom()
    self:ClearRwds()
    self:RemoveLsnr();
    self:ClearHeadInfos();
    OffLBatUISet.RevertMMUI();
end

function My:ClearHeadInfos()
    for k,v in pairs(My.HeadInfos) do
        v:Dispose();
        ObjPool.Add(v);
        My.HeadInfos[k] = nil;
    end
end

--设置奖励
function My:SetRewards(addHonor,addExp)
    self:ClearRwds();
    self.RewardCells = {};
    local honorId = 11;
    local expId = 100;
    --荣誉奖励
    local cell = ObjPool.Get(UIItemCell);
    cell:InitLoadPool(self.Table.transform,0.8,self);
    cell:UpData(honorId,addHonor);
    self.RewardCells[1] = cell;
    --经验奖励
    cell = ObjPool.Get(UIItemCell);
    cell:InitLoadPool(self.Table.transform,0.8,self);
    cell:UpData(expId,addExp);
    self.RewardCells[2] = cell;
end

--加载奖励格子完成
function My:LoadCD(go)
    self.Table:Reposition();
end

--设置击败描述
function My:SetKillDes(des)
    if self.KillDes == nil then
        return;
    end
    self.KillDes.text = des;
end

--设置排名
function My:SetRank(rank)
    if self.CurRank == nil then
        return;
    end
    rank = tostring(rank);
    self.CurRank.text = rank;
end

--清除奖励格子
function My:ClearRwds()
    if self.RewardCells == nil then
        return;
    end
    for k,v in pairs(self.RewardCells) do
        if self.RewardCells[k] ~= nil then
            local data = self.RewardCells[k]
            data:DestroyGo()
            ObjPool.Add(data)
            self.RewardCells[k]=nil
        end
    end
    self.RewardCells = nil;
end

--持续显示 ，不受配置tOn == 1 影响
function My:ConDisplay()
	do return true end
end

return My;