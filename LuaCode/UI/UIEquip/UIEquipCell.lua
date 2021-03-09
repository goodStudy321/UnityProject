--[[
装备格子
--]]
require("UI/Base/Cell")
UIEquipCell=Super:New{Name="UIEquipCell"}
local My=UIEquipCell
My.eClick=Event()

function My:Ctor()
	self.tList={}
end

function My:Init(go)
	self.go=go
	local trans=go.transform
	local CG=ComTool.Get
	local TF=TransTool.FindChild

	self.cell=ObjPool.Get(Cell)
	self.cell:InitLoadPool(trans)

	self.select=TF(trans,"select")
	self.NameLab=CG(UILabel,trans,"Name",self.Name,false)
	-- self.maxLv=CG(UILabel,trans,"maxLv",self.Name,false)
	self.red=TF(trans,"tip")
	self.lock = TF(trans,"lock") 
	self.full = TF(trans,"full")
	self.Grid=TF(trans,"Grid")
	for i=1,6 do
		self.tList[i]=CG(UISprite,trans,"Grid/t"..i,self.Name,false)
	end
	self.tList[6].gameObject:SetActive(true);
	UITool.SetLsnrClick(trans,"Container",self.Name,self.OnClick,self)
end


function My:UpData(part)
	--self:GridState(false)
	self.part=part
	local tb = EquipMgr.hasEquipDic[part]
	self.cell:UpData(tb.type_id)
end

function My:SetPart(part)
	self.part = part
end

function My:OnClick(go)
	My.eClick(self.part)
	self:UpBg(true)
end

function My:UpBg(isClick)
	if LuaTool.IsNull(self.select)~=true then self.select:SetActive(isClick) end
end

function My:UpName(text)
	self.NameLab.text=text
end

function My:OnRed(state)
	if LuaTool.IsNull(self.red) then return end
	self.red:SetActive(state)
end

function My:FullState(state)
	self.full:SetActive(state)
end

function My:GridState(state)
	if LuaTool.IsNull(self.Grid)~=true then self.Grid.gameObject:SetActive(state) end
end

function My:Dispose()
	if self.cell then 
		self.cell:DestroyGo()
		ObjPool.Add(self.cell)
		self.cell=nil 
	end
	self:UpBg(false)
	self:OnRed(false)
	self:FullState(false)
	ListTool.Clear(self.tList)
	if(LuaTool.IsNull(self.go)~=true)then
		self.go.name="EquipCell"
		GbjPool:Add(self.go)
		self.go=nil
	end
	TableTool.ClearUserData(self)
end