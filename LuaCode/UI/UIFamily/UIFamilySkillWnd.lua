--// 帮派技能窗口
require("UI/UIFamily/UIFSkillItem");


UIFamilySkillWnd = UIBase:New{Name = "UIFamilySkillWnd"};

local base = UIBase

local winCtrl = {};

local iLog = iTrace.eLog;
local iError = iTrace.Error;

local AssetMgr=Loong.Game.AssetMgr;


--// 初始化界面
--// 链接所有操作物体
function UIFamilySkillWnd:InitCustom()

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	
	local C = ComTool.Get;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	--// 道庭技能条目克隆主体
	winCtrl.itemMain = T(winCtrl.winRootTrans, "SkillCont/SkillSV/UIGrid/SkillItem_99");
	--// 
	winCtrl.upgradeBtnObj = T(winCtrl.winRootTrans, "InfoCont/UpgradeBtn");
	--// 说明面板
	winCtrl.tipPanelObj = T(winCtrl.winRootTrans, "TipCont/TipPanel");
	winCtrl.tipPanelObj:SetActive(false);
	--// 说明按钮
	winCtrl.tipBtnObj = T(winCtrl.winRootTrans, "TipCont/TipBtn");
	--// 
	winCtrl.tipBgBtnObj = T(winCtrl.winRootTrans, "TipCont/TipPanel/Bg");


	--------- 获取控件 ---------

	local tip = "UI道庭技能窗口"

	--// 滚动区域
	winCtrl.itemsSV = C(UIScrollView, winCtrl.winRootTrans, "SkillCont/SkillSV", tip, false);
	--// 排序控件
	winCtrl.itemGrid = C(UIGrid, winCtrl.winRootTrans, "SkillCont/SkillSV/UIGrid", tip, false);

	--// 技能图标
	winCtrl.iconTex = C(UITexture, winCtrl.winRootTrans, "InfoCont/SkillIcon", tip, false);
	--// 技能名称
	winCtrl.skillName = C(UILabel, winCtrl.winRootTrans, "InfoCont/SkillName", tip, false);
	--// 技能说明
	winCtrl.skillInfo = C(UILabel, winCtrl.winRootTrans, "InfoCont/SkillInfo", tip, false);
	--// 当前属性
	winCtrl.curPropInfo = C(UILabel, winCtrl.winRootTrans, "InfoCont/CurPropInfo", tip, false);
	--// 下一级属性
	winCtrl.nextPropInfo = C(UILabel, winCtrl.winRootTrans, "InfoCont/NextPropInfo", tip, false);
	--// 道绩
	winCtrl.pointNum = C(UILabel, winCtrl.winRootTrans, "InfoCont/PointNum", tip, false);
	--// 说明属性
	winCtrl.tipInfo = C(UILabel, winCtrl.winRootTrans, "TipCont/TipPanel/Sprite/Label", tip, false);


	local com = C(UIButton, winCtrl.winRootTrans, "Bg/Title/backBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:Close();
	end;

	com = C(UIButton, winCtrl.winRootTrans, "InfoCont/UpgradeBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickUpgrade();
	end;

	--// 
	UITool.SetLsnrSelf(winCtrl.tipBtnObj, self.ClickShowTip, self);
	--// 
	UITool.SetLsnrSelf(winCtrl.tipBgBtnObj, self.ClickCloseTip, self);

	EventMgr.Add( "FamilySkillChange", function() self:NewDataArrive() end );

	winCtrl.closeEnt = EventHandler(self.Close, self);
	EventMgr.Add("QuitFamily", winCtrl.closeEnt);


	--// 帮派成员条目列表
	winCtrl.itemLists = {};
	--// 数据
	winCtrl.infos = nil;
	--// 当前选择技能Id
	winCtrl.CurSelSkillId = 0;
	--// 延迟重置倒数
	winCtrl.delayResetCount = 0;
	--// 
	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;
end

--// 打开窗口
function UIFamilySkillWnd:OpenCustom()
	winCtrl.mOpen = true;
	self:ShowData();
	self:SelFirst();
end

--// 关闭窗口
function UIFamilySkillWnd:CloseCustom()
  	winCtrl.mOpen = false;
end

--// 更新
function UIFamilySkillWnd:Update()
	if winCtrl.delayResetCount > 0 then
		winCtrl.delayResetCount = winCtrl.delayResetCount - 1;
		if winCtrl.delayResetCount <= 0 then
			winCtrl.delayResetCount = 0;
			winCtrl.itemsSV:ResetPosition();
		end
	end
end

--// 销毁释放窗口
function UIFamilySkillWnd:DisposeCustom()
	EventMgr.Remove("QuitFamily", winCtrl.closeEnt);

	local texName = StrTool.Concat(winCtrl.iconTex.mainTexture, ".png");
	AssetMgr.Instance:Unload(texName);
	winCtrl.iconTex.mainTexture = nil;

	for i = 1, #winCtrl.itemLists do
		winCtrl.itemLists[i]:Dispose();
		ObjPool.Add(winCtrl.itemLists[i]);
	end
	winCtrl.itemLists ={};
	winCtrl.CurSelSkillId = 0;
	winCtrl.mOpen = false;
	winCtrl.init = false;
end

--// 首选项
function UIFamilySkillWnd:SelFirst()
	winCtrl.itemLists[1]:SetSelSign(true);
	self:SelSkill(winCtrl.infos[1].cfgInfo.id);
end

--// 刷新成员列表数据
function UIFamilySkillWnd:ShowData(notRePos)
	if winCtrl.mOpen == false then
		return;
	end

	winCtrl.infos = FamilyMgr:GetSkillInfo();
	if winCtrl.infos ~= nil then
		self:RenewItemNum(#winCtrl.infos, notRePos);
	end

	for i = 1, #winCtrl.itemLists do
		local showIndex = 0;
		local tT = i;
		if math.floor(i % 2) == 1 then
			tT = tT + 1;
		end
		if math.floor(math.floor(tT / 2) % 2) == 1 then
			showIndex = 1;
		end

		winCtrl.itemLists[i]:LinkAndConfig(winCtrl.infos[i], showIndex, function()
			self:ResetItemSel();
			self:SelSkill(winCtrl.infos[i].cfgInfo.id);
		end);
	end
end

--// 新数据到达
function UIFamilySkillWnd:NewDataArrive()
	if winCtrl.mOpen == false then
		return;
	end

	self:ShowData(true);

	if winCtrl.CurSelSkillId > 0 then
		local tpId = math.floor(winCtrl.CurSelSkillId / 1000);
		for i = 1, #winCtrl.infos do
			if tpId == winCtrl.infos[i].baseInfo.preId then
				self:SelSkill(winCtrl.infos[i].cfgInfo.id);
				winCtrl.itemLists[i]:SetSelSign(true);
				break;
			end
		end
	end
end

--// 重置所有按钮选择状态
function UIFamilySkillWnd:ResetItemSel()
	for i = 1, #winCtrl.itemLists do
		winCtrl.itemLists[i]:ResetSel();
	end
end

function UIFamilySkillWnd:SelSkill(skillId)
	-- if winCtrl.CurSelSkillId == skillId then
	-- 	return;
	-- end

	winCtrl.CurSelSkillId = skillId;

	local tData = self:GetInfo(skillId);
	if tData == nil then
		return;
	end

	if tData.unlock == true then
		winCtrl.upgradeBtnObj:SetActive(true);
	else
		winCtrl.upgradeBtnObj:SetActive(false);
	end

	local skillInfo = SkillLvTemp[tostring(tData.cfgInfo.id)];
	if skillInfo ~= nil and skillInfo.icon ~= nil and skillInfo.icon ~= "" then
		self:SetIcon(skillInfo.icon);
	end

	winCtrl.skillName.text = ""..tData.cfgInfo.name;
	winCtrl.skillInfo.text = "";

	local cfgName = PropName[tData.cfgInfo.propId].name;
	--// 当前属性
	if tData.lv <= 0 then
		winCtrl.curPropInfo.text = StrTool.Concat(cfgName, "+0");
	else
		if tData.baseInfo.showPct == 1 then
			winCtrl.curPropInfo.text = StrTool.Concat(cfgName, "+", tostring(tData.cfgInfo.prop / 100), "%");
		else
			winCtrl.curPropInfo.text = StrTool.Concat(cfgName, "+", tostring(tData.cfgInfo.prop));
		end
	end

	local selfPot = FamilyMgr:GetFamilyCon();
	--// 下一级属性
	if tData.lv <= 0 then
		if tData.baseInfo.showPct == 1 then
			winCtrl.nextPropInfo.text = StrTool.Concat(cfgName, "+", tostring(tData.cfgInfo.prop / 100), "%");
		else
			winCtrl.nextPropInfo.text = StrTool.Concat(cfgName, "+", tostring(tData.cfgInfo.prop));
		end

		local pointStr = StrTool.Concat(tostring(selfPot), "/", tostring(tData.cfgInfo.pay));
		if selfPot < tData.cfgInfo.pay then
			pointStr = StrTool.Concat("[F21919FF]", pointStr, "[-]");
		else
			pointStr = StrTool.Concat("[F4DDBDFF]", pointStr, "[-]");
		end
		winCtrl.pointNum.text = pointStr;
	else
		local tNextData = FamilyMgr:GetSkillInfoById(skillId + 1);
		if tNextData == nil then
			winCtrl.nextPropInfo.text = "已达到最高等级";
			winCtrl.pointNum.text = StrTool.Concat(tostring(selfPot), "/ --");
		else
			if tData.baseInfo.showPct == 1 then
				winCtrl.nextPropInfo.text = StrTool.Concat(cfgName, "+", tostring(tNextData.prop / 100), "%");
			else
				winCtrl.nextPropInfo.text = StrTool.Concat(cfgName, "+", tostring(tNextData.prop));
			end

			local pointStr = StrTool.Concat(tostring(selfPot), "/", tostring(tNextData.pay));
			if selfPot < tNextData.pay then
				pointStr = StrTool.Concat("[F21919FF]", pointStr, "[-]");
			else
				pointStr = StrTool.Concat("[F4DDBDFF]", pointStr, "[-]");
			end
			winCtrl.pointNum.text = pointStr;
		end
	end


end

function UIFamilySkillWnd:GetInfo(id)
	local retData = nil;
	for i = 1, #winCtrl.infos do
		if winCtrl.infos[i].cfgInfo.id == id then
			retData = winCtrl.infos[i];
			break;
		end
	end
	return retData;
end

--// 点击升级按钮
function UIFamilySkillWnd:ClickUpgrade()
	if winCtrl.CurSelSkillId == nil or winCtrl.CurSelSkillId <= 0 then
		return;
	end

	local tData = self:GetInfo(winCtrl.CurSelSkillId);
	local selfPot = FamilyMgr:GetFamilyCon();
	if tData.cfgInfo.pay > selfPot then
		UITip.Log("道绩不足");
		return;
	end

	if tData == nil or tData.unlock == false then
		iLog("LY", "Family upgrade lock !!!");
		return;
	end

	FamilyMgr:ReqFamilySkillUpgrade(winCtrl.CurSelSkillId);
end

--// 点击说明按钮
function UIFamilySkillWnd:ClickShowTip()
	winCtrl.tipPanelObj:SetActive(true);
	winCtrl.tipInfo.text = InvestDesCfg["10"].des;
end

--// 点击关闭按钮
function UIFamilySkillWnd:ClickCloseTip()
	winCtrl.tipPanelObj:SetActive(false);
end

--// 设置图标
function UIFamilySkillWnd:SetIcon(iconName)
	AssetMgr.Instance:Load(iconName, ObjHandler(self.LoadIconFin,self));
end

--// 读取图标完成
function UIFamilySkillWnd:LoadIconFin(obj)
	winCtrl.iconTex.mainTexture = obj;
end

--// 克隆道庭技能条目
function UIFamilySkillWnd:CloneItem()
	local cloneObj = GameObject.Instantiate(winCtrl.itemMain);
	cloneObj.transform.parent = winCtrl.itemMain.transform.parent;
	cloneObj.transform.localPosition = winCtrl.itemMain.transform.localPosition;
	cloneObj.transform.localRotation = winCtrl.itemMain.transform.localRotation;
	cloneObj.transform.localScale = winCtrl.itemMain.transform.localScale;
	cloneObj:SetActive(true);

	local cloneItem = ObjPool.Get(UIFSkillItem);
	cloneItem:Init(cloneObj);
	-- cloneObj.name = string.gsub(cloneObj.name, "99", tostring(#winCtrl.itemLists + 1));
	-- winCtrl.itemLists[#winCtrl.itemLists + 1] = cloneItem;

	local newName = "";
	if #winCtrl.itemLists + 1 >= 100 then
		newName = string.gsub(winCtrl.itemMain.name, "99", tostring(#winCtrl.itemLists + 1));
	elseif #winCtrl.itemLists + 1 >= 10 then
		newName = string.gsub(winCtrl.itemMain.name, "99", "0"..tostring(#winCtrl.itemLists + 1));
	else
		newName = string.gsub(winCtrl.itemMain.name, "99", "00"..tostring(#winCtrl.itemLists + 1));
	end
	cloneObj.name = newName;
	winCtrl.itemLists[#winCtrl.itemLists + 1] = cloneItem;

	return cloneItem;
end

--// 重置道庭技能数量
function UIFamilySkillWnd:RenewItemNum(number, notRePos)
	for a = 1, #winCtrl.itemLists do
		winCtrl.itemLists[a]:Show(false)
	end

	local realNum = number;
	if realNum <= #winCtrl.itemLists then
		for a = 1, realNum do
			winCtrl.itemLists[a]:Show(true);
		end
	else
		for a = 1, #winCtrl.itemLists do
			winCtrl.itemLists[a]:Show(true)
		end

		local needNum = realNum - #winCtrl.itemLists;
		for a = 1, needNum do
			self:CloneItem();
		end
	end

	winCtrl.itemGrid:Reposition();

	if notRePos ~= nil and notRePos == true then
		return;
	end

	self:DelayResetSVPosition();
end

--// 延迟重置滑动面板位置
function UIFamilySkillWnd:DelayResetSVPosition()
	winCtrl.delayResetCount = 2;
end

return UIFamilySkillWnd