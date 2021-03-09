--[[
 	authors 	:Liu
 	date    	:2018-7-25 09:45:00
 	descrition 	:开服活动界面项2
--]]

UIRankMenuIt2 = Super:New{Name = "UIRankMenuIt2"}

local My = UIRankMenuIt2

require("UI/UIRankActiv/UIRankBuyItem")

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find
	local FindC = TransTool.FindChild
	local str, str1 = "/lab1", "powerUp/icons/bg"
	local str2, str3 = "myRank", "myLv"
	local str4 = "buyBg/Scroll View/Grid"

	self.labList = {}
	self.iconList = {}
	self.iconBtnList = {}
	self.itList = {}
	self.myRank = CG(UILabel, root, str2..str)
	self.lvLab = CG(UILabel, root, str3.."/lab")
	self.myLv = CG(UILabel, root, str3..str)
	self.upLab =  CG(UILabel, root, "powerUp/lab")
	self.grid = CG(UIGrid, root, str4)
	self.sView = CG(UIScrollView, root, "buyBg/Scroll View")
	self.iconGrid = CG(UIGrid, root, "powerUp/icons")
	self.item = FindC(root, str4.."/item", des)

	self:InitIcon(root, CG, str1, des)
end

--更新数据
function My:UpData(id, rank, cond, state)
	local cfg = RankActivCfg[id]
	if cfg == nil then return end
	self:UpIcon(cfg, id)
	self:UpBuyItems(cfg)
	if id == 1 then
		self:UpRankLab(rank, "我的等级：", cond, "我要冲级", state)
	elseif id == 2 then
		local str = RankActivMgr:GetMountsInfo(cond)
		self:UpRankLab(rank, "坐骑阶级：", str, "我要进阶", state)
	elseif id == 3 then
		self:UpRankLab(rank, "我的战力：", cond, "我要套装", state)
	elseif id == 4 then
		local str = RankActivMgr:GetPetInfo(cond)
		self:UpRankLab(rank, "伙伴阶级：", str, "伙伴提升", state)
	elseif id == 5 then
		self:UpRankLab(rank, "我的战力：", cond, "我要印记", state)
	elseif id == 6 then
		self:UpRankLab(rank, "我的战力：", cond, "我要变强", state)
	elseif id == 7 then
		local str1 =RankActivMgr:GetFiveInfo(cond)
		self:UpRankLab(rank, "我的进度：", str1, "我要幻力", state)
	end
end

--更新排行文本
function My:UpRankLab(myRank, lvLab, myLv, upLab, state)
	local rank = (myRank==0) and "未上榜" or myRank
	if state == 0 then--活动未开启
		self:SetRankLab("未开启", lvLab, "未开启", upLab, state)
	elseif state == 1 then--活动开启中
		self:SetRankLab(rank, lvLab, myLv, upLab, state)
	elseif state == 2 then--活动已结束
		self:SetRankLab(rank, lvLab, myLv, upLab, state)
	end
end

--设置排行文本
function My:SetRankLab(myRank, lvLab, myLv, upLab, state)
	local isEnd = (state==2 and myRank==0)
	local rank = isEnd and "已错过活动" or myRank
	local lv = isEnd and "已错过活动" or myLv
	self.myRank.text = rank
	self.lvLab.text = lvLab
	self.myLv.text = lv
	self.upLab.text =  upLab
end

--更新Icon
function My:UpIcon(cfg, id)
	if cfg == nil then return end
	self:HideIcon()
	local labList = self.labList
	local iconList = self.iconList
	local iconBtnList = self.iconBtnList
	for i,v in ipairs(cfg.sysName) do
		if i > 3 then return end
		self:ShowIcon(labList[i])
		labList[i].text = v
		iconList[i].spriteName = cfg.iconName[i]
		iconBtnList[i].name = cfg.mark[i]
	end
	self.iconGrid:Reposition()
end

--初始化Icon
function My:InitIcon(root, CG, str1, des)
	local Find, SetS = TransTool.Find, UITool.SetLsnrSelf
	for i=1, 3 do
		local iconBtn = Find(root, str1..i, des)
		local lab = CG(UILabel, root, str1..i.."/lab")
		local icon = CG(UISprite, root, str1..i.."/icon")
		SetS(iconBtn, self.OnIconBtn, self, des)
		table.insert(self.labList, lab)
		table.insert(self.iconList, icon)
		table.insert(self.iconBtnList, iconBtn)
	end
	self.iconGrid:Reposition()
end

--初始化购买道具
function My:UpBuyItems(cfg)
	if cfg == nil then return end
	local Add = TransTool.AddChild
	local parent = self.grid.transform
	local len = #cfg.buyItems
	if #self.itList < len then
		local num = len - #self.itList
		for i=1, num do
			local go = Instantiate(self.item)
			local tran = go.transform
			go:SetActive(true)
			Add(parent, tran)
			local it = ObjPool.Get(UIRankBuyItem)
			it:Init(tran)
			table.insert(self.itList, it)
		end
		for i,v in ipairs(self.itList) do
			v:Updata(cfg.buyItems[i])
		end
	else
		for i,v in ipairs(self.itList) do
			if i > len then
				v.go:SetActive(false)
			else
				v.go:SetActive(true)
				v:Updata(cfg.buyItems[i])
			end
		end
	end
	self.item:SetActive(false)
	self.grid:Reposition()
	self.sView:ResetPosition()
end

--点击图标按钮
function My:OnIconBtn(go)
	self.num = go.name
	local O = UIMgr.Open
	local index = UIRankActiv.id
	local amgr = ActivityMgr
	local isShowTips = false

	if go.name == "1" then--限时云购
		local isOpen = UITabMgr.IsOpen(amgr.XSYG)
		if isOpen then O(UICloudBuy.Name) else isShowTips = true end

	elseif go.name == "2" then--经验副本
		local isOpen = OpenMgr:IsOpen(401)
		if isOpen then UICopy:Show(CopyType.Exp) else isShowTips = true end

	elseif go.name == "3" then--装备副本
		local isOpen = OpenMgr:IsOpen(404)
		if isOpen then UICopy:Show(CopyType.Equip) else isShowTips = true end

	elseif go.name == "4" then--宠物副本
		local isOpen = OpenMgr:IsOpen(402)
		if isOpen then UICopy:Show(CopyType.SingleTD) else isShowTips = true end
		
	elseif go.name == "5" then--VIP礼包
		if VIPMgr.GetVIPLv() < 1 then VIPMgr.OpenVIP(5) else VIPMgr.OpenVIP(6) end
		
	elseif go.name == "6" then--商城
		local isOpen = UITabMgr.IsOpen(amgr.SD)
		if isOpen then StoreMgr.OpenStore(2) else isShowTips = true end

	elseif go.name == "7" then--充值
		local IsShield = UITabMgr.Pattern2(1002)
		if not IsShield then VIPMgr.OpenVIP(1) else isShowTips = true end
		
	elseif go.name == "8" then--日常活跃
		local isOpen = UITabMgr.IsOpen(amgr.HY)
		if isOpen then O(UILiveness.Name) else isShowTips = true end

	elseif go.name == "9" then--世界Boss
		local isOpen = UITabMgr.IsOpen(amgr.BOSS)
		if isOpen then O(UIBoss.Name) else isShowTips = true end

	elseif go.name == "10" then--寻宝
		local isOpen = UITabMgr.IsOpen(amgr.XB)
		if isOpen then UITreasure:OpenTab(1) else isShowTips = true end

	elseif go.name == "11" then--五行秘境
		local isOpen = OpenMgr:IsOpen(407)
		if isOpen then UIRobbery:OpenRobbery(11) else isShowTips = true end

	elseif go.name == "12" then--洞天福地
		local isOpen = UITabMgr.IsOpen(amgr.BOSS)
		if isOpen then
			BossHelp.curType = 2
			O(UIBoss.Name)
		else isShowTips = true end

	elseif go.name == "13" then--魔域禁地
		local isOpen = UITabMgr.IsOpen(amgr.DemonArea)
		if isOpen then O(UIDemonArea.Name) else isShowTips = true end
	end

	if isShowTips then
		UITip.Log("系统未开启")
		return
	end
	JumpMgr:InitJump(UIRankActiv.Name, index)
end

--隐藏Icon
function My:HideIcon()
	for i,v in ipairs(self.labList) do
		local go = v.transform.parent.gameObject
		go:SetActive(false)
	end
end

--显示Icon
function My:ShowIcon(icon)
	local go = icon.transform.parent.gameObject
	go:SetActive(true)
end

--清理缓存
function My:Clear()
	
end
    
--释放资源
function My:Dispose()
	self:Clear()
	ListTool.ClearToPool(self.itList)
end

return My

