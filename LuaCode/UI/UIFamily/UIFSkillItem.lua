--// 道庭技能控件

UIFSkillItem = {Name = "UIFSkillItem"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

local AssetMgr=Loong.Game.AssetMgr;

--// 创建控件
function UIFSkillItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFSkillItem:Init(gameObj)

	--// 列表条目物体
	self.itemObj = gameObj;
	--// 面板transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI道庭技能控件";

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;

	self.bg1Obj = T(self.rootTrans, "Bg1");
	self.bglObj1 = T(self.rootTrans, "BgL1");
	--self.bglObj2 = T(self.rootTrans, "BgL2");
	--self.bg2Obj = T(self.rootTrans, "Bg2");
	self.selObj = T(self.rootTrans, "SelSign");
	self.lockObj = T(self.rootTrans, "LockSign");
	self.iconObj = T(self.rootTrans, "Icon");
	--// 红点提示
	self.redSignObj = T(self.rootTrans, "RedSign");
	if self.redSignObj ~= nil then
		self.redSignObj:SetActive(false);
	end

	--// 技能图标
	self.iconTex = C(UITexture, self.rootTrans, "Icon", tip, false);
	--// 技能名称
	self.skillName = C(UILabel, self.rootTrans, "SkillName", tip, false);
	--// 技能说明
	self.skillInfo = C(UILabel, self.rootTrans, "UnlockInfo", tip, false);

	--// 自身按钮
	local com = CF(UIButton, self.rootTrans, tip);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:ClickSelf(); end;

	--// 是否选择
	self.isSel = false;
	--// 点击回调事件
	self.selCallBack = nil;
	--// 技能数据
	self.itemData = nil;
end

function UIFSkillItem:Dispose()
	if self.iconTex ~= nil and self.iconTex.mainTexture ~= nil then
		local texName = StrTool.Concat(self.iconTex.mainTexture.name, ".png");
		AssetMgr.Instance:Unload(texName);
		--UITool.UnloadTex(self.iconTex);
	end
end

--// 链接和初始化配置
function UIFSkillItem:LinkAndConfig(itemData, showIndex, selCB)
	if itemData == nil then
		iError("LY", "itemData is null !!! ");
		return;
	end
	self.itemData = itemData;
	-- if showIndex == 0 then
	-- 	self.bg1Obj:SetActive(true);
	-- 	self.bg2Obj:SetActive(false);
	-- else
	-- 	self.bg1Obj:SetActive(false);
	-- 	self.bg2Obj:SetActive(true);
	-- end

	self.selCallBack = selCB;

	--self.skillName.text = ""..itemData.cfgInfo.name;
	if self.itemData.unlock == true then
		self.skillName.text = StrTool.Concat("[F39800FF]", self.itemData.cfgInfo.name, "[-]");

		self.lockObj:SetActive(false);

		UITool.SetNormal(self.bg1Obj);
		UITool.SetNormal(self.bglObj1);
		--UITool.SetNormal(self.bglObj2);
		UITool.SetAllNormal(self.iconObj);

		if self.itemData.lv <= 0 then
			self.skillInfo.text = StrTool.Concat("[F21919FF]", "未习得", "[-]");
		else
			self.skillInfo.text = "";
		end

		local selfPot = FamilyMgr:GetFamilyCon();
		local nextPay = 0;
		local maxLv = false;
		if self.itemData.lv <= 0 then
			nextPay = self.itemData.cfgInfo.pay
		else
			local nextData = FamilyMgr:GetSkillInfoById(self.itemData.cfgInfo.id + 1);
			if nextData ~= nil then
				nextPay = nextData.pay;
			else
				maxLv = true;
			end
		end

		--if selfPot >= self.itemData.cfgInfo.pay then
		if maxLv == false and selfPot >= nextPay then
			self.redSignObj:SetActive(true);
		else
			self.redSignObj:SetActive(false);
		end
	else
		self.skillName.text = StrTool.Concat("[808080FF]", self.itemData.cfgInfo.name, "[-]");

		self.lockObj:SetActive(true);

		UITool.SetGray(self.bg1Obj);
		UITool.SetGray(self.bglObj1);
		--UITool.SetGray(self.bglObj2);
		UITool.SetAllGray(self.iconObj);

		--self.skillInfo.text = "道庭"..tostring(itemData.cfgInfo.unlockLv).."级解锁";
		self.skillInfo.text = StrTool.Concat("[B2B2B2FF]", "道庭", tostring(self.itemData.cfgInfo.unlockLv), "级解锁", "[-]");

		self.redSignObj:SetActive(false);
	end

	local skillInfo = SkillLvTemp[tostring(self.itemData.cfgInfo.id)];
	if skillInfo ~= nil and skillInfo.icon ~= nil and skillInfo.icon ~= "" then
		self:SetIcon(skillInfo.icon);
	end
	self:ResetSel();
end

--// 显示隐藏
function UIFSkillItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

--// 设置选择标记
function UIFSkillItem:SetSelSign(isSel)
	self.isSel = isSel;
	self.selObj:SetActive(isSel);
end

--// 重置选择
function UIFSkillItem:ResetSel()
	self:SetSelSign(false);
end

--// 设置图标
function UIFSkillItem:SetIcon(iconName)
	AssetMgr.Instance:Load(iconName, ObjHandler(self.LoadIconFin,self));
end

--// 读取图标完成
function UIFSkillItem:LoadIconFin(obj)
	self.iconTex.mainTexture = obj;
end

--// 点击事件
function UIFSkillItem:ClickSelf()
	if self.selCallBack ~= nil then
		self.selCallBack(self.isSel);
	end

	self:SetSelSign(true);
end