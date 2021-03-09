UICopyInfoExp = UICopyInfoBase:New{Name = "UICopyInfoExp"}

local M = UICopyInfoExp
local cMgr = CopyMgr

local base = UICopyInfoBase

M.Items = {}
M.Cost = GlobalTemp[tostring(8)]
M.Ids = GlobalTemp[tostring(9)]
M.ExpList = {}

--构造函数
function M:InitSelf()
	local C = ComTool.Get
	local T = TransTool.FindChild
	local E = UITool.SetLsnrSelf
	local F = TransTool.Find

	local trans = self.left
	self.NameLab = C(UILabel, trans, "Name", name, false)
	-- self.Target = C(UILabel, trans, "Target", name, false)
	self.Num = C(UILabel, trans, "Num", name, false)
	self.Num.text = "0"
	self.GetExp = C(UILabel, trans, "Exp", name, false)
	self.BuffValue1 = C(UILabel, trans, "buff1", name, false)
	self.BuffValue2 = C(UILabel, trans, "buff2", name, false)

	local other = F(self.root, "Other")
	self.CheerBtn = T(other, "CheerBtn", name, false)
	self.CheerDes = C(UILabel, other, "CheerBtn/CheerDes")
	self.CheerFx = T(other, "CheerBtn/FX_tishi")

	self.RatioBtn = T(other, "RatioBtn", name, false)
	self.RatioDes = C(UILabel, other, "RatioBtn/RatioDes")
	self.RatioFx = T(other, "RatioBtn/FX_tishi")

	self.Buff = C(UILabel, other, "CheerView/Buff", name, false)
	self.CheerView = T(other, "CheerView")
	self.CheerBlack = T(other, "CheerView/BlackBtn")
	self.CopperT = C(UIToggle, other, "CheerView/Copper", name, false)
	self.GlodT = C(UIToggle, other, "CheerView/Glod", name, false)
	self.CopperTL = C(UILabel, other, "CheerView/Copper/Label", name, false)
	self.GlodTL = C(UILabel, other, "CheerView/Glod/Label", name, false)
	self.CostC = C(UILabel, other, "CheerView/CostC", name, false)
	self.CostG = C(UILabel, other, "CheerView/CostG", name, false)
	self.CostGLab = C(UILabel, other, "CheerView/CostG/Label", name, false)
	self.CostGLab.gameObject:SetActive(false)
	self.Btn2 = T(other, "CheerView/Btn2")
	self.TickC = C(UIToggle, other, "CheerView/TickC", name, false)
	self.TickG = C(UIToggle, other, "CheerView/TickG", name, false)
	self.TickGLab = C(UILabel, other, "CheerView/TickG/Label", name, false)
	self.TickGLab.text = "绑元不足消耗元宝"

	self.ItemView = T(other, "ItemView")
	self.ItemBlack = T(other, "ItemView/BlackBtn")
	self.Panel = C(UIScrollView, other, "ItemView/ScrollView")
	self.Grid = C(UIGrid, other, "ItemView/ScrollView/Grid")
	self.Prefab = T(other, "ItemView/ScrollView/Grid/Item")

	self.aveExp = C(UILabel, other, "AveExp")
	self.aveExp.gameObject:SetActive(false)

	E(self.CheerBtn, self.OnClickCheerBtn, self)
	E(self.RatioBtn, self.OnClickRatioBtn, self)
	E(self.Btn2, self.OnClickBtn2, self)
	E(self.CheerBlack, self.OnClickCheerBlack, self)
	E(self.ItemBlack, self.OnClickItemBlack, self)
	E(self.CopperT, self.OnClickCopperT, self, nil, false)
	E(self.TickC, self.OnClickTickC, self, nil, false)
	E(self.TickG, self.OnClickTickG, self, nil, false)

	self.CostCCheer = 0
	local cost  = self.Cost
	local t = self.Cost.Value1
	if cost then
		local sf = "%s/次"
		self.CopperTL.text = string.format("%s鼓舞", GetCurrencyTypeName(t[1].id))
		self.GlodTL.text = string.format("%s鼓舞", GetCurrencyTypeName(t[2].id))
		self.CostC.text = string.format(sf, t[1].value)
		self.CostG.text = string.format(sf, t[2].value)
		self.CostCCheer = cost.Value2[1]
		self.CostMax = cost.Value2[2]
	end
	self:InitItem()
	self:InitBuff()
	self:SetEvent(EventMgr.Add)
end


function M:SetEvent(M)
	M("BufValOnChange", EventHandler(self.ChangeBuff, self))
	M("BufValOnDel", EventHandler(self.DelBuff, self))
end

function M:SetLsnrSelf(key)
	CopyMgr.eUpdateCopyExpInfo[key](CopyMgr.eUpdateCopyExpInfo, self.UpdateCopyExpInfo, self)
	PropMgr.eUpdate[key](PropMgr.eUpdate, self.UpdateItemList, self)
	GuardMgr.eGuardUp[key](GuardMgr.eGuardUp, self.GuardUp, self)
	PropMgr.eAdd[key](PropMgr.eAdd, self.BagAdd, self)
	QuickUsePro.eClose[key](QuickUsePro.eClose, self.CloseQuickUse, self)
	CopyMgr.eExpCheerStatus[key](CopyMgr.eExpCheerStatus, self.NeedOpenCheerView, self)
end

function M:OnClickCopperT(go)
	local harmInfo = CopyMgr:GetCopyHarmCheer()
	if not harmInfo then return end
	if harmInfo.silverTimes >= self.CostCCheer then
		UITip.Error("已达到银两鼓舞次数上限")
	end
end

function M:OnClickTickC(go)
	CopyMgr:ReqCopyExpCheerStatus(self.TickC.value, self.TickG.value)
end

function M:OnClickTickG(go)
	CopyMgr:ReqCopyExpCheerStatus(self.TickC.value, self.TickG.value)
end

function M:ChangeBuff(buffid, value)
	local id = math.floor(buffid/1000)
	if id == 201 then
		local num = value*BuffTemp[tostring(buffid)].valueList[1].v*0.01
		self.BuffValue1.text = string.format("[00FF00FF]%d%%",num)
		self.BuffValue1.gameObject:SetActive(true)
		self.CheerDes.text = string.format("伤害+%d%%",num)
		self:UpdateCopyCheerInfo()
	end
	if id == 204 then
		local num = value*BuffTemp[tostring(buffid)].valueList[1].v*0.01
		self.BuffValue2.text = string.format("[00FF00FF]%d%%", num)
		self.BuffValue2.gameObject:SetActive(true)
		self.RatioDes.text = string.format("经验+%d%%", num)
	end
end

function M:DelBuff(buffid)
	local id = math.floor(buffid/1000)
	if id == 201 then
		self.BuffValue1.gameObject:SetActive(false)
		self.CheerDes.text = "伤害+0%"
	end
	if id == 204 then
		self.BuffValue2.gameObject:SetActive(false)
		self.RatioDes.text = "经验+0%"
	end
end


function M:InitData()
	self:UpdateName()
	self:UpdateCur()
	self:UpdateSub()
	self:UpdateCopyCheerInfo()
	self:UpdateCopyExpInfo()
	self:NeedOpenCheerView()	
end

function M:CopyStart()
	base.CopyStart(self)
	self:UpdateAveExp()
end

function M:UpdateAveExp()
	if not self.timer then
		self.timer = ObjPool.Get(iTimer)
		self.timer.invlCb:Add(self.InvlCb, self)
		self.timer.interval = 5
	end
	self.timer.seconds = 5000
	self.timer:Start()
	self:InvlCb()
end

function M:InvlCb()
	if LuaTool.IsNull(self.aveExp) then return end
	table.insert(self.ExpList, CopyMgr.GetExp)
	if self.timer.cnt < 60 then 
		return 
	end
	self.aveExp.gameObject:SetActive(true)
	local lastExp = table.remove( self.ExpList, 1)
	local exp = CopyMgr.GetExp - lastExp
	self.aveExp.text = LuaTool.FormatNum(exp)
end

function M:NeedOpenCheerView()
	local info = CopyMgr.Copy[CopyMgr.Exp]
	if info.IsSilverAuto == nil then return end
	if (info.IsSilverAuto or info.IsGoldAuto) or (info.Num and info.Num >= 1) then 
		self:HaveExpSprite()
		return 
	end 
	if not info.FirstSet then
		self.CheerView:SetActive(true)
		self.TickC.value = true
		self.TickG.value = true
		CopyMgr:ReqCopyExpCheerStatus(self.TickC.value, self.TickG.value)
	end
end

function M:GuardUp()
	self:HaveExpDrug()
end

function M:BagAdd(tb, action)
	if not tb then return end
	if tb.type_id == 31000 then
		local value = User:GetBufValBySrID(204)
		if value <= 0 then
			PropMgr.ReqUse(tb.type_id, 1, 1)
		end
	end
end


function M:HaveExpSprite()
	if self.checkExpSprite then return end
	self.checkExpSprite = true
	local state = GuardMgr.GetGuardS()
	if User.MapData.Level >= GlobalTemp["138"].Value3 then
		self.id = nil
		if state == 1 then
			self.id = 40002
		elseif state == 2 then
			self.id = 40001
		end
		self.state = state

		if self.id then
			if StoreMgr.IsCanBuyT(self.id) then
				local data = ItemData[tostring(self.id)]
				UIUseTip:Show(data, "购买", self.OKCb, self, Vector3(210,-130,0), "购买", self.CloseCb)
				return
			end			
		end	
	end
	self:HaveExpDrug()	
end

function M:CloseCb()
	self:HaveExpDrug()
end

function M:CloseQuickUse(typeId)
	if typeId == 40001 or typeId == 40002 then
		self:HaveExpDrug()
	end 
end

function M:HaveExpDrug()
	if self.isCheck then return end
	self.isCheck = true
	local value = User:GetBufValBySrID(204)
	if value <= 0 then
		local list = {31002, 31001, 31000, 31055}
		local typeId = nil
		for i=1,#list do
			local num = PropMgr.TypeIdByNum(list[i])
			local data = ItemData[tostring(list[i])]
			if num > 0 and User.MapData.Level >= data.useLevel then
				typeId = list[i]
				break
			end
		end
		if typeId then
			local data = ItemData[tostring(typeId)]
			self.id=data.id
			UIUseTip:Show(data, data.name, self.UserCb, self, Vector3(210,-130,0), "使用")
		else
			local data = StoreData["50010"]
			if data then
				local state = RoleAssets.IsEnoughAsset(3, data.curPrice)
				if state then
					local temp = ItemData[tostring(data.PropId)]
					if User.MapData.Level >= temp.useLevel then
						self.id = temp.id
						UIUseTip:Show(temp, temp.name, self.BuyCb, self, Vector3(210,-130,0), "购买")
					end
				end
			end
		end
	end
end

function M:BuyCb()
	StoreMgr.TypeIdBuy(self.id, 1)
end

function M:UserCb()
	PropMgr.ReqUse(self.id, 1, 1)
end

function M:OKCb()
	local state = self.state
	if state == 1 or state == 2 then
		StoreMgr.TypeIdBuy(self.id, 1)
	end	
end

function M:UpdateName()
	local temp = self.Temp
	if not temp then return end
	if self.NameLab then
		self.NameLab.text = temp.name
	end
end

function M:UpdateCur()
	-- if self.Target then
	-- 	local info = CopyMgr.CopyInfo
	-- 	self.Target.text = string.format("[F4DDBDFF]当前进度：[00FF00FF]%d/%d[-]",info.Cur or 0, info.totalWave)
	-- end
end

function M:UpdateSub()
	if self.Num then
		local info = CopyMgr.CopyInfo
		self.Num.text = tostring(info.Sub)
	end
end

function M:UpdateCopyCheerInfo()
	local harmInfo = CopyMgr:GetCopyHarmCheer()
	if not harmInfo then return end
	local cheer = self.CostMax - harmInfo.allTimes 
	self.CheerFx:SetActive(cheer>0)
	local buffDes = string.format("伤害+%d%%",User:GetBufValBySrID(201))
	if self.Buff then
		self.Buff.text = buffDes
	end

	local harmInfo = CopyMgr:GetCopyHarmCheer()
	if harmInfo then
		self.GlodT.value = harmInfo.silverTimes >= self.CostCCheer
	end
	local copy =  CopyMgr.Copy[CopyMgr.Exp]
	if not copy then return end
	self.TickC.value = copy.IsSilverAuto
	self.TickG.value = copy.IsGoldAuto
end

function M:UpdateCopyExpInfo()
	local gExp = CopyMgr.GetExp
	if gExp then
		local exp = tonumber(gExp)
		local str = gExp
		local offset = LuaTool.GetIntPart(exp / 100000000)
		if offset >= 1 then
			local value = LuaTool.GetIntPart(offset)
			str = string.format( "%s亿",offset)
		else
			offset = LuaTool.GetIntPart(exp / 10000)
			if offset >= 1 then
				str = string.format( "%s万",offset)
			end
		end
		self.GetExp.text = str
	end
end

function M:OnClickCheerBtn(go)
	-- local harmInfo = CopyMgr:GetCopyHarmCheer()
	-- if not harmInfo then return end
	-- if self.CostMax - harmInfo.allTimes <= 0 then		
	-- 	UITip.Error("鼓舞次数已经用完，不能继续鼓舞")
	-- 	return
	-- end
	if self.CheerView then
		self.CheerView:SetActive(true)
	end
	self:UpdateCopyCheerInfo()
end

function M:OnClickRatioBtn(go)
	self.RatioFx:SetActive(false)
	if self.ItemView then self.ItemView:SetActive(true) end
end

function M:OnClickBtn2(go)
	local harmInfo = CopyMgr:GetCopyHarmCheer()
	if not harmInfo then return end
	if harmInfo.allTimes >= self.CostMax then 
		UITip.Log("鼓舞次数达到上限，不能继续鼓舞！！")
		self:HaveExpSprite()
		self.CheerView:SetActive(false)
		return
	end
	local temp = self.Cost 
	if not temp then return end
	local cost = temp.Value1
	if self.GlodT.value == true then
		self:CostGlod(cost[2].id)
	end
	if self.CopperT.value == true and harmInfo.silverTimes < self.CostCCheer then 
		self:CostCopper(cost[1].id)
	else
		self.CopperT:Set(false,false)
		self.GlodT:Set(true,false)
	end
	
 end

function M:OnClickCheerBlack(go)
	if self.CheerView then self.CheerView:SetActive(false) end
	self:HaveExpSprite()
end

function M:OnClickItemBlack(go)
	if self.ItemView then self.ItemView:SetActive(false) end
end

function M:CostCopper(t)
	local cost = self.Cost.Value1[1].value
	local val = RoleAssets.GetCostAsset(t);
	if val < cost then
		local n = GetCurrencyTypeName(t)
		UITip.Error(string.format( "%s不足，鼓舞失败!! 请获取%s", n, n));
		return 
	end
	cMgr:ReqCopyCheer(1, t)
end

function M:CostGlod(t)
	local cost = self.Cost.Value1[2].value
	local val = RoleAssets.GetCostAsset(t);
	 if val < cost then
		 local n = GetCurrencyTypeName(t)
		 UITip.Error(string.format( "%s不足，鼓舞失败!! 请获取%s", n, n));
		 return 
	 end
	 cMgr:ReqCopyCheer(1, t)
end

function M:InitItem()
	if not self.Ids then return end
	local list = self.Ids.Value2
	for i=1,#list do
		local item = ItemData[tostring(list[i])]
		if item then
			self:AddItem(item)
		end
	end
end

function M:AddItem(item)
	local id = tostring(item.id)
	local go = GameObject.Instantiate(self.Prefab)
	go.name = tostring(id)
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
	go:SetActive(true)
	local cell =  ObjPool.Get(UICellButton)
	cell:Init(go)
	cell:UpdateItem(item)
	table.insert(self.Items, cell)
end

function M:UpdateItemList()
	local items = self.Items
	if not items then return end
	for i=1,#items do
		items[i]:UpdateItemList()
	end
end


function M:InitBuff()
	local harm = User:GetBufValBySrID(201)
	local exp = User:GetBufValBySrID(204)
	self.CheerDes.text = string.format("伤害+%d%%",harm) 
	self.RatioDes.text = string.format("经验+%d%%",exp)
	if self.BuffValue1 then
		if harm <= 0 then
			self.BuffValue1.text = "[F21919FF]未鼓舞[-]"
		else
			self.BuffValue1.text = string.format("[00FF00FF]%d%%",harm)
		end
		self.BuffValue1.gameObject:SetActive(true)
	end
	if self.BuffValue2 then
		if exp <= 0 then
			self.BuffValue2.text = "[F21919FF]0效益[-]"
		else
			self.BuffValue2.text = string.format("[00FF00FF]%d%%",exp)
		end
		self.BuffValue2.gameObject:SetActive(true)
	end
end

function M:SetMenuStatus(value)
	if self.CheerBtn then
		self.CheerBtn:SetActive(value)
	end
	if self.RatioBtn then
		self.RatioBtn:SetActive(value)
	end
	self.CheerDes.gameObject:SetActive(value)
	self.RatioDes.gameObject:SetActive(value)
end

function M:Clear()
	TableTool.ClearDic(self.ExpList)
end

function M:DisposeSelf()
	self:SetEvent(EventMgr.Remove)
	TableTool.ClearDicToPool(self.Items)
	self.state = nil
	self.id = nil
	self.isCheck = nil
	self.checkExpSprite = nil
	if self.timer then
		self.timer:AutoToPool()
		self.timer = nil
	end
end

return M
