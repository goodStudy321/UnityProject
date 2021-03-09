--// 道庭仓库宝箱

UIFamilyBoxItem = {Name = "UIFamilyBoxItem"}

local iLog = iTrace.Log;
local iError = iTrace.Error;

local AssetMgr=Loong.Game.AssetMgr;

--// 创建控件
function UIFamilyBoxItem:New(o)
	o = o or {}
	setmetatable(o, self);
	self.__index = self;
	return o
end

--// 初始化赋值
function UIFamilyBoxItem:Init(gameObj)
	--// 列表条目物体
	self.itemObj = gameObj;
	--// 面板transform
	self.rootTrans = self.itemObj.transform;

	local tip = "UI道庭仓库宝箱";

	local C = ComTool.Get;
	local CF = ComTool.GetSelf;
	local T = TransTool.FindChild;

	self.cellObj = T(self.rootTrans, "CellCont");
	self.newContObj = T(self.rootTrans, "NewCont");
	self.getContObj = T(self.rootTrans, "GetCont");
	self.getBtnObj = T(self.rootTrans, "NewCont/GetBtn");

	--// 获取来源名称
	self.fromTitle = C(UILabel, self.rootTrans, "FromTitle", tip, false);
	--// 倒计时显示
	self.timeLabel = C(UILabel, self.rootTrans, "NewCont/TimeLabel", tip, false);
	--// 道具名称显示
	self.itemName = C(UILabel, self.rootTrans, "GetCont/ItemName", tip, false);

	--// 连接领取按钮
	UITool.SetBtnSelf(self.getBtnObj, self.ClickGetBtn, self, self.Name);

	self.tbData = nil;
	self.cellCont = nil;

	self.showTime = false;
	self.curTime = 0;
end

--// 更新
function UIFamilyBoxItem:Update(dTime)
	if self.tbData == nil then
		return;
	end

	if self.showTime == true then
		self.curTime = self.curTime - dTime;
		if self.curTime < 0 then
			self.curTime = 0;
		end

		local strTime =  DateTool.FmtSec(math.ceil(self.curTime), 3, 2, true);
		if self.curTime <= 0 then
			strTime = StrTool.Concat("[F21919FF]", strTime, "[-]");
		else
			strTime = StrTool.Concat("[00FF00FF]", strTime, "[-]");
		end

		self.timeLabel.text = strTime;
	end
end

--// 释放
function UIFamilyBoxItem:Dispose()
	self:ClearCellCont();
	self.tbData = nil;
	self.showTime = false;
end

--// 链接和初始化配置
function UIFamilyBoxItem:LinkAndConfig(tbData)
	self.tbData = tbData;
	self:ShowData();

	--self.fromTitle.text = tostring(self.tbData.itemId);

	-- self.cellCont = ObjPool.Get(UIItemCell);
	-- self.cellCont.showDepotPoint = true;
	-- self.cellCont:InitLoadPool(self.rootTrans, 1);
	-- self.cellCont:TipData(self.tbData, 1, self.btnList, self.isCom);
end

--// 清除cell
function UIFamilyBoxItem:ClearCellCont()
	if self.cellCont ~= nil then
		self.cellCont:DestroyGo();
		ObjPool.Add(self.cellCont);
		self.cellCont = nil;
	end
end

--// 
function UIFamilyBoxItem:ShowFromTitle()
	local fromText = "";
	if self.tbData.fromType == 1000 then
		fromText = StrTool.Concat("充值·", tostring(self.tbData.param), "元宝箱");
	elseif self.tbData.fromType == 2000 then
		local evilData = MonsterTemp[tostring(self.tbData.param)];
		if evilData ~= nil then
			fromText = StrTool.Concat("世界·", evilData.name, "宝箱");
		end
	elseif self.tbData.fromType == 3000 then
		local evilData = MonsterTemp[tostring(self.tbData.param)];
		if evilData ~= nil then
			fromText = StrTool.Concat("魔域·", evilData.name, "宝箱");
		end
	elseif self.tbData.fromType == 4000 then
		local evilData = MonsterTemp[tostring(self.tbData.param)];
		if evilData ~= nil then
			fromText = StrTool.Concat("福地·", evilData.name, "宝箱");
		end
	elseif self.tbData.fromType == 5000 then
		fromText = "道庭·神兽宝箱"
	end

	self.fromTitle.text = fromText;
end

--// 显示当前数据信息
function UIFamilyBoxItem:ShowData()
	if self.tbData == nil then
		return;
	end

	self:ShowFromTitle();

	self:ClearCellCont();
	self.cellCont = ObjPool.Get(UIItemCell);
	self.cellCont:InitLoadPool(self.cellObj.transform, 1);
	--// 未领取宝箱
	if self.tbData.goods == nil then
		self.newContObj:SetActive(true);
		self.getContObj:SetActive(false);

		self.cellCont:UpData(self.tbData.itemId);

		self.showTime = true;
		local tm = TimeTool.GetServerTimeNow() * 0.001;
		self.curTime = self.tbData.endTime - tm;

	--// 已经打开宝箱
	else
		self.newContObj:SetActive(false);
		self.getContObj:SetActive(true);

		local nameShow = "";
		--// 道具名称
		local itemCfg = ItemData[tostring(self.tbData.goods.type_id)]
		if itemCfg ~= nil then
			nameShow = StrTool.Concat(itemCfg.name, "x", tostring(self.tbData.goods.num));
			nameShow = FamilyMgr:ChangeTextColByQua(nameShow, itemCfg.quality);
		end
		self.itemName.text = nameShow;
		
		self.cellCont:TipData(self.tbData.goods, 1, nil, true);

		-- local nameShow = "";
		-- --// 道具名称
		-- local itemCfg = ItemData[tostring(self.tbData.goods)]
		-- if itemCfg ~= nil then
		-- 	nameShow = StrTool.Concat(itemCfg.name, "x1");
		-- 	nameShow = FamilyMgr:ChangeTextColByQua(nameShow, itemCfg.quality);
		-- end
		-- self.itemName.text = nameShow;
		
		-- self.cellCont:UpData(self.tbData.goods);

		self.showTime = false;
	end
end

--// 点击领取按钮
function UIFamilyBoxItem:ClickGetBtn()
	if self.tbData == nil or self.tbData.goods ~= nil then
		return;
	end

	if self.curTime <= 0 then
		UITip.Log("宝箱已过期！");
		return;
	end

	local openList = {};
	openList[1] = self.tbData;
	FamilyMgr:ReqFamilyBoxOpen(openList);
end

--// 显示隐藏
function UIFamilyBoxItem:Show(sOh)
	if sOh == false then
		self.tbData = nil;
		self.showTime = false;
	end
	self.itemObj:SetActive(sOh);
end

--// 转换到新宝箱状态
function UIFamilyBoxItem:ChangeToNewCont()
	self.newContObj:SetActive(true);
	self.getContObj:SetActive(false);

	self.showTime = true;
end

--// 转换到已经领取状态
function UIFamilyBoxItem:ChangeToGetCont()
	self.newContObj:SetActive(false);
	self.getContObj:SetActive(true);

	self.showTime = false;
end