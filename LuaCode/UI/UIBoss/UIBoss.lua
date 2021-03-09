require("UI/UIBoss/DropRecord");
require("UI/UIBoss/HomeOfBoss");
require("UI/UIBoss/PersonalBoss");
require("UI/UIBoss/WildFBoss");
require("UI/UIBoss/WorldBoss");
require("UI/UIBoss/UIComView");
-- require("UI/UIBoss/WBossInfo");
require("UI/UIBoss/BossRwd");
require("UI/UIBoss/BossModel");
require("Data/Boss/SelectBoss");
require("UI/UIBoss/BossCostTip");
require("UI/UIBoss/BossCare");
require("UI/UIBoss/bKillRcd");
require("UI/UIBoss/IslandBoss");
require("UI/UIBoss/OutIslandBoss");
require("UI/UIBoss/BossDetal");
require("UI/UIBoss/BossHelp");
require("UI/UIBoss/RemnantBoss");
require("UI/UIBoss/WBossRem")
require("UI/UIBoss/bossRwdAll")

UIBoss = UIBase:New{Name ="UIBoss"}

local My = UIBoss;

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

--掉落描述
My.DropDesc = nil;
--选择的id
My.SelectId = nil

--选择层级
My.SelectLayer=nil;
--选中tip
My.isTip=nil;
My.redLst={}
--选中的格子上bossID
function My.ChoseBossCell(bossid)
    local id = tostring(bossid)
    local info = SBCfg[id]
    if info==nil then
        iTrace.Error("soon","无此bossid请检查配置表id="..id)
    end
    My.SelectId=info.id;
    My.curType=info.type;
    My.SelectLayer=info.layer
    BossHelp.SetSelect(My.SelectId,My.curType ,My.SelectLayer )
end

function My:OpenTabByIdxBeforOpen(t1, t2, t3, t4)
   BossHelp.curType=t1
   BossHelp.SelectLayer=t2
end
function My:OpenTabByIdx(t1, t2, t3, t4)

end

function My:InitCustom()
    local GetActive = UIMgr.GetActive(UICross.Name)
    if GetActive~=-1 then
        UICross:Close()
    end
    local name = "UIBoss";
	local trans = self.root;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    local FC = TransTool.FindChild;
    local CG = ComTool.Get;

    self.WBoss = TF(trans,"WBoss",name);
    self.HOfBoss = TF(trans,"HOfBoss",name);
    self.POfBoss = TF(trans,"POfBoss",name);
    self.WildF = TF(trans,"WildForbid",name);
    -- self.islandB = TF(trans,"IslandBoss",name);
    -- self.RemB = TF(trans,"RemnantBoss",name);
    self.DropR = TF(trans,"DropRecord",name);
    self.ModelRoot = TF(trans,"rt/BossModel",name);
    self.ModBg = TF(trans,"ModBg",name);
    self.Detail = FC(trans, "Detail", name);
    BossDetal:Init(self.Detail)
    -- self.IslDetal = TF(trans,"Detail/IslDetal");
    -- IslDetal:Init(self.IslDetal);
    self.bossPrefeb=FC(trans,"BossCell")
    soonTool.setPerfab(self.bossPrefeb,"BossCell")
    self.worldBtn=CG(UIToggle,trans,"ToggleWorld", name);
    self.homeBtn=CG(UIToggle,trans,"ToggleHome", name);
    self.perBtn=CG(UIToggle,trans,"TogglePer", name);
    self.wildBtn=CG(UIToggle,trans,"ToggleWild", name);

    self.dropBtn=CG(UIToggle,trans,"ToggleDrop", name);    
    self.TIP=TF(trans,"TIP",name).gameObject;
    self.DropDesc = CG(UILabel,trans,"DropDesc",name,false);
    self.DropDesc.gameObject:SetActive(false);
    self.modCamUI=TF(trans,"modCamUI");
    self.modCamUI.gameObject:SetActive(false);
    -- self.what3Lb =FC(trans,"Detail/what3Lb")
--红点处理
    self.redLst[1]=FC(trans,"ToggleWorld/red")
    self.redLst[1]:SetActive(NetBoss.redLst[1])

    UC(trans, "ToggleWorld", name, self.TglC, self);
    UC(trans, "ToggleHome", name, self.TglC, self);
    UC(trans, "TogglePer", name, self.TglC, self);
    UC(trans, "ToggleWild", name, self.TglC, self);
    UC(trans, "ToggleDrop", name, self.TglC, self);
    UC(trans,"CloseBtn",name,self.CloseC,self);
    UC(trans,"EnterBtn",name,BossHelp.EnterC,BossHelp);
    UC(trans, "introdus", name, BossHelp.Bintrodus, BossHelp);    
    self.introdusDec=CG(UILabel,trans,"introdus/dec",name)
    self:Lsnr("Add")
    self.EntBtnG = TF(trans,"EnterBtn",name);
    self.EntBtnLbl = CG(UILabel,trans,"EnterBtn/Label",name,false);
    BossHelp:Setgbj(self.TIP,self.Detail,self.ModelRoot,self.EntBtnLbl,self.DropDesc,self.modCamUI,self.introdusDec)   
    self.lv = User.instance.MapData.Level
    self.homeLock=SceneTemp["90021"].unlocklv
    self.perLock=SceneTemp["90031"].unlocklv
    self.wildLock=SceneTemp["90101"].unlocklv
    BossHelp.isLock(self.homeLock, self.homeBtn,self.HOfBoss,self.lv )
    BossHelp.isLock(self.perLock, self.perBtn,self.POfBoss,self.lv )
    BossHelp.isLock(self.wildLock, self.wildBtn,self.WildF,self.lv )
    self:SetTargetData();
    BossHelp:setWhictClass( self )
end

function My:Lsnr( fun )
    NetBoss.eUpTieTime[fun](NetBoss.eUpTieTime,self.UpdateTC,self);
    NetBoss.eUpBInfo[fun](NetBoss.eUpBInfo,self.UpdateBI,self);
    NetBoss.edouble[fun](NetBoss.edouble,BossHelp.BintrodusText,BossHelp);
    -- BossHelp.eSltBCell[fun](BossHelp.eSltBCell,self.ctrOpen,self);
    -- BossHelp.eSltCare[fun](BossHelp.eSltCare,self.doCareActive,self);
    EventMgr[fun]("UICameraOpen",My.SetSelfActiveTrue)
    EventMgr[fun]("UICameraClose",My.SetSelfActiveFalse)
end

function My:SetPotorl(  )
    soonTool.setPerfab(self.bossPrefeb,"BossCell")
end

function My:UpdateTC(  )
    BossHelp:UpdateTC()
end
function My:UpdateBI( bossList )
    BossHelp:UpdateBI(bossList)
end

function My.SetSelfActiveTrue(  )
    if LuaTool.IsNull(My.root) then
    return
    end
    My.root.gameObject:SetActive(true)
end
function My.SetSelfActiveFalse(  )
    if LuaTool.IsNull(My.root) then
        return
    end
    My.root.gameObject:SetActive(false)
end
-- --打开记录
-- function My:OpenModCam(go )
--     bKillRcd:Init(UIBoss.modCamUI,1);
-- end
function My:SetTargetData()
    local t = self:checkType();
    local TF = TransTool.Find;
    local trans = self.root
    local go = nil
    if t == 1 or t == nil then
        self.worldBtn.value=true;
        go = TF(trans,"ToggleWorld", "InitData");
    elseif t == 2 then
        self.homeBtn.value=true;
        go = TF(trans,"ToggleHome", "InitData");
    elseif t == 3 then
        self.perBtn.value=true;
        go = TF(trans,"TogglePer", "InitData");
    elseif t == 4 then
        self.wildBtn.value=true;
        go = TF(trans,"ToggleWild", "InitData");
    -- elseif t == 5 then
    --     self.islandBtn.value=true;
    --     go = TF(trans,"ToggleIsland", "InitData");
    -- elseif t == 7 then
    --     self.RemBtn.value=true;
    --     go = TF(trans,"ToggleRemnant", "InitData");
    end
    if go then self:TglC(go,true) end
end

function My:checkType( )
    local t = My.curType==1 and BossHelp.curType or My.curType
    if t==4 and self.lv < self.wildLock then
        t=1
    -- elseif t == 5 and self.lv < self.islandLock then
    --     t=1
    -- elseif t == 7 and self.lv < self.RemLock then
    --     t=1
    end
    return t
end

-- --重置boss奖励格子
-- function My:RepRwd(go)
--     BossRwd:RepRwd();
-- end
--设置右侧显示隐藏
function My:SetRightAct(show)
    self.EntBtnG.gameObject:SetActive(show);
    self.ModBg.gameObject:SetActive(show);
    self.ModelRoot.gameObject:SetActive(show);
    self.DropDesc.gameObject:SetActive(false);
    -- self.IslDetal.gameObject:SetActive(false);
    self.Detail:SetActive(show)
end

function My:checkOpen( go,checkName,lock )
    if go.name == checkName and self.lv < lock then
        UITip.Log(UserMgr:chageLv(lock).."开启，角色等级尚未达到")
        return true;
    end
        return false;
end

--单选按钮点击
function My:TglC(go,bool)
    if self.TagG ~= nil and self.TagG.name == go.name then
        return;
    end
    local reboolone = false;
    if self:checkOpen(go,"ToggleHome",self.homeLock) then
        reboolone = true
    elseif self:checkOpen(go,"TogglePer",self.perLock) then
        reboolone = true
    elseif self:checkOpen(go,"ToggleWild",self.wildLock) then
        reboolone = true
    -- elseif self:checkOpen(go,"ToggleIsland",self.islandLock) then
    --     reboolone = true
    -- elseif self:checkOpen(go,"ToggleRemnant",self.RemLock) then
    --     reboolone = true
    end
    if reboolone then
        if bool==true then
          self.active=1
          self:CloseC()
        end
        return
    end
    if bool~=true then
        BossHelp.ClearSelect( );
    end
    self.TagG = go;
    BossHelp:ClearDate();
    BossModel:DestroyModel();
    if go.name == "ToggleWorld" then
        BossHelp:SetData(1,1,WorldBoss,self.WBoss);
        self:SetRightAct(true);
    elseif go.name == "ToggleHome" then
        BossHelp:SetData(2,1,HomeOfBoss,self.HOfBoss);
        self:SetRightAct(true);
    elseif go.name == "TogglePer" then
        BossHelp.CopyScelect();
        BossHelp:SetData(3,0,PersonalBoss,self.POfBoss);
        self:SetRightAct(true);
    elseif go.name == "ToggleWild" then
        BossHelp:SetData(4,1,WildFBoss,self.WildF);
        self:SetRightAct(true);
    -- elseif go.name == "ToggleIsland" then
    --     BossHelp:SetData(5,1,IslandBoss,self.islandB);
        -- self:SetRightAct(true);
    -- elseif go.name == "ToggleRemnant" then
    --     BossHelp:SetData(7,1,RemnantBoss,self.RemB);
    --     self:SetRightAct(true);
    elseif go.name == "ToggleDrop" then
        local Data = ObjPool.Get(DropRecord);
        self:SetRightAct(false);
        BossHelp:SetDataDrop(DropRecord,self.DropR);
    end
end


function My:CloseCustom()
    BossHelp:Clear();
    BossRwd:Dispose();
    BossModel:DestroyModel();
    DropRecord:Close()
    BossDetal:Clear( )
    self:Lsnr("Remove")
    soonTool.DesGo("BossCell")
    soonTool.DesGo("boosRcd1");
    soonTool.DesGo("boosRcd2");
end

--点击关闭
function My:CloseC(go)
    self:Close();
    JumpMgr.eOpenJump()
end

return My;