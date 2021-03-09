--[[
 	authors 	:Liu
 	date    	:2018-11-1 14:10:00
 	descrition 	:仙魂佩戴界面（穿戴）
--]]

UIImmSoulWearMod2 = Super:New{Name = "UIImmSoulWearMod2"}

local My = UIImmSoulWearMod2

local strs = "UI/UIImmortalSoul/UIImmSoulWear/"
require(strs.."UIImmSoulWearIt")
require(strs.."UIImmSouProPanel")
require(strs.."UIImmSouGetPanel")

function My:Init(root)
	local des = self.Name
	local Find = TransTool.Find
	local SetB = UITool.SetBtnClick

	SetB(root, "proBtn", des, self.OnProPanel, self)
	SetB(root, "getBtn", des, self.OnGetPanel, self)
	self.proTran = Find(root, "proBg", des)
	self.getTran = Find(root, "getBg", des)
	self.itList = {}
	self:InitWearCell(root, des)
	self:InitUseList()
end

--添加实例
function My:AddIt()
	local info = ImmortalSoulInfo
	local len = #info.useList
	self:UpUseList(info.useList[len])
	self:SetAction()
end

--删除实例
function My:RemoveIt(pos)
    for i,v in ipairs(self.itList) do
        if v.index == pos then
            v:UpIcon(false)
            v:ClearCfg()
            break
        end
    end
end

--获取镶嵌位置
function My:GetMosaicPos()
	for i,v in ipairs(self.itList) do
		if i ~= #self.itList then
			if not v.isLock and not v.isDress then
				return v.index
			end
		end
	end
	return nil
end

--获取核心位置
function My:GetCorePos()
	local len = #self.itList
	local it = self.itList[len]
	if not it.isLock and not it.isDress then
		return it.index
	end
	if it.isLock then
		return 0
	end
	return nil
end

--初始化镶嵌列表
function My:InitUseList()
	local info = ImmortalSoulInfo
	for i,v in ipairs(info.useList) do
		self:UpUseList(v)
	end
	self:SetAction()
end

--更新镶嵌列表
function My:UpUseList(v)
	local baseCfg = ImmSoulCfg
	local num = v.index - 900
	local it = self.itList[num]
	if v.index == it.index then
		local key1 = tostring(v.soulId)
		local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, v.lvId)
		if baseCfg[key1] and lvCfg then
			it:SetData(lvCfg, baseCfg[key1].icon, true)
		end
	end
end

--设置红点
function My:SetAction()
	for i,v in ipairs(self.itList) do
		local isShow = ImmortalSoulInfo:IsShowAction(v.index)
		if not v.isLock then
			if not v.isDress then
				v:UpShowAction()
			else
				if isShow then
					v:SetAction(true)
				else
					v:SetAction(false)
				end
			end
		else
			v:SetAction(false)
		end
	end
end

--更新红点
function My:UpAction(index, state)
	for i,v in ipairs(self.itList) do
		if v.index == index then
			v:SetAction(state)
		end
	end
end

--刷新镶嵌列表
function My:ResetUseList()
	for i,v in ipairs(self.itList) do
		v:UpIcon(false)
		v:ClearCfg()
    end
    self:InitUseList()
end

--更新指定位置的仙魂
function My:UpPosIt(pos, id)
	for i,v in ipairs(self.itList) do
		if v.index == pos then
			local cfg, temp = BinTool.Find(ImmSoulLvCfg, id)
			if cfg then
				v:UpCfg(cfg)
				break
			end
		end
	end
end

--点击属性加成面板
function My:OnProPanel()
	if self.proPanel == nil then
		self.proPanel = ObjPool.Get(UIImmSouProPanel)
		self.proPanel:Init(self.proTran)
	end
	self.proPanel:UpShow(true)
end

--点击获取途径面板
function My:OnGetPanel()
	UIMgr.Open(UIGetWay.Name, self.GetWatCb, self)
end

--打开获取途径面板回调
function My:GetWatCb()
	local ui = UIMgr.Get(UIGetWay.Name)
	if ui then
		local pos = Vector3.New(-321, -140, 0)
		ui:SetPos(pos)
		ui:CreateCell("仙魂副本", self.OnGetWayItem1, self)
		ui:CreateCell("仙魂凝聚", self.OnGetWayItem2, self)
	end
end

--点击获取途径项
function My:OnGetWayItem1(name)
	if name == "仙魂副本" then
		UICopy:Show(CopyType.XH)
	end
end

--点击获取途径项
function My:OnGetWayItem2(name)
	if name == "仙魂凝聚" then
		UIMgr.Close(UIGetWay.Name)
		UIImmortalSoul:UpShow(2)
	end
end

--初始化穿戴格子
function My:InitWearCell(root, des)
	local Find = TransTool.Find
	local info = ImmortalSoulInfo
	for i=1, 7 do
		local tran = Find(root, "normal"..i, des)
		local it = ObjPool.Get(UIImmSoulWearIt)
		local isLock, needLv, index = self:IsLock(info.openList[i], i)
		it:Init(tran, isLock, needLv, index)
		it:ChangeName(i)
		table.insert(self.itList, it)
	end
end

--设置装备项文本
function My:SetWearItLab(pos, lvId)
	for i,v in ipairs(self.itList) do
		if v.index == pos then
			v:UpLvLab(lvId)
			break
		end
	end
end

--是否锁定
function My:IsLock(pos, index)
	local cfg = GlobalTemp["49"].Value1[index]
	if cfg == nil then return end
	local needLv = cfg.value
	if pos == nil then
		return true, needLv, 0
	end
	return false, needLv, pos
end

--清理缓存
function My:Clear()

end

--释放属性面板
function My:ClearProPanel()
	if self.proPanel then
		ObjPool.Add(self.proPanel)
		self.proPanel = nil
	end
end

--释放资源
function My:Dispose()
	self:Clear()
	self:ClearProPanel()
	if self.getPanel then
		ObjPool.Add(self.getPanel)
		self.getPanel = nil
	end
	ListTool.ClearToPool(self.itList)
end

return My