--//市场求购物品条目
UIMktWantItem = Super:New{Name = "UIMktWantItem"}

local M = UIMktWantItem

local iLog = iTrace.Log
local iError = iTrace.Error

-- local AssetMgr=Loong.Game.AssetMgr;

--//创建控件
-- function M:New(o)
-- 	o = o or {}
-- 	setmetatable(o, self);
-- 	self.__index = self;
-- 	return o
-- end

--// 初始化赋值
function M:Init(gameObj)
	--// 列表条目物体
	self.itemObj = gameObj;
	--// 面板transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI市场出售物品条目";

	local C = ComTool.Get
	local CF = ComTool.GetSelf
	local T = TransTool.FindChild

	--// 物品名称
	self.itemName = C(UILabel, self.rootTrans, "ItemName", tip, false)
	--// 物品数量
	self.itemNum = C(UILabel, self.rootTrans, "NumLabel", tip, false)
	--// 图标
	self.itemTex = C(UITexture, self.rootTrans, "IconBg/Icon", tip, false)

	local com = CF(UIButton, self.rootTrans, tip)
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickSelf()
	end

	--// 是否选择
	self.isSel = false
	--// 选择事件回调
	self.selCallBack = nil
	--// 链接数据
	self.tbData = nil

	self.texList = {}
end

--// 释放
function M:Dispose()
	self.isSel = nil
	self.selCallBack = nil
	self.tbData = nil
	-- AssetMgr.Instance:Unload(self.iconName)

	--self:UnloadTex()
	AssetTool.UnloadTex(self.texList)
	self.texList = nil
end

--释放
function M:UnloadTex()
	if self.dicCfg then
		AssetMgr:Unload(self.dicCfg.icon, false)
		self.iconName = nil
	end
end

--// 链接和初始化配置
function M:LinkAndConfig(tbData, selCB)
	self:UnloadTex()
	--// 创建一个空框
	if tbData == nil then
		self.isSel = false
		self.selCallBack = nil
		self.tbData = nil
		return;
	end

	self.tbData = tbData
	self.selCallBack = selCB

	local dicCfg = MarketDic[tostring(self.tbData.id)]
	self.dicCfg = dicCfg
	if dicCfg ~= nil then
		self:SetIcon(dicCfg.icon)
	end

	self.itemName.text = self.tbData.name
	self.itemNum.text = tostring(self.tbData.num)
end

--// 点击自身
function M:ClickSelf()
	if self.selCallBack ~= nil then
		self.selCallBack()
	end
end

--// 显示隐藏
function M:Show(sOh)
	self.itemObj:SetActive(sOh)
end

--// 设置图标
function M:SetIcon(iconName)
	AssetMgr:Load(iconName, ObjHandler(self.LoadIconFin,self))
	self.iconName = self.dicCfg.icon
end

--// 读取图标完成
function M:LoadIconFin(obj)
	self.itemTex.mainTexture = obj
	if self.texList then
		table.insert( self.texList, obj.name )
	else
		AssetTool.UnloadTex(obj.name)
	end
end