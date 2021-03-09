require("UI/UIFiveElmnts/UIFiveElmntMons")
require("UI/UIFiveElmnts/UIFiveElmntView")
require("UI/UIFiveElmnts/UIFiveElmntRwd")
require("UI/UIFiveElmnts/SecretDropEff")
require("UI/UIFiveElmnts/UIFiveElmntLayer")
UIFiveElmntAttr = UIBase:New{Name ="UIFiveElmntAttr"}
local My = UIFiveElmntAttr;
My.monsItem = nil;

function My:InitCustom()
    local name = self.Name;
    local trans = self.root;
    local CG = ComTool.Get;
    local TF = TransTool.Find;
    local TFC = TransTool.FindChild;
    local UC = UITool.SetLsnrClick;

    FiveElmtMgr:InitCfgMons();
    local monsView = TF(trans,"MonstersView",name);
    UIFiveElmntMons:Init(monsView);

    local fvElmntView = TF(trans,"FiveElmtView",name);
    UIFiveElmntView:Init(fvElmntView);

    local dropRwdView = TF(trans,"DropRwdView",name);
    UIFiveElmntRwd:Init(dropRwdView);

    local layView = TF(trans,"FElmntLyView",name);
    UIFiveElmntLayer:Init(layView);

    self.LayBtn = TFC(trans,"LayBtn",name);
    self.RwdBtn = TFC(trans,"RwdBtn",name);
    self.ExitBtn = TFC(trans,"ExitBtn",name);
    UC(trans,"LayBtn",name,self.LayBtnC,self);
    UC(trans,"RwdBtn",name,self.DropRwdViewC,self);
    UC(trans,"ExitBtn",name,self.ExitC,self);

    SecretDropEff:Init(self.RwdBtn.transform.position);

    self:AutoFight();
end

--自动打进入前选中的怪物
function My:AutoFight()
    local BKMgr = BossKillMgr.instance;
    local monsId = FiveElmHelp.curBossId;
    local pos = FiveElmtMgr.GetMonsPos(monsId);
    if pos == nil then
        return;
    end
    BKMgr:StartNavPath(pos,0,2,monsId);
end

function My:AddLsnr()
    EventMgr.Add("OnChangeScene", EventHandler(self.OnChgScene,self));
    UIMainMenu.eHide:Add(self.SetBtnState,self);
    SecretDropEff:AddLsnr();
end

function My:RemoveLsnr()
    EventMgr.Remove("OnChangeScene", EventHandler(self.OnChgScene,self));
    UIMainMenu.eHide:Remove(self.SetBtnState,self);
    SecretDropEff:RemoveLsnr();
end

--场景改变
function My:OnChgScene()
    UIFiveElmntMons:Close();
    UIFiveElmntView:Close();
    UIFiveElmntMons:Open();
end

--设置掉落统计及退出按钮状态
function My:SetBtnState(value)
    if self.LayBtn ~= nil then
        self.LayBtn:SetActive(value);
    end
    if self.RwdBtn ~= nil then
        self.RwdBtn:SetActive(value);
    end
    if self.ExitBtn ~= nil then
        self.ExitBtn:SetActive(value);
    end
end

--自定义打开
function My:OpenCustom()
    UIFiveElmntMons:Open();
    self:AddLsnr();
end

--自定义关闭
function My:CloseCustom()
    UIFiveElmntMons:Close();
    UIFiveElmntRwd:Close();
    UIFiveElmntView:Close();
    UIFiveElmntLayer:Close();
    SecretDropEff:Clear();
    self:RemoveLsnr();
end

--选择怪物条目
function My.SelectItem(monsItem)
    if My.monsItem ~= nil then
        My.monsItem:SetSelect(false);
        My.monsItem = nil;
    end
    if monsItem == nil then
        return;
    end
    monsItem:SetSelect(true);
    My.monsItem = monsItem;
end

--秘境切换点击
function My:LayBtnC()
    UIFiveElmntLayer:Open();
end

--点击掉落统计
function My:DropRwdViewC()
    UIFiveElmntRwd:Open();
end

--点击退出
function My:ExitC()
    local msg = "是否确定退出当前秘境？";
    MsgBox.ShowYesNo(msg,self.YesCb, self, "退出");
end

--前往回调
function My:YesCb()
    SceneMgr:QuitScene();
end

function My:ConDisplay()
	do return true end
end

--释放资源
function My:DisposeCustom()
    UIFiveElmntMons:Dispose();
end

--更新
function My:Update()
    SecretDropEff:Update();
end

return My;