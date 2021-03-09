--[[
角色基本信息
--]]
RoleCell=Super:New{Name="RoleCell"}
local My=RoleCell

function My:Init(go)
    self.tog=go:GetComponent(typeof(UIToggle))
    self.trans=go.transform
    local C = ComTool.Get
    local T = TransTool.FindChild

    local back = T(self.trans,"Background").transform
    self.icon1=C(UISprite,back,"icon",self.Name,false)
    self.Name1=C(UILabel,back,"Name",self.Name,false)
    self.god1=T(back,"god")


    local chec = T(self.trans,"Checkmark").transform
    self.icon2=C(UISprite,chec,"icon",self.Name,false)
    self.Name2=C(UILabel,chec,"Name",self.Name,false)
    self.god2=T(chec,"god")

end

function My:ShowData(tb)
    local text = tb.name

    local isgod = UserMgr:IsGod(tb.lv)
    self.god2:SetActive(isgod)
    self.god1:SetActive(isgod)

    local lv = UserMgr:GetToLv(tb.lv)
    if isgod~=true then
        lv="Lv."..lv
    else
        lv="   "..lv
    end

    local path2 = "job_icon_04"
    local path1 = "job_icon_02"
    if tb.sex==1 then
        path1="job_icon_01"
        path2="job_icon_03"
    end
    self.icon1.spriteName=path1
    self.icon2.spriteName=path2
    self.icon1:MakePixelPerfect()
    self.icon2:MakePixelPerfect()

    self.Name1.text=text.."\n"..lv
    self.Name2.text=text.."\n"..lv
end

function My:Dispose()
    TableTool.ClearUserData(self)
end