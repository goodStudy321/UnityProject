UISkyMysterySealTipView = {}

local M = UISkyMysterySealTipView

M.Pos = {
    Vector3.New(197, 253.04, 0),
    Vector3.New(-473.93, 253.04, 0),
    Vector3.New(-136.5, 253.04, 0)
}

function M:New(go)
    self.Root = go
    local trans = go.transform
	local C = ComTool.Get
    local T = TransTool.FindChild
    local name = "UISkyMysterySealTipView"
    self.Mask = T(trans, "Mask")
    self.ProTip = ObjPool.Get(UISkyMysterySealTip)
    self.ProTip:Init(T(trans, "TargetTip"), true)
    self.CompareTip = ObjPool.Get(UISkyMysterySealTip)
    self.CompareTip:Init(T(trans, "CompareTip"), false)
    UITool.SetLsnrSelf(self.Mask, self.Reset, self, nil, false)
	return self
end

-----------------------------------------------------
--更新印章tip
--target: true(背包，与当前镶嵌对比) false(当前镶嵌)
function M:UpdateData(item, target)
    self:Reset()
    local cur = nil
    local isOpen = false
    local index = -1
    local temp = SMSProTemp[tostring(item.type_id)]
    if target == true then
        if temp then
            local info = SMSMgr:GetPageInfo(SMSMgr.CurPage, temp.index)
            if info then
                isOpen = info.Pro ~= nil
                if info.Pro then
                    cur = info.Pro.Item
                end
            end
        end
    end

    --测试
    --cur = item
    --isOpen = true
    --isOpen = true
    --target = false
    --测试
    local score = 0
    if cur ~= nil then
        self.CompareTip:UpdateData(cur, false, false)
        score = self.CompareTip.ScoreLimit
    end
    self.ProTip:UpdateData(item, target, isOpen, cur ~= nil)
    self.ProTip:UpdateContrast(score)
    if target == true then
        self.ProTip:UpdatePos(self.Pos[1])
    else
        if temp then
            if temp.index >= 3 and temp.index <= 5 then
                self.ProTip:UpdatePos(self.Pos[3])
            else
                self.ProTip:UpdatePos(self.Pos[2])
            end
        end
    end
    self:SetActive(true)
end
-----------------------------------------------------

function M:SetActive(bool)
    self.Root:SetActive(bool)
end

function M:ActiveSelf()
    return self.Root.activeSelf
end

function M:Reset()
    local proTip = self.ProTip
    if proTip then proTip:Reset() end
    local compareTip = self.CompareTip
    if compareTip then compareTip:Reset() end
    self:SetActive(false)
end

function M:Dispose()
    self:Reset()
    local proTip = self.ProTip
    if proTip then 
        proTip:Dispose()
        ObjPool.Add(self.ProTip)
    end
    local compareTip = self.CompareTip
    if compareTip then 
        compareTip:Dispose() 
        ObjPool.Add(self.CompareTip)
    end
end