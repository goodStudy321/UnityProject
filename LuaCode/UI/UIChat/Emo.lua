--[[
表情
--]]
Emo=Super:New{Name="Emo"}
local My=Emo
My.eEmo=Event()

function My:Ctor()
	self.list={}
end

function My:Init(go)
	self.trans=go.transform
	local T = TransTool.FindChild
	local C = ComTool.Get
	self.grid=self.trans:GetComponent(typeof(UIGrid))
	self.emo=C(UISprite,self.trans,"emo",self.Name,false)
	self.atlas=self.emo.atlas

	self:CreateEmo()
end

function My:CreateEmo()
	if not self.atlas then iTrace.eError("xiaoyu","表情图集丢失")return end
	local list = self.atlas.spriteList
	local count=list.Count
	if count== 0 then return end
	for i=0,count-1 do
		local name = list[i].name
		local go = GameObject.Instantiate(self.emo.gameObject)
		go.name=name
		go:SetActive(true)
		go.transform.parent=self.grid.transform
		go.transform.localScale=Vector3.one
		go.transform.localPosition=Vector3.zero
		local spr=go:GetComponent(typeof(UISprite))
		spr.spriteName=name
		self.list[#self.list+1]=go

		UITool.SetLsnrSelf(go,self.OnClick,self,self.Name)
	end
	self.grid:Reposition()
end

function My:OnClick(go)
	My.eEmo(go.name)
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:Close()
	self.trans.gameObject:SetActive(false)
end

function My:Dispose()
	while(#self.list>0)do
		local go = self.list[#self.list]
		GameObject.Destroy(go)
		self.list[#self.list]=nil
	end
	TableTool.ClearUserData(self)
end