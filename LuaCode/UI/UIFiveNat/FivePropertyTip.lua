FivePropertyTip = Super:New{Name="FivePropertyTip"}
local My = FivePropertyTip
function My:Init(root)
    self.root=root
    self.go=root.gameObject
    --常用工具
    local tip = "FivePropertyTip"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;

    UC(root,"uc_Close",tip,self.CloseClick,self)
    self.fiveRoot=TF(root,"tf_fiveRoot",tip)
    self.AllProp=CG(UILabel,root,"tf_fiveRoot/lab_AllProp",tip)
end

function My:ShowMsg(  )
    local CG = ComTool.Get
    for i=1,5 do
        local lab = CG(UILabel,self.fiveRoot,tostring(i),tip)
        local attrId = FiveCopyHelp.AtkFvLst[i]
        local num = FiveCopyHelp.FvRoleElmtNum(attrId)
        lab.text=num
    end
    self.AllProp.text=FiveCopyHelp.GetAllRoleElmtNum()
end

function My:Open(  )
    self.go:SetActive(true)
    self:ShowMsg(  )
end

function My:CloseClick(go)
    FiveCopyTip:Close()
end

function My:Close(  )
    self.go:SetActive(false)
end

function My:Clear()

end

return My
