--[[
 	authors 	:Liu
 	date    	:2018-6-27 11:30:00
 	descrition 	:符文寻宝
--]]

UIRuneTreas = Super:New{Name="UIRuneTreas"}

local My = UIRuneTreas

require("UI/UITreasure/UIRuneTreasMenu")

local Animation = UnityEngine.Animation
local Renderer = UnityEngine.Renderer

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find
	local SetB = UITool.SetBtnClick
	local SetS = UITool.SetLsnrSelf
	local FindC = TransTool.FindChild
	
	self.tokens = 0
	self.norList = {}
	self.rareList = {}
	self.texNameList = {}

	self.runeTran = Find(root, "runeTreasMenu", des)
	self.freeLab = CG(UILabel, root, "BottomBg/hintSpr/freeLab")
	self.tokenLab = CG(UILabel, root, "BottomBg/token/lab")
	self.goldLab = CG(UILabel, root, "BottomBg/gold/lab")

	local str = "Model/FWZP/FWZP"
	local ED = EventDelegate
	self.buyEff = FindC(root, "fx_baokai", des)
	self.runeParent = Find(root, str.."/all_b/Dummy002")
	self.anim = CG(Animation, root, str)
	self.tex1 = CG(Renderer, self.runeParent, "Dummy003/c/icon")
	self.tex2 = CG(Renderer, self.runeParent, "Dummy004/d/icon")
	self.mask = FindC(root, "MaskPanel/mask", des)
	self.animTime = self.anim:GetClip("FWZP_idle02").length
	self.isOpen = false
	self.timer = 0

	SetB(root, "BottomBg/runeBag", des, self.OnRuneBagClick, self)
	SetB(root, "BottomBg/runeSwop", des, self.OnRunSwopClick, self)
	SetB(root, "BottomBg/gold/plus", des, self.OnPlus, self)
	SetB(root, "BottomBg/hintSpr", des, self.OnHelp, self)
	SetB(self.tex1.transform, "box", des, self.OnRune1, self)
	SetB(self.tex2.transform, "box", des, self.OnRune2, self)
	SetS(self.mask.transform, self.OnMask, self, des)

	self:InitModule()
	self:InitFreeLab()
	self:UpTokenLab()
	self:UpGold()
	self:InitTex1()
	self:InitTex2()
	self:SetLnsr("Add")
end

--设置监听
function My:SetLnsr(func)
	local mgr = TreasureMgr
	mgr.eUpFreeTime[func](mgr.eUpFreeTime, self.RespUpFreeTime, self)
	mgr.eEndFreeTime[func](mgr.eEndFreeTime, self.RespEndFreeTime, self)
	PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
	RoleAssets.eUpAsset[func](RoleAssets.eUpAsset, self.UpGold, self)
	UIGetRewardPanel.eDoublePop[func](UIGetRewardPanel.eDoublePop, self.OnDoublePop, self)
end

--点击遮罩
function My:OnMask()
	self:StopAnim()
end

--更新
function My:Update()
	if self.isOpen then
		self.timer = self.timer + Time.deltaTime
		if self.timer >= self.animTime then
			self:StopAnim()
		end
	end
end

--停止动画
function My:StopAnim()
	self.anim:Stop("FWZP_idle02")
	self.anim:CrossFade("FWZP_idle")
	self:UpEff(false)
	self.timer = 0
	self.isOpen = false
	UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
end

--播放动画
function My:PlayAnim()
	self.isOpen = true
	self:UpEff(true)
	self.anim:CrossFade("FWZP_idle02")
end

--更新特效
function My:UpEff(state)
	UITreasure:UpZPos(state)
	self.buyEff:SetActive(state)
	self.mask.gameObject:SetActive(state)
	-- self.runeParent.gameObject:SetActive(not state)
end

--点击展示符文1
function My:OnRune1()
	self.curClickId = self:GetShowId(3)
	UIMgr.Open(UITreasRuneTip.Name, self.OpenRuneTip, self)
end

--点击展示符文2
function My:OnRune2()
	self.curClickId = self:GetShowId(4)
	UIMgr.Open(UITreasRuneTip.Name, self.OpenRuneTip, self)
end

--符文Tip的回调方法1
function My:OpenRuneTip(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		local key = tostring(self.curClickId)
		local cfg = RuneCfg[key]
		if cfg == nil then return end
		ui:Refresh(cfg, 2)
    end
end

--初始化贴图1
function My:InitTex1()
	local id = self:GetShowId(3)
	local cfg = ItemData[tostring(id)]
	if cfg == nil then return end
	table.insert(self.texNameList, cfg.icon)
	AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcons1, self))
end

--初始化贴图2
function My:InitTex2()
	local id = self:GetShowId(4)
	local cfg = ItemData[tostring(id)]
	if cfg == nil then return end
	table.insert(self.texNameList, cfg.icon)
	AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcons2, self))
end

--设置贴图1
function My:SetIcons1(tex)
    self.tex1.material.mainTexture = tex
end

--设置贴图2
function My:SetIcons2(tex)
    self.tex2.material.mainTexture = tex
end

--获取展示符文id
function My:GetShowId(type)
	local list = self.rune:GetShowCfg(type)
	for i,v in ipairs(list) do
		if type == v.showType then
			return v.awardId
		end
	end
end

--道具添加
function My:OnAdd(action,dic)
	if action==10112 then
		self:SetRateList(dic)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		if #self.rareList > 0 then
            ui:UpRareData(self.rareList)
        else
            ui:UpdateData(self.norList)
        end
	end
end

--重复弹窗
function My:OnDoublePop()
	if #self.rareList > 0 and #self.norList > 0 then
		UIMgr.Open(UIGetRewardPanel.Name,self.DoubleCb,self)
	end
end

--重复回调获得奖励界面
function My:DoubleCb(name)
	local ui = UIMgr.Get(name)
    if(ui)then
        ui:UpdateData(self.norList)
        self:ClearList()
	end
end

--设置稀有奖励列表
function My:SetRateList(dic)
    self:ClearList()
    for k,v in pairs(dic) do
        local key = tostring(v.k)
        local info = {}
        info.k = v.k
        info.v = v.v
        info.b = v.b
        if self:IsRare(v.k) then
            table.insert(self.rareList, info)
        else
            table.insert(self.norList, info)
        end
    end
end

--是否是稀有符文
function My:IsRare(id)
	local bid = RuneMgr.GetBaseID(id)
	local key = tostring(bid)
	local cfg = RuneCfg[key]
	if cfg then
		return cfg.qt > 4
	end
end

--清空列表
function My:ClearList()
    ListTool.Clear(self.norList)
    ListTool.Clear(self.rareList)
end

--响应更新免费时间
function My:RespUpFreeTime()
	self.freeLab.text = "[FF0000FF]"..TreasureMgr.timer.remain.."[00FF21FF]后，可免费寻宝一次"
end

--响应结束免费时间
function My:RespEndFreeTime()
	self.freeLab.text = "[00FF21FF]点击寻宝，可免费寻宝一次"
	self.rune:UpTreasStste(true)
end

--初始化免费时间文本
function My:InitFreeLab()
	if TreasureMgr.isEnd then
		self.freeLab.text = "[00FF21FF]点击寻宝，可免费寻宝一次"
		self.rune:UpTreasStste(true)
	end
end

--更新符文令牌数量
function My:UpTokenLab()
	local list = GlobalTemp["15"].Value2
    local tokens = ItemTool.GetNum(list[1])
	self.tokenLab.text = tokens
	self.tokens = tokens
end

--点击符文背包
function My:OnRuneBagClick()
	UITreasure:Close()
	UIRune.tabName = "embed"
	UIMgr.Open(UIRune.Name, self.OpenDecmTab, self)
end

--点击符文兑换
function My:OnRunSwopClick()
	UITreasure:Close()
	UIRune.tabName = "exchg"
	UIMgr.Open(UIRune.Name, self.OpenExchgTab, self)
end

--符文分解界面的回调方法
function My:OpenDecmTab()
	UIRune:SwitchByName("embed")
end

--符文兑换界面的回调方法
function My:OpenExchgTab()
	UIRune:SwitchByName("exchg")
end

--初始化模块
function My:InitModule()
    self.rune = ObjPool.Get(UIRuneTreasMenu)
    self.rune:Init(self.runeTran)
end

--更新元宝
function My:UpGold()
	-- self.goldLab.text = RoleAssets.Gold
	self.goldLab.text = RoleAssets.BindGold
end

--点击增加元宝
function My:OnPlus()
	VIPMgr.OpenVIP(1)
end

--点击帮助
function My:OnHelp()
	UIComTips:Show(InvestDesCfg["15"].des, Vector3(-280,-260,0))
end

--清理缓存
function My:Clear()
	self.tokens = 0
end
    
--释放资源
function My:Dispose()
	self:Clear()
	self:SetLnsr("Remove")
	ObjPool.Add(self.rune)
	self.rune = nil
	if self.texNameList then
        for i,v in ipairs(self.texNameList) do
            AssetMgr:Unload(v, false)
        end
    end
end

return My