--region UIPetActive.lua
--Date
--此文件由[HS]创建生成


UIPetActive = {}
local P = UIPetActive
P.Name = "UI伙伴界面激活窗口"
--local PetInfoMgr = PetInfoManager.instance
--local PetMgs = PetMessage.instance

function P:New()
	return self
end

function P:Init(go)
	local name = self.Name
	self.gameObject = go
	local trans = go.transform
	local C = ComTool.Get
	local T = TransTool.FindChild

	self.Need = C(UILabel, trans, "Need1", name, false)
	self.MaterialCell = UICellQuality.New(T(trans, "ActiveMaterial"))
	self.ActiveBtn = C(UIButton, trans, "ActiveBtn", name, false)
	self.MaterialCell:Init()
	self.CurMaterialNum = 0
	self.NeedMaterialNum = 0
	self.NeedInfo = nil
	self:AddEvent()
end

--注册的事件回调函数
function P:AddEvent()
	local E = UITool.SetLsnrSelf
	if self.ActiveBtn then
		E(self.ActiveBtn, self.OnClickActiveBtn, self)
	end
end

function P:UpdateData(data)
	self:Clean()
	if data == nil then return end
	self.Data = data
	local condition = data.Info.condition
	if not condition then
		self.Item = nil
		self:AddNeedDes("无")
		self:UpdateItem()
	else
		if #condition == 2 then
			self:UpdateMaterialId(condition[1], condition[2])
		elseif #condition == 1 then
			self:UpdatePetId(condition[1])
		end
	end
end

function P:UpdatePetId(id)
	local key = tostring(id)
	if not PetTemp[key] then return end
	self.NeedInfo = PetTemp[key]
	if self.NeedInfo == nil then return end
	local des = string.format("[ff0000]%s[-]%s阶", self.NeedInfo.name, self.NeedInfo.step)
	self:AddNeedDes(des)
end

function P:UpdateMaterialId(id, num)
	if self.Item == nil or self.Item ~= nil and self.Item.id ~= id then
		self.Item = ItemData[tostring(id)]
	end
	self:UpdateItem()
end

function P:UpdateItem()
	local icon = nil
	local quality = nil 
	local value = nil
	local active = nil
	if self.Item == nil then
		icon = nil
		quality = 0
		value = nil
		active = false
		self.CurMaterialNum = 0
		self.NeedMaterialNum = 0
	else
		icon = self.Item.icon
		quality = self.Item.quality
		active = true	
		local count = PropMgr.TypeIdByNum(self.Item.id)
		self.CurMaterialNum = count
		self.NeedMaterialNum = self.Data.Info.costMaterialNum
		value =  self.CurMaterialNum.."/"..self.NeedMaterialNum
		if self.CurMaterialNum < self.NeedMaterialNum then
			value = string.format("[ff0000]%s[-]", value)
		else
			value = string.format("[ffffff]%s[-]", value)
		end
	end
	if self.MaterialCell then
		self.MaterialCell:SetActive(active)
		self.MaterialCell:UpdateIcon(icon)
		self.MaterialCell:UpdateQuality(quality)
		self.MaterialCell:UpdateLabel(value)
	end
end

function P:AddNeedDes(des)
	self.Need.text = des
	self.Need.gameObject:SetActive(true)
end

function P:UpdateItemList( )
	self:UpdateItem()
end

--激活法宝
function P:OnClickActiveBtn(go)
	if not self.Data then 
		UITip.Error("激活失败，数据存在！！！")
		return 	
	end
	if self.NeedMaterialNum ~=0 and self.CurMaterialNum < self.NeedMaterialNum then
		UITip.Error("激活失败，材料不足！！！")
		return
	end
	if self.NeedInfo then
	local info = PetMgr:GetInfo(self.NeedInfo.id)
		if info ~= nil and info.step < self.NeedInfo.step then
			UITip.Error(string.format("激活失败，%s等级未达到lv%s", info.name, self.NeedInfo.step))
			return
		end
	end
	local id = self.Data.Info.id
	local idd=PropMgr.TypeIdById(id)
	if not idd then 
		iTrace.eError("hs", string.format("未从道具表找到指定id:%s",id))
		return
	end	
	PropMgr.ReqUse(idd,1)
	--NetworkMgr.reqPetActive(self.Data.Info.id)
end

function P:SetActive(value)
	if self.gameObject then self.gameObject:SetActive(value) end
end

function P:Clean()
	self.CurMaterialNum = 0
	self.NeedMaterialNum = 0
	self.NeedInfo = nil
end

function P:Dispose()
	if self.MaterialCell then
		self.MaterialCell:Dispose()
	end
	self.MaterialCell = nil
	self.gameObject = nil
	self.Need = nil
	self.ActiveBtn = nil
	self.CurMaterialNum = nil
	self.NeedMaterialNum = nil
	self.NeedInfo = nil
	self.Data = nil
	self.Item = nil
end
--endregion
