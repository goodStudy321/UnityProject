--// 帮派信息条目

UIFamilyInfoItem = {Name = "UIFamilyInfoItem"};

local iLog = iTrace.eLog;
local iError = iTrace.Error;

--// 创建条目
function UIFamilyInfoItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFamilyInfoItem:Init(gameObj, ignoreBtn)
	-- if self.itemObj ~= nil then
	-- 	--print("LY : Family item has init !!! ");
	-- 	return;
	-- end

	local tip = "UI帮派条目"

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;

	local C = ComTool.Get
	local T = TransTool.FindChild

	self.bg = T(self.itemTrans, "Bg1/Bg2");
	self.rankObj = T(self.itemTrans, "RankBg");

	self.rankingLabel = C(UILabel, self.itemTrans, "Cont1", tip, false);
	self.nameLabel = C(UILabel, self.itemTrans, "Cont2", tip, false);
	self.lvLabel = C(UILabel, self.itemTrans, "Cont3", tip, false);
	self.mbNumLabel = C(UILabel, self.itemTrans, "Cont4", tip, false);
	self.ownerLabel = C(UILabel, self.itemTrans, "Cont5", tip, false);
	self.abilityLabel = C(UILabel, self.itemTrans, "Cont6", tip, false);

	self.rankBg = C(UISprite, self.itemTrans, "RankBg", tip, false);
	self.rankKuang = C(UISprite, self.itemTrans, "RankBg/RankKuang", tip, false);

	--// 申请按钮
	if ignoreBtn == nil or ignoreBtn == false then
		local com = C(UIButton, self.itemTrans, "ApplyBtn", tip, false);
		UIEvent.Get(com.gameObject).onClick = function (gameObject)
			self:ClickApplyBtn();
		end;
	end

	--// 当前链接数据
	--[[
		connetData.familyId			：道庭Id
		connetData.rank 			：道庭排名
		connetData.familyName		：道庭名称
		connetData.familyLv			：道庭等级
		connetData.memberNum 		：道庭人数
		connetData.ownerName 		：庭主名称
		connetData.power 			：道庭战力
	]]
	self.curData = nil;
	--// 当前等级数据
	self.curLvData = nil;
end

--// 显示隐藏
function UIFamilyInfoItem:Show(sOh)
	self.itemObj:SetActive(sOh);
end

--// 条纹背景打开
function UIFamilyInfoItem:BgOn(show)
	self.bg:SetActive(show);
end

--// 点击帮派申请按钮
function UIFamilyInfoItem:ClickApplyBtn()
	if self.curData == nil then
		return;
	end

	iLog("LY", "Click family apply !!! "..self.curData.familyId);

	FamilyMgr:ReqFamilyApply(self.curData.familyId);
end

--// 刷新链接数据
--[[
	connetData.familyId			：道庭Id
	connetData.rank 			：道庭排名
	connetData.familyName		：道庭名称
	connetData.familyLv			：道庭等级
	connetData.memberNum 		：道庭人数
	connetData.ownerName 		：庭主名称
	connetData.power 			：道庭战力
]]
function UIFamilyInfoItem:ResetData(connetData)
	if connetData == nil then
		return;
	end

	self.curData = connetData;
	self.curLvData = FamilyMgr:GetLvCfgByLv(self.curData.familyLv);

	local rankStr = tostring(self.curData.rank);
	--self.rankingLabel.text = tostring(self.curData.rank);
	if self.curData.rank == 1 then
		self.rankingLabel.text = StrTool.Concat("[F39800FF]", rankStr, "[-]");
		self.rankObj:SetActive(true);
		self.rankBg.spriteName = "rank_info_g";
		self.rankKuang.spriteName = "rank_icon_1";
	elseif self.curData.rank == 2 then
		self.rankingLabel.text = StrTool.Concat("[B03DF2FF]", rankStr, "[-]");
		self.rankObj:SetActive(true);
		self.rankBg.spriteName = "rank_info_z";
		self.rankKuang.spriteName = "rank_icon_2";
	elseif self.curData.rank == 3 then
		self.rankingLabel.text = StrTool.Concat("[008FFCFF]", rankStr, "[-]");
		self.rankObj:SetActive(true);
		self.rankBg.spriteName = "rank_info_b";
		self.rankKuang.spriteName = "rank_icon_3";
	else
		self.rankingLabel.text = StrTool.Concat("[F4DDBDFF]", rankStr, "[-]");
		self.rankObj:SetActive(false);
	end

	self.nameLabel.text = self.curData.familyName;
	self.lvLabel.text = tostring(self.curData.familyLv);
	self.mbNumLabel.text = StrTool.Concat(tostring(self.curData.memberNum), "/", tostring(FamilyMgr:GetLvCfgMaxPer(self.curData.familyLv)));
	self.ownerLabel.text = self.curData.ownerName;
	self.abilityLabel.text = tostring(self.curData.power);
end