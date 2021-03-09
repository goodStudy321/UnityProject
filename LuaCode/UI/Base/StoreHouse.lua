--[[
仓库
--]]
StoreHouse=UIBase:New{Name="StoreHouse"}
local My = StoreHouse


function My:InitCustom()
	local TF = TransTool.FindChild
	local CG = ComTool.Get
	local U=UITool.SetBtnClick

	self.pre=TF(self.root,"00")
	self.Panel1=ObjPool.Get(UIContentY)
	self.Panel1:Init(TF(self.root,"bg1"),1,false,self.pre)
	self.Panel1:Open()

	self.Panel2=ObjPool.Get(UIContentY)
	self.Panel2:Init(TF(self.root,"bg2"),2,false,self.pre)
	self.Panel2:Open()

	U(self.root,"CloseBtn",self.Name,self.CloseBtn,self)
end

function My:CloseBtn( ... )
	self:Close()
	JumpMgr.eOpenJump()
end

function My:DisposeCustom()
	if self.Panel1 then self.Panel1:Close()  ObjPool.Add(self.Panel1) self.Panel1=nil end
	if self.Panel2 then self.Panel2:Close()  ObjPool.Add(self.Panel2) self.Panel2=nil end
end

return My