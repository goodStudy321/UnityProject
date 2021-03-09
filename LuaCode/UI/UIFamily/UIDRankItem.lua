--// 通用伤害排行条目

UIDRankItem = {Name = "UIDRankItem"};

local iLog = iTrace.Log;
local iError = iTrace.Error;

--// 创建条目
function UIDRankItem:New(o)
	o = o or {};
	setmetatable(o, self);
	self.__index = self;
	return o;
end

--// 初始化赋值
function UIDRankItem:Init(gameObj)
	
	local tip = "UI伤害排行条目";

	--// 条目物体
	self.itemObj = gameObj;
	self.itemTrans = gameObj.transform;

	local C = ComTool.Get;
	--local CGS = ComTool.GetSelf;
	local T = TransTool.FindChild;

	--// 名次
	self.rankNum = C(UILabel, self.itemTrans, "RankNum", tip, false);
	--// 玩家名称
	self.name = C(UILabel, self.itemTrans, "Name", tip, false);
	--// 伤害值
	self.dNum = C(UILabel, self.itemTrans, "DNum", tip, false);
end

--// 显示
function UIDRankItem:Show(isShow)
	self.itemObj:SetActive(isShow);
end

--// 显示数据
function UIDRankItem:ShowData(rankInfo)
	if rankInfo == nil then
		self.rankNum.text = "";
		self.name.text = "";
		self.dNum.text = "";
		return;
	end

	self.rankNum.text = tostring(rankInfo.rank)..".";
	self.name.text = rankInfo.roleName;
	self.dNum.text = math.NumToStr(rankInfo.damage,0);
end