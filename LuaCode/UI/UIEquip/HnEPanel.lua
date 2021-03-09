--[[
已穿戴装备列表
--]]
require("UI/UIEquip/UIEquipCell")

HnEPanel=Super:New{Name="HnEPanel"}
local My=HnEPanel
My.eUpData=Event()
My.cDic={}
My.curPart=nil
My.grid=nil

function My:Init(go)
	local TF=TransTool.FindChild
	local CG=ComTool.Get
	self.trans=go.transform

	self.panel=CG(UIScrollView,self.trans,"Panel",self.Name,false)
	self.grid=CG(UIGrid,self.trans,"Panel/Grid",self.Name,false)
	self.grid.onCustomSort=function(a,b) return self:SortName(a,b)end
	My.grid=self.grid
	self.bg = TF(self.trans,"rightBg",self.trans.name)
	self.eqCell = TF(self.trans,"Panel/Grid/EquipCell",self.trans.name)
	self.eqCell:SetActive(false);
	self:AddE()
end

function My:AddE()
	EquipMgr.eLoad:Add(self.LoadEquip,self)
	--UIEquip.eSwitchTg7:Add(self.UpData,self);
	UIEquipCell.eClick:Add(self.ClickCell,self)
	EquipMgr.eHoning:Add(self.OnRed,self);
	EquipMgr.eChangeRed:Add(self.OnRed,self)
end

function My:ReE()
	EquipMgr.eLoad:Remove(self.LoadEquip,self)
	--UIEquip.eSwitchTg7:Remove(self.UpData,self);
	UIEquipCell.eClick:Remove(self.ClickCell,self)
	EquipMgr.eHoning:Remove(self.OnRed,self);
	EquipMgr.eChangeRed:Remove(self.OnRed,self)
end

function My:SortName(a,b)
	local num1 = tonumber(a.name)
	local num2 = tonumber(b.name)
	if(num1<num2)then
		return -1
	elseif (num1>num2)then
		return 1
	else
		return 0
	end
end

-- function My:UpData(tp,mas)
-- 	if not self.isfirst then self.isfirst=true end
-- 	self.tp=tp
-- 	self.mas=mas
-- 	if self.isfirst==true then --第一次
-- 		self.isfirst=false
-- 		--稍等0.1秒
-- 		self.timer=ObjPool.Get(iTimer)
-- 		self.timer:Stop()
-- 		self.timer.seconds=0.1
-- 		self.timer.complete:Add(self.Light,self)
-- 		self.timer:Start()
-- 	else
-- 		self:Light()
-- 	end	
-- end

function My:ClickCell(part)
	if My.curPart then 
		local after = My.cDic[My.curPart]
		after:UpBg(false)
	end
	My.curPart=part
end

-- function My:Light()
-- 	if self.timer then
-- 		self.timer:Stop()
-- 		self.timer:AutoToPool()
-- 		self.timer=nil
-- 	end
-- 	self:Tg7()
-- 	self:OnRed()
-- 	self.grid:Reposition()
-- 	self.panel:ResetPosition()

-- 	if TableTool.GetDicCount(My.cDic)==0 then return end
-- 	if self.clkName then My.cDic[self.clkName]:UpBg(false) end
-- 	local clickname = self:GetSltCellName()
-- 	if clickname then
-- 		if not My.cDic[clickname] then return end
-- 		My.cDic[clickname].eClick(clickname)
-- 		My.cDic[clickname]:UpBg(true)
-- 		self.clkName=clickname
-- 	end
-- end

function My:OnRed()
	EquipMgr.SetHonRedDic();
	self:OnUnRed()
    local dic=EquipMgr.cuilianPartDic
	for k,v in pairs(My.cDic) do 
		local state = dic[k]
		v:OnRed(state)
	end
end

function My:OnUnRed()
	for k,v in pairs(My.cDic) do
		v:OnRed(false)
	end
end

--获取需要选中的装备格子
function My:GetSltCellName()
	local name = self:SltClickCell();
	if name == nil then
		name = self:GetFirstCell();
	end
	return name;
end

--选择可以淬炼装备的格子
function My:SltClickCell()
	dic=EquipMgr.cuilianPartDic
	local index = 100;
	local name = nil;
	for k,v in pairs(dic) do
		local part = tonumber(k);
		if v == true then
			if part < index then
				index = part;
				local equipTbl = My.cDic[k].equip;
				if equipTbl ~= nil then
					name = tostring(equipTbl.wearParts);
				end
			end
		end
	end
	return name;
end

--获取第一个格子
function My:GetFirstCell()
	local go=self.grid:GetChild(0)
	if go==nil then return nil end
	return go.name
end

function My:Tg7()
	for k,v in pairs(My.cDic) do
		v:Tip7()
	end
end

function My:InitEquip(tp,mas)
	self.tp=tp
	self.mas=mas
	local list=EquipMgr.hasEquipDic
	if(list==nil)then return end
	for k,v in pairs(list) do
		self:AddEquip(k)
	end
	self.grid.repositionNow=true
end


function My:LoadEquip(tb,part)
	local cell = My.cDic[part]
	if(cell)then
		cell:UpData(part)
		My.eUpData(part)
	else
		self:AddEquip(part)
	end
	self.grid.repositionNow=true
end

function My:AddEquip(part)
	local go = GameObject.Instantiate(self.eqCell)
	go.name=part
	go.transform.parent=self.grid.transform
	go.transform.localScale = Vector3.one
	go.transform.localPosition = Vector3.zero
	go:SetActive(true)

	local cell =ObjPool.Get(UIEquipCell)
	cell:Init(go)
	cell:UpData(part)

	My.cDic[part]=cell
end

function My:Close()
	self.trans.gameObject:SetActive(false)
	self.bg:SetActive(false);
end

function My:Open()
	self.trans.gameObject:SetActive(true)
	self.bg:SetActive(true);
end

function My:AddToPool()
	if My.cDic == nil then
		return;
	end
	for k, v in pairs(My.cDic) do
		local go = v.go;
		ObjPool.Add(v)
		DestroyImmediate(go);
		My.cDic[k] = nil
	end
end

function My:Dispose()
	My.curPart=nil
	--if self.timer then self.timer:Stop() self.timer:AutoToPool() self.timer=nil end
	self:ReE()
	--self.clkName=nil
	self:AddToPool();
end
