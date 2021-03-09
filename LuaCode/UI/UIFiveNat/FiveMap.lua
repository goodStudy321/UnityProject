FiveMap = Super:New{Name="FiveMap"}
local My = FiveMap
My.CurFloor=0
My.MapLvLst={}
function My:Init(root)
    self.root=root
    --常用工具
    local tip = "FiveMap"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;

    self.texSv=CG(UIScrollView,root,"sv_texSv",tip)
    self.FiveBigItem=TFC(root,"sv_texSv/bg/gbj_FiveBigItem",tip)
    soonTool.setPerfab( self.FiveBigItem,"FiveBigItem")
    self.FiveSmalItem=TFC(root,"sv_texSv/bg/gbj_FiveSmalItem",tip)
    soonTool.setPerfab( self.FiveSmalItem,"FiveSmalItem")
    self.barrier=TF(root,"sv_texSv/bg/tf_barrier",tip)
end

function My:UpdateLever( )
    FiveCopyHelp.CurMapSlct=nil
    My.CurFloor=FiveCopyHelp.CurFloor
    local Msg = FiveElmtMgr.floorMsg[My.CurFloor]
    local CopyLst= Msg.CopyLst
    if CopyLst==nil or #CopyLst~=FiveCopyHelp.MaxCopyLv then
        iTrace.Error("soon","五行秘境关卡缺少配置副本层数为："..My.CurFloor)
        return
    end
    soonTool.ObjAddList(My.MapLvLst)
    local TF = TransTool.Find
    for i=1,FiveCopyHelp.MaxCopyLv do
        local Root = TF( self.barrier,tostring(i),"fivemap")
        local obj = ObjPool.Get(FiveBarrierItem)
        obj:CreatOne(CopyLst[i],Root)
        My.MapLvLst[i]=obj
    end
end

function My:Clear()
    soonTool.ObjAddList(My.MapLvLst)
end

return My
