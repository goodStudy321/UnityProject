CopyTool = {}

local M = CopyTool

local cMgr = CopyMgr
local vMgr = VIPMgr

function M.CanBuyTime(temp)
	local lv = vMgr.vipLv or 0
	if not temp then return end
    local copyData = cMgr.Copy[tostring(temp.type)]
    local max = vMgr.CopyEnter(temp.type, lv) or 0
    if copyData and max > copyData.Buy then
        M.OnBuyCopyNum(temp, copyData.Buy)
        return true
    end
    M.CheckOpenVIP(lv, temp)
    return false
end

function M.OnBuyCopyNum(temp, buyTimes)
    if not temp then return end
    local cost = temp.bCost[buyTimes+1] or temp.bCost[#temp.bCost]

    -- if RoleAssets.Gold < cost and RoleAssets.BindGold < cost then
    if RoleAssets.Gold + RoleAssets.BindGold < cost then
        UITip.Log(string.format("购买进入次数需要%s元宝。元宝不足，不能购买", cost))
        return
    end
    cMgr:ReqCopyBuyTimes(temp.id)
end

function M.CheckOpenVIP(lv, temp)
	local nLv, nNum = vMgr.NextCopyEnter(temp.type)
    if nLv and lv < nLv then
        UITip.Error("未达到VIP等级要求，无法继续购买")
	else
		UITip.Log("已达到今日的购买上限，不能继续购买次数")
	end
end

function M.OpenUIVIP(type)
	-- cMgr.CloseUICopy()
    --VIPMgr.OpenVIP()
    UIMgr.Open(UIV4Panel.Name)
    local uiName = nil
    if type == CopyType.ZHTower then
        uiName = UICopyTowerPanel.Name
    else
        uiName = UICopy.Name
    end
    JumpMgr:InitJump(uiName, type)
end

return M