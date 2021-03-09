UICross=UIBase:New{Name="UICross"}
require("UI/Cross/CrossislBoss")
local My = UICross
--神兽岛5跨服神兽岛6远古7
My.SelectType=0;
--当前层神兽岛5跨服神兽岛6远古7
My.curType=0;
--选择小层级
My.SelectLayer=1;
--选择的单个
My.SelectId=nil;
--选择的脚本
My.Data=nil;

function My.OpenCheck( )
    -- if CrossMgr.crossOpen==false then
    --     UITip.Log("服务器匹配中，无法进入")
    -- else
        UIMgr.Open(UICross.Name)
    -- end
end
function My:OpenTabByIdxBeforOpen(t1, t2, t3, t4)
    My:setSelect(t1,t2,t3)
end
function My:OpenTabByIdx(t1, t2, t3, t4)
    
end

function My:setSelect(SelectType,SelectLayer,SelectId)
    if SelectLayer==nil or SelectLayer==0 then
        SelectLayer=1
    end
    BossHelp.curType=SelectType
    BossHelp.SelectLayer=SelectLayer
    BossHelp.SelectId=SelectId~=0 and SelectId or nil
    My.SelectType=SelectType;
    My.SelectLayer=SelectLayer;
end

function My:InitCustom(  )
    if UIMgr.GetActive(UIBoss.Name)~=-1 then
        UIBoss:Close()
    end
	local root = self.root;
    local TF = TransTool.Find;
    local UC = UITool.SetLsnrClick;
    local US = UITool.SetBtnSelf
    local TFC = TransTool.FindChild;
    local CG = ComTool.Get;
    local name = "UICross"
    self.nextTime=CG(UILabel,root,"next/NextTime")
    self:doTime()
    local btnRoot = TF(root,"tipBtn/Grid")
    self.IslandBtn =  CG(UIToggle,btnRoot,"ToggleIsland");
    self.IslandBtnGbj = self.IslandBtn.gameObject;
    UC(btnRoot, "ToggleIsland", name, self.TglC, self);
    self.OutIslandBtn =  CG(UIToggle,btnRoot,"ToggleOutIsland");
    self.OutIslandBtnGbj = self.OutIslandBtn.gameObject;
    UC(btnRoot, "ToggleOutIsland", name, self.TglC, self);
    self.RemBtn=CG(UIToggle,btnRoot,"ToggleRemnant", name);  
    self.RemBtnGbj = self.RemBtn.gameObject;
    UC(btnRoot, "ToggleRemnant", name, self.TglC, self);

    UC(root,"CloseBtn",name,self.CloseC,self)
    self.crossOb=TF(root,"CrossislBoss")
    CrossislBoss:Init( self.crossOb)
    self.lv = User.instance.MapData.Level
    self.islandLock=SceneTemp["90201"].unlocklv
    self.RemLock =SceneTemp["90301"].unlocklv
    self.OutIslandLock=SceneTemp["90202"].unlocklv   
    BossHelp.isLock(self.islandLock, self.IslandBtn,nil,self.lv )
    BossHelp.isLock(self.RemLock, self.RemBtn,nil,self.lv ) 
    BossHelp.isLock(self.OutIslandLock, self.OutIslandBtn,nil,self.lv)
    self:openCHoose()
    self:Lsnr("Add")
end
function My:Lsnr( fun )
    EventMgr[fun]("UICameraOpen",My.SetSelfActiveTrue)
    EventMgr[fun]("UICameraClose",My.SetSelfActiveFalse)
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
function My:doTime(  )
    local str = ""
    if CrossMgr.nextTime~=nill and CrossMgr.nextTime ~=0 then
        local time =  DateTool.GetDate(CrossMgr.nextTime):ToString("MM月dd日HH时mm分")
        str= string.format( "[F39800FF]下次分配日期：[-][00FF00FF]%s[-]",time )
    end
    self.nextTime.text=str
end

function My:openCHoose( )
    local t = self:checkType()
    local go = nil
    if t ==5 then
        go=self.IslandBtnGbj 
    elseif t ==6 then
        go=self.OutIslandBtnGbj 
    elseif t ==7 then
        go=self.RemBtnGbj 
    else
        iTrace.Error("soon","下标传入错误")
        go=self.IslandBtnGbj 
    end
    self:TglC( go ,true )
end
function My:checkType( )
    local t = BossHelp.curType
    if BossHelp.curType==nil or BossHelp.curType==0 or BossHelp.curType<5 then
        t=My.SelectType==0 and 5 or My.SelectType
    end
    if t==5 and self.lv < self.islandLock then
        t=5
    elseif t == 6 and self.lv < self.OutIslandLock then
        t=5
    elseif t == 7 and self.lv < self.RemLock then
        t=5
    end
    return t
end

function My:checkOpen( go,checkName,lock )
    if go.name == checkName and self.lv < lock then
        UITip.Log(UserMgr:chageLv(lock).."开启，角色等级尚未达到")
        return true;
    end
        return false;
end
function My:TglC(go,bool )
    if self.TagG ~= nil and self.TagG.name == go.name then
        return;
    end
    local reboolone = false;
    if self:checkOpen(go,"ToggleIsland",self.islandLock) then
        reboolone = true
    elseif self:checkOpen(go,"ToggleRemnant",self.RemLock) then
        reboolone = true
    elseif self:checkOpen(go,"ToggleOutIsland",self.OutIslandLock) then
        reboolone = true
    end
    if index==6 and CrossMgr.crossOpen==false  then
        UITip.Log("服务器匹配中，无法进入")
        reboolone=true
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
    local goName = go.name
    if goName=="ToggleIsland" then
        self:PanelChoose(5);
        self.IslandBtn.value=true
    elseif goName =="ToggleOutIsland" then
        self:PanelChoose(6);
        self.OutIslandBtn.value=true
    elseif goName =="ToggleRemnant" then
        self:PanelChoose(7);
        self.RemBtn.value=true
    end
end

function My:PanelChoose(index )
    if index==My.curType then
        return;
    end
    My.curType=index;
    if self.Data ~= nil then
        self.Data:Close();
        ObjPool.Add(self.Data);
    end
    if index==5 then
        self:SetDate(CrossislBoss)
        self.IslandBtn.value=true;
    elseif index==6 then
        self:SetDate(CrossislBoss)
        self.OutIslandBtn.value=true;
    elseif index==7 then
        self.RemBtn.value=true;
        self:SetDate(CrossislBoss)
    else
        iTrace.Error("soon","下标传入错误")
    end
end

function My:SetDate( class)
    self.Data = ObjPool.Get(class);
    self.Data:SetSelct(My.curType,BossHelp.SelectLayer,BossHelp.SelectId);
    self.Data:Open();
    -- self.Data:Init(go);
end

function My:Clear( )
    self.SelectType=0;
    self.curType=0;
    self.SelectLayer=1;
    self.SelectId=nil;
    if self.Data~=nil then
        self.Data:Close();
        ObjPool.Add(self.Data);
        self.Data=nil;
    end
    CrossislBoss:Clear()
end
function My:CloseC(  )
    self:Close()
end

return My;