--// 帮派物品控件

UIFItemCell = {Name = "UIFItemCell"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

local AssetMgr=Loong.Game.AssetMgr;

--// 创建控件
function UIFItemCell:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFItemCell:Init(gameObj)

	--// 列表条目物体
	self.itemObj = gameObj;
	--// 面板transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI帮派仓库物品控件";

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;

	self.upSign = T(self.rootTrans, "Up");
	self.selSignObj = T(self.rootTrans, "SelSign");

	--self.qualityBg = C(UISprite, self.rootTrans, "Bg", tip, false);
	self.qualityBg = CF(UISprite, self.rootTrans, tip);
	self.iconTex = C(UITexture, self.rootTrans, "Icon", tip, false);
	self.itemNum = C(UILabel, self.rootTrans, "ItemNum", tip, false);

	--// 打开捐献装备按钮
	local com = C(UIButton, self.rootTrans, "Bg", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickSelf(); end;

	--// 是否需要比较
	self.isCom = false;
	--// 显示按钮列表
	self.btnList = nil;
	--// 按钮回调事件列表
	self.btnCBList = nil;
	--// 是否可以选择
	self.canSel = false;
	--// 是否选择
	self.isSel = false;
	--// 点击回调事件
	self.selCallBack = nil;
	--// 品质特效物体
	self.quaEffObj = nil;
	--// 链接数据
	self.itemData = nil;
end

--// 链接和初始化配置
function UIFItemCell:LinkAndConfig(itemData, isCom, btnList, btnCBList, canSel, selCB)
	--// 创建一个空框
	if itemData == nil then
		--iError("LY", "itemData is null !!! ");
		self.isCom = false;
		self.btnList = nil;
		self.btnCBList = nil;
		self.canSel = false;
		self.isSel = false;
		self.selCallBack = nil;
		if self.quaEffObj ~= nil then
			GbjPool:Add(self.quaEffObj);
			self.quaEffObj = nil;
		end
		self.itemData = nil;

		self.qualityBg.spriteName = UIMisc.GetQuaPath(0);
		self.iconTex.mainTexture = nil;

		return;
	end
	self.itemData = itemData;

	self.isCom = false;
	if isCom ~= nil then
		self.isCom = isCom;
	end

	self.btnList = btnList;
	self.btnCBList = btnCBList;

	self.canSel = false;
	if canSel ~= nil then
		self.canSel = canSel;
	end

	self.selCallBack = selCB;

	self:SetIcon(self.itemData.itemCfg.icon);
	self:SetQuality(self.itemData.itemCfg.quality);
	self:SetItemNum(0);
	self:ResetSel();
end

--// 显示隐藏
function UIFItemCell:Show(sOh)
	self.itemObj:SetActive(sOh);
end

function UIFItemCell:SetSel(isSel)
	self.isSel = isSel;
	self:SetSelSign(self.isSel);
end

--// 设置选择标记
function UIFItemCell:SetSelSign(isSel)
	self.selSignObj:SetActive(isSel);
end

--// 设置是否可以选择
function UIFItemCell:SetCanSel(canSel)
	self.canSel = canSel;
end

--// 重置选择
function UIFItemCell:ResetSel()
	-- if self.canSel == false then
	-- 	return;
	-- end

	self:SetSel(false);
end

--// 设置图标
function UIFItemCell:SetIcon(iconName)
	AssetMgr.Instance:Load(iconName, ObjHandler(self.LoadIconFin,self));
end

--// 读取图标完成
function UIFItemCell:LoadIconFin(obj)
	self.iconTex.mainTexture = obj;
end

--// 设置品质相关显示
function UIFItemCell:SetQuality(qua)
	if self.quaEffObj ~= nil then
		GbjPool:Add(self.quaEffObj);
		self.quaEffObj = nil;
	end

	self.qualityBg.spriteName = UIMisc.GetQuaPath(qua);
	if qua == 4 then --紫色
		AssetMgr.LoadPrefab("FX_Equip_purple", GbjHandler(self.LoadEffFin,self));
	elseif qua == 5 then --橙色
		AssetMgr.LoadPrefab("FX_Equip_gold", GbjHandler(self.LoadEffFin,self));
	elseif qua == 6 then --紫色
		AssetMgr.LoadPrefab("FX_Equip_red", GbjHandler(self.LoadEffFin,self));
	end
end

--// 读取品质特效完成
function UIFItemCell:LoadEffFin(go)
	go.transform.parent = self.rootTrans;
    go:SetActive(true);
    go.transform.localScale = Vector3.one;
	go.transform.localPosition = Vector3.New(98, 0, 0);
	
	local CF = ComTool.GetSelf;
	local effBind = CF(UIEffectBinding, go.transform, "获取特效绑定");
	if effBind ~= nil then
		effBind.enabled = true;
	end
	
    self.quaEffObj = go;
end

--// 设置道具数量
function UIFItemCell:SetItemNum(number)
	self.itemNum.text = ""..number;
end

--// 点击事件
function UIFItemCell:ClickSelf()
	if self.canSel == true then
		if self.isSel == false then
			self.isSel = true;
		else
			self.isSel = false;
		end
		self:SetSel(self.isSel);
	else
		if self.itemData ~= nil then
			if self.itemData.isEqu == true then		
				UIMgr.Open(EquipTip.Name,self.OpenCb,self)
			else--其他道具
				UIMgr.Open(PropTip.Name,self.OpenCb,self)
			end
		end
	end

	if self.selCallBack ~= nil then
		self.selCallBack(self.itemData.uId, self.isSel);
	end
end

--// 打开弹出提示回调
function UIFItemCell:OpenCb(name)
	local ui = UIMgr.Get(name);
	if ui then
		if self.itemData.isEqu == true and self.btnList ~= nil then
			-- local equTbs = PropMgr.ATbDic[tostring(self.itemData.typeId)];
			-- local equTb = equTbs[tostring(self.itemData.uId)];
			
			--ui:UpData(equTb, self.isCom);
			ui:UpData(self.itemData.typeId, self.isCom);
			ui:ShowBtn(self.btnList);

			for i = 1, #self.btnList do
				if self.btnList[i] == "Donate" then
					ui:SetDonateEvnt(self.btnCBList[i]);
				elseif self.btnList[i] == "Exchange" then
					ui:SetExchangeEvnt(self.btnCBList[i]);
				end
			end
		else
			ui:UpData(self.itemData.typeId, self.isCom);
			ui:ShowBtn(self.btnList);
			ui:SetExchangeEvnt(self.btnCBList[1]);
		end
	end
end