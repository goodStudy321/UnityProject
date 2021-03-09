--[[
聊天系统消息
]]
SysInfo=Super:New{Name="SysInfo"}
local My = SysInfo

function My:Init(go)
    self.Name=SysInfo.Name
    self.trans=go.transform
    local CG=ComTool.Get
    self.icon=self.trans:GetComponent(typeof(UISprite))
    self.lab=CG(UILabel,self.trans,"lab",self.Name,false)

    UITool.SetLsnrSelf(self.lab.gameObject,self.ClickUrl,self,self.Name, false)
end

function My:ClickUrl(go)
	if self.lab then
		local url=self.lab:GetUrlAtPosition(UICamera.lastWorldPosition)
		NoticeMgr.DealUrl(self.trans.name,url)
	end
end

function My:Update()
    -- body
end

function My:InitData(tp,text)
    self.icon.spriteName="tp"..tp
    self.lab.text="　　　  "..text

    self.y=self.lab.height
end

function My:Dispose()
    GbjPool:Add(self.trans.gameObject)
end