FiveNextTip = Super:New{Name="FiveNextTip"}
local My = FiveNextTip
function My:Init(root)
    self.root=root
    self.go=root.gameObject
    --常用工具
    local tip = "FiveNextTip"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;

    UC(root,"uc_Close",tip,self.CloseClick,self)
    self.fanBefMax=CG(UILabel,root,"lasdd/lab_fanBefMax",tip)
    self.fanNowMax=CG(UILabel,root,"lasdd/lab_fanNowMax",tip)
    self.fanBefGet=CG(UILabel,root,"lasdd (1)/lab_fanBefGet",tip)
    self.fanNowGet=CG(UILabel,root,"lasdd (1)/lab_fanNowGet",tip)
    self.natBefGet=CG(UILabel,root,"lasdd (2)/lab_natBefGet",tip)
    self.natNowGet=CG(UILabel,root,"lasdd (2)/lab_natNowGet",tip)
    self.natBefMax=CG(UILabel,root,"lasdd (5)/lab_natBefMax",tip)
    self.natNowMax=CG(UILabel,root,"lasdd (5)/lab_natNowMax",tip)
    self.Enter=CG(UIButton,root,"btn_Enter",tip)
    self:ClickEvent()
end

function My:Open(  )
    self.go:SetActive(true)
    self:ShowMsg( )
end

function My:ShowMsg( )
    local beforFloor =FiveCopyHelp.UnLockFloor-1
    local beforemsg =  FiveElmtMgr.floorMsg[beforFloor]
    self.fanBefMax.text= beforemsg.illMax
    local decimal =beforemsg.illSpeed*60
    decimal = math.floor(decimal +0.5)
    self.fanBefGet.text=decimal
    self.natBefMax.text= beforemsg.natMax
    self.natBefGet.text= beforemsg.natSpeed
    self.fanNowMax.text= FiveCopyHelp.illMax
    self.fanNowGet.text= FiveCopyHelp.illSpeed
    self.natNowMax.text= FiveCopyHelp.natMax
    self.natNowGet.text= FiveCopyHelp.natSpeed
end

function My:ClickEvent()
   local US = UITool.SetLsnrSelf
   US(self.Enter, self.EnterClick, self)
end

function My:CloseClick(go)
    FiveCopyTip:Close()
end

function My:EnterClick(go)
    FiveCopyTip:Close()
end

function My:Close(  )
    self.go:SetActive(false)
end

function My:Clear()

end

return My
