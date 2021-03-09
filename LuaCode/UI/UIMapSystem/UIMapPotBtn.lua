--// 地图地点按钮

UIMapPotBtn = {Name = "UIMapPotBtn"};

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 创建按钮
function UIMapPotBtn:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIMapPotBtn:Init(gameObj, btnIndex)

	local tip = "UI地图地点按钮"

	--// 按钮物体
	self.btnObj = gameObj;
	--// 面板transform
	self.rootTrans = self.btnObj.transform;
	--// 按钮索引
	self.btnIndex = btnIndex;

	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--// 正常背景
	self.norBgObj = T(self.rootTrans, "Sprite");
	--// 上锁标志
	self.lockSignObj = T(self.rootTrans, "Mask");
	--// 头像标志
	self.iconObj = T(self.rootTrans, "IconBg");
	--// 等级物体
	self.lvObj = T(self.rootTrans, "Lv");
	--// 化神等级物体
	self.godLvObj = T(self.rootTrans, "God");
	

	--// 场景名称
	self.nameL = C(UILabel, self.rootTrans, "Name", tip, false);
	--// 等级
	self.lvL = C(UILabel, self.rootTrans, "Lv", tip, false);
	--// 化神等级
	self.godLvL = C(UILabel, self.rootTrans, "God/GodLv", tip, false);

	--// self按钮
	self.btnBgObj = T(self.rootTrans, "Bg");
	--local com = C(UIButton, self.rootTrans, "Bg", tip, false)
	UIEvent.Get(self.btnBgObj).onClick = function (gameObject)
		MapMgr:CallChangeScene(self.btnIndex);
	end;

	self.openText = "[EDF4FAFF]"..self.nameL.text.."[-]";
	self.closeText = "[808999FF]"..self.nameL.text.."[-]";
end

--// 显示隐藏
function UIMapPotBtn:Show(sOh)
	self.btnObj:SetActive(sOh);
end

--// 设置场景名称
function UIMapPotBtn:SetSceneName(sceneName)
	self.nameL.text = sceneName;
end

--// 设置上锁
function UIMapPotBtn:SetLock(unLock, unlockLv)
	if unlockLv ~= nil then
		-- if unlockLv > 370 then
		if unlockLv > 999 then
			self.lvObj:SetActive(false);
			self.godLvObj:SetActive(true);

			self.godLvL.text = FamilyMgr:GetLvShowText(unlockLv);
		else
			self.lvObj:SetActive(true);
			self.godLvObj:SetActive(false);

			self.lvL.text = FamilyMgr:GetLvShowText(unlockLv);
		end
	end

	if unLock == true then
		--self.nameL.text = self.openText;
		self.nameL.color = Color.New(237, 244, 250, 255) / 255.0;
		--self.lvL.text = tostring(unlockLv);
		-- if unlockLv ~= nil then
		-- 	self.lvL.text = FamilyMgr:GetLvShowText(unlockLv);
		-- end
		self.lvL.color = Color.New(237, 244, 250, 255) / 255.0;
		self.godLvL.color = Color.New(237, 244, 250, 255) / 255.0;

		self.norBgObj:SetActive(true);
		self.lockSignObj:SetActive(false);
	else
		--self.nameL.text = self.closeText;
		self.nameL.color = Color.New(128, 137, 153, 255) / 255.0;
		--self.lvL.text = tostring(unlockLv);
		-- if unlockLv ~= nil then
		-- 	self.lvL.text = FamilyMgr:GetLvShowText(unlockLv);
		-- end
		self.lvL.color = Color.New(128, 137, 153, 255) / 255.0;
		self.godLvL.color = Color.New(128, 137, 153, 255) / 255.0;

		self.norBgObj:SetActive(false);
		self.lockSignObj:SetActive(true);
	end
end

--// 显示头像
function UIMapPotBtn:ShowIcon(isShow)
	self.iconObj:SetActive(isShow);
end