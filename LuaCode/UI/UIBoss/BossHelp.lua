require("UI/UIBoss/BossEnter");
BossHelp={Name="BossHelp"};

local My = BossHelp;
local BKMgr = BossKillMgr.instance;

--当前对象
My.curGo = nil;
--当前类型  1世界boss 2洞天福地 3个人Boss 4幽冥地界 5神兽岛 6神兽岛跨服 7远古遗迹
My.curType = 1;
--当前层
My.curLayer = nil;
--当前类
My.curC = nil;
--当前boss格子
My.CurCell = nil;

--模型根节点
My.ModelRoot = nil;
--掉落描述
My.DropDesc = nil;
--选择的id
My.SelectId = nil
--选择层级
My.SelectLayer=nil;
--选中tip
My.isTip=nil;
My.eSltBCell=Event()
My.eSltCare=Event();

function My.OpenBoss( type, layer) 
    My.curType = type;
    My.SelectLayer=layer;
    if type==5 or type==6 or type==7 then
        UICross.OpenCheck()
    else
        UIMgr.Open(UIBoss.Name)
    end
end

function My.Open(  )
    local lv = User.instance.MapData.Level
    local homeLock=SceneTemp["90021"].unlocklv
    if NetBoss.WorldTimes <=0 and  lv>=homeLock then
        My.curType = 2;
    end
    UIMgr.Open(UIBoss.Name)
end

function My.worldChoose(tp  )
    if My.SelectId~=nil then  return; end
    local lv =User.instance.MapData.Level;
    for k,v in pairs(SBCfg) do
        if v.type==tp then
            local sceneId = v.sceneId;
            info = SceneTemp[tostring(sceneId)];
            local clv = info.unlocklv
            if lv>=clv then
                if My.SelectId==nil or SceneTemp[tostring(SBCfg[tostring(My.SelectId)].sceneId)].unlocklv<clv then
                    My.SelectId=v.id
                end
            end
        end
    end
end

function My:setWhictClass( fun )
    self.ClassBig=fun
end

function My:bossFindPath( )
    local mostid = SelectBoss.BossId 
    if mostid~=nil and mostid~=0 then
        local pos = My.SetPos(mostid)
        BKMgr:StartNavPath(pos,0,3,mostid);
    end
end
--设置位置
function My.SetPos(typeId)
    local info = SBCfg[tostring(typeId)];
    if info == nil then
        return;
    end
    return Vector3.New(info.pos.k * 0.01, 0, info.pos.v * 0.01);
end

function My.inSenceGo()
    if UIMgr.Dic[UIBossList.Name]~=nil then
        UIBossList:SetDefaultInfo();
      if UIMgr.Dic[UIBoss.Name]~=nil  then
          UIBoss:Close();
      end  
    end
end

--选中and打开
function My.ChoseBossCellAndOpen(bossid)
    My.ChoseBossCell(bossid)
    if  My.curType==5 or My.curType==6 or My.curType==7 then
        local isOpenCross= UIMgr.GetActive(UIBoss.Name);
        if isOpenCross==-1 then
            UICross.OpenCheck()
        else
            CrossislBoss:SetDate();
        end
    else
        local isOpen= UIMgr.GetActive(UIBoss.Name);
        if isOpen ==-1 then
            UIMgr.Open(UIBoss.Name)
        else
            UIBoss:SetTargetData();
        end
    end
end
--副本选择
function My.CopyScelect( )
    if My.SelectId~=nil then  return; end
    local lv =User.instance.MapData.Level;
    for k,v in pairs(SBCfg) do
        if v.type==3 then
            local copyid = v.sceneId;
            info = CopyTemp[tostring(copyid)];
            local clv = info.lv
            if lv>=clv then
                if My.SelectId==nil or CopyTemp[tostring(SBCfg[tostring(My.SelectId)].sceneId)].lv<clv then
                    My.SelectId=v.id
                end
            end
        end
    end
end

--选中的格子上bossID
function My.ChoseBossCell(bossid)
    if bossid==nil then
        return
    end
    local id = tostring(bossid)
    if type(id)==""  then
        id = tostring(bossid)
    end
    local info = SBCfg[id]
    if info==nil then
       iTrace.Error("soon","世界Boss配置表无此bossid="..id)
       return
    end
    My.SelectId=info.id;
    My.curType=info.type;
    My.SelectLayer=info.layer
end

--设置个个数据
function My.SetSelect(SelectId,curType ,SelectLayer )
    My.SelectId=SelectId;
    My.curType=curType;
    My.SelectLayer=SelectLayer
end

function My.isLock( Lock, btn , panel ,lv )
    if  lv < Lock then
        btn.enabled=false
        if panel~=nil then
            panel.gameObject:SetActive(false)
        end
    end
end

function My:Bintrodus( )
    local cur = self.curType+1000;
    local str=InvestDesCfg[tostring(cur)].des;
    UIComTips:Show(str, Vector3(-529,-249,0),nil,nil,nil,400,UIWidget.Pivot.BottomLeft);
end
function My:BintrodusText( )
    local cur = self.curType+1820;
    local str=InvestDesCfg[tostring(cur)].des;
    if My.curType==2 then
         if NetBoss.doubleISOpen then
            str=""
         else
            local max = NetBoss.GetAllCaveAssistTimes()
            local cur = NetBoss.CaveAssistTimes
           str= string.format( str,cur,max )
         end
    end
    self.introdusDec.text=str
end
--更新疲劳值
function My:UpdateTC()
    if self.Data == nil then
        return;
    end
    if self.Data.SetTimes == nil then
        return;
    end
    self.Data:SetTimes();
end

--更新Boss信息
function My:UpdateBI(bossList)
    if self.Data == nil then
        return;
    end
    if self.Data.Refresh == nil then
        return;
    end
     if self.SelectId==nil and self.curType==1 and  NetBoss.worlMaxKill~=nil  then
        self.SelectId=NetBoss.worlMaxKill
    end
    self.Index = self:GetIndex(bossList, self.SelectId)
    self.Data:Refresh(bossList, self.curType);
end
function My:GetIndex(list, id)
    if list and id then
        id=tonumber(id)
        for i,v in ipairs(list) do
            local x = v.type_id 
            if x == id then
                return i
            end
        end
    end
    return 1
end
--设置BossCell点击
function My:SlctBossCell(bossCell)
    if self.CurCell ~= nil then
        if self.CurCell.index ~= bossCell.index then
            self.CurCell:ClearSelect();
        end
    end
    BossModel:DestroyModel();
    self.CurCell = bossCell;
    local monsId = bossCell.MontId;
    self.SelectId=monsId;
    local what = bossCell.what
    self:SetDropDesc(monsId,what);
    -- if what==0 or what ==3 or  what==4 then
        -- self.IslDetal.gameObject:SetActive(false);
        self.Detail.gameObject:SetActive(true);
        -- WBossInfo:chosType(monsId,what);
        BossDetal:Setdesj(monsId,bossCell.NameTex,what,bossCell.curNum,self.curType)
    -- else
    --     self.Detail.gameObject:SetActive(false);
        -- IslDetal:Setdesj(bossCell.NameTex,what,bossCell.curNum,self.curType)
    -- end
    local uiPos = self.GetSBUiPos(monsId);
    local uiAgl = self.GetSBUiAgl(monsId);
    BossModel:ShowModel(self.ModelRoot,monsId,uiPos,uiAgl,what);
    self.eSltBCell();
    self.eSltCare(what);
    self:SetEnterBtn();
end

--打开第二成相机
function My:OpenModCam(index )
    self.modCamUI.gameObject:SetActive(true);
    local TF = TransTool.Find
    local root1 = TF(self.modCamUI,"bKillRcd")
    local root2 = TF(self.modCamUI,"AllRwd")
    if index==1 then
        root2.gameObject:SetActive(false)
        bKillRcd:Init(root1);
    elseif index==2 then
        root1.gameObject:SetActive(false)
        bossRwdAll:Init(root2);
    end
end
--关闭第二成相机
function My:CloseModCam(  )
    if self.modCamUI~=nil then
        self.modCamUI.gameObject:SetActive(false);
    end
    bKillRcd:Clear()
    bossRwdAll:Clear()
end

--设置数据
function My:SetData(type, layer, class, go)
    self.curType = type;
    self.curGo = go;
    self.curC = class;
    self.Data = ObjPool.Get(class);
    if self.SelectLayer~=nil then
        layer=self.SelectLayer;
    end
    self.curLayer = layer;
    if type == 3  then
        NetBoss:ReqUpBInfo(type,layer);
    end
    self:BintrodusText()
    self.Data:Open(self.curGo);
end
--设置数据
function My:SetDataDrop( class, go)
    self.curGo = go;
    self.curC = class;
    self.Data = ObjPool.Get(class);
    self.Data:Open(self.curGo);
end


function My:SendReqUpBInfo( )
    NetBoss:ReqUpBInfo(self.curType,self.curLayer);
end

--设置进入按钮
function My:SetEnterBtn()
    local text = "立即前往";
    local type = self.curType;
    if type == 3 then
        -- if self.CurCell ~= nil then
        --     local vipLv = VIPMgr.GetVIPLv();
        --     if vipLv < 4 then
        --         text = "[FF9808FF]Vip4[-]立即前往"
        --     end
        -- end
    elseif type == 2 then
        local sceneId = tostring(self.Data.mapId);
        text   = self:GetBtnText(sceneId);
    end
    self.EntBtnLbl.text = text;
end
--获取文本内容
function My:GetBtnText(sceneId)
    local text = "立即前往";
    local text2 = "";
    local info = SceneTemp[sceneId];
    if info == nil then
        return text;
    end
    local vipLv = VIPMgr.GetVIPLv();
    if vipLv < info.fvipLv then
        text = string.format("[FF9808FF]Vip%s[-]立即前往",info.fvipLv);
    end
    return text;
end


--给些需要的obj
function My:Setgbj( TIP,Detail,ModelRoot,EntBtnLbl,DropDesc,modCamUI,introdusDec )
    self.TIP=TIP;
    self.Detail=Detail
    -- self.IslDetal=IslDetal
    self.ModelRoot=ModelRoot
    self.EntBtnLbl=EntBtnLbl
    self.DropDesc=  DropDesc
    self.modCamUI=modCamUI
    self.introdusDec=introdusDec
end

--设置和平显示
function My:TIPShow(bool)
    if self.isTip~=bool then
        self.isTip=bool;
        self.TIP:SetActive(bool);
    end
end


function My:CheckAtkLim(typeId )
    local canAtk = false
    local info = My.GetMonsInfo(typeId)
    if info ==nil or info.atkLim==nil or info.atkLim==0 then
        return true
    end
    local lv = User.instance.MapData.Level 
    if lv<=info.atkLim then
        canAtk = true
    end
    return canAtk
end
--获取怪物信息
function My.GetMonsInfo(typeId)
    local idStr = tostring(typeId);
    local info = MonsterTemp[idStr];
    if info == nil then
        return nil;
    end
    return info;
end
--设置掉落描述
function My:SetDropDesc(monsId,what)
    local t = self.curType
    if t == 3 or what~=0 then
        -- if self.DropDesc.gameObject.activeSelf == true then
            self.DropDesc.gameObject:SetActive(false);
        -- end
        return;
    end
    local check =self:CheckAtkLim(monsId )
    self.DropDesc.gameObject:SetActive(not check);
end

--获取世界bossUI位置
function My.GetSBUiPos(montId)
    local info = SBCfg[tostring(montId)];
    if info == nil then
        return nil;
    end
    return info.uiPos;
end

--获取世界bossUI角度
function My.GetSBUiAgl(montId)
    local info = SBCfg[tostring(montId)];
    if info == nil then
        return nil;
    end
    return info.uiElAgl;
end
--点击进入
function My:EnterC()
    if self.Data == nil then
        return;
    end
    local mapId=User.instance.SceneId;
    local scenceInfo=SceneTemp[tostring(mapId)];
    local PlaceType =scenceInfo.maptype
    if PlaceType==2 then
        UITip.Log("副本不允许跳转")
        return
    end
    if My.CurCell ==nil then
        UITip.Log("先选中要击败boss")
        return
    end
    local toscenceId = My.CurCell.sceneId 
    local nextscenceinfo = SceneTemp[tostring(toscenceId)];
    local sameScence = GameSceneManager.instance:CheckSceneName(nextscenceinfo.res)
    if scenceInfo.mapchildtype ~=nil and sameScence==false  then
        UITip.Log("请先退出当前地图")
        return
    end
    SelectBoss:SetSelectBoss(self.SelectId);    
    self.Data:EnterMap();
end
function My:ClearDate(  )
    if self.Data ~= nil then
        self.Data:Close();
        ObjPool.Add(self.Data);
        self.CurCell = nil;
    end
end

--获取消耗道具信息
function My.GetCostInfo(mapId,enterTime)
    local info = SceneTemp[tostring(mapId)];
    if info == nil then
        return;
    end
    if info.costItems == nil then
        return;
    end
    local item = info.costItems;
    local len = #info.costItems;
    for i = 1,len do
        if item[i].x == enterTime then
            return item[i].y, item[i].z;
        end
    end
end


--清里个个数据
function My.ClearSelect( )
    My.SelectId=nil;
    My.curType=nil;
    My.SelectLayer=nil
end
function My:Clear(  )
    self:CloseModCam(  )
    self:ClearDate()
    self.ClearSelect();
    -- TableTool.ClearUserData(self);
end
return My;