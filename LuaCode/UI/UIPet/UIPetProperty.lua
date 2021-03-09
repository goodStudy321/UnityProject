--region UIPetProperty.lua
--Date
--此文件由[HS]创建生成

UIPetProperty = {}
local P = UIPetProperty
P.Name = "UI伙伴界面属性窗口"

function P:New()
	return self
end

function P:Init(go)
	local name = self.Name
	self.gameObject = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.ProName = {"HP", "Attack", "Defence", "Arp"}
	self.CurProperty = {}
	self.CurProLabel = {}
	self.NetProperty = {}
	local len = #self.ProName
	local UL=UILabel
	for i=1,len do
		local key = self.ProName[i]
		local target = string.format("Property%s",i)
		local nTarget = string.format("UpProperty%s",i)
		self.CurProperty[key] = C(UL, trans, target, name, false)
		self.CurProLabel[key] = C(UL, trans, string.format("%s/Label",target),name,false)
		self.NetProperty[key] = C(UL, trans, nTarget, name,false)
	end

	self.CostBaseIdList = {30361,30362,30363}
	self.MaterialCell = {}
	self.Len = #self.CostBaseIdList
	for i=1, self.Len do
		local target = string.format("UseExpView/ActiveMaterial%s", i)
		self.MaterialCell[i] = UICellQuality.New(T(trans, target))
		self.MaterialCell[i]:Init()
	end
	self.ItemValue = {}

	self.Exp = C(UILabel, trans, "Exp", name, false)
	self.ExpSlider = C(UISprite, trans, "ExpSlider", name, false)
	self.UpExpBtn = C(UIButton, trans, "UpExpBtn", name, false)
	self.UpStepBtn = C(UIButton, trans, "UpStepBtn", name, false)
	self.FullStep = T(trans, "FullStep")

	self:AddEvent()
end

--注册的事件回调函数
function P:AddEvent()
	local E = UITool.SetLsnrSelf
	for i=1, self.Len do
		local cell = self.MaterialCell[i]
		if cell then
			E(cell.gameObject, self.OnClickCell, self, nil, false)
		end
	end
	if self.UpExpBtn then
		E(self.UpExpBtn, self.OnUpExpBtn, self)
	end
	if self.UpStepBtn then
		E(self.UpStepBtn, self.OnUpStepBtn, self)
	end
end

function P:UpdateData(data)
	if data == nil then return end
	self.Data = data
	self.Info = data.Info
	self.NextInfo = data.NextInfo
	local hp,atk,def,arm = nil
	if not self.Info then return end
	if self.NextInfo then 
		hp = self.NextInfo.hp
		atk = self.NextInfo.atk
		def = self.NextInfo.def
		arm = self.NextInfo.arm
	end
	self:UpdateProperty("HP",PetMgr.ProDic.HP, ProType.HP, hp)
	self:UpdateProperty("Attack",PetMgr.ProDic.Attack, ProType.Atk,	atk)
	self:UpdateProperty("Defence",PetMgr.ProDic.Defence, ProType.Def, def)
	self:UpdateProperty("Arp",PetMgr.ProDic.Arp, ProType.Arp, arm)
	self:UpdateExp(self.Info.costSoul)
	self:UpdateFullStep(self.NextInfo == nil)
	self.Exp.gameObject:SetActive(self.NextInfo ~= nil)
	self:UpdateMaterial()
end

function P:UpdateMaterial()
	self.ItemValue = {}
	for i=1, self.Len do
		local id = self.CostBaseIdList[i]
		local key = tostring(id)
		local item = ItemData[key]
		if item then
			local count = PropMgr.TypeIdByNum(key)
			self.ItemValue[key] = count
			local value = 0
			if self.ItemValue[key] > 0 then
				value = string.format("[ffffff]%s[-]", count)
			else
				value = string.format("[ff0000]%s[-]", count)
			end
			if self.MaterialCell[i] then
				self.MaterialCell[i]:UpdateIcon(item.icon)
				self.MaterialCell[i]:UpdateQuality(item.quality)
				self.MaterialCell[i]:UpdateLabel(value)
			end
		else
			iTrace.eError("hs", string.format("未从道具表找到指定id",id))
			if self.MaterialCell[i] then
				self.MaterialCell[i].Clean()
			end
		end
	end
	if self.UpExpBtn then
		self.UpExpBtn.Enabled = self:UpExpBtnStatus()
	end
end

function P:UpdateNimbus( )
	if not self.Info then return end
	self:UpdateExp(self.Info.costSoul)
end

--更新经验进度显示
function P:UpdateExp(maximum)
	local per = 1.0
	if maximum ~= 0 then 
		per = PetMgr.StepExp/maximum
		if per > 1 then per = 1 end
	end
	if self.Exp then self.Exp.text = string.format("%s/%s", PetMgr.StepExp, maximum) end
	if self.ExpSlider then self.ExpSlider.fillAmountValue = per end
end

--更新属性 传入值要tostring()
--table的key string类型
--curPro 当前属性
--nextPro 当前属性
function P:UpdateProperty(name, curPro, index, nPro)
	if self.CurProperty[name] then self.CurProperty[name].text = tostring(curPro) end
	if self.CurProLabel[name] then self.CurProLabel[name].text = GetProName(index) end
	if self.NetProperty[name] then 
		self.NetProperty[name].gameObject:SetActive(nPro ~= nil)
		if nPro then
			self.NetProperty[name].text = tostring(nPro - curPro) 
		end
	end
end

function P:UpExpBtnStatus()
	local dic = self.ItemValue
	if not dic then return false end
	local count = 0
	for k,v in pairs(dic) do
		if v then
			count = count + v
		end
	end
	if count <= 0 then return false end
	return true
end
----------------------

function P:OnClickCell(go)
	for i=1, self.Len do
		local cell = self.MaterialCell[i]
		if cell and cell.gameObject.name == go.name then
			local id = self.CostBaseIdList[i]
			if id then
				local item = ItemData[tostring(id)]
				if item then
					UIMgr.Open(PropTip.Name ,function()
						local ui=UIMgr.Dic[PropTip.Name]
						if(ui)then 
							ui:UpData(item)
							ui:BtnState(false)
						end
					end)
				end
			end
		end
	end
end

--提升经验
function P:OnUpExpBtn(go)
	if not self.Len then return end
	for i=1, self.Len do
		local id = self.CostBaseIdList[i]
		local list=PropMgr.typeIdDic[tostring(id)]
		if list ~= nil and #list~=0 then 
			for i,id in ipairs(list) do
				local tb = PropMgr.tbDic[tostring(id)]
				PropMgr.ReqUse(id, tbtb.num)
			end
		else
			iTrace.eLog("hs", string.format("未从背包找到指定id:%s",id))
		end	
	end
end

--进阶
function P:OnUpStepBtn(go)
	if not self.Info then return end
	if PetMgr.StepExp < self.Info.costSoul then
		UITip.Error("进阶失败，坐骑进阶经验不足！！！")
		return
	end
	Mgr.reqPetUpStep(self.Info.id)
end

--点击化形按钮
function P:OnClickBtn1(go)
	if not self.Data then
		UITip.Error("请选择需要化形的宠物！！！")
		return
	end
	NetworkMgr.reqPetChange(self.Data.ID)
	--PetMgs:SetPetBattle(self.Data.ID)
end
--点击分解按钮
function P:OnClickBtn2(go)
end
--点击进阶按钮
function P:OnClickBtn3(go)
	if PetMgr.StepExp < self.Data.Info.costSoul then
		UITip.Error("进阶失败，宠物进阶精华不足！！！")
		return
	end
	if self.Data.NextInfo == nil then 
		UITip.Error("宠物已满阶，不能进阶！！！")
		return
	end
	NetworkMgr.reqPetUpStep(self.Data.Info.id)
end

function P:UpdateItemList()
	self:UpdateMaterial()
	self:UpdateNimbus()
end

function P:UpdateFullStep(value)
	if self.UpExpBtn then self.UpExpBtn.gameObject:SetActive(not value) end
	if self.UpStepBtn then self.UpStepBtn.gameObject:SetActive(not value) end
	if self.UseExpView then self.UseExpView:SetActive(not value) end
	if self.FullStep then self.FullStep:SetActive(value) end

end

function P:SetActive(value)
	if self.gameObject then self.gameObject:SetActive(value) end
end

function P:Dispose()
	self.Info = nil
	self.gameObject = nil
	self.ProName = nil
	if self.CurProperty then
		while #self.CurProperty > 0 do
			table.remove(self.CurProperty)
		end
	end
	self.CurProperty = nil
	if self.NextProperty then
		while #self.NextProperty > 0 do
			table.remove(self.NextProperty)
		end
	end
	self.NextProperty = nil
	if self.MaterialCell then
		while #self.MaterialCell > 0 do
			table.remove(self.MaterialCell)
		end
	end
	self.MaterialCell = nil
	self.ItemValue = nil
	self.Len = nil
	self.ItemValue = nil
	self.Exp = nil
	self.ExpSlider = nil
	self.UpExpBtn = nil
	self.UpStepBtn = nil
	self.FullStep = nil
end
--endregion
