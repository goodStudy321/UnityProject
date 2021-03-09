--[[
 	authors 	:Liu
 	date    	:2018-8-17 12:00:00
 	descrition 	:VIP投资界面
--]]

UIVIPInvest = Super:New{Name="UIVIPInvest"}

local My = UIVIPInvest

require("UI/UIVIPInvest/UIVIPInvestItem")

function My:Init(go)
	local root = go.transform
	local CG, des = ComTool.Get, self.Name
	local Find, str = TransTool.Find, "ScrollView/Grid"
	local btnTran = Find(root, "BtnInvest", des)
	local parent = Find(root, str, des)
	local item = TransTool.FindChild(root, str.."/Cell", des)
	UITool.SetBtnSelf(btnTran, self.OnBtnClick, self, des)
	UITool.SetBtnClick(root, "BtnHelp", des, self.OnHelp, self)
	self.daysLab = CG(UILabel, root, "lab3")
	self.investLab1 = CG(UILabel, root, "BtnInvest/lab1")
	self.investLab2 = CG(UILabel, root, "BtnInvest/lab2")
	self.btnSpr = CG(UISprite, root, "BtnInvest", des)
	self.go = go
	self.itList = {}
	self:UpLab()
	self:InitItem(item, parent)
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = VIPInvestMgr
	mgr.eGetAward[func](mgr.eGetAward, self.RespGetAward, self)
	mgr.eUpInfo[func](mgr.eUpInfo, self.RespUpInfo, self)
	mgr.eBuy[func](mgr.eBuy, self.RespBuy, self)
	PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10113 then		
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

--响应领取奖励
function My:RespGetAward()
	self:UpData()
end

--响应更新VIP投资信息
function My:RespUpInfo()
	self:UpData()
end

--响应购买VIP投资
function My:RespBuy()
	self:UpData()
	UITip.Log("投资成功")
end

--更新数据
function My:UpData()
	for i,v in ipairs(self.itList) do
		v:UpBtnState()
	end
	self:UpLab()
	self:UpVIPLv(self.investLab1, self.investLab2)
	self.grid:Reposition()
end

--初始化VIP投资项
function My:InitItem(item, parent)
	local Add = TransTool.AddChild
	local awardLv = self:GetAwardLv()
	for i,v in ipairs(VIPInvestCfg) do
		local lv = math.floor(v.id / 100)
		if awardLv == lv then
			local go = Instantiate(item)
			local tran = go.transform
			go.name = 1000 + i
			Add(parent, tran)
			local it = ObjPool.Get(UIVIPInvestItem)
			it:Init(tran, v)
			table.insert(self.itList, it)
		end
	end
	item:SetActive(false)
	self.grid = parent:GetComponent(typeof(UIGrid))
	self.grid:Reposition()
end

--获取奖励档次
function My:GetAwardLv()
	local awardLv = VIPInvestMgr.awardLv
	if awardLv == 0 then
		local lv = User.MapData.Level
		for i,v in ipairs(VIPInvestCfg) do
			if lv >= v.minLv and lv <= v.maxLv then
				awardLv = math.floor(v.id / 100)
				break
			end
		end
	end
	return awardLv
end

--初始化文本
function My:UpLab()
	local mgr = VIPInvestMgr
	local days = mgr.rDays
	local lab = self.daysLab
	if mgr.isMark then
		days = days
	else
		if mgr.isAward then
			local temp = days - 1
			days = (temp<=0) and 0 or temp
		end
	end
	if days == 0 then
		lab.gameObject:SetActive(false)
		return
	else
		lab.gameObject:SetActive(true)
	end
	lab.text = "[ee9a9e]剩余可领取天数：[00ff00]"..days.."[-]天"

end

--更新VIP等级
function My:UpVIPLv(lab1, lab2)
	local isVIP, openGold = self:IsVIP()
	if isVIP and VIPInvestMgr.rDays ~= 0 then
		local str1 = string.format("[5d5451]花费%s元宝", openGold)
		self:UpVIPLab(lab1, lab2, str1, "[5d5451]开启尊享投资", false)
		self.btnSpr.spriteName = "btn_figure_down_avtivity"
	elseif not isVIP then
		self:UpVIPLab(lab1, lab2, "[772a2a]开通VIP4", "[772a2a]体验尊享投资", true)
		self.btnSpr.spriteName = "btn_figure_non_avtivity"
	else
		local str1 = string.format("[772a2a]花费%s元宝", openGold)
		self:UpVIPLab(lab1, lab2, str1, "[772a2a]开启尊享投资", true)
		self.btnSpr.spriteName = "btn_figure_non_avtivity"
	end
end

--更新VIP文本
function My:UpVIPLab(lab1, lab2, str1, str2, state)
	local go = lab1.transform.parent.gameObject
	CustomInfo:SetBtnState(go, state)
	lab1.text = str1
	lab2.text = str2
end

--判断当前VIP是否足够
function My:IsVIP()
	local list = GlobalTemp["33"].Value2
	local vipLv, openGold = list[1], list[2]
	if VIPMgr.GetVIPLv() >= vipLv then
		return true, openGold
	else
		return false, openGold
	end
end

--点击投资说明
function My:OnHelp()
	UIComTips:Show(InvestDesCfg["2"].des, Vector3(35,245,0))
end

--点击开通VIP投资按钮
function My:OnBtnClick()
	local isVip, gold = self:IsVIP()
	local info = RoleAssets
	local myGold = info.Gold
	if not isVip then
		MsgBox.ShowYesNo("VIP等级不足，是否开通VIP4等级？", self.YesCb2, self, "开通")
		return
	elseif myGold < gold then
		MsgBox.ShowYesNo("元宝不足，是否充值？", self.YesCb1, self, "充值")
		return
	end
	MsgBox.ShowYesNo("确定花费"..gold.."元宝参与VIP投资？", self.YesCb3, self, "确定")
end

--跳转到充值界面
function My:YesCb1()
	VIPMgr.OpenVIP(1)
end

--跳转到VIP购买界面
function My:YesCb2()
	VIPMgr.OpenVIP(5)
end

--点击MsgBox的确定按钮
function My:YesCb3()
	VIPInvestMgr:ReqBuyVIPInvest()
end

--打开面板
function My:Open()
	self.go:SetActive(true)
	self:UpVIPLv(self.investLab1, self.investLab2)
end

--关闭面板
function My:Close()
	self.go:SetActive(false)
end

--清理缓存
function My:Clear()
	self.dic = nil
	TableTool.ClearUserData(self)
end
    
--释放资源
function My:Dispose()
	self:Clear()
	self:SetLnsr("Remove")
	ListTool.ClearToPool(self.itList)
end

return My