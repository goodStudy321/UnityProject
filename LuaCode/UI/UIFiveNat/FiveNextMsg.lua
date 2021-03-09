FiveNextMsg = Super:New{Name="FiveNextMsg"}
local My = FiveNextMsg

My.ItemLst={}

function My:Init(root)
    self.root=root
    self.go=root.gameObject
    --常用工具
    local tip = "FiveNextMsg"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;
    self.title=CG(UILabel,root,"lab_title",tip)
    self.haveNext=TFC(root,"gbj_haveNext",tip)
    self.nxtGrid=CG(UIGrid,root,"gbj_haveNext/grid_nxtGrid",tip)
    self.nexttip=CG(UILabel,root,"lab_nexttip",tip)
    self.fanBefMax=CG(UILabel,root,"dsddd/lab_fanBefMax",tip)
    self.fanNowMax=CG(UILabel,root,"dsddd/lab_fanNowMax",tip)
    self.fanBefGet=CG(UILabel,root,"dsddd (1)/lab_fanBefGet",tip)
    self.fanNowGet=CG(UILabel,root,"dsddd (1)/lab_fanNowGet",tip)
    self.natBefMax=CG(UILabel,root,"dsddd (2)/lab_natBefMax",tip)
    self.natNowMax=CG(UILabel,root,"dsddd (2)/lab_natNowMax",tip)
    self.natBefGet=CG(UILabel,root,"dsddd (3)/lab_natBefGet",tip)
    self.natNowGet=CG(UILabel,root,"dsddd (3)/lab_natNowGet",tip)
    UC(root,"uc_box",tip,self.Close,self)
    self.isOpen=false
end

function My:Open(  )
    if self.isOpen then
        self:Close()
        return
    end
    self.isOpen=true
    self.go:SetActive(true)
    self:ShowMsg( )
end



function My:ShowMsg( )
    local NextFloor =FiveCopyHelp.UnLockFloor+1
    local Nextemsg =  FiveElmtMgr.floorMsg[NextFloor]
    local decimal =Nextemsg.illSpeed*60
    decimal = math.floor(decimal +0.5)
    self.fanNowMax.text= Nextemsg.illMax
    self.fanNowGet.text=decimal
    self.natNowMax.text= Nextemsg.natMax
    self.natNowGet.text= Nextemsg.natSpeed
    self.fanBefMax.text= FiveCopyHelp.illMax
    self.fanBefGet.text= FiveCopyHelp.illSpeed
    self.natBefMax.text= FiveCopyHelp.natMax
    self.natBefGet.text= FiveCopyHelp.natSpeed
    local nowmsg = FiveElmtMgr.floorMsg[FiveCopyHelp.UnLockFloor]
    self:showGet(nowmsg )
end

function My:showGet( msg )
    local nextShowGet = msg.NextGet
    soonTool.desCell(My.ItemLst)
    soonTool.AddNoneCell(nextShowGet,self.nxtGrid,My.ItemLst,1,0.9)
end

function My:Close()
    self.isOpen=false
    self.go:SetActive(false)
    soonTool.desCell(My.ItemLst)
end

return My
