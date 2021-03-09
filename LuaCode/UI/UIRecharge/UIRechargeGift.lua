--[[
 	authors 	:Liu
 	date    	:2018-8-17 12:00:00
 	descrition 	:充值礼包
--]]

UIRechargeGift = Super:New{Name="UIRechargeGift"}

local My = UIRechargeGift

function My:Init(root, cfg)
	local CG, des = ComTool.Get, self.Name
	local moneyLab = CG(UILabel, root, "lab")
	local dayLab = CG(UILabel, root, "daysLab")
	local getLab = CG(UILabel, root, "getLab")
	self.cfg = cfg
	UITool.SetBtnSelf(root, self.OnClick, self, des)
	self:InitLab(cfg, moneyLab, dayLab, getLab)
end

--初始化文本
function My:InitLab(cfg, moneyLab, dayLab, getLab)
	if cfg == nil then iTrace.Error("SJ", "充值配置不存在") return end
	local key = tostring(cfg.gift[1])
	local it = ItemData[key]
	if it == nil then iTrace.Error("SJ", "没有这个道具") return end
	moneyLab.text = cfg.gold
	dayLab.text = "[6A3906FF]购买后持续[B65600FF]"..cfg.day.."天"
	getLab.text = "[6A3906FF]每天得[B65600FF]"..cfg.gift[2].."绑元"
end

--点击充值项
function My:OnClick()
	local mgr = RechargeMgr
	if mgr.rDays == nil then
		iTrace.Error("SJ", "礼包剩余天数获取错误")
		return
	elseif mgr.rDays ~= 0 then
		UITip.Log("该礼包的持续时间尚未结束")
		return
	elseif mgr.rDays == 0 then
		RechargeMgr:BuyGold("Func1", "Func2", "Func3", "Func4", self)
	end
end

--编辑器
function My:Func1()
	
end

--Android
function My:Func2()
    RechargeMgr:ReqRecharge(self.cfg.id)
end

--IOS
function My:Func3()
    RechargeMgr:ReqRecharge(self.cfg.id)
end

--其他
function My:Func4()
    
end

--清理缓存
function My:Clear()
    self.cfg = nil
end
        
--释放资源
function My:Dispose()
    self:Clear()
end

return My