--[[
表情.物品.坐标等
--]]
Chat=Super:New{Name="Chat"}
local My=Chat

function My:Init(go)
	self.trans=go.transform
	local T = TransTool.FindChild
	local C = ComTool.Get

	self.emo=ObjPool.Get(Emo)
	self.emo:Init(T(self.trans,"Emo"))

	self.prop=ObjPool.Get(Prop)
	self.prop:Init(T(self.trans,"Good"))

	local U = UITool.SetBtnClick
	U(self.trans,"e",self.Name,self.OnEmo,self)
	U(self.trans,"b",self.Name,self.OnGood,self)
	UITool.SetLsnrClick(self.trans,"mask",self.Name,self.Close,self)

	self:OnEmo()
end

function My:OnEmo()
	if self.cur then self.cur:Close() end
	self.emo:Open()
	self.cur=self.emo
end

function My:OnGood()
	if self.cur then self.cur:Close() end
	self.prop:Open()
	self.cur=self.prop
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:Close()
	self.trans.gameObject:SetActive(false)
end

function My:Dispose()
	if self.cur then self.cur:Close() self.cur=nil end
	if self.emo then ObjPool.Add(self.emo) self.emo=nil end
	if self.prop then ObjPool.Add(self.prop) self.prop=nil end
end