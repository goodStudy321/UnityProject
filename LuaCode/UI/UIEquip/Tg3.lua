--[[
宝石镶嵌
--]]
require("UI/UIEquip/UIGemCell")
require("UI/UIEquip/GemCell")
Tg3=Super:New{Name="Tg3"}
local My=Tg3
My.rank = {"一阶","五阶","六阶","八阶","九阶"}

function My:Ctor()
	self.cellList={}
end

function My:Init(go,gemTipGO)
	local TF=TransTool.FindChild
	local CG = ComTool.Get
	local trans=go.transform
	self.go=go
	local U = UITool.SetLsnrSelf

	local rank = My.rank
	for i=1,6 do
		local cell = ObjPool.Get(GemCell)
		local gg = TF(trans,"bg/d"..i)
		cell:Init(gg,i)
		self.cellList[i]=cell
		if i<6 then 
			local lab = CG(UILabel,gg.transform,"Label",self.Name,false)
			lab.text=rank[i].."开启"
		end
	end

	local US = UITool.SetBtnClick
	-- US(trans,"down",self.Name,self.Down,self)
	-- US(trans,"wear",self.Name,self.Wear,self)
	US(trans,"GetWay",self.Name,self.GetWay,self)

	self.cell=ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(trans,nil,nil,nil,nil,Vector3.New(-164.3,-38.34,0))
    
    self.gemtip=GemTip
    self.gemtip:Init(gemTipGO)
end

function My:SetEvent(fn)
	EquipMgr.eChangeRed[fn](EquipMgr.eChangeRed,self.StonePunch,self)
	-- EquipMgr.ePunch[fn](EquipMgr.ePunch,self.StonePunch,self)
	-- EquipMgr.eRemove[fn](EquipMgr.eRemove,self.UpData,self)
	EquipMgr.eECompose[fn](EquipMgr.eECompose,self.OnECompose,self)
	--EquipMgr.eAKey:Add(self.OnAKey,self)
    VIPMgr.eVIPLv[fn](VIPMgr.eVIPLv,self.VIPLv,self)
    EquipPanel.eClick[fn](EquipPanel.eClick,self.OnClickCell,self)
    GemCell.eClickGem[fn](GemCell.eClickGem,self.OnClickGem,self)
end

function My:OnClickCell(part)
    self.part=part
    local tb = EquipMgr.hasEquipDic[part]
    self:UpData(tb)
end

function My:OnClickGem(title,tipList)
    -- self.gemtip:Open()
    -- self.gemtip:UpDataGem() --之后优化

    self.gemtip:UpData(title,tipList)
end

--获得途径
function My:GetWay()
	UIMgr.Open(UIGetWay.Name,self.GetWayCb,self)
end

function My:GetWayCb(name)
	local ui = UIMgr.Get(name)
	if ui then 
		ui:SetPos(Vector3.New(335.83,-150.9,0))
		ui:CreateCell("道具商城",self.OnClickWayItem,self)
		ui:CreateCell("宝石合成",self.OnGem,self)
	end
end

function My:OnClickWayItem()
	JumpMgr:InitJump(UIEquip.Name,4,1)
	StoreMgr.OpenStoreId(30001)
end

function My:OnGem()
	UICompound:SwitchTg(1)
	UIMgr.Close(UIGetWay.Name)
end

function My:StonePunch(tp)
	if tp~=3 then return end
	local part = tostring(EquipPanel.curPart)
	local tb = EquipMgr.hasEquipDic[part]
	self:UpData(tb,part)
end

function My:OnECompose(tb,part)
	self:UpData(tb,part)
end

-- function My:OnAKey(tp)
-- 	if tp==1 then
-- 		local tb = EquipMgr.hasEquipDic[EquipPanel.curPart]
-- 		self:UpData(tb,EquipPanel.curPart)
-- 	elseif tp==2 then
-- 		for i,v in ipairs(self.cellList) do
-- 			v:Clean()
-- 			v:AddRedUp(EquipPanel.curPart)
-- 		end
-- 	end
-- end

function My:UpData(tb)
	self.type_id=tb.type_id
	for i,v in ipairs(self.cellList) do
		v:Clean()
		v:AddRedUp(self.part)
	end
	self:STList(tb)
	local item = ItemData[tostring(tb.type_id)]
	if(item==nil)then iTrace.eError("xiaoyu","道具表为空  type_id：".. self.type_id)return end
	self.cell:TipData(tb)
	self:ShowLock()
end

function My:VIPLv()
	if VIPMgr.GetVIPLv()>=7 then 
		self.cellList[6]:LockState(0.001) 
	else 
		self.cellList[6]:LockState(1) 
	end
end

--已开启的孔不显示锁定，未开启的显示
function My:ShowLock()
	self.equip = EquipBaseTemp[tostring(self.type_id)]
	if(self.equip==nil)then iTrace.eError("xiaoyu","装备表为空  type_id：".. self.type_id)return end
	local num = self.equip.holesNum
	for i,v in ipairs(self.cellList) do
		if i<=num then
			v:LockState(0.001)
		else
			v:LockState(1)
		end
	end
	self:VIPLv()
end

--显示已镶嵌宝石
function My:STList(tb)
	local dic=tb.stDic
	for index,id in pairs(dic) do
		local cell = self.cellList[tonumber(index)]		
		local gem=GemData[tostring(id)]
		if(gem==nil)then iTrace.sLog("xiaoyu","宝石表为空 type_id: ".. id)return end
		cell:UpData(id)
	end
end

function My:Open()
	self:SetEvent("Add")
    self.go:SetActive(true)
    if EquipPanel.curPart then self:OnClickCell(EquipPanel.curPart) end
end

function My:Close()
    self:SetEvent("Remove")
    self.go:SetActive(false)
end

function My:Dispose()
    self:Close()
	ListTool.ClearToPool(self.cellList)
    if self.cell then self.cell:DestroyGo() ObjPool.Add(self.cell) end
    if self.gemtip then ObjPool.Add(self.gemtip) self.gemtip=nil end
end