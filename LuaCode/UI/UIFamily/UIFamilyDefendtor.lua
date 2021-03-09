require("UI/UIFamily/UIDftItem")
require("UI/UIFamily/UIDftExit")
require("UI/UIFamily/UIDftRfMons")
UIFamilyDefendtor = UIBase:New{Name = "UIFamilyDefendtor"}
local My = UIFamilyDefendtor;
My.DftDic = {};

local BKMgr = BossKillMgr.instance;

function My:InitCustom()
    local trans = self.root;
	local name = "守护者界面";
	local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    local UC = UITool.SetLsnrSelf;

    self.Df1 = TF(trans, "Df1")
    self.Df2 = TF(trans, "Df2")
    self.Df3 = TF(trans, "Df3")
    self.ExitBtn = TF(trans, "ExitBtn")
    
    UC(self.Df1,self.Df1C,self, nil, false);
    UC(self.Df2,self.Df2C,self, nil, false);
    UC(self.Df3,self.Df3C,self, nil, false);
    UC(self.ExitBtn,self.ExitMap,self, nil, false);
    local exit = TF(trans,"ExitTip",name);
    local rfMons = TF(trans,"MonsTip",name);
    UIDftExit:Init(exit);
    UIDftRfMons:Init(rfMons);

    self:InitData();
    self:AddLsnr();
end

function My:OpenCustom()
    self:InitData();
end

function My:CloseCustom()
    
end

--初始化数据
function My:InitData()
    local trans = self.root;
	local name = "守护者界面";
    local CG = ComTool.Get;
    local TF = TransTool.FindChild;
    My.DftDic = {};
    for i = 19,21 do
        local index = i -  18;
        local headPath = string.format("Df%s",index);
        local pathName = string.format("%s/Label",headPath);
        local pathHp = string.format("%s/HPSlider",headPath);
        local behit = string.format("%s/Behit",headPath);
        local dead = string.format("%s/Dead",headPath);
        local pos,monsId = self.GetMonsInfo(i);
        local item = UIDftItem:New();
        item.HeadIcon = CG(UISprite,trans,headPath,name,false);
        item.HeadIcon.color = Color.New(1, 1, 1,1);
        item.Name = CG(UILabel,trans,pathName,name,false);
        item.Hp = CG(UISlider,trans,pathHp,name,false);
        item.BehitG = TF(trans,behit,name);
        item.BehitG:SetActive(false);
        item.DeadG = TF(trans,dead,name);
        item.DeadG:SetActive(false);
        item.timer = ObjPool.Get(iTimer);
        item.timer.complete:Add(item.HitTimeCount,item);
        My.DftDic[monsId] = item;
        self:SetInfo(monsId);
    end
end

--添加监听
function My:AddLsnr()
    FamilyActivityMgr.eRfrDftHP:Add(self.SetHp,self);
    UIMainMenu.eHide:Add(self.Hide,self);
    local EM = EventMgr.Add;
    local EH = EventHandler;
end

--移除监听
function My:RemoveLsnr()
    FamilyActivityMgr.eRfrDftHP:Remove(self.SetHp,self);
    UIMainMenu.eHide:Remove(self.Hide,self);
    EventMgr.Remove("FamilyRelife",self.OnDead);
end

function My:Hide(value)
    self.Df1:SetActive(value)
    self.Df2:SetActive(value)
    self.Df3:SetActive(value)
    self.ExitBtn:SetActive(value)
 end

--设置数据
function My:SetInfo(monsId)
    local info = MonsterTemp[tostring(monsId)];
    if info == nil then
        return;
    end
    self:SetName(monsId,info.name);
    local hpPer = My.GetDftHpPersent(monsId);
    self:SetHp(monsId,hpPer,true);
end

--获取守护者血量比
function My.GetDftHpPersent(monsId)
    local fam = FamilyActivityMgr;
    if fam == nil then
        return 1;
    end
    if fam.DftHPDic == nil then
        return 1;
    end
    if fam.DftHPDic[monsId] == nil then
        return 1;
    end
    return fam.DftHPDic[monsId];
end

--初始化名字
function My:SetName(monsId,name)
    local item = My.DftDic[monsId];
    if item == nil then
        return;
    end
    if item.Name == nil then
        return;
    end
    item.Name.text = name;
end

--设置血量
function My:SetHp(monsId,hpPer,bInit)
    local item = My.DftDic[monsId];
    if item == nil then
        return;
    end
    self:SetBehitEffect(item,hpPer,bInit);
    self:SetDead(item,hpPer);
    if item.Hp == nil then
        return;
    end
    item.Hp.value = hpPer;
end

--设置受击效果
function My:SetBehitEffect(item,hpPer,bInit)
    if bInit == true then
        return;
    end
    if hpPer == 0 then
        item.BehitG:SetActive(false);
        return;
    end
    item:StartTimer();
    if item.BehitG == nil then
        return;
    end
    if item.BehitG.activeSelf == true then
        return;
    end
    item.BehitG:SetActive(true);
end

--设置死亡
function My:SetDead(item,hpPer)
    if hpPer > 0 then
        if item.DeadG.activeSelf == true then
            return;
        end
        item.DeadG:SetActive(false);
        return;
    end
    if item.HeadIcon == nil then
        return;
    end
    item.HeadIcon.color = Color.New(0, 1, 1, 1);
    if item.DeadG == nil then
        return;
    end
    item.DeadG:SetActive(true);
end

--点击防护者1
function My:Df1C(go)
    self:MoveTo(19);
end

--点击防护者2
function My:Df2C(go)
    self:MoveTo(20);
end

--点击防护者3
function My:Df3C(go)
	self:MoveTo(21);
end

--退出地图
function My:ExitMap(go)
    MsgBox.ShowYes("确认退出守卫道庭？",self.ExitCB,self);
end

--退出回调
function My:ExitCB()
    self:Close();
    SceneMgr:QuitScene();
end

--移动
function My:MoveTo(index)
    local pos,monsId = self.GetMonsInfo(index);
    BKMgr:StartNavPath(pos,0,-1,monsId);
end

--获取
function My.GetMonsInfo(index)
    local info = GlobalTemp[tostring(index)];
    if info == nil then
        return nil;
    end
    local value = info.Value2;
    if value == nil then
        return;
    end
    local monsId = value[1];
    local x = value[2];
    local z = value[3];
    if monsId==nil or x==nil or z==nil then
        return nil;
    end
    local pos = Vector3.New(x*0.01,0,z*0.01);
    return pos,monsId;
end

function My:Clear()

end

--持续显示 ，不受配置tOn == 1 影响
function My:ConDisplay()
	do return true end
end

function My:DisposeCustom()
    for k,v in pairs(My.DftDic) do
        if v.timer ~= nil then
            v.timer:AutoToPool();
            v.timer = nil
        end
        TableTool:ClearUserData(v);
        v = nil;
    end
    self:RemoveLsnr();
    UIDftExit:Dispose();
    -- UIDftRelife:Dispose();
    UIDftRfMons:Dispose();
end

return My;