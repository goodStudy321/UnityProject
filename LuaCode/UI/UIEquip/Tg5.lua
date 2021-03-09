--[[
纹印镶嵌
--]]
require("UI/UIEquip/SealCell")
Tg5=Super:New{Name="Tg5"}
local My=Tg5

function My:Ctor()
	self.cellList={}
end

function My:Init(go)
	local TF=TransTool.FindChild
	local CG = ComTool.Get
	local trans=go.transform
	self.go=go

	local U = UITool.SetLsnrSelf
	for i=1,5 do
		local cell = ObjPool.Get(SealCell)
		cell:Init(TF(trans,"bg/d"..i),i)
		self.cellList[i]=cell
	end

	local US = UITool.SetBtnClick
	US(trans,"down",self.Name,self.Down,self)
	US(trans,"wear",self.Name,self.Wear,self)
	US(trans,"GetWay",self.Name,self.GetWay,self)

	self.cell=ObjPool.Get(UIItemCell)
	self.cell:InitLoadPool(trans,nil,nil,nil,nil,Vector3.New(-164.3,-38.34,0))
end

function My:SetEvent(fn)
	EquipMgr.eSealPunch[fn](EquipMgr.eSealPunch,self.StonePunch,self)
	EquipMgr.eSealRemove[fn](EquipMgr.eSealRemove,self.UpData,self)
	EquipMgr.eESealCompose[fn](EquipMgr.eESealCompose,self.OnECompose,self)
	EquipMgr.eASealKey[fn](EquipMgr.eASealKey,self.OnAKey,self)
	VIPMgr.eVIPLv[fn](VIPMgr.eVIPLv,self.VIPLv,self)
	EquipPanel.eClick[fn](EquipPanel.eClick,self.OnClickCell,self)
end

function My:OnClickCell(part)
    self.part=part
    local tb = EquipMgr.hasEquipDic[part]
    self:UpData(tb)
end

--一键卸下所有纹印
local idList = {}
function My:Down()
	ListTool.Clear(idList)
	for k,v in pairs(EquipMgr.hasEquipDic) do
		local dic = v.slDic
		for k1,v1 in pairs(dic) do
			if v1~=0 then 
				idList[#idList+1]=v1
			end
		end
	end
	if #idList==0 then UITip.Log("没有纹印可卸下")return end
	EquipMgr.ReqSealOneKey(2,idList)
end

--一键穿戴所有纹印
local idDic = {}
function My:Wear()
	TableTool.ClearDic(idDic)
	ListTool.Clear(idList)
	local add =0
	local vip = VIPMgr.GetVIPLv()
	local vipInfo = soonTool.GetVipInfo(vip)
	if vipInfo.sealVip== 1 then  add=1 end
	for k,v in pairs(EquipMgr.hasEquipDic) do
		local stnum = TableTool.GetDicCount(v.slDic)
		local type_id = tostring(v.type_id)
		local equip = EquipBaseTemp[type_id]
		local num = equip.SealholesNum+add-stnum
		if num>0 then 
			local sList = PropMgr.GetSealByPart(k)
			if sList then 
				for i1,type_id in ipairs(sList) do
					local has = idDic[tostring(type_id)] or 0 --已经记录需要的
					local tbnum = PropMgr.TypeIdByNum(type_id)-has
					if tbnum>0 then 
						if tbnum>=num then idDic[tostring(type_id)]=num+has break end
						idDic[tostring(type_id)]=tbnum+has
						num=num-tbnum
					end
				end
			end
		end
	end

	for k,num in pairs(idDic) do
		local tbList = PropMgr.typeIdDic[k]
		for i1,v1 in ipairs(tbList) do
			local tb = PropMgr.tbDic[tostring(v1)]
			num=num-tb.num
			idList[#idList+1]=v1
			if num<0 then break end
		end
	end
	if #idList==0 then UITip.Log("没有纹印可穿戴")return end
	EquipMgr.ReqSealOneKey(1,idList)
end

--获得途径
function My:GetWay()
	UIMgr.Open(UIGetWay.Name,self.GetWayCb,self)
end

function My:GetWayCb(name)
	local ui = UIMgr.Get(name)
	if ui then 
		ui:CreateCell("化神寻宝",self.OnClickWayItem,self)
	end
end

function My:OnClickWayItem(name)
	JumpMgr:InitJump(UIEquip.Name,4,2)
	UITreasure:OpenTab(3)
end

function My:StonePunch(tb,part)
	if part~=self.part then return end
	self:UpData(tb,part)
end

function My:OnECompose(tb,part)
	if part~=self.part then return end
	self:UpData(tb,part)
end

function My:OnAKey(tp)
	if tp==1 then
		local tb = EquipMgr.hasEquipDic[self.part]
		self:UpData(tb)
	elseif tp==2 then
		for i,v in ipairs(self.cellList) do
			v:Clean()
			v:AddRedUp(self.part)
		end
	end
end

function My:UpData(tb)
	self.type_id=tb.type_id
	for i,v in ipairs(self.cellList) do
		v:Clean()
		v:AddRedUp(self.part)
	end
	self:STList(tb)

	local item = ItemData[tostring(tb.type_id)]
	if(item==nil)then iTrace.Error("soon","纹印表为空  type_id：".. self.type_id)return end
	self.cell:TipData(tb)
	self:ShowLock()
end

function My:VIPLv()
	local vip = VIPMgr.GetVIPLv()
	local vipInfo = soonTool.GetVipInfo(vip)
	if vipInfo.sealVip== 1 then 
		self.cellList[5]:LockState(0.001) 
	else 
		self.cellList[5]:LockState(1) 
	end
end

--已开启的孔不显示锁定，未开启的显示
function My:ShowLock()
	self.equip = EquipBaseTemp[tostring(self.type_id)]
	if(self.equip==nil)then iTrace.Error("soon","装备表为空  type_id：".. self.type_id)return end
	local num = self.equip.SealholesNum
	for i,v in ipairs(self.cellList) do
		if i<=num then
			v:LockState(0.001)
		else
			v:LockState(1)
		end
	end
	self:VIPLv()
end

--显示已镶嵌纹印
function My:STList(tb)
	local dic=tb.slDic
	for index,id in pairs(dic) do
		local cell = self.cellList[tonumber(index)]		
		local gem=tSealData[tostring(id)]
		if(gem==nil)then iTrace.sLog("soon","纹印表为空 type_id: ".. id)return end
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
    self.part=nil
	self:Close()
	ListTool.ClearToPool(self.cellList)
	if self.cell then self.cell:DestroyGo() ObjPool.Add(self.cell) end
end