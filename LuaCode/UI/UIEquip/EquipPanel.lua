--[[
已穿戴装备列表
]]
require("UI/UIEquip/UIEquipCell")
require("UI/UIEquip/EquipPanelBase")
require("UI/UIEquip/Tg1Panel")
require("UI/UIEquip/Tg2Panel")
require("UI/UIEquip/Tg3Panel")
require("UI/UIEquip/Tg4Panel")
require("UI/UIEquip/Tg5Panel")
require("UI/UIEquip/Tg6Panel")

EquipPanel=Super:New{Name="EquipPanel"}
local My=EquipPanel
My.curPart = nil
My.cellDic={}
My.str=ObjPool.Get(StrBuffer)
My.eClick=Event()

function My:Init(go)
	local TF=TransTool.FindChild
    local CG=ComTool.Get
    self.go=go
    if not My.cellDic then My.cellDic={} end
	if not self.partList then self.partList={} end
	if not self.tgPanelList then self.tgPanelList={} end
	local trans=go.transform

	self.panel=CG(UIScrollView,trans,"Panel",self.Name,false)
	self.grid=CG(UIGrid,trans,"Panel/Grid",self.Name,false)
	self.grid.onCustomSort=function(a,b) return self:SortName(a,b)end

	self:SetTgPanel()

	self.str=ObjPool.Get(StrBuffer)

	
end

function My:SortName(a,b)
	local num1 = tonumber(a.name)
	local num2 = tonumber(b.name)
	if not num1 or not num2 then return end
	if(num1<num2)then
		return -1
	elseif (num1>num2)then
		return 1
	else
		return 0
	end
end

function My:SetTgPanel()
	local p1 = ObjPool.Get(Tg1Panel)
	p1:Init(EquipPanel.Name)
	table.insert( self.tgPanelList, p1)

	local p2 = ObjPool.Get(Tg2Panel)
	p2:Init(EquipPanel.Name)
	table.insert( self.tgPanelList, p2)

	local p3 = ObjPool.Get(Tg3Panel)
	p3:Init(EquipPanel.Name)
	table.insert( self.tgPanelList, p3)

	local p4 = ObjPool.Get(Tg4Panel)
	p4:Init(HnEPanel.Name)
	table.insert( self.tgPanelList, p4)

	local p5 = ObjPool.Get(Tg5Panel)
	p5:Init(EquipPanel.Name)
	table.insert( self.tgPanelList, p5)

	local p6 = ObjPool.Get(Tg6Panel)
	p6:Init(EquipPanel.Name)
	table.insert( self.tgPanelList, p6)
end

function My:WitchTg()
	local bTp = UIEquip.bTp
	local p = self.tgPanelList[bTp]

	if not p then return end
	p:UpData()
	self:Sort(UIEquip.bTp,UIEquip.sTp)
	if bTp<3 or bTp>5 then p:ShowGrid(false) end
end

function My:SetEvent(fn)
	UIEquipCell.eClick[fn](UIEquipCell.eClick,self.OnClickCell,self)
	EquipMgr.eChangeRed[fn](EquipMgr.eChangeRed,self.OnRed,self)
	EquipMgr.eLoad[fn](EquipMgr.eLoad,self.EquipLoad,self)
	Tg1Panel.eSort[fn](Tg1Panel.eSort,self.OnMAX,self)
end

function My:OnClickCell(part)
	self:ResetBg()
	if My.curPart then
		local last = My.cellDic[My.curPart]
		last:UpBg(false)
	end
	My.curPart=part
	My.eClick(part)
end

--重置背景显示（修复多个背景高亮）
function My:ResetBg()
	for k,v in pairs(My.cellDic) do
		v:UpBg(false)
	end
end

function My:OnRed(bTp,sTp)
	if UIEquip.bTp~=bTp then return end
	local p = self.tgPanelList[bTp]
	p:ShowRed()
end

function My:EquipLoad(tb,part)
	local cell = self.cellDic[part]
	if not cell then 
		local del = ObjPool.Get(DelGbj)
		del:Adds(part)
		del:SetFunc(self.LoadEquipCb,self)
		LoadPrefab("EquipCell",GbjHandler(del.Execute,del))
	else
		cell:UpData(part)
		if not My.curPart or My.curPart==part then
			cell:OnClick() 
			My.eClick(part)
		end
		self:UpPartData(part)
	end
end

function My:LoadEquipCb(go,part)
	go.name="600"
    go:SetActive(true)
    go.transform.parent=self.grid.transform
	go.transform.localScale = Vector3.one
	go.transform.localPosition = Vector3.zero

    local cell =ObjPool.Get(UIEquipCell)
	cell:Init(go)
	cell:UpData(part)
	My.cellDic[part]=cell
	table.insert(self.partList,part)
	if not My.curPart then
		cell:OnClick() 
		My.curPart=part
		My.eClick(part)
	end
	self:UpPartData(part)
	self.grid:Reposition()
end

function My:UpPartData(part)
	local p = self.tgPanelList[UIEquip.bTp]
	if p then 
		p:ShowPartTip(part)
		p:ShowPartRed(part) 
	end
end

function My:OnMAX()
	self:Sort(1)
end

--排序
function My:Sort(bTp,sTp)
	local count = #self.partList
	if count==0 then return end
	if count>1 then 
		local p = self.tgPanelList[bTp]
		if p then 
			p:Sort(self.partList) 
		else 
			table.sort( self.partList) 
		end
		if bTp==4 then return end
	end
    for i,v in ipairs(self.partList) do
        local cell = My.cellDic[v]
        cell.go.name=tostring(i)
		if i==1 then 
			cell:OnClick() 
			My.curPart=v
			My.eClick(v)
		end
	end
    self.grid:Reposition()
end

function My:CreateEquipCellList()
    local list=EquipMgr.hasEquipDic
    self.count=TableTool.GetDicCount(list)
	for k,v in pairs(list) do
		self:CreateEquipCell(k)
	end
end

function My:CreateEquipCell(part)
    local del = ObjPool.Get(DelGbj)
	del:Adds(part)
	del:SetFunc(self.LoadCb,self)
	LoadPrefab("EquipCell",GbjHandler(del.Execute,del))
end

function My:LoadCb(go,part)
    go:SetActive(true)
    go.transform.parent=self.grid.transform
	go.transform.localScale = Vector3.one
	go.transform.localPosition = Vector3.zero

    local cell =ObjPool.Get(UIEquipCell)
	cell:Init(go)
	cell:UpData(part)
	My.cellDic[part]=cell
	table.insert(self.partList,part)
end





function My:Open()
    self.go:SetActive(true)
    self:SetEvent("Add")
end

function My:Close()
    self.go:SetActive(false)
    self:SetEvent("Remove")
end

function My:Dispose( ... )
	ListTool.Clear(self.partList)
	self:Close()
	My.curPart=nil
	if self.str then ObjPool.Add(self.str) self.str=nil end
	if self.tgPanelList then ListTool.ClearToPool(self.tgPanelList) end
end
