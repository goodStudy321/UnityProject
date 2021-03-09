--[[
 	authors 	:Liu
 	date    	:2019-6-15 16:00:00
 	descrition 	:帮派任务求助界面
--]]

UIFamilyHelp = UIBase:New{Name = "UIFamilyHelp"}

local My = UIFamilyHelp

require("UI/UIFamilyMission/UIFamilyHelpIt")

function My:InitCustom()
	local des = self.Name
    local root = self.root
    local CG = ComTool.Get
    local SetB = UITool.SetBtnClick
	local FindC = TransTool.FindChild

	self.itList = {}
	self.texName = nil
	
	self.countLab = CG(UILabel, root, "tex/lab1")
	self.grid = CG(UIGrid, root, "ScrollView/Grid")
	self.tween = CG(UITweener, root, "TweenPanel/tex")
	self.tex = CG(UITexture, root, "TweenPanel/tex")
	self.icon = CG(UITexture, root, "tex")
	self.panel = CG(UIPanel, root, "ScrollView")
	self.item = FindC(root, "ScrollView/Grid/item", des)
	self.item:SetActive(false)

	SetB(root, "close", des, self.OnClose, self)
	SetB(root, "btn", des, self.OnBtn, self)

	self:SetLnsr("Add")
	
	FamilyMissionMgr:ReqMissionHelp()
	self:InitTex()
end

--设置监听
function My:SetLnsr(func)
    local mgr = FamilyMissionMgr
	mgr.eUpHelpMenu[func](mgr.eUpHelpMenu, self.RespUpHelpMenu, self)
	mgr.eHelp[func](mgr.eHelp, self.RespHelp, self)
	-- mgr.eHelpError[func](mgr.eHelpError, self.RespHelpError, self)
end

-- --
-- function My:RespHelpError()

-- end

--响应更新求助界面
function My:RespUpHelpMenu()
	if not self.allRefresh then
		if #FamilyMissionInfo.helpList < 1 then
			UITip.Log("手速过慢，任务已被其他成员加速")
			self:Close()
			return
		end
	end
	self:InitLab()
	self:UpItem()
	if self.allRefresh then
		for i,v in ipairs(self.itList) do
			v:CompleteState()
			v:UpCountLab()
			v:PlayTween()
		end
		self:PlayTweens()
		self.allRefresh = nil
	end
end

--响应求助
function My:RespHelp(id)
	if id == 0 then
		UITip.Log("加速成功")
		self.allRefresh = true
		return
	end
	local info = FamilyMissionInfo
	local v = info:GetHelpInfo(id)
	local it = self:GetItFromId(id)
	if v == nil or it == nil then return end
	it:UpData(v.id, v.name, v.sex, v.vip, v.count, v.missionId)
	it:CompleteState()
	it:UpCountLab()
	self:InitLab()

	if info:IsMaxCount(VIPMgr.vipLv) then
		UITip.Log("加速成功")
	else
		local val = info:GetFamilyScoreVal(1)
		local str = string.format("已获得%s道绩", val)
		UITip.Log(str)
		UITip.Log("加速成功")
	end
end

--根据id获取求助项
function My:GetItFromId(id)
	for i,v in ipairs(self.itList) do
		if v.id == id then
			return v
		end
	end
	return nil
end

--更新求助项
function My:UpItem()
	local Add = TransTool.AddChild
    local list = self.itList
	local hList = FamilyMissionInfo.helpList
    local gridTran = self.grid.transform
	local num = #hList - #list
	
	-- self:HideItem()
	if num > 0 then
		for i=1, num do
			local go = Instantiate(self.item)
			local tran = go.transform
			go:SetActive(true)
			Add(gridTran, tran)
			local it = ObjPool.Get(UIFamilyHelpIt)
			it:Init(tran, #self.itList)
			it:InitTex(self.tex.mainTexture)
            table.insert(self.itList, it)
		end
	end
	self:RefreshItem(hList, list)
    self.grid:Reposition()
end

--隐藏求助项
function My:HideItem()
	for i,v in ipairs(self.itList) do
		v.go:SetActive(false)
	end
end

--刷新任务项
function My:RefreshItem(hList, list)
	for i,v in ipairs(hList) do
		list[i].go:SetActive(true)
        list[i]:UpData(v.id, v.name, v.sex, v.vip, v.count, v.missionId)
    end
end

--初始化文本
function My:InitLab()
	local info = FamilyMissionInfo
	local val = info:GetFamilyScoreVal(1)
	local maxVal = info:GetFamilyScoreVal(2)
	if val == nil or maxVal == nil then return end
	local num = info.inspire * val
	self.countLab.text = string.format("%s/%s", num, maxVal)
end

--播放动画
function My:PlayTween(pos)
	self.tween:ResetToBeginning()
	local newY = pos.y - self.panel.clipOffset.y
	self.tween.transform.localPosition = Vector3(pos.x, newY, pos.z)
	self.tween.gameObject:SetActive(true)
	self.tween:PlayForward()
end

--点击一键加速
function My:OnBtn()
	local temp = false
	for i,v in ipairs(self.itList) do
		if v.isRecord == nil then
			temp = true
			break
		end
	end
	if temp then
		FamilyMissionMgr:ReqHelp(0, 0)
	else
		UITip.Log("没有能加速的成员")
	end
end

--播放一键加速动画
function My:PlayTweens()
	local list = self.itList
	if #list > 0 and #list < 3 then
		self:PlayTween(list[1].pos)
	elseif #list >= 3 then
		local offsetY = self.panel.clipOffset.y
		local maxY = math.abs(offsetY) + 260
		for i,v in ipairs(list) do
			if maxY - (v.index * 130) < 130 then
				self:PlayTween(v.pos)
				break
			end
		end
	end
end

--初始化贴图
function My:InitTex()
	local cfg = ItemData["13"]
	if cfg == nil then return end
	self.texName = cfg.icon
	AssetMgr:Load(self.texName, ObjHandler(self.SetIcon, self))
end

--设置贴图
function My:SetIcon(tex)
    if self.tex then
		self.tex.mainTexture = tex
		self.icon.mainTexture = tex
    end
end

--点击关闭
function My:OnClose()
	FamilyMissionMgr:ReqMissionHelp()
	self:Close()
end

--清理缓存
function My:Clear()
	self.allRefresh = nil
	if self.texName then
		AssetMgr:Unload(self.texName,false)
	end
end

--重写释放资源
function My:DisposeCustom()
	self:Clear()
	self:SetLnsr("Remove")
	ListTool.ClearToPool(self.itList)
end

return My