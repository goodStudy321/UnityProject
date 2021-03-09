CrossislBoss = Super:New{Name="CrossislBoss"}
local My = CrossislBoss

---当前对象
My.curGo = nil;
--当前类型  1世界boss 2洞天福地 3个人Boss 4幽冥地界 5神兽岛 6神兽岛跨服
My.curType = 6;
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
--选中格子
My.eSltBCell = Event();
--x选择脚本
My.Date=nil

function My:SetSelct(curType, SelectLayer,SelectId )
    My.curType=curType
    My.SelectLayer=SelectLayer;
    My.SelectId=SelectId;
    BossHelp.SetSelect(My.SelectId,My.curType ,My.SelectLayer )
end

function My:Init( go )
    local name = "CrossislBoss";
	local trans = go.transform;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    local FC = TransTool.FindChild;
    local CG = ComTool.Get;
    self.go=go.gameObject
    self.ModelRoot = TF(trans,"rt/BossModel",name);
    self.ModBg = TF(trans,"ModBg",name);
    self.Detail = FC(trans, "Detail", name);
    BossDetal:Init(self.Detail)
    self.TIP=TF(trans,"TIP",name).gameObject;
    self.DropDesc = CG(UILabel,trans,"DropDesc",name,false);
    self.DropDesc.gameObject:SetActive(false);
    self.modCamUI=TF(trans,"modCamUI");
    self.modCamUI.gameObject:SetActive(false);
    self.islandOB=TF(trans,"IslandBoss",name);
    self.OutislandOB=TF(trans,"OutIslandBoss",name);
    self.OutislandOB=TF(trans,"OutIslandBoss",name);
    self.RemOB = TF(trans,"RemnantBoss",name);
    UC(trans,"EnterBtn",name,BossHelp.EnterC,BossHelp);

    self.bossPrefeb=FC(trans,"BossCell")
    soonTool.setPerfab(self.bossPrefeb,"BossCell")

    UC(trans, "introdus", name, BossHelp.Bintrodus, BossHelp);    
    self.introdusDec=CG(UILabel,trans,"introdus/dec",name)
    self:Lsnr("Add")
    self.EntBtnG = TF(trans,"EnterBtn",name);
    self.EntBtnLbl = CG(UILabel,trans,"EnterBtn/Label",name,false);
    BossHelp:Setgbj(self.TIP,self.Detail,self.ModelRoot,self.EntBtnLbl,self.DropDesc,self.modCamUI,self.introdusDec)   
    -- self.BossCostTip=FC(trans,"CostTip",name);
    -- BossCostTip:init(self.BossCostTip);
    self.lv = User.instance.MapData.Level
    -- self:SetDate();
    BossHelp:setWhictClass( self )
end

function My:SetPotorl(  )
    soonTool.setPerfab(self.bossPrefeb,"BossCell")
end

function My:Open(  )
    local class = nil
    local go = nil
    if My.curType==5 then
        class=IslandBoss;
        go= self.islandOB
    elseif My.curType==6 then 
        class=OutIslandBoss;
        go= self.OutislandOB
    elseif My.curType==7 then 
        class=RemnantBoss;
        go= self.RemOB
    else
        My.curType=5 
        class=IslandBoss;
        go= self.islandOB
    end
    self.go:SetActive(true)
    self:SetDate(class,go  )
end

function My:SetDate( class,go )
    BossHelp:ClearDate();
    BossModel:DestroyModel();
    if My.curLayer ==nil or My.curLayer ==0 then
        My.curLayer =1
    end
    BossHelp:SetData(My.curType,My.curLayer ,class,go);
end
function My:Lsnr( fun )
    NetBoss.eUpTieTime[fun](NetBoss.eUpTieTime,self.UpdateTC,self);
    NetBoss.eUpBInfo[fun](NetBoss.eUpBInfo,self.UpdateBI,self);  
end

function My:UpdateTC(  )
    BossHelp:UpdateTC()
end
function My:UpdateBI( bossList )
    BossHelp:UpdateBI(bossList)
end
--设置右侧显示隐藏
function My:SetRightAct(show)
    self.EntBtnG.gameObject:SetActive(show);
    self.ModBg.gameObject:SetActive(show);
    self.ModelRoot.gameObject:SetActive(show);
    self.IslDetal.gameObject:SetActive(false);
    self.Detail:SetActive(show)
end
--重置boss奖励格子
function My:RepRwd(go)
    BossRwd:RepRwd();
end
--打开记录
function My:OpenRcd( )
    bKillRcd:Init(self.bKillRcd);
end
--点击进入
function My:EnterC()
    if CrossMgr.crossOpen then
        BossHelp:EnterC()
    else
        UITip.eLog("服务器匹配中，无法进入")
    end
end

function My:Close(  )
    BossHelp:ClearDate();
    BossModel:DestroyModel();
end
function My:Clear()  
    BossHelp:Clear();
    BossRwd:Dispose();
    self:Lsnr("Remove")
    soonTool.DesGo("BossCell")
end