--[[
VIP续费提示
]]
UIVIPTip=UIBase:New{Name="UIVIPTip"}
local My = UIVIPTip

function My:InitCustom()
    local trans = self.root

    UITool.SetBtnClick(trans,"CloseBtn",self.Name,self.Close,self)
    UITool.SetBtnClick(trans,"bg/yesBtn",self.Name,self.OnClick,self)

end

function My:OnClick()
    UIMgr.Open(UIV4Panel.Name)
    self:Close()
end

function My:CloseCustom()
    -- body
end

return My