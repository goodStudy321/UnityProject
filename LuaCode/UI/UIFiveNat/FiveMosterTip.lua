FiveMosterTip = Super:New{Name="FiveMosterTip"}
local My = FiveMosterTip

My.itemLst={}
My.CurSweedNum=1
function My:Init(root)
    self.root=root
    self.go=root.gameObject
    --常用工具
    local tip = "FiveMosterTip"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;

    self.bossRt=CG(UITexture,root,"tex_bossRt",tip)
    self.BossName=CG(UILabel,root,"tex_bossRt/lab_BossName",tip)
    self.fiveElm=CG(UILabel,root,"tex_bossRt/lab_fiveElm",tip)
    self.MyfiveElm=CG(UILabel,root,"tex_bossRt/lab_MyfiveElm",tip)
    self.bossLv=CG(UILabel,root,"tex_bossRt/lab_bossLv",tip)
    self.lowit=TFC(root,"tex_bossRt/gbj_lowit",tip)
    -- self.egTime=CG(UILabel,root,"lab_egTime",tip)
    -- self.SweepGbj= self.egTime.gameObject
    -- UC(root,"lab_egTime/uc_tomax",tip,self.tomaxClick,self)
    -- UC(root,"lab_egTime/uc_add",tip,self.addClick,self)
    UC(root,"uc_tip",tip,self.tipsClick,self)
    self.Sweep=CG(UISprite,root,"btn_Sweep",tip)
    self.Sweep3=CG(UISprite,root,"btn_Sweep3",tip)
    self.Sweeptf=self.Sweep.transform
    self.Sweep3tf=self.Sweep3.transform
    self.labNotSweep = TF(root, "lab_notSweep", tip)
    self.labNotSweepText = CG(UILabel, root, "lab_notSweep", tip)
    self.Enter=CG(UISprite,root,"btn_Enter",tip)
    UC(root,"uc_Close",tip,self.CloseClick,self)
    self.itmGrid=CG(UIGrid,root,"ScrollView/grid_itmGrid",tip)
    self.costShow=CG(UITexture,root,"tex_costShow",tip)
    self.num=CG(UILabel,root,"tex_costShow/lab_num",tip)
    self.RwdgetTxt=CG(UILabel,root,"lab_RwdgetTxt",tip)
    self.Title=CG(UILabel,root,"Title",tip)
    self:ClickEvent()
    AssetMgr:Load(FiveCopyHelp.illIconTxt,ObjHandler(self.LoadIllIcon1,self));
end
--加载icon完成
function My:LoadIllIcon1(obj)
	if self.costShow == nil then
        AssetTool.UnloadTex(obj.name)
        return;
    end
    self.costShow.mainTexture=obj;    
end
--加载icon完成
-- 
function My:Open(  )
    if FiveCopyHelp.CurMapSlct==nil then
        FiveCopyTip:Close()
       return
    end
    local copyid = FiveCopyHelp.CurMapSlct.copyId
    self.CopyId=copyid
    if copyid>FiveCopyHelp.ChallengeId then
        UITip.Log("请通关前面关卡")
        FiveCopyTip:Close()
        return
    end
    if copyid==FiveCopyHelp.ChallengeId then
       self.notSweep=true
    else
        self.notSweep=false
    end
    self.Msg = FvElmntCfg[tostring(copyid)]
    if self.Msg==nil then
        iTrace.Error("soon","副本id没有找到："..copyid)
        FiveCopyTip:Close()
        return
    end
    self.go:SetActive(true)
    self:SetTilt( self.Msg )
    self:SetBossMsg( self.Msg )
    self:ShowItem( self.Msg )
    self:SetBtn( self.Msg )
end

function My:SetBtn( msg )
    local cost = msg.costIllusion
    local Sweep = self.Sweeptf.gameObject
    local Sweep3 = self.Sweep3tf.gameObject
    local notSweepObj = self.labNotSweep.gameObject
    local notSweepLab = self.labNotSweepText
    self.costOne=cost
    self.num.text=self.costOne
    if   self.notSweep then
        --没有首通，隐藏扫荡按钮，显示提示文本
        Sweep:SetActive(not self.notSweep)
        Sweep3:SetActive(not self.notSweep)
        notSweepObj:SetActive(self.notSweep)
        notSweepLab.text = "Boss关首次通关后开启扫荡功能"
        --UITool.SetGray(self.Sweeptf)
        --UITool.SetGray(self.Sweep3tf)
    else
        --首通完成，开启扫荡按钮，隐藏提示文本
        notSweepObj:SetActive(self.notSweep)
        Sweep:SetActive(true)
        Sweep3:SetActive(true)
        UITool.SetNormal(self.Sweeptf)
        UITool.SetNormal(self.Sweep3tf)
    end
    My.ChangeSweep=1
    -- self:ChgSweep(0)
end

-- function My:ChgSweep( num )
--     My.ChangeSweep= My.ChangeSweep+num
    -- local All = My.ChangeSweep*self.Msg.costIllusion
    -- self.egTime.text= My.ChangeSweep
-- end

function My:SetTilt( msg )
    self.Title.text=msg.name
end

function My:SetBossMsg( msg )
    self.MostId = msg.monsId
    local monstInfo = MonsterTemp[tostring(self.MostId)]
    local monstAllFive = FiveCopyHelp.GetMostFiveElm( self.MostId)
    local roleFv = FiveCopyHelp.GetAllRoleElmtNum()
    self.BossName.text=msg.BossName.."("..monstInfo.level.."级)"
    self.IconTex = monstInfo.icon;
    self.bossLv.text=""
    self.fiveElm.text=monstAllFive
    self.MyfiveElm.text=FiveCopyHelp.GetAllRoleElmtNum()
    AssetMgr:Load(self.IconTex,ObjHandler(self.LoadIcon,self));
    self.isShowTip=roleFv<monstAllFive
    self.lowit:SetActive( self.isShowTip)
end
--加载道具
function My:ShowItem( msg )
    soonTool.desCell(My.itemLst)
    local list = ""
    if self.notSweep then
        list=msg.fpRwds
        self.RwdgetTxt.text="首通奖励"
        soonTool.AddkvCell(list,self.itmGrid,My.itemLst,1)
    else
        self.RwdgetTxt.text="几率获得"
        self.curWorldLvl=FamilyBossInfo.worldLv
        if  self.curWorldLvl>=msg.worldLvl then
            list=msg.nmlRwds1
        else
            list=msg.nmlRwds
        end
        soonTool.AddNoneCell(list,self.itmGrid,My.itemLst,1)
        --首次通关后，关卡面板首个奖励增加特效显示
        local path = "FX_Five_Orange_01"
        if My.itemLst[1] then
            local cell = My.itemLst[1]
            local AssetMgr=Loong.Game.AssetMgr
            if(StrTool.IsNullOrEmpty(path)~=true)then
                local del = ObjPool.Get(DelGbj)
                del:Adds(1, cell.trans)
                del:SetFunc(self.LoadEff,cell)
                AssetMgr.LoadPrefab(path, GbjHandler(del.Execute,del))
            end
        end
    end
end
--加载icon完成
function My:LoadIcon(obj)
	if self.bossRt == nil then
        AssetTool.UnloadTex(obj.name)
        return;
    end
    self.bossRt.mainTexture=obj;    
end

function My:ClickEvent()
   local US = UITool.SetLsnrSelf
   US(self.Sweep, self.SweepClick, self)
   US(self.Sweep3, self.Sweep3Click, self)
   US(self.Enter, self.EnterClick, self)
end


function My:tipsClick( )
    local msg = InvestDesCfg["1829"]
    local str=msg.des;
    UIComTips:Show(str, Vector3(-229,0,0),nil,nil,nil,400,UIWidget.Pivot.BottomLeft);

end
--首次通关后，关卡面板首个奖励增加特效显示
function My:LoadEff(go, scale, cellTrans)
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    self.eff = go
    local effRoot = TFC(cellTrans, "eff", "FiveMosterTip")
    local effRootSprite = CG(UISprite,cellTrans,"eff","FiveMosterTip",false)
    if LuaTool.IsNull(go) then return end
    if LuaTool.IsNull(effRoot) then return end
    go:SetActive(false);
    local eff = go

    --// LY add begin
    effRootSprite.color = Color.New(255, 255, 255, 2) / 255.0;

    local effScale = Vector3.one * scale;

    eff.transform:SetParent(effRoot.transform);
    eff.transform.localScale = effScale;
    eff.transform.localPosition = Vector3.New(0,0,0)
    eff:SetActive(true)

end

-- function My:tomaxClick(go)
--     if self.notSweep then
--        UITip.Log("请先通关副本")
--     end
--     My.ChangeSweep=FiveCopyHelp.GetMaxSweepTimes(self.costOne)
--     self:ChgSweep(0)
-- end

-- function My:addClick(go)
--     if self.notSweep then
--         UITip.Log("请先通关副本")
--      end
--     local max = FiveCopyHelp.GetMaxSweepTimes(self.costOne)
--     if My.ChangeSweep+1>max then
--         UITip.Log("达到最大次数")
--         return
--     end
--      self:ChgSweep(1)
-- end

-- function My:decClick(go)
--     if self.notSweep then
--         UITip.Log("请先通关副本")
--      end
--     if My.ChangeSweep-1 < 0 then
--         return
--     end
--     self:ChgSweep(-1)
-- end

function My:SweepClick(go)
    self:SweepDo(1)
end
function My:Sweep3Click(go)
    self:SweepDo(3)
end

function My:SweepDo( num )
    local max = FiveCopyHelp.GetMaxSweepTimes(self.costOne)
    if num>max then
        UITip.Log("幻力不足")
        return
    end
    if  num==0 then
        return
    end
    FiveCopyHelp.toSweepCopy(self.CopyId,num)
    -- FiveCopyTip:Close()
end

function My:EnterClick(go)
    local max = FiveCopyHelp.GetMaxSweepTimes(self.costOne)
    if 1>max then
        UITip.Log("幻力不足")
        return
    end
    FiveCopyHelp.curCopyId=self.CopyId
    FiveCopyTip:Close()
    FiveCopyHelp.EntrMap(self.isShowTip)
end
---------关闭
function My:CloseClick(go)
    FiveCopyTip:Close()
end

function My:Close(  )
    self.go:SetActive(false)
    if self.eff then
        self:unLoadEff()
    end
    soonTool.desCell(My.itemLst)
    if  self.IconTex  then
        AssetMgr:Unload(self.IconTex,false); 
        self.IconTex =nil 
    end
end

function My:unLoadEff()
    if LuaTool.IsNull(self.eff)~=true then
        self.eff:SetActive(false);
        GbjPool:Add(self.eff)
        self.eff=nil
    end
end

function My:Clear()
    soonTool.desCell(My.itemLst)
    if  self.IconTex  then
        AssetMgr:Unload(self.IconTex,false); 
        self.IconTex =nil 
    end
    AssetMgr:Unload(FiveCopyHelp.illIconTxt,false);  
    AssetMgr:Unload(FiveCopyHelp.illIconTxt,false);  
end

return My
