--[[
背包物品
--]]
Prop=Super:New{Name="Prop"}
local My=Prop
My.eProp=Event()

function My:Ctor()
	self.list={}
end

function My:Init(go)
	self.trans=go.transform
	local T = TransTool.FindChild
	local C = ComTool.Get
	self.Panel=self.trans:GetComponent(typeof(UIPanel))
	self.grid=C(UIGrid,self.trans,"Grid",self.Name,false)

	self:Create()
end

function My:Create()
	local tb=PropMgr.tbDic
	for k,v in pairs(tb) do
		local cell = ObjPool.Get(Cell)
		cell:InitLoadPool(self.grid.transform,0.8)
		cell:UpData(v.type_id,v.num)
		self.list[#self.list+1]=cell
		local go=cell.trans.gameObject
		go.name=k
		UITool.SetLsnrSelf(go,self.OnClick,self,self.Name,false)
	end
	self.grid:Reposition()
end

function My:OnClick(go)
	local id=go.name
	My.eProp(id)
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:Close()
	self.trans.gameObject:SetActive(false)
end

function My:Dispose()
	while(#self.list>0)do
		local cell = self.list[#self.list]
		cell:DestroyGo()
		ObjPool.Add(cell)
		self.list[#self.list]=nil
	end
	TableTool.ClearUserData(self)
end