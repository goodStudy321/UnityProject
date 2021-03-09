--[[
 	authors 	:Liu
 	date    	:2018-11-2 14:10:00
 	descrition 	:仙魂合成界面（合成预览）
--]]

UIImmSoulCompMod1 = Super:New{Name = "UIImmSoulCompMod1"}

local My = UIImmSoulCompMod1

local AssetMgr = Loong.Game.AssetMgr

local strs = "UI/UIImmortalSoul/UIImmSoulComp/"
require(strs.."UIImmSoulCompIt")

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find

	self.lab1 = CG(UILabel, root, "txtBg1/lab1")
	self.lab2 = CG(UILabel, root, "txtBg1/lab2")
	self.lab3 = CG(UILabel, root, "txtBg2/lab")
	self.yPos = self.lab1.transform.localPosition.y
	self.itList = {}
	self.index1 = 0
	self.index2 = 0
	self.count = 0
	self.compId = 0
	self:InitCompIt(root, Find, des)
	self:UpLab()
end

--初始化合成项
function My:InitCompIt(root, Find, des)
	local num1, num2 = self:InitTogIndex()
	local cfg = self:UpCompCfg(num1, num2)
	for i=1, 4 do
		local tran = Find(root, "item"..i.."/cell", des)
		local it = ObjPool.Get(UIImmSoulCompIt)
		it:Init(tran)
		table.insert(self.itList, it)
		if cfg == nil then return end
		local num = self:GetData(cfg, i)
		local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, cfg.id)
		if lvCfg == nil then return end
		it:UpData(num, i, lvCfg)
	end
	local it = UIImmortalSoul.mod2.compList
	if it then
		it:SetTab(num1, num2)
	end
end

--获取传输的数据
function My:GetData(cfg, index)
	local temp = 0
	if index == 1 then
		temp = cfg.compNeed1
		self.index1 = temp
	elseif index == 2 then
		temp = cfg.needCount
		self.count = temp
	elseif index == 3 then
		temp = cfg.compNeed2
		self.index2 = temp
	elseif index == 4 then
		temp = cfg.id
		self.compId = temp
	end
	return temp
end

--更新数据
function My:UpData()
	local num1, num2 = self:GetTogIndex()
	local cfg = self:UpCompCfg(num1, num2)
	if cfg == nil then return end
	for i,v in ipairs(self.itList) do
		local num = self:GetData(cfg, i)
		local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, cfg.id)
		if lvCfg == nil then return end
		v:UpData(num, i, lvCfg)
	end
end

--设置合成所需的道具索引
function My:SetCompIndex(index1, index2)
	if index1 ~= 0 then
		self.index1 = index1
	end
	if index2 ~= 0 then
		self.index2 = index2
	end
end

--更新合成配置
function My:UpCompCfg(num1, num2)
	local cfg = UIImmortalSoul:GetCompData(num1, num2)
	if cfg == nil then return end
	return cfg
end

--初始化Tog索引
function My:InitTogIndex()
	local info = ImmortalSoulInfo
	if info.togIndex ~= 0 and info.tabIndex ~= 0 then
		return info.togIndex, info.tabIndex
	end
    info:SetTogIndex(1)
	info:SetTabIndex(1)
	return info.togIndex, info.tabIndex
end

--获取Tog索引
function My:GetTogIndex()
	local info = ImmortalSoulInfo
	return info.togIndex, info.tabIndex
end

--更新文本
function My:UpLab()
	local num1, num2 = self:GetTogIndex()
	local cfg = self:UpCompCfg(num1, num2)
	if cfg == nil then return end
	local lvCfg, temp = BinTool.Find(ImmSoulLvCfg, cfg.id)
	if lvCfg == nil then return end
	self:SetLab(lvCfg.pro1, self.lab1, lvCfg.proVal1, 1)
	self:SetLab(lvCfg.pro2, self.lab2, lvCfg.proVal2, 2)
	local str = string.format("需要等级%s级", cfg.needLv)
	self.lab3.text = str
end

--判断是否隐藏文本
function My:SetLab(num, lab, val, index)
	if num == 0 then
		lab.gameObject:SetActive(false)
		self:UpLabPos(0)
	else
		lab.gameObject:SetActive(true)
		local cfg = PropName[num]
		if cfg == nil then return end
		local value = (cfg.show==1) and string.format("%.2f", val/10000*100).."%" or val
		local col = (index==1) and "[008FFCFF]" or "[FF66FCFF]"
		local str = string.format("[F4DDBDFF]%s：%s%s", cfg.name, col, value)
		lab.text = str
	end
	if index == 2 and num ~= 0 then
		self:UpLabPos(self.yPos)
	end
end

--更新文本位置
function My:UpLabPos(y)
	local tran = self.lab1.transform
	tran.localPosition = Vector3.New(tran.localPosition.x, y, 0)
end

--创建特效
function My:CreatePrefab()
    AssetMgr.LoadPrefab("UI_xianhunFw", GbjHandler(self.LoadPrefabCb, self))
end

--加载特效回调
function My:LoadPrefabCb(eff)
    local Add = TransTool.AddChild
	local tran = eff.transform
	local pos = tran.localPosition
	local it = self.itList[4]
	if it then
		it.effName = eff.name..".prefab"
		table.insert(it.effList, eff)
		Add(it.root, tran)
		tran.localPosition = pos
	end
end

--卸载贴图
function My:UnloadTexs()
	for i,v in ipairs(self.itList) do
		v:UnloadTex()
	end
end

--清理缓存
function My:Clear()
	self:UpLabPos(self.yPos)
end

--释放资源
function My:Dispose()
	self:Clear()
	ListTool.ClearToPool(self.itList)
end

return My