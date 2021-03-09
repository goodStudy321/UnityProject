require("UI/UIFiveNat/FiveCopyHelp")
FiveCopy = UILoadBase:New{Name="FiveCopy"}
local My = FiveCopy
function My:Init()
    self.root = self.GbjRoot
    self.roInfo = self.robInfo
	local root = self.root
    self.go=root.gameObject
    self.root.localPosition=Vector3.New(-11,8,0) 
        --常用工具
    local tip = "FiveCopy"
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;

    self.FiveCopyTip_end=TF(root,"tf_FiveCopyTip_end",tip)
    self.FiveMap_end=TF(root,"tf_FiveMap_end",tip)
    self.FiveNextShow_end=TF(root,"tf_FiveNextShow_end",tip)
    self.FiveBtnOnMap_end=TF(root,"tf_FiveBtnOnMap_end",tip)
    self.FiveNextMsg=TF(root,"FiveNextMsg",tip)
    FiveCopyTip:Init(self.FiveCopyTip_end)
    FiveMap:Init(self.FiveMap_end)
    FiveNextShow:Init(self.FiveNextShow_end)
    FiveBtnOnMap:Init(self.FiveBtnOnMap_end)
    FiveNextMsg:Init(self.FiveNextMsg)
    self:Allllnsr("Add")
end

function My:Open( t1, t2, t3 )
    -- self.go:SetActive(true)
    FiveCopyHelp.OpenFiveBigan()
    FiveCarnetTip.OpenCheck()
    FiveElmtMgr.OpenChange(  )
end

function My:Allllnsr( fun )
    FiveCopyHelp.lnsr(fun)
end

function My:CloseC(  )
    FiveCopyHelp.ClearLoad()
end

function My:Dispose()
    self:Allllnsr("Remove")
    FiveCopyHelp.Clear()
end

-- return My
