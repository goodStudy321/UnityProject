--[[
 	authors 	:Liu
 	date    	:2019-3-19 11:00:00
 	descrition 	:限时活动界面1(右)
--]]

UIRankInfoMod = Super:New{Name="UIRankInfoMod"}

local My = UIRankInfoMod

function My:Init(root)
    local des = self.Name
    local CG = ComTool.Get
    local Find = TransTool.Find
    local SetS = UITool.SetLsnrSelf
    local FindC = TransTool.FindChild

    self.labList = {}
    self.iconList = {}
    self.iconBtnList = {}
    self.rankList = {}

    local str = "powerUp/icons/bg"
    for i=1, 3 do
        local iconBtn = Find(root, str..i, des)
		local lab = CG(UILabel, root, str..i.."/lab")
		local icon = CG(UISprite, root, str..i.."/icon")
		SetS(iconBtn, self.OnIconBtn, self, des)
		table.insert(self.labList, lab)
		table.insert(self.iconList, icon)
		table.insert(self.iconBtnList, iconBtn)
	end

    self.lab1 = CG(UILabel, root, "myRank/lab1")
    self.lab2 = CG(UILabel, root, "myLv/lab1")
    self.rankItem = FindC(root, "rankBg/Grid/item", des)

    self:InitLab()
    self:InitIcon()
    self:InitMiniRank()
    self:UpMiniRank()
end

--初始化文本
function My:InitLab()
    local str = ""
    local info = TimeLimitActivInfo
    local idList = info.idList
    local type = info:GetOpenType()
    if type == idList[1] then
        str = User.MapData:GetFightValue(9)
    elseif type == idList[2] then
        str = User.MapData:GetFightValue(12)
    elseif type == idList[3] then
        str = User.MapData:GetFightValue(35)
    end
    self.lab2.text = str

    local myRank = info:GetMyRank()
    local val = (myRank) and myRank.rank or "未上榜"
    self.lab1.text = val
end

--初始化Icon
function My:InitIcon()
    local info = TimeLimitActivInfo
    local list = info:GetCfgList(TimeLimitRankCfg)
    if #list < 1 then return end
    self:HideIcon()
    local it = list[1]
    for i,v in ipairs(it.sysName) do
		self:ShowIcon(self.iconBtnList[i])
		self.labList[i].text = v
		self.iconList[i].spriteName = it.iconName[i]
		self.iconBtnList[i].name = it.mark[i]
	end
end

--初始化迷你排行榜
function My:InitMiniRank()
    local Add = TransTool.AddChild
    local parent = self.rankItem.transform.parent
    for i=1, 6 do
        local go = Instantiate(self.rankItem)
        local tran = go.transform
        Add(parent, tran)
        table.insert(self.rankList, tran)
    end
end

--更新迷你排行榜
function My:UpMiniRank()
    local CG = ComTool.Get
    local rankList = self.rankList
    local info = TimeLimitActivInfo
    local list = info:GetMiniRank()
    for i,v in ipairs(list) do
        local tran = rankList[i]
        local lab1 = CG(UILabel, tran, "lab1")
        local lab2 = CG(UILabel, tran, "lab2")
        lab1.text = v.roleName
        lab2.text = v.val
        tran.gameObject:SetActive(true)
    end
end

--显示Icon
function My:ShowIcon(icon)
	local go = icon.gameObject
	go:SetActive(true)
end

--隐藏Icon
function My:HideIcon()
	for i,v in ipairs(self.iconBtnList) do
		local go = v.gameObject
		go:SetActive(false)
	end
end

--点击icon按钮
function My:OnIconBtn(go)
	local O = UIMgr.Open
	local amgr = ActivityMgr
	local isShowTips = false

	if go.name == "1" then--限时云购
		local isOpen = UITabMgr.IsOpen(amgr.XSYG)
		if isOpen then O(UICloudBuy.Name) end

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
		if isOpen then StoreMgr.OpenStore(2) end

	elseif go.name == "7" then--充值
		local IsShield = UITabMgr.Pattern2(1002)
		if not IsShield then VIPMgr.OpenVIP(1) else isShowTips = true end
		
	elseif go.name == "8" then--日常活跃
		local isOpen = UITabMgr.IsOpen(amgr.HY)
		if isOpen then O(UILiveness.Name) end

	elseif go.name == "9" then--世界Boss
		local isOpen = UITabMgr.IsOpen(amgr.BOSS)
		if isOpen then O(UIBoss.Name) end

	elseif go.name == "10" then--寻宝
		local isOpen = UITabMgr.IsOpen(amgr.XB)
		if isOpen then UITreasure:OpenTab(1) end
	end

	if isShowTips then
		UITip.Log("系统未开启")
		return
	end
    
    JumpMgr:InitJump(UITimeLimitActiv.Name, 1)
end

--清理缓存
function My:Clear()
    TableTool.ClearUserData(self)
end
    
--释放资源
function My:Dispose()
    self:Clear()
end

return My