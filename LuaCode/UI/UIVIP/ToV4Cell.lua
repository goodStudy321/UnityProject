ToV4Cell=VIPBuyCell:New{Name="ToV4Cell"}
local My=ToV4Cell

function My:InitCustom( ... )
    local btn = ComTool.Get(UILabel,self.trans,"Btn/Label",self.Name,false)
    btn.text="直升V4"
end

function My:UpData(id,money)
    self.id=id
    self.trans.name=self.id
    self.price.text=money
    -- self.isenough=RoleAssets.IsEnoughAsset(2,money)
    self.des.text="补价差，直升VIP4"
    self.cell:UpData(self.id)
end

--购买并使用
function My:OnClick()
    -- if self.isenough==true then 
    --     UIMgr.Open(UIV4Panel.Name)
    -- else
    --     StoreMgr.JumpRechange()
    -- end
    UIMgr.Open(UIV4Panel.Name)
end