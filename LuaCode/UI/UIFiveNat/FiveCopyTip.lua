FiveCopyTip = Super:New{Name="FiveCopyTip"}
local My = FiveCopyTip
My.curOpen=nil
function My:Init(root)
    self.root=root
    self.go=root.gameObject
    --常用工具
    local tip = "FiveCopyTip"
	local root = self.root
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local CG = ComTool.Get
    local UC = UITool.SetLsnrClick;

    self.FiveMosterTip_end=TF(root,"tf_FiveMosterTip_end",tip)
    self.bg1=TFC(root,"gbj_bg1",tip)
    self.FiveNextTip_end=TF(root,"tf_FiveNextTip_end",tip)
    self.FiveBuytip_end=TF(root,"tf_FiveBuytip_end",tip)
    self.MyFivePropertyTip_end=TF(root,"tf_MyFivePropertyTip_end",tip)
    self.RankRT=TF(root,"FiveRank",tip)
    FivePropertyTip:Init( self.MyFivePropertyTip_end)
    FiveNextTip:Init( self.FiveNextTip_end)
    FiveMosterTip:Init(self.FiveMosterTip_end)
    FiveBuytip:Init(self.FiveBuytip_end)
    FiveRank:Init( self.RankRT)
end

function My:Open(tip )
    self.go:SetActive(true)
    self.curOpen=tip
    self.curOpen:Open()
end

function My:UseBg1(bl )
    self.bg1:SetActive(bl)
end

function My:OpenFiveMosterTip(  )
    self:UseBg1(false )
    self:Open( FiveMosterTip )
end

function My:OpenFiveRankTip(  )
    self:UseBg1(false )
    self:Open( FiveRank )
end

function My:OpenFivePropertyTip( )
    self:UseBg1(false )
    self:Open( FivePropertyTip )
end

function My:OpenFiveNextTip( )
    self:UseBg1(true )
    self:Open( FiveNextTip )
end

function My:OpenFiveBuytip( )
    self:UseBg1(false )
    self:Open(FiveBuytip )
end

function My:Close(  )
    if LuaTool.IsNull(self.go) then
     return
    end
    self.go:SetActive(false)
    if self.curOpen==nil then
        return
    end
    self.curOpen:Close()
    self.curOpen=nil
end

function My:Clear()
    self.curOpen=nil
    FiveMosterTip:Clear()
    FiveBuytip:Clear()
end

return My
