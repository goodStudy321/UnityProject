CopyExpBuyView = Super:New {Name = "CopyExpBuyView"}

local M = CopyExpBuyView

local cMgr = CopyMgr
local vMgr = VIPMgr

function M:Init(go)
    local trans = go.transform
    local S = UITool.SetLsnrSelf
    local G = ComTool.Get
    local F = TransTool.Find
    local FC = TransTool.FindChild

    self.mGo = go
    self.mBtnTick = FC(trans, "TciketUse/Btn")
	self.mTickItemRoot = F(trans, "TciketUse/ItemRoot")
	self.mFxBtn = FC(self.mBtnTick.transform, "FX_UI_Button")


    self.mBtnBuy = FC(trans, "VIPBuy/Btn")
    self.mVipItemRoot = F(trans, "VIPBuy/ItemRoot")
    self.mVipDes = G(UILabel, trans, "VIPBuy/Des")
	self.mVipDes3 = G(UILabel, trans, "VIPBuy/Des3")
	self.mVipDes3.text = "（绑元不足消耗元宝）"

    self.mBtnClose = FC(trans, "BtnClose")

    S(self.mBtnTick, self.OnTick, self)
    S(self.mBtnBuy, self.OnBuy, self)
    S(self.mBtnClose, self.OnClose, self)
end

function M:Open(temp)
	self.mTemp = temp
	self:SetActive(true)
	self:UpdateData()
end

function M:UpdateCell()
	if not self.mTickCell then
		self.mTickCell = ObjPool.Get(UIItemCell)
		self.mTickCell:InitLoadPool(self.mTickItemRoot)
		self.mTickCell:UpData(31025)
	end

	if not self.mGoldCell then
		self.mGoldCell = ObjPool.Get(UIItemCell)
		self.mGoldCell:InitLoadPool(self.mVipItemRoot)
		self.mGoldCell:UpData(3)
	end
	local num = PropMgr.TypeIdByNum(31025)
	local state = num > 0
	local color = state and "[00FF00FF]" or "[F21919FF]"
	self.mTickCell:UpLab(string.format("%s%s/%s", color, num, 1))
	local temp = self.mTemp
	local copyData = CopyMgr.Copy[tostring(temp.type)]
	local buy = copyData.Buy
	local cost = temp.bCost[buy+1] or temp.bCost[#temp.bCost]
	self.mGoldCell:UpLab(cost)
	self.mFxBtn:SetActive(state)
end

function M:SetActive(bool)
    self.mGo:SetActive(bool)
end

function M:UpdateData()
	if not self.mTemp then return end
	local temp = self.mTemp
	local t = temp.type
	local curlv = vMgr.vipLv or 0
	local num = vMgr.CopyEnter(t, curlv) or 0

	local info = CopyMgr.Copy[tostring(t)]
	local buy = info and info.Buy or 0

	local nextlv, nextNum = vMgr.NextCopyEnter(t)
	if nextlv then
		self.mVipDes.text = string.format("[F39800FF]VIP%s[F4DDBDFF]每日可购买次数：[00FF00FF]%s/%s\n[99886BFF]（VIP%s每日可购买%s次）", curlv, num-buy, num, nextlv, nextNum)
	else
		self.mVipDes.text = string.format("[F39800FF]VIP%s每日可购买次数：[00FF00FF]%s/%s", curlv, num-buy, num)
	end
	self:UpdateCell()
end

function M:OnClose()
    self:SetActive(false)
end

function M:OnTick()
	local num = PropMgr.TypeIdByNum(31025)
	if num > 0 then
		PropMgr.ReqUse(31025,1,1)
	else
		UITip.Log("道具不足")
	end
end

function M:OnBuy()
	if not CopyTool.CanBuyTime(self.mTemp) then
		self:OnClose()
		local vip = VIPMgr.GetVIPLv()
		if vip == 0 then
			CopyTool.OpenUIVIP(self.mTemp.type)
        end
    end
end

function M:Dispose()
	self.mTemp = nil
	TableTool.ClearUserData(self)
	if self.mTickCell then
		self.mTickCell:DestroyGo()
		ObjPool.Add(self.mTickCell)
		self.mTickCell = nil
	end
	if self.mGoldCell then
		self.mGoldCell:DestroyGo()
		ObjPool.Add(self.mGoldCell)
		self.mGoldCell = nil
	end
end

return M