FiveNextShow = Super:New{Name="FiveNextShow"}
local My = FiveNextShow
My.CurFloor=0
My.Maxfloor=false
My.NxtShowLst={};
My.NeedShowLst={}
function My:Init(root)
    self.root=root
    --常用工具
    local tip = "FiveNextShow"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;
    -- self.natshowTf=TF(root,root,"")
    self.title=CG(UILabel,root,"lab_title",tip)
    self.showseal=TF(root,"tf_showseal",tip)
    self.chooseItem=TFC( self.showseal,"chooseItem",tip)
    soonTool.setPerfab(self.chooseItem,"FiveNextShowItem")
    UC(root,"tf_showseal/uc_toNext",tip,self.toNextClick,self)
    UC(root,"uc_tip",tip,self.tipClick,self)
    UC(root,"uc_showNextTip",tip,self.showNextTip,self)
    self.showNextTiptf=TFC(root,"uc_showNextTip",tip)
    self.nextEff=TFC( self.showseal,"uc_toNext/nextEff",tip)
    -- UC(root,"uc_toSMS",tip,self.toSMSClick,self)
    -- self.haveNext=TFC(root,"gbj_haveNext",tip)
    -- self.nxtGrid=CG(UIGrid,root,"gbj_haveNext/sv/grid_nxtGrid",tip)
    self.nexttip=CG(UILabel,root,"lab_nexttip",tip)
    self.FiveNatShowRt=TF(root,"FiveNatShow",tip)
    FiveNatShow:Init( self.FiveNatShowRt)
end


function My:Open(  )
    My.CurFloor=FiveCopyHelp.CurFloor
    My.Maxfloor=false
    local Msg = FiveElmtMgr.floorMsg[My.CurFloor]
    if Msg==nil then
        iTrace.Error("soon","缺少配置第为:"..My.CurFloor)
        return
    end
    if FiveElmtMgr.floorMsg[My.CurFloor+1]==nil then
        My.Maxfloor=true
    end
    self.showNextTiptf:SetActive(not My.Maxfloor)
    self.CanGoNextTxtShow=Msg.dec
    -- self:ShowNextItem( Msg.NextGet )
    -- self.haveNext:SetActive(not Msg.Maxfloor)
    self:SetLab(Msg)
    self:ShowGet(Msg.CopyNeed)
    self:GoNextRed( )
end

function My:GoNextRed( )
    if (FiveElmtMgr.CanGoNxt or FiveCopyHelp.CurFloor<FiveCopyHelp.UnLockFloor) and My.Maxfloor==false then
        self.nextEff:SetActive(true)
    else
        self.nextEff:SetActive(false)
    end
end

function My:ShowGet(CopyNeed )
    soonTool.ObjAddList(My.NeedShowLst)
    if CopyNeed==nil or #CopyNeed~=8 then
        iTrace.Error("soon","五行配置表副本显示配置错误："..My.CurFloor)
        return
    end
    local haveNum = 0
    local TF = TransTool.Find
    for i=1,8 do
       local num = 0
       local parent = TF(self.showseal,tostring(i),"fiveroot")
       local go = soonTool.Get("FiveNextShowItem",parent)
       local obj = ObjPool.Get(FiveNextShowItem)
       obj:Init(go)
       num =  obj:SetInfo(CopyNeed[i],i)
       haveNum = haveNum+num
       My.NeedShowLst[i]=obj
    end
    My:bookHaveNumber( haveNum )
end

function My:SetLab(Msg )
    self.title.text=Msg.CopyName
end
 
function My:bookHaveNumber( num )
    if My.Maxfloor then
        self.nexttip.text= self.CanGoNextTxtShow
    else
        self.nexttip.text=string.format(  self.CanGoNextTxtShow,num )
    end
end

function My:tipClick()
    local cur = 1828;
    local str=InvestDesCfg[tostring(cur)].des;
    UIComTips:Show(str, Vector3(-110,50,0),nil,nil,nil,400,UIWidget.Pivot.BottomLeft);
end

-- function My:ShowNextItem( NextGet )
--     soonTool.ClearList(My.NxtShowLst)
--     if NextGet==nil or #NextGet==0 then
--         return
--     end
--     soonTool.AddNoneCell(NextGet,self.nxtGrid,My.NxtShowLst)
-- end

function My:showNextTip(  )
    FiveNextMsg:Open()
end

function My:toNextClick(go)
    if My.Maxfloor==true then
        UITip.Log("达到最大层数")
       return 
    end
    if My.CurFloor<FiveCopyHelp.UnLockFloor then
        FiveCopyHelp.changeFloor(1)
       return 
    end
     if FiveElmtMgr.CanGoNxt then
        FiveCopyHelp.goNextFloor(  )
     else
        UITip.Log("需要通关并收集齐套装")
     end
end

-- function My:toSMSClick(go)
--   FiveCopyHelp.toUISMS()
-- end

function My:Clear()
    FiveNextMsg:Close()
    soonTool.ObjAddList(My.NeedShowLst)     
    FiveNatShow:Clear()  
    My.Maxfloor=false
end

return My
