require("UI/UIBoss/BLstInfo")
require("UI/UIBoss/UIHitBossRank")
require("UI/UIBoss/BossCopyLst")
UIBossList = UIBase:New{ Name = "UIBossList"}
local My = UIBossList;

--boss列表
My.BossList = {}
My.CurInfo = nil;
My.msList = {}
local dicName = {"Boss列表","小怪列表","伤害排行",}

function My:InitCustom()
    local name = "UIBossList";
	local trans = self.root;
    local CG = ComTool.Get;
    local TFC = TransTool.FindChild;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    local UCS = UITool.SetLsnrSelf;
    local svRoot = TF(trans,"Info/sv",name);
    --释放与否控
    EventMgr.Add("BegChgScene",self.disChange);
    self.cfg.cleanOp=0;
    self.lv = User.instance.MapData.Level    
    
    --提示小花女
    if self.lv>=GlobalTemp["138"].Value3 then
        UseTipHelp:CheckBossSence(40002)
    end
    self.svRooot=svRoot;
    self.sv=svRoot.gameObject;
    self.sv1 = TFC(svRoot,"1",name);
    self.sv2 = TFC(svRoot,"2",name);
    self.sv3 = TFC(svRoot,"3",name);
    -- UC(trans,"ExitBtn",name,self.ExitC,self);
   
    --刘海
    if ScreenMgr.orient==ScreenOrient.Left then
        UITool.SetLiuHaiAnchor(self.root, "Info", name, true)
    else
        -- UITool.SetLiuHaiAnchor(self.root, "ExitBtn", name, true,true)
    end
    ScreenMgr.eChange:Add(self.ScreenChange, self);
    local mapId=User.instance.SceneId;
    self.mapId=mapId
    self.scenceInfo=SceneTemp[tostring(mapId)];
    --组队
    self.team=TFC(trans,"Info/Team",name);
    -- self.BossTeam=ObjPool.Get(BossTeam)
    -- self.BossTeam:Init(self.team);
    self.UITeamSmallView=ObjPool.Get(UITeamSmallView);
    -- self.UITeamSmallView:New1(self.team)
    UILeftView.TeamView=self.UITeamSmallView:New1(self.team);
    UC(trans,"Info/bg/mosBtn",name,self.SetBtn,self);
    --分支是否为引导
 
    --end
    NetBoss.eUpMBInfos:Add(self.SetList,self);
    NetBoss.eUpMBInfo:Add(self.SetSglInfo,self);
    -- GuardMgr.eGuardUp:Add(self.checkBag,self);
    --判断是不是在幽冥禁地
    self.tip1=TFC(trans,"Info/bg/tip1",name);
    self.tip2=TFC(trans,"Info/bg/tip2",name)
    local bossPlace = self.scenceInfo.mapchildtype; 
    self.bossPlace = bossPlace;
    self.tipType=1;
    self.issm=false;
    self.hit=TF(trans,"Info/hit",name);
    self.hittg = CG(UIToggle,trans,"Info/bg/mosBtn",name);
    --排行提示
    self.RankHitTxT=CG(UILabel,self.hit,"Sprite/Label");
    self.help=TFC(trans,"Info/bg/help",name)
    if bossPlace~=1 and bossPlace~=3 and bossPlace~=4 then
        self.help:SetActive(true)
        UCS(self.help,self.helpOnClick,self,name);
    else
        self.help:SetActive(false)
    end
    if bossPlace~=4 and  bossPlace ~= 17  then
        self:SetGO(self.sv2,false);
        self:SetGO(self.sv3,false);
        self.bossbtn=CG(UIToggle,self.tip1.transform,"bossbtn",name);
        -- self.sv1:SetActive(true);
        self.UITable = CG(UITable,svRoot,"1/ScrollView1/Table",name,false);
        self.BossItem = TFC(svRoot,"1/ScrollView1/Table/BossItem",name);
        self.BossItem:SetActive(false);
        self.tipType=1;
        self.tip1:SetActive(true);
        self.tip2:SetActive(false);
        self.aclb=CG(UILabel,self.bossbtn.transform,"ac",name);
        self.unaclb=CG(UILabel,self.bossbtn.transform,"unac",name);
        -- self.bosLb=CG(UILabel,self.bossbtn.transform,"lb",name);
        UC(self.tip1.transform,"bossbtn",name,self.SetBtn,self,false);
        UC(self.tip1.transform,"team",name,self.SetBtn,self,false);
        self.RankHitTxT.text=InvestDesCfg["1101"].des;
    else
        self.UITable = CG(UITable,svRoot,"3/ScrollView3/Table",name,false);
        self.UITable2 = CG(UITable,svRoot,"2/ScrollView2/Table",name,false);
        self.BossItem2 = TFC(svRoot,"2/ScrollView2/Table/BossItem",name);
        self.sv1:SetActive(false);
       
        -- self.sv2:SetActive(true);
        self.BossItem2:SetActive(false);
        self.BossItem = TFC(svRoot,"3/ScrollView3/Table/BossItem",name);
        self.BossItem:SetActive(false);
        self.tipType=2;
        self.tip2:SetActive(true);
        self.tip1:SetActive(false);
        self.bossbtn=CG(UIToggle,self.tip2.transform,"bossbtn",name); 
        self.aclb=CG(UILabel,self.bossbtn.transform,"ac",name);
        self.unaclb=CG(UILabel,self.bossbtn.transform,"unac",name);
        -- self.bosLb=CG(UILabel,self.bossbtn.transform,"lb",name);       
        UC(self.tip2.transform,"bossbtn",name,self.SetBtn,self,false);
        UC(self.tip2.transform,"team",name,self.SetBtn,self,false);
        UC(self.bossbtn.transform,"choos",name,self.SetBtn,self,false);
        self.choosBtn=CG(UIToggle,self.bossbtn.transform,"choos");
        self.RankHitTxT.text=InvestDesCfg["1104"].des;
    end
    if bossPlace==2 then
        self.RankHitTxT.text=InvestDesCfg["1102"].des;
    end
    self.hiRank=TFC(trans,"Info/bg/mosBtn")
    if bossPlace==16 then
        self.hiRank:SetActive(false);
    else
        self.hiRank:SetActive(true);
    end
    self.bossbtn.value=true;
    UIHitBossRank:Init(self.hit);
    if bossPlace==1 then
        self.hittg.value=true;
        self:SetBtn(self.hittg.gameObject);
        self.hittg.gameObject:SetActive(false)
    else
        self.hittg.value=false;
        self:SetBtn(self.bossbtn.gameObject);
    end
    self.Timer = ObjPool.Get(DateTimer);
    self.Timer.complete:Add(self.EndCountDown, self);
    self.hlepOneMin=true
    -- euiclose:Add(self.openBlsCheck,self)
end

-- function My:openBlsCheck( name )
--     if name~=self.Name and not self.gbj.activeSelf then
--         self.gbj:SetActive(true);
--     end
-- end

	--释放与否控
function My.disChange( )
    My.cfg.cleanOp=1;
    My.active = 1
    My.Close(My)
end

function My:OpenCustom()
    iTrace.eError("soon","boss列表被打开")
    self.gbj:SetActive(true);
end

function My:helpOnClick( )
    if FamilyMgr.JoinFamily() then
        if  self.hlepOneMin then
            self.hlepOneMin=false  
            NetBoss.sendBossHelp()
            UITip.Log("已在道庭发送援助")  
            self.Timer.seconds = 61;
            self.Timer.cnt = 0;
            self.Timer:Start();
        else
            UITip.Log("你的伙伴正在来的路上，请一分钟后再发送援助")    
        end
    else
        UITip.Log("请先加入道庭")
    end
end

function My:EndCountDown()
    if self.Timer ~=nil then
        self.hlepOneMin=true
    end
end

--按钮点击设置
function My:SetBtn(go)
    local tg = ComTool.GetSelf(UIToggle,go);
  if tg.value==true then
    if go.name=="bossbtn" then
        if  self.aclb.text==dicName[3] then
            self:SetGO(self.hit, true);
            self:SetGO(self.sv,false);
            self:SetGO(self.team,false);
        else 
            self.hittg.value=false;
            self:SetGO(self.team,false);
            self:SetGO(self.hit,dalse);
            self:SetGO(self.sv,true);
           if self.tipType==1 then
            self:SetGO(self.sv1,true);
            else 
            self:SetGO(self.choosBtn,true);    
           end
           self:choseName(1)
        end
    elseif go.name=="team" then
        self:SetGO(self.sv,false);
        self:SetGO(self.hit,false);
        self:SetGO(self.team,true);
        self:SetGO(self.aclb,false);
        self:SetGO(self.unaclb,true);
        self:SetGO(self.choosBtn,false); 
    elseif go.name=="mosBtn" then
        self.bossbtn.value=true;
        self:SetGO(self.hit, true);
        self:SetGO(self.sv,false);
        self:SetGO(self.team,false);
        self:SetGO(self.choosBtn,false);   
        self:choseName(3);
    elseif go.name =="choos" then
        self:choseName(1);
    end
 else
    if go.name =="choos" then
        self:choseName(2);
    elseif go.name=="mosBtn" then
        self.bossbtn.value=true;
        self:SetGO(self.hit, false);
        self:SetGO(self.sv,true);
        self:SetGO(self.team,false);
        self:SetGO(self.choosBtn,true);           
        self:choseName(1);
    end
 end
end

function My:choseName(num )
    if num==1 then
        if  self.choosBtn==nil  then
            self:doNameBoss(1)
        elseif self.choosBtn.value then
            self:doNameBoss(1)
        elseif self.choosBtn.value ==false then
            self:doNameBoss(2)
        end
    elseif num==2 then
        self:doNameBoss(2)
    elseif num ==3 then
        self:doNameBoss(3);
    end
end
function My:doNameBoss(num)
    self.aclb.text=dicName[num];
    self.unaclb.text=dicName[num];
end

function My:SetGO( go,bool )
    if go~=nil then
        go.transform.gameObject:SetActive(bool);
    end
end

--刘海旋转
function My:ScreenChange(orient)
	if orient == ScreenOrient.Left then
        UITool.SetLiuHaiAnchor(self.root, "Info", name, true)
        -- UITool.SetLiuHaiAnchor(self.root, "ExitBtn", name, true)
	elseif orient == ScreenOrient.Right then
        UITool.SetLiuHaiAnchor(self.root, "Info", name, true, true)
        -- UITool.SetLiuHaiAnchor(self.root, "ExitBtn", name, true, true)
	end
end
--设置列表
function My:SetList()
    local showList = NetBoss.MapBossInfos;
    if showList == nil then
        return;
    end
    self:ClearBossList();
    if self.tipType==2 then
        self.issm=true;
        --刷新序列  
        local smdate =nil;
        if self.bossPlace==17 then
            self:getSmLst7(smdate);
        else
            local smdate = self.scenceInfo.update;
            self:getSmLst(smdate);
        end
    end
    for k,v in pairs(showList) do
        local info = ObjPool.Get(BLstInfo);
        info:Init(self.BossItem);
        info:SetData(v);
        self.BossList[k] = info;
    end
    if  SelectBoss.BossId~=0  then
        self:SetDefaultInfo();
    end
    self.UITable.repositionNow = true;
end
--设置小怪表信息
function My:getSmLst(smdate )
    if smdate==nil then return; end
    for k,va in pairs(smdate) do
        local v= WildMapTemp[tostring(va)];
        local id = v.mID;
        local info = ObjPool.Get(BLstInfo);
        local pos = Vector3.New((v.lbPos.x+v.rtPos.x)* 0.005,0,(v.lbPos.y+v.rtPos.y)* 0.005);
        info:Init(self.BossItem2,true);
        info:SetSmData(id,pos);
        My.msList[id]=info;
    end
    self.UITable2.repositionNow = true;
end

--设置小怪表信息
function My:getSmLst7( )
    local smdate=tRemCollect[tostring(self.mapId)]    
    if smdate==nil then return; end
    vecLst=smdate.vecLst
    local mapsm = NetBoss.MapMsInfos
    for i=1,#vecLst do
        local info = ObjPool.Get(BLstInfo);
        local vec = vecLst[i].attrs
        local id = vec[3].k
        local pos = Vector3.New((vec[1].k+vec[2].k)* 0.005,0,(vec[1].v+vec[2].v)* 0.005);
        info:Init(self.BossItem2,true);
        local time = nil;
        if mapsm[id] ~= nil then
            time=mapsm[id].nxtRfTime
        end
        info:SetSmData(id,pos,time);
        My.msList[id]=info;
    end
    self.UITable2.repositionNow = true;
end

--设置单个数据更新
function My:SetSglInfo(info,k,witch)
    if self.BossList == nil then
        return;
    end
    if witch then
       if self.BossList[k].typeId==info.typeId then
        self.BossList[k]:SetData(info); 
        else
            iTrace.eError("id没有对应上","k="..k.."  id="..info.typeId)
       end 
    else
        if self.msList[k].typeId==info.typeId and info.lv==0 then
            self.msList[k]:smTimeDo(info.nxtRfTime); 
       end 
    end
end

--设置默认选择信息
function My:SetDefaultInfo()
    for k,v in pairs(self.BossList) do
        if tostring(v.typeId) == SelectBoss.BossId then
            v:InfoC(nil);
            SelectBoss:Clear()
            return;
        end
    end
end

--设置当前信息
function My:SetCurInfo(info)
    if self.CurInfo ~= nil then
        self.CurInfo:SetSltState(false);
    end
    self.CurInfo = info;
end

--点击退出
function My:ExitC(go)
    MsgBox.ShowYesNo("是否退出当前场景",self.YesCb,self,"确定",self.NoCb,self,"取消");
end
--点击MsgBox的确定按钮
function My:YesCb()
    -- self:Clear();
    SceneMgr:QuitScene();
end
--点击MsgBox的取消按钮
function My:NoCb()
    return ;
end


--清除boss列表
function My:ClearBossList()
    self.issm=false;
    if self.BossList == nil then
        return;
    end
    for k,v in pairs(self.BossList) do
        v:DestroyGo();
        self.BossList[k] = nil;
    end
end
function My:CloseCustom(  )
    iTrace.eError("soon","boss列表被关闭")
end
function My:DisposeCustom()
    if self.Timer~=nil then
        self.Timer:AutoToPool();
        self.Timer = nil;
    end
    UILeftView.TeamView=UILeftView.utsvTeam;
    BossCopyLst:clear()
    if self.sv==nil then   
      return;
    end
    self:ClearBossList();
    self.CurInfo = nil;
    UIHitBossRank:Clear();
    ScreenMgr.eChange:Remove(self.ScreenChange, self);
    NetBoss.eUpMBInfos:Remove(self.SetList,self);
    NetBoss.eUpMBInfo:Remove(self.SetSglInfo,self);
    -- GuardMgr.eGuardUp:Remove(self.checkBag,self);
    for k,v in pairs(My.BossList) do
        v:DestroyGo();
        v=nil;
    end
    for k,v in pairs(My.msList) do
        v:DestroyGo();
        v=nil;
    end
    EventMgr.Remove("BegChgScene",self.disChange);
end

function My:Clear( isReconnect )
	if isReconnect then
        return
    end
    My.cfg.cleanOp=1;
    self.active = 0
    if LuaTool.IsNull(self.gbj)  then
		return
	end
    My:DisposeCustom()
	Destroy(self.gbj)
	AssetMgr:Unload(self.Name..".prefab")
    UIMgr.Dic[self.Name]=nil
end

return My;