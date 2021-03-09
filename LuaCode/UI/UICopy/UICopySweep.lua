UICopySweep = Super:New{Name = "UICopySweep"}

local M = UICopySweep

M.mBossNum = 6

function M:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local SC = UITool.SetLsnrClick
    local F = TransTool.Find
    
    self.mGo = go
	self.mDes = G(UILabel, trans, "Des")
	self.mTick = G(UIToggle, trans, "Tick")
    self.mPrice = G(UILabel, trans, "Tick/Price")
    self.mCount = G(UILabel, trans, "Tick/Count")
    self.mSweepCount = G(UILabel, trans, "Count")

    self.mCount.text = M.mBossNum
    self.mSweepCount.text = "1"
    
	self.mSweepCell = ObjPool.Get(UIItemCell)
    self.mSweepCell:InitLoadPool(F(trans, "ItemRoot"))
    
    SC(trans, "Close", "", self.OnClose, self)
    SC(trans, "Button1", "", self.OnSweep, self)
    SC(trans, "Button2", "", self.OnClose, self)
    SC(trans, "Tick/BtnReduce", "", self.OnReduce, self)
    SC(trans, "Tick/BtnAdd", "", self.OnAdd, self)
    SC(trans, "BtnReduce", "", self.OnReduceSweepCount, self)
    SC(trans, "BtnAdd", "", self.OnAddSweepCount, self)
end

function M:OnReduceSweepCount()
    local num = tonumber(self.mSweepCount.text)
    num = num - 1
    if num > 0 then
        self.mSweepCount.text = num
        self:UpdateCell()
    end  
end

function M:OnAddSweepCount()
    if not self.mTemp then return end
    local copy = CopyMgr.Copy[tostring(self.mTemp.type)] 
    local remainCount = self.mTemp.num + copy.Buy + copy.itemAdd - copy.Num
    local num = tonumber(self.mSweepCount.text)
    num = num + 1
    if num <= remainCount then
        self.mSweepCount.text = num
        self:UpdateCell()
    end
end

function M:OnReduce()
    local num = tonumber(self.mCount.text)
    num = num - 1
    if num < 0 then
        num = 0
    end
    self.mCount.text = num
    self:UpdatePrice()
end

function M:OnAdd()
    local num = tonumber(self.mCount.text)
    num = num + 1
    if num > M.mBossNum then
        num = M.mBossNum
    end
    self.mCount.text = num
    self:UpdatePrice()
end

function M:OnClose()
    self:SetActive(false)
end

function M:OnSweep()
    local temp = self.mTemp
    if not temp then return end
    if not temp.sCost then return end
    self:CheckSweepItem()
end

function M:BuyResp(typeId)
    if self.mItemId == typeId then
        self:CheckBossCost()
    end
end

--检测召唤神兽
function M:CheckBossCost()
    local temp = self.mTemp
    if not temp then return end
    local count = tonumber(self.mSweepCount.text)
    if temp.type ~= CopyType.XH then
        CopyMgr:ReqCopyCleanTos(temp.id, count)
    else
        local num = tonumber(self.mCount.text)
        if self.mTick.value then
            if RoleAssets.IsEnoughAsset(3, self.mBossCost * count) then
                CopyMgr:ReqCopyCleanTos(temp.id, count, num)
            else
                UITip.Error(string.format("绑元不足,无法召唤%s只神兽", num))
            end
        else
            CopyMgr:ReqCopyCleanTos(temp.id, count)
        end
    end
end

--检测扫荡劵
function M:CheckSweepItem()
    local temp = self.mTemp
    local copy = CopyMgr.Copy[tostring(temp.type)]  
    if not copy then return end
    local times = copy.CleanTims or 0
    local index = times+1
    local sCost = temp.sCost
    if not sCost then return end
    local cost = sCost[index] or sCost[#sCost]
    local id = cost.k
    local item = ItemData[tostring(id)]
    local count = PropMgr.TypeIdByNum(item.id)
    local sweepTimes = tonumber(self.mSweepCount.text)
    local need = cost.v*sweepTimes
    if count < need then
        local num = need - count
        local total = StoreMgr.GetTotalPrice(item.id, num)
        self.mItemPrice = total
        self.mNeedNum = num
        self.mItemId = item.id
        MsgBox.ShowYesNo(string.format("[FF0000]%s[-]不足，是否花费%s绑元购买并完成扫荡(绑元不足消耗元宝)", item.name, total), self.YesCb, self)
    else
        self:CheckBossCost()
    end
end

function M:YesCb()
    local temp = self.mTemp
    if not temp then return end
    if RoleAssets.IsEnoughAsset(3, self.mItemPrice) then
        StoreMgr.TypeIdBuy(self.mItemId, self.mNeedNum, false)
    else
        UITip.Error("绑元/元宝不足")
    end
end

function M:UpdateData(temp)
    if not temp then return end
    self.mTemp = temp
    self:UpdateDesTick()
    self:UpdateCell()
end

function M:UpdateDesTick()
    local temp = self.mTemp
    local state = temp.type ~= CopyType.XH
    self.mDes.gameObject:SetActive(state)
    self.mTick.gameObject:SetActive(not state)
    if state then
        self:UpdateDes()
    else
        self:UpdatePrice()
    end
end

function M:UpdateDes()
    local temp = self.mTemp
    local Copy = CopyMgr.Copy[tostring(temp.type)]
    self.mDes.text = ""
    if Copy then
        local dic = Copy.Dic
        if dic then
            local info = dic[tostring(temp.id)]
            if info then
                local s1, s2 = "无评级", "[F39800FF]基础[-]"
                local star = info.Star
                if star == 1 then
                    s1, s2 = "丙级", "[F39800FF]丙级[-]评级"
                elseif star == 2 then
                    s1, s2 = "乙级", "[F39800FF]乙级[-]评级"
                elseif star == 3 then
                    s1, s2 = "甲级", "[F39800FF]甲级[-]评级"
                end
                self.mDes.text = string.format("[F4DDBDFF]该副本目前最高评级为[F39800FF]%s[-]，扫荡可获得%s奖励", s1, s2)
            end
        end
    end
end

function M:UpdatePrice()
    local price = GlobalTemp["48"].Value3
    local total = price * tonumber(self.mCount.text)
    self.mBossCost = total
    local color = RoleAssets.IsEnoughAsset(3, self.mBossCost) and "[00FF00FF]" or "[CC2500FF]"
    self.mPrice.text = string.format("%s%s[-]", color, total)
end

function M:UpdateCell()
    local temp = self.mTemp 
    local copy = CopyMgr.Copy[tostring(temp.type)]  
    if not copy then return end
    local times = copy.CleanTims or 0
    local index = times+1
    local sCost = temp.sCost
    if not sCost then return end
    local cost = sCost[index] or sCost[#sCost]
	if not cost then return end
    if self.mSweepCell then
        local need = cost.v * tonumber(self.mSweepCount.text)
		local str = ItemTool.GetConsumeOwn(cost.k, need)
		self.mSweepCell:UpData(cost.k, str)
	end
end

function M:SetActive(bool)
    self.mTick.value = false
    self.mSweepCount.text = "1"
    self.mGo:SetActive(bool)
end

function M:IsActive()
    return self.mGo.activeSelf
end

function M:Dispose()
    self.mTemp = nil
    TableTool.ClearUserData(self)
    self.mSweepCell:DestroyGo()
    ObjPool.Add(self.mSweepCell)
    self.mSweepCell = nil
end

return M