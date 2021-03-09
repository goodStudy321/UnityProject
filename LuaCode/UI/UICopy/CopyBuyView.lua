CopyBuyView = Super:New{Name = "CopyBuyView"}

local M = CopyBuyView

local cMgr = CopyMgr
local vMgr = VIPMgr

function M:Init(go)
    local trans = go.transform
    local FC = TransTool.FindChild
    local G = ComTool.Get
    local S = UITool.SetLsnrSelf

    self.BuyRoot = go
	self.CloseBuy = FC(trans, "Close")
	self.BuyBtn1 = FC(trans, "Button1")
	self.BuyBtn2 = FC(trans, "Button2")
	self.BuyBtn2Name = G(UILabel, self.BuyBtn2.transform, "Label")
	self.BuyCost = G(UILabel, trans, "Cost", name, false)

	self.BuyTable = G(UITable, self.BuyRoot.transform, "Table")
	self.Cur = FC(self.BuyTable.transform, "Cur")
	self.CurVip = G(UILabel, self.Cur.transform, "CurVip")
	self.CurNum = G(UILabel, self.Cur.transform, "CurNum")
	self.Next = FC(self.BuyTable.transform, "Next")
	self.NextVip = G(UILabel, self.Next.transform, "NextVip")
    self.NextNum = G(UILabel, self.Next.transform, "NextNum")
    
    S(self.BuyBtn1, self.OnClickBuyBtn1, self)
    S(self.BuyBtn2, self.OnClickBuyBtn2, self)
    S(self.CloseBuy, self.OnClose, self)
end

function M:Open(temp)
    self.Temp = temp
    self:SetActive(true)
    self:UpdateData()
end

function M:OnClose()
    self:SetActive(false)
end

function M:OnClickBuyBtn1(go)
    if not CopyTool.CanBuyTime(self.Temp) then
        self:OnClose()
    end
end

function M:UpdateData()
	if not self.Temp then return end
	local temp = self.Temp
	local t = temp.type
	local curlv = vMgr.vipLv or 0
	local num = vMgr.CopyEnter(t, curlv) or 0

	local info = CopyMgr.Copy[tostring(t)]
	local buy = info and info.Buy or 0

	self.BuyBtn2Name.text = curlv >= 4 and "取 消" or "升级VIP"
	local cost = temp.bCost[buy+1] or temp.bCost[#temp.bCost]
	self.BuyCost.text = string.format("[F4DDBDFF]是否使用[F39800FF]%d[-]绑元购买[F39800FF]%d[-]次副本次数[-]\n[99886BFF](绑元不足消耗元宝)[-]", cost, 1) 
	self.CurVip.text = "VIP"..curlv
	self.CurNum.text = string.format("[99886BFF]每日可购买次数：[00FF00FF]%s/%s[-][-]\n[00FF00FF](当前)[-]", num-buy, num)

	local nextlv, num = vMgr.NextCopyEnter(t)
	if nextlv then
		self.Next:SetActive(true)
		self.NextVip.text = string.format("VIP%s",nextlv or curlv)
		self.NextNum.text = string.format("[99886BFF]每日可购买[00FF00FF]%s[-]次[-]", num)
	else
		self.Next:SetActive(false)
	end
	self.BuyTable:Reposition()
end

function M:OnClickBuyBtn2(go)
	self:OnClose()
	local curlv = vMgr.vipLv
	if curlv < 4 then
		CopyTool.OpenUIVIP(self.Temp.type)
	end
end

function M:SetActive(bool)
    self.BuyRoot:SetActive(bool)
end

function M:Dispose()
    self.Temp = nil
    TableTool.ClearUserData(self)
end

return M