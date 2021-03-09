--// 道庭守卫界面
--require("UI/UIFamily/UIFItemCell");

UIFamilyDefendWnd = UIBase:New{Name = "UIFamilyDefendWnd"};

local winCtrl = {};
local My = UIFamilyDefendWnd;

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化界面
--// 链接所有操作物体
function UIFamilyDefendWnd:InitCustom()

	--// 窗口gameObject
	winCtrl.winRootObj = self.gbj;
	--// 窗口transform
	winCtrl.winRootTrans = winCtrl.winRootObj.transform;
	local trans = winCtrl.winRootTrans;
	local name = trans.name;
	
	local CG = ComTool.Get;
	local TF = TransTool.FindChild;
	local UC = UITool.SetLsnrClick;

	--------- 获取GO ---------

	--// 帮派成员条目克隆主体
	--winCtrl.cellMain = T(winCtrl.winRootTrans, "DepotPanel/ItemsCont/ItemsSV/GridObj/ItemCell_99");

	--------- 获取控件 ---------

	local tip = "UI道庭守卫窗口"
	--// 滚动区域
	--winCtrl.itemsSV = C(UIScrollView, winCtrl.winRootTrans, "DepotPanel/ItemsCont/ItemsSV", tip, false);

	--// 关闭按钮
	local com = CG(UIButton, trans, "Bg/BackBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:Close(); end;

	com = CG(UIButton, trans, "Bg/EnterBtn", tip, false);
	UIEvent.Get(com.gameObject).onClick = function (gameObject) self:EnterBattle(); end;

	self.ActTime = CG(UILabel,trans,"ActInfo/ActTime",name,false);
	self.Week = CG(UILabel,trans,"ActInfo/Week",name,false);
	self.LimitLev = CG(UILabel,trans,"ActInfo/LimitLev",name,false);
	self.Desc = CG(UILabel,trans,"ActInfo/Desc",name,false);
	self.UITable = CG(UITable,trans,"UITable",name,false);
	UC(trans,"PlayDescBtn",name,self.PlayDesc,self);
	self.playDesTip = TF(trans,"PlayDescBtn/Tip")
	self.playDesTipLb = CG(UILabel,trans,"PlayDescBtn/Tip/Label",name,false)
	UC(trans,"PlayDescBtn/Tip",name,self.CloseTip,self)

	winCtrl.init = true;
	--// 窗口是否打开
	winCtrl.mOpen = false;

	self:SetActInfo();
	self:SetRewards();
end

--// 打开窗口
function UIFamilyDefendWnd:OpenCustom()
	winCtrl.mOpen = true;
	self:ShowData();
end

--// 关闭窗口
function UIFamilyDefendWnd:CloseCustom()
	self:ClearRwds();
  	winCtrl.mOpen = false;
end

--// 更新
function UIFamilyDefendWnd:Update()
	
end

--// 销毁释放窗口
function UIFamilyDefendWnd:DisposeCustom()
	
end

--// 刷新成员列表数据
function UIFamilyDefendWnd:ShowData()
	
end

--设置活动信息
function My:SetActInfo()
	local time = ActvHelper.GetTime("10003");
	self.ActTime.text = time;
	local week = ActvHelper.GetWeek("10003");
	self.Week.text = week;
	local info = ActiveInfo[tostring("10003")];
    if info == nil then
        return;
	end
	self.LimitLev.text = string.format("%s级",info.needLv);
	self.Desc.text = info.desc;
end

--玩法介绍
function UIFamilyDefendWnd:PlayDesc()
	self.playDesTipLb.text = InvestDesCfg["6"].des
	self.playDesTip:SetActive(true)
end

-- 玩法面板关闭
function UIFamilyDefendWnd:CloseTip()
	self.playDesTip:SetActive(false)
end

--设置奖励
function My:SetRewards()
    local info = ActiveInfo["10003"];
    if info == nil then
        return;
    end
    if info.rewards == nil then
        return;
    end
    self.RewardCells = {};
    local len = #info.rewards;
    for i = 1, len do
        local iconId = info.rewards[i];
        local coinCell = ObjPool.Get(UIItemCell);
        coinCell:InitLoadPool(self.UITable.transform,1,self);
        coinCell:UpData(iconId);
        self.RewardCells[i] = coinCell;
    end
end

--加载奖励格子完成
function My:LoadCD(go)
    self.UITable:Reposition();
end

--清除奖励格子
function My:ClearRwds()
    if self.RewardCells == nil then
        return;
    end
    local length = #self.RewardCells;
    if length == 0 then
        return;
    end
    local dc = nil;
    for i = 1, length do
        dc = self.RewardCells[i];
        dc:DestroyGo();
        ObjPool.Add(dc);
        self.RewardCells[i] = nil;
    end
    self.RewardCells = nil;
end

--// 进入副本
function UIFamilyDefendWnd:EnterBattle()
	local enter = ActvHelper.EnterFmlDft();
	if enter == false then
		return;
	end
	UIMgr:Close(UISystem.Name);
	self:Close();
end

--特殊的开启条件
function My:GetSpecial()
	return CustomInfo:IsJoinFamily()
end

--打开分页
function My:OpenTabByIdx(t1,t2,t3,t4)

end

return UIFamilyDefendWnd