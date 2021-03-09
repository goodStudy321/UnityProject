require("UI/UIArena/ArenaBase")
require("UI/UIArena/UIPeak")
require("UI/UIArena/UIQYunTop")
require("UI/UIArena/UIThrUni")
require("UI/UIArena/UIDemon")
require("UI/UIArena/UIDroiyan")
require("UI/UIArena/UIPeakDesc")
require("UI/UIArena/TopThrDemon")
require("UI/UIArena/UIPVPanel/UIPVPanel")

UIArena = UIBase:New{Name = "UIArena"}
local My = UIArena;

My.ActiveIds = {0,10002,10008,10001,10009}
My.PeakDesc = nil;
My.CurAct = nil;
My.index = nil;
My.OpenIndex = 1;

function My:InitCustom()
    local root = self.root;
    local name = "竞技大厅界面";
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;

    self.DroiyanG = TF(root,"Droiyan",name);
    self.PeakG = TF(root,"PeakArena",name);
    self.TopThrDemon = TF(root,"TopThrDemon",name);
    self.RankRwd = TF(root,"RankRwd",name);
    self.RankRwd:SetActive(false);
    My.PeakDesc = TF(root,"PeakDesc",name);
    My.PeakDesc:SetActive(false);

    self.droiyanFlag = TF(root,"DroiyanBtn/action",name)
    self.peakFlag = TF(root,"PeakBtn/action",name)
    self.thrFlag = TF(root,"ThrUniBatBtn/action",name)

    self.DroiyTgl = CG(UIToggle,root,"DroiyanBtn",name,false);
    self.Peak = CG(UIToggle,root,"PeakBtn",name,false);
    self.Top = CG(UIToggle,root,"TopBtn",name,false);
    self.ThrUni = CG(UIToggle,root,"ThrUniBatBtn",name,false);
    self.Demon = CG(UIToggle,root,"DemonBat",name,false);

    self.PVPanel = ObjPool.Get(UIPVPanel)
    self.PVPanel:Init(TF(root,"UIPVPanel",name))

    UC(root,"DroiyanBtn",name,self.DroiyanC,self);
    UC(root,"PeakBtn",name,self.PeakC,self);
    UC(root,"TopBtn",name,self.TopC,self);
    UC(root,"ThrUniBatBtn",name,self.ThrBatC,self);
    UC(root,"DemonBat",name,self.DemonC,self);
    UC(root,"CloseBtn",name,self.CloseC,self);
    self:OpenTab();
    self:AddEvent()
    self:SetDroiyanFlag()
    self:SetPeakFlag()
    self:SetThrFlag()
end

function My:AddEvent()
    Droiyan.eRedFlag:Add(self.SetDroiyanFlag, self)
    Peak.eRedFlag:Add(self.SetPeakFlag, self)
    Peak.eBoxRed:Add(self.SetPeakFlag, self)
    ThrUniBattle.eRedFlag:Add(self.SetThrFlag, self)
end

function My:RemoveEvent()
    Droiyan.eRedFlag:Remove(self.SetDroiyanFlag, self)
    Peak.eRedFlag:Remove(self.SetPeakFlag, self)
    Peak.eBoxRed:Remove(self.SetPeakFlag, self)
    ThrUniBattle.eRedFlag:Remove(self.SetThrFlag, self)
end

function My:SetDroiyanFlag()
    if LuaTool.IsNull(self.droiyanFlag) then
        return
    end
    self.droiyanFlag:SetActive(false)
    local isRew = Droiyan.IsReward
    local challNum = Droiyan.ChallgTime
    if (isRew == false) or (challNum and challNum > 0) then
        self.droiyanFlag:SetActive(true)
    end
end

function My:SetPeakBoxFlag()
    local ac = false
    local redTab = Peak.ReBoxRed
    for k,v in pairs(redTab) do
        if redTab[k] ~= nil then
            ac = true
            break
        end
    end
    return ac
end

function My:SetPeakFlag()
    local isOpen = Peak.PeakIsOpen
    local isBoxRe = self:SetPeakBoxFlag()
    if isOpen == true or isBoxRe == true then
        self.peakFlag:SetActive(true)
    elseif isOpen == false and isBoxRe == false then
        self.peakFlag:SetActive(false)
    end
end

function My:SetThrFlag()
    if ThrUniBattle.ThrIsOpen then
        self.thrFlag:SetActive(true)
    else
        self.thrFlag:SetActive(false)
    end
end

function My:RemoveCustom()

end

function My:OpenCustom()
    
end

function My:CloseCustom()
    self:RemoveEvent()
    My.index = nil;
    self.CloseCurAct();
    UIDroiyan.SendClose();
end

function My:DisposeCustom()
    -- local act = self.CurPeak
    -- if act then
    --     act:Dispose()
    --     self.CurPeak = nil
    -- end

    if self.PVPanel then
        ObjPool.Add(self.PVPanel)
        self.PVPanel = nil
    end
end

--邮件链接入口
function My:OpenTabByIdx(t1, t2, t3, t4)
    self.OpenIndex = t1
end

--index==1 打开决胜逍遥
--index==2 打开决战天梯
--index==3 打开逐鹿巅峰
--index==4 打开三界角斗
--index==5 打开仙魔之战
function My.OpenArena(index)
    UIArena.OpenIndex = index;
    UIMgr.Open(UIArena.Name);
end

--打开分页
function My:OpenTab()
    if self.OpenIndex == 1 or self.OpenIndex == nil then
        self.DroiyTgl.value = true;
        self:DroiyanC(nil);
    elseif self.OpenIndex == 2 then
        self.Peak.value = true;
        self:PeakC(nil);
    elseif self.OpenIndex == 3 then
        self.Top.value = true;
        self:TopC(nil);
    elseif self.OpenIndex == 4 then
        self.ThrUni.value = true;
        self:ThrBatC(nil);
    elseif self.OpenIndex == 5 then
        self.Demon.value = true;
        self:DemonC(nil);
    end
end

function My:DroiyanC(go)
    if self:IsCurTab(1) == true then
        return;
    end
    UIDroiyan.SendOpen();
    My.index = 1;
    self.CloseCurAct();
    self.DroiyanG:SetActive(true);
    self.PeakG:SetActive(false);
    self.TopThrDemon:SetActive(false);
    self.CurAct = UIDroiyan:New();
    self.CurAct:Open(self.DroiyanG);
end

function My:PeakC(go)
    if self:IsCurTab(2) == true then
        return;
    end
    My.index = 2;
    self.CloseCurAct();
    self.DroiyanG:SetActive(false);
    self.PeakG:SetActive(true);
    self.TopThrDemon:SetActive(false);
    self.CurAct = UIPeak:New();
    self.CurPeak = self.CurAct
    self.CurAct:Open(self.PeakG);
end

function My:TopC(go)
    if self:IsCurTab(3) == true then
        return;
    end
    My.index = 3;
    self.CloseCurAct();
    self.CurAct = UIQYunTop:New();
    self.DroiyanG:SetActive(false);
    self.PeakG:SetActive(false);
    self.TopThrDemon:SetActive(true);
    self.CurAct:Open(self.TopThrDemon);
end

function My:ThrBatC(go)
    if self:IsCurTab(4) == true then
        return;
    end
    My.index = 4;
    self.CloseCurAct();
    self.DroiyanG:SetActive(false);
    self.PeakG:SetActive(false);
    self.TopThrDemon:SetActive(true);
    self.CurAct = UIThrUni:New();
    self.CurAct:Open(self.TopThrDemon);
end

function  My:DemonC(go)
    if self:IsCurTab(5) == true then
        return;
    end
    My.index = 5;
    self.CloseCurAct();
    self.DroiyanG:SetActive(false);
    self.PeakG:SetActive(false);
    self.TopThrDemon:SetActive(true);
    self.CurAct = UIDemon:New();
    self.CurAct:Open(self.TopThrDemon);
end

--是否是当前页
function My:IsCurTab(index)
    if self.index == index then
        return true;
    end
    return false;
end

function My.CloseCurAct()
    if My.CurAct == nil then
        return;
    end
    My.CurAct:Close();
    TableTool.ClearUserData(My.CurAct);
end

function My:CloseC(go)
    self:Close();
    My.CurAct:Close();
    JumpMgr.eOpenJump()
end

--打开活动描述
function My.OpenActDesc()
    if My.PeakDesc == nil then
        return;
    end
    UIPeakDesc:Open(My.PeakDesc);
end

--获取活动时间字符串
function  My.GetActTime()
    local activeId = My.ActiveIds[My.index];
    local time = ActvHelper.GetActTime(activeId);
    return time;
end

return My;