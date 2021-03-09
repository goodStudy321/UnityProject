--[[
 	authors 	:Liu
 	date    	:2018-11-1 14:10:00
 	descrition 	:仙魂分解界面
--]]

UIImmSoulDecomp = Super:New{Name = "UIImmSoulDecomp"}

local My = UIImmSoulDecomp

require("UI/UIImmortalSoul/UIImmSoulDecompIt")

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find
	local FindC = TransTool.FindChild
	local SetB = UITool.SetBtnClick
	local str = "cellBg/Scroll View/Grid"
	
	local grid = Find(root, str, des)
	local item = FindC(root, str.."/item", des)
	SetB(root, "close", des, self.OnClose, self)
	SetB(root, "hintBtn", des, self.OnHint, self)
	SetB(root, "hintPanel", des, self.OnhintPanel, self)
	SetB(root, "decompSpr", des, self.OnDecompSpr, self)
	SetB(root, "decompBtn", des, self.OnDecompBtn, self)
	SetB(root, "quaSelect", des, self.OnQuaSelect, self)
	SetB(root, "quaSelect/popPanel/box", des, self.OnPopPanel, self)
	self.decompLab = CG(UILabel, root, "decompLab/lab")
	self.hintPanel = FindC(root, "hintPanel", des)
	self.selectSpr = FindC(root, "decompSpr/spr", des)
	self.up = FindC(root, "quaSelect/up", des)
	self.down = FindC(root, "quaSelect/down", des)
	self.spr = CG(UISprite, root, "quaSelect/spr")
	self.lab = CG(UILabel, root, "quaSelect/lab")
	self.popPanel = FindC(root, "quaSelect/popPanel", des)
	self.cellNum = 200
	self.select = 0
	self.isSelect = false
	-- self.isAdd = false
	self.itList = {}
	self.togList = {}
	self:InitCell(grid, item)
	self:InitTog(root, CG, des)
end

--初始化Tog
function My:InitTog(root, CG, des)
	local SetS = UITool.SetLsnrSelf
	local str = "quaSelect/popPanel/popBg/Grid/btn"
	for i=1, 3 do
		local tog = CG(UIToggle, root, str..i)
		SetS(tog.transform, self.OnTog, self, des)
		table.insert(self.togList, tog)
	end
	self:InitTogVal()
end

--初始化Tog状态
function My:InitTogVal()
	local info = ImmortalSoulInfo
	local tog = self.togList
	if info.decompSet < 3 then
		tog[3].value = true
	elseif info.decompSet < 4 then
		tog[2].value = true
	elseif info.decompSet < 5 then
		tog[1].value = true
	end
	local info = ImmortalSoulInfo
	self.select = info.decompSet
	self:SetSelectSpr(self.select)
end

--是否是选择添加状态
-- function My:IsAdd(index)
-- 	if self.isAdd then
-- 		self:ClearDecompBag()
-- 		local info = ImmortalSoulInfo
-- 		for i,v in ipairs(info.bagList) do
-- 			if v.index == index then
-- 				self:UpDecompBag(v, true)
-- 				break
-- 			end
-- 		end
-- 		self:UpDecompLab()
-- 		self.isAdd = false
-- 		return true
-- 	end
-- 	return false
-- end

--更新数据
function My:UpData(index)
	if self.isSelect then return end
	-- if self:IsAdd(index) then return end
	local info = ImmortalSoulInfo
	local bagList = info.bagList
	info.decompSet = self.select
	self:ClearDecompBag()
	if info.decompSet < 3 then
		self:SetDecompList(info, bagList, 2)
	elseif info.decompSet < 4 then
		self:SetDecompList(info, bagList, 3)
	elseif info.decompSet < 5 then
		self:SetDecompList(info, bagList, 4)
	end
	self:UpDecompLab()
end

--设置分解列表
function My:SetDecompList(info, compList, qua)
	for i=qua, 1, -1 do
		local list = info:GetQuaList(compList, i)
		self:SetDecompBag(list)
	end
	self:SetDebris(info)
end

--设置仙魂碎片
function My:SetDebris(info)
    local debrisList = info:GetDebris()
    for i=5, 1, -1 do
        local list = info:GetQuaList(debrisList, i)
        for i,v in ipairs(list) do
            self:UpDecompBag(v)
        end
    end
end

--清空分解背包
function My:ClearDecompBag()
	for i,v in ipairs(self.itList) do
		v:UpIcon(false)
		v:ClearCfg()
	end
end

--设置分解背包
function My:SetDecompBag(list)
	local topList = ImmortalSoulInfo:GetTopSoulInBag()
	local dic = {}
	for i,v in ipairs(topList) do
		local key = tostring(v.index)
		dic[key] = true
	end
	for i,v in ipairs(list) do
		local key = tostring(v.index)
		local cfg = ImmSoulCfg[tostring(v.soulId)]
		if cfg then
			if not dic[key] and cfg.wearType ~= 0 then
				self:UpDecompBag(v)
			end
		end
	end
end

--更新分解背包
function My:UpDecompBag(v, isAdd)
	local key = tostring(v.soulId)
	local cfg = ImmSoulCfg[key]
	local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, v.lvId)
	if cfg and lvCfg then
		if #cfg.proType > 1 and isAdd == nil then return end
		local index = self:IsCell()
		if index == nil then return end
        self.itList[index]:SetData(lvCfg, cfg.icon, v.index)
    end
end

--判断是否是空格子
function My:IsCell()
	for i,v in ipairs(self.itList) do
		if v.cfg == nil then
			return i
		end
	end
	return nil
end

--添加实例
-- function My:AddIt(index)
-- 	self.isAdd = true
-- 	self:UpData(index)
-- end

--点击Tog
function My:OnTog(go)
	local mgr = ImmortalSoulMgr
	local info = ImmortalSoulInfo
	if go.name == "btn1" then
		self.select = 4
		mgr:ReqDecompSet(4)
	elseif go.name == "btn2" then
		self.select = 3
		mgr:ReqDecompSet(3)
	elseif go.name == "btn3" then
		self.select = 2
		mgr:ReqDecompSet(2)
	end
	self:SetSelectSpr(self.select)
	self:OnQuaSelect()
	self.isSelect = false
end

--初始化格子
function My:InitCell(grid, item)
    local Add = TransTool.AddChild
    for i=1, self.cellNum do
        local go = Instantiate(item)
        local tran = go.transform
        Add(grid, tran)
        local it = ObjPool.Get(UIImmSoulDecompIt)
        it:Init(tran)
        it:ChangeName(i)
		table.insert(self.itList, it)
    end
    item:SetActive(false)
end

--更新分解文本
function My:UpDecompLab()
	local info = ImmortalSoulInfo
	local total = self:GetDecompCount()
	local str = string.format("[F4DDBDFF]%s  [00FF00FF]+%s", info.debris, total)
	self.decompLab.text = str
end

--获取分解所得仙尘
function My:GetDecompCount()
	local list = {}
	for i,v in ipairs(self.itList) do
		if v.cfg and v.tog.value then
			table.insert(list, v.cfg.getDebris)
		end
	end
	local total = 0
	for i,v in ipairs(list) do
		total = total + v
	end
	return total
end

--点击品质筛选
function My:OnQuaSelect()
	local up = self.up
	self.down:SetActive(up.activeSelf)
	up:SetActive(not up.activeSelf)
	local state = self.popPanel.activeSelf
	self.popPanel:SetActive(not state)
end

--设置选择图标
function My:SetSelectSpr(num)
	if num < 3 then
		self.spr.spriteName = "depot_b"
		self.lab.text = "蓝色及以下"
	elseif num < 4 then
		self.spr.spriteName = "depot_p"
		self.lab.text = "紫色及以下"
	elseif num < 5 then
		self.spr.spriteName = "depot_y"
		self.lab.text = "黄色及以下"
	end
end

--点击分解选择框
function My:OnDecompSpr()
	local go = self.selectSpr
	go:SetActive(not go.activeSelf)
	local num = (go.activeSelf) and self.select or 0
	ImmortalSoulMgr:ReqDecompSet(num)
	self.isSelect = true
end

--点击分解按钮
function My:OnDecompBtn()
	-- local info = ImmortalSoulInfo
	-- local dic = info:GetBagDic()
	local list = self:GetDecompList()
	if #list == 0 then
		UITip.Log("没有仙魂可以分解")
		return
	-- elseif #list == 1 then
	-- 	local key = tostring(list[1])
	-- 	local it = dic[key]
	-- 	if it then
	-- 		local itInfo = info:GetDecompInfo(it)
	-- 		if itInfo ~= nil then
	-- 			if itInfo.val1 ~= 0 and itInfo.val2 ~= 0 then
	-- 				local str = string.format("[F39800FF]%s[-]将拆解为等级1的[F39800FF]%s[-]和[F39800FF]%s[-]，并返还仙魂石x%s和仙尘x%s是否确认拆解？", itInfo.name, itInfo.val1, itInfo.val2, itInfo.stone, itInfo.debris)
	-- 				MsgBox.ShowYesNo(str, self.OnYes, self)
	-- 				return
	-- 			end
	-- 		end
	-- 	end
	end
	MsgBox.ShowYesNo("是否分解选中的仙魂？", self.OnYes, self)
end

--选择分解
function My:SelectDecomp(index)
	local it = nil
	self.decompList = {}
	local info = ImmortalSoulInfo
	for i,v in ipairs(info.bagList) do
		if v.index == index then
			it = v
			table.insert(self.decompList, v)
		end
	end
	if it then
		local itInfo = info:GetDecompInfo(it)
		if itInfo then
			if itInfo.val1 ~= 0 and itInfo.val2 ~= 0 then
				local str = string.format("[F39800FF]%s[-]将拆解为等级1的[F39800FF]%s[-]和[F39800FF]%s[-]，并返还仙魂石x%s和仙尘x%s是否确认拆解？", itInfo.name, itInfo.val1, itInfo.val2, itInfo.stone, itInfo.debris)
				MsgBox.ShowYesNo(str, self.OnSure, self)
			end
		else
			local cfg, temp = BinTool.Find(ImmSoulLvCfg, it.lvId)
			if cfg then
				local str = string.format("是否分解，%s", cfg.name)
				MsgBox.ShowYesNo(str, self.OnSure, self)
			end
		end
	end
end

--点击确定按钮（背包）
function My:OnSure()
	local list = self.decompList
	local tempList = {}
	table.insert(tempList, list[1].index)
	local cfg, temp = BinTool.Find(ImmSoulLvCfg, list[1].lvId)
	if cfg then
		ImmortalSoulInfo:SetDecompCount(cfg.getDebris)
		ImmortalSoulMgr:ReqSoulDecomp(tempList)
	end
	self.decompList = {}
end

--点击确定按钮
function My:OnYes()
	local total = self:GetDecompCount()
	ImmortalSoulInfo:SetDecompCount(total)
	local list = self:GetDecompList()
	ImmortalSoulMgr:ReqSoulDecomp(list)
end

--获取分解列表
function My:GetDecompList()
	local list = {}
	for i,v in ipairs(self.itList) do
		if v.cfg and v.tog.value then
			table.insert(list, v.cellId)
		end
	end
	return list
end

--点击提示
function My:OnHint()
	self.hintPanel:SetActive(true)
end

--点击提示面板
function My:OnhintPanel()
	self.hintPanel:SetActive(false)
end

--点击弹窗面板
function My:OnPopPanel()
	self:OnQuaSelect()
end

--点击关闭按钮
function My:OnClose()
	UIImmortalSoul:UpShow(1)
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