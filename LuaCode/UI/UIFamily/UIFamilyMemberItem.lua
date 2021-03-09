--// 帮派成员条目

UIFamilyMemberItem = {Name = "UIFamilyMemberItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建条目
function UIFamilyMemberItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFamilyMemberItem:Init(gameObj)
	-- if self.itemObj ~= nil then
	-- 	--print("LY : Family member item has init !!! ");
	-- 	return;
	-- end

	local tip = "UI帮派成员条目"

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;

	local C = ComTool.Get;
	local CGS = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--------- 获取GO ---------

	self.bg1 = T(self.itemTrans, "Bg/Bg1");
	self.selBg = T(self.itemTrans, "Bg/Bg2");

	--------- 获取控件 ---------

	self.nameLabel = C(UILabel, self.itemTrans, "Fig1/Label", tip, false);
	self.lvLabel = C(UILabel, self.itemTrans, "Fig2/Label", tip, false);
	self.categoryLabel = C(UILabel, self.itemTrans, "Fig3/Label", tip, false);
	self.titleLabel = C(UILabel, self.itemTrans, "Fig4/Label", tip, false);
	--self.conLabel = C(UILabel, self.itemTrans, "Fig5/Label", tip, false);
	self.powerLabel = C(UILabel, self.itemTrans, "Fig6/Label", tip, false);
	self.offTimeLabel = C(UILabel, self.itemTrans, "Fig7/Label", tip, false);

	--// 条目选择按钮
	local com = CGS(UIButton, self.itemTrans, tip);
	UIEvent.Get(com.gameObject).onClick = function (gameObject)
		self:ClickSelf();
	end;

	--// 当前链接数据
	--[[
		self.curData.roleId				：角色Id
		self.curData.roleName			：角色名
		self.curData.roleLv 			：角色等级
		self.curData.category			：角色职业
		self.curData.title 				：角色职位
		self.curData.con 				：帮派贡献度
		self.curData.power 				：角色战斗力
		self.curData.isOnline 			: 是否在线
		self.curData.offTime 			: 上次下线时间 时间戳
	]]
	self.curData = nil;
end

--// 显示隐藏
function UIFamilyMemberItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

--// 显示背景2
function UIFamilyMemberItem:BgShow(bgOn)
	self.bg1:SetActive(bgOn);
end

--// 设置在线状态
function UIFamilyMemberItem:SetOnline(isOL)
	-- local col = nil;
	-- if isOL == true then
	-- 	col = Color.New(1, 0.91, 0.74, 1);
	-- else
	-- 	col = Color.New(0.6, 0.6, 0.6, 0.6);
	-- end

	-- self.nameLabel.color = col;
	-- self.lvLabel.color = col;
	-- self.categoryLabel.color = col;
	-- self.titleLabel.color = col;
	-- -- self.conLabel.color = col;
	-- self.powerLabel.color = col;
	-- self.offTimeLabel.color = col;
end

--// 点击帮派申请按钮
function UIFamilyMemberItem:ClickSelf()

	--// 暂时屏蔽
	-- if 1 == 1 then
	-- 	return;
	-- end

	if self.curData == nil then
		return;
	end

	--iLog("LY", "Click family member !!! "..self.curData.roleName);
	UIFamilyMemberPanel:SelMemberItem(self.curData, self);
end

--// 刷新链接数据
--[[
	connetData.roleId			：角色Id
	connetData.roleName			：角色名
	connetData.roleLv 			：角色等级
	connetData.category			：角色职业
	connetData.title 			：角色职位
	connetData.active 			：帮派贡献度
	connetData.power 			：角色战斗力
	connetData.isOnline 		: 是否在线
	connetData.offTime 			: 上次下线时间 时间戳
]]
function UIFamilyMemberItem:ResetData(connetData)
	if connetData == nil then
		return;
	end

	self.curData = connetData;

	self.nameLabel.text = self.curData.roleName;
	if connetData.roleId == FamilyMgr.ChangeInt64Num(User.MapData.UID) then
		self.lvLabel.text = FamilyMgr:GetLvShowText(User.MapData.Level);
		-- local catShow = FamilyMgr:GetJobByIndex(User.MapData.Sex + 1, RebirthMsg.RbLev);
		-- self.categoryLabel.text = catShow;
	else
		self.lvLabel.text = FamilyMgr:GetLvShowText(self.curData.roleLv);
		-- local catShow = FamilyMgr:GetJobByIndex(self.curData.sex + 1, self.curData.category);
		-- --local catShow = FamilyMgr:GetJobByIndex(self.curData.sex + 1, RebirthMsg.RbLev);
		-- self.categoryLabel.text = catShow;
	end

	local catShow = FamilyMgr:GetJobByIndex(self.curData.sex + 1, 0);
	self.categoryLabel.text = catShow;

	self.titleLabel.text = FamilyMgr:GetTitleByIndex(self.curData.title);
	-- self.conLabel.text = tostring(self.curData.active);
	self.powerLabel.text = tostring(self.curData.power);

	if self.curData.isOnline == true then
		self.offTimeLabel.text = "在线";
	else
		local curTime = math.floor(TimeTool.GetServerTimeNow()/1000);
		local sc = self.curData.offTime
		local dVal = curTime - sc;

		local showTime = "";
		local tH = math.floor(dVal / 3600);

		if dVal < 3600 then
			local sMin = math.ceil(dVal / 60);
			if sMin < 5 then
				showTime = "【刚刚】";
			else
				showTime = StrTool.Concat(tostring(sMin), "分钟");
			end
		else
			if tH <= 2 then
				showTime = tostring(tH).."小时";
			else
				-- local tD = math.floor(tH / 24);
				-- local tH = math.floor(tH % 24);
				-- showTime = tostring(tD).."天"..tostring(tH).."小时";
				showTime = "超过2小时"
			end
		end
		self.offTimeLabel.text = showTime;

		--local val = DateTool.GetDate(sc)
		--self.tmStr = val:ToString("yyyy/MM/dd HH:mm:ss")
		--self.offTimeLabel.text = self.tmStr
	end

	self:SetOnline(self.curData.isOnline);
end

--// 标记选择
function UIFamilyMemberItem:SetSelectSign(sel)
	self.selBg:SetActive(sel);
end