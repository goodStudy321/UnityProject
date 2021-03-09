UIMktWBSetPanel = Super:New{Name = "UIMktWBSetPanel"}

local M = UIMktWBSetPanel

local priceStr = ObjPool.Get(StrBuffer)
local numStr = ObjPool.Get(StrBuffer)

-- 0为数量，1为总价
local type = 0

function M:Init(panelObject)
	self.obj=panelObject
	self.objTrans=self.obj.transform

    local C = ComTool.Get
	local T = TransTool.FindChild

	self.StarLvObj = T(self.objTrans,"StarLv")
	self.InputNum = C(UIInput,self.objTrans, "Num/InputBg", tip, false)
	self.InputPrice = C(UIInput,self.objTrans, "onePrice/InputBg", tip, false)
	--self.InputBg = C(UIInput,self.objTrans, "BgPrice/InputBg", tip, false)

	self.bgLb = C(UILabel,self.objTrans, "BgPrice/InputLb", tip, false)
	
	self.StarLv = C(UIPopupList,self.objTrans,"StarLv/StarLvMenu")
	self.StarLvLb = C(UILabel,self.objTrans,"StarLv/StarLvMenu/Label")

	self.resetBtn=T(self.objTrans,"ResetBtn")
	UITool.SetLsnrSelf(self.resetBtn,self.ClickToReset,self,self.Name)

	self.releaseBtn=T(self.objTrans,"ReleaseBtn")
	UITool.SetLsnrSelf(self.releaseBtn,self.ClickToRelease,self,self.Name)

	EventDelegate.Add(self.InputNum.onChange,EventDelegate.Callback(self.OnCNum,self))
	EventDelegate.Add(self.InputPrice.onChange,EventDelegate.Callback(self.OnCPNum,self))
	EventDelegate.Add(self.StarLv.onChange,EventDelegate.Callback(self.OnCValue,self))


	self.numLb = T(self.objTrans,"Num/InputBg/InputLb")
	UITool.SetLsnrSelf(self.numLb,self.CNum,self,self.Name, false)
	self.priceLb = T(self.objTrans,"onePrice/InputBg/InputLb")
	UITool.SetLsnrSelf(self.priceLb,self.OnPrice,self,self.Name, false)
end

function M:AddE()
	PricePanel.eNum:Add(self.OnNum,self)
	PricePanel.eClear:Add(self.OnClear,self)
	PricePanel.eConfirm:Add(self.OnConfirm,self)
end

function M:RemoveE()
	PricePanel.eNum:Remove(self.OnNum,self)
	PricePanel.eClear:Remove(self.OnClear,self)
	PricePanel.eConfirm:Remove(self.OnConfirm,self)
end

function M:OnNum(name)
	if type == 0 then
		local num = self.InputNum.value
		if StrTool.IsNullOrEmpty(num) then
			numStr:Dispose()
		end
		numStr:Apd(name)
		self:ShowNum()
	else
		local price = self.InputPrice.value
		if StrTool.IsNullOrEmpty(price) then
			priceStr:Dispose()
		end
		priceStr:Apd(name)
		self:ShowPrice()
	end
	
end

function M:OnClear()
	if type == 0 then
		numStr:Dispose()
		self:ShowNum()
	else
		priceStr:Dispose()
		self:ShowPrice()
		self.bgLb.text = 0
	end
end

function M:OnConfirm()
	if type == 0 then
		self:ShowNum()
	else
		local price = tonumber(priceStr:ToStr())
		if price < 2 then
			self.InputPrice.value = 2
		end
	end
end

--==============================--

function M:CNum()
	type = 0
	local num = self.InputNum.value
	self:AddE()
	UIMgr.Open(PricePanel.Name);
end

function M:OnPrice()
	type = 1
	self:AddE()
	UIMgr.Open(PricePanel.Name);
end

--==============================--

function M:ShowNum()
	local num = tonumber(numStr:ToStr())
	self.InputNum.value = num
end

function M:ShowPrice()
	local price = tonumber(priceStr:ToStr())
	self.InputPrice.value = price
end

--==============================--

function M:OnCNum()
	local wantItemId = MarketMgr:GetIWBGoodId();
	local overlayNum = ItemData[tostring(wantItemId)].overlayNum
	if overlayNum == 1 then
		self.InputNum.value = 1
	else
		if StrTool.IsNullOrEmpty(self.InputNum.value) then
			return
		else
			if tonumber(self.InputNum.value) < 1 or self.InputNum.value == nil then
				self.InputNum.value = 1
			elseif tonumber(self.InputNum.value) > overlayNum then
				self.InputNum.value = overlayNum
			end
		end
	end
end

function M:OnCPNum()
	if StrTool.IsNullOrEmpty(self.InputPrice.value)  then
		return
	elseif tonumber(self.InputPrice.value) < 0 then
		self.InputPrice.value = 0
	elseif tonumber(self.InputPrice.value) > 999999 then
		self.InputPrice.value = 999999
	end
	self.bgLb.text = self.InputPrice.value
end

function M:OnCValue()
	local subItemTbl = self.subItemTbl
	for i,v in pairs(subItemTbl) do
		if v.startLv == tonumber(self.StarLvLb.text) then
			MarketMgr:SetIWBGoodId(v.id)
		end
	end
	self:OnCNum()
end


function M:Open()
	self.obj:SetActive(true)
	self:ClickToReset()
end

function M:Close()
	self.obj:SetActive(false)
end

function M:InitFilterBtns(itemList)
	self.subItemTbl = itemList.subItemTbl
	if self.subItemTbl ~= nil then
		self.StarLvObj:SetActive(true)
		self.StarLvLb.text = tostring(self.subItemTbl[1].startLv)
		self.StarLv:Clear()
		for i=1,#self.subItemTbl do
			self.StarLv:AddItem(tostring(self.subItemTbl[i].startLv))
		end
	else
		self.StarLvObj:SetActive(false)
	end
	MarketMgr:SetIWBGoodId(itemList.id)
end

function M:ClickToReset()
	self.InputNum.value = ""
	self.InputPrice.value = ""
	self.bgLb.text = 0
end

function M:ClickToRelease()
	local num = self.InputNum.value
	local price = self.InputPrice.value
	local bg = self.bgLb.text
	if StrTool.IsNullOrEmpty(num) or StrTool.IsNullOrEmpty(price) or StrTool.IsNullOrEmpty(bg) then UITip.Log("请先输入信息") return end
	if RoleAssets.Gold < tonumber(price) then
		--UITip.Log("元宝不足，求购失败")
		StoreMgr.JumpRechange()
	else
		local wantItemId = MarketMgr:GetIWBGoodId()
		if wantItemId <= 0 then
			return;
		end
		local list={}
		list.id = wantItemId
		list.price = price
		list.num = num
		MarketMgr:ReqMarketWantInfos(list)
		self:ClickToReset()
	end
end

function M:ShowStarLvObj(bool)
	if bool == true then
		self.StarLvObj:SetActive(true)
	else
		self.StarLvObj:SetActive(false)
	end
end

function M:Dispose()
	self:RemoveE()
end

return M