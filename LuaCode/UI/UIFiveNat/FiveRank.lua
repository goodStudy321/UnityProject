FiveRank = Super:New{Name="FiveRank"}
local My = FiveRank

My.UseInfoLst={}
My.MyInfo=nil
My.MyObj=nil
My.objLst={}
function My:Init(root)
    --常用工具
    local tip = "FiveRank"
     self.root=root
     self.go=root.gameObject
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;
    self.MyFiveRankItem_end=TFC(root,"gbj_MyFiveRankItem_end",tip)
    self.Grid=CG(UIGrid,root,"Scroll View/grid_Grid",tip)
    self.FiveRankItem=TFC(root,"Scroll View/grid_Grid/gbj_FiveRankItem",tip)
    soonTool.setPerfab(self.FiveRankItem,"FiveRankItem")
    UC(root,"uc_close",tip,self.closeClick,self)
end

function My:Lsnr( fun )
    RankNetMgr.eRankInfo[fun]( RankNetMgr.eRankInfo,self.GetRank,self)
    RankNetMgr.eRankParams[fun]( RankNetMgr.eRankParams,self.Copymsg,self)
    RankNetMgr.eRankEnd[fun]( RankNetMgr.eRankEnd,self.RankGetEnd,self)
end

function My:Open( )
    self.go:SetActive(true)
    self:Lsnr( "Add" )
    FiveCopyHelp.toSendRank()
end

function My:GetRank( key, rank, role_id, role_name, role_level, vip_level, category, confine )
    if key==10010 then
       local dec = My.UseInfoLst[rank]
       if dec==nil then
         dec={}
       end
       dec.rank=rank
       dec.role_name=role_name
       dec.role_id=role_id
       dec.confine=RobberyMgr:GetCurCfg(confine).stateName
       dec.vip_level=vip_level
       My.UseInfoLst[rank]=dec
    end
end

function My:Copymsg( key, rank, id, val )
    if key==10010 and id=="116"  then
        local dec = My.UseInfoLst[rank]
        if dec==nil then
            dec={}
        end
        dec.copyId=val
        My.UseInfoLst[rank]=dec
    end
end

function My:RankGetEnd(  )
    My.MyInfo=nil
    local len=#My.UseInfoLst
    for i=1,len do
        local msg = My.UseInfoLst[i]
        local obj = ObjPool.Get(MyFiveRankItem)
        local go = soonTool.Get("FiveRankItem")
        obj:Init(go)
        obj:UpInfo(msg)
        My.objLst[msg.rank]=obj
        if tostring(msg.role_id)==tostring(FiveCopyHelp.playId) then
            My.MyInfo=msg
        end
    end
    self:CreatMy()
    self.Grid:Reposition();
end

function My:CreatMy( )
    local obj = ObjPool.Get(MyFiveRankItem)
    local go = self.MyFiveRankItem_end
    obj:Init(go)
    if My.MyInfo==nil then
        My.MyInfo={}
        My.MyInfo.rank="未上榜"
        My.MyInfo.role_name=UserMgr:GetName()
        My.MyInfo.confine=RobberyMgr:GetCurCfg().stateName
        My.MyInfo.copyId=FiveCopyHelp.curMaxCopyId
    end
    obj:UpInfo(My.MyInfo,true)
    My.MyObj=obj
end

function My:closeClick(  )
    FiveCopyTip:Close()
end

function My:Close()
    self.go:SetActive(false)
    soonTool.ObjAddList(My.objLst)
    ObjPool.Add(My.MyObj)
    soonTool.ClearList(My.UseInfoLst)
    self:Lsnr( "Remove" )
end

function My:Clear()
 My.MyInfo=nil
 self:Close()
end

return My
