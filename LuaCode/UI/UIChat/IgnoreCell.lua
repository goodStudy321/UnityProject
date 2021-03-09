--[[
屏蔽列表格子
--]]
local AssetMgr=Loong.Game.AssetMgr
IgnoreCell=Super:New{Name="IgnoreCell"}
local My = IgnoreCell

function My:Init(go)
    self.go=go
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    local trans = go.transform

    self.vip=CG(UISprite,trans,"vip",self.Name,false)
    self.NameLab=CG(UILabel,trans,"Name",self.Name,false)
    self.Lv=CG(UILabel,trans,"Lv",self.Name,false)
    self.area=CG(UILabel,trans,"area",self.Name,false)
    self.Icon=CG(UISprite,trans,"bg/Icon",self.Name,false)
    UITool.SetBtnClick(trans,"btn",self.Name,self.OnClick,self)
end

function My:UpData(info)
    self.info=info
    self.vip.spriteName="vip"..info.vip
    self.NameLab.text=info.rN
    self.Lv.text=tostring(info.lv)
    self.area.text=info.server
	self.Icon.spriteName="TX_0"..info.cg
end

--解除屏蔽
function My:OnClick()
    ChatMgr.ReqBanDel(self.info.rId)
end


function My:Dispose()
    local name = self.go.name
    Destroy(self.go)
    AssetMgr.Instance:Unload(name..".prefab",false)
    TableTool.ClearUserData(self)
end