--// 帮派仓库界面
require("UI/UIFamily/UIFamilyRecordPanel");
require("UI/UIFamily/UIFamilyItemPanel");
require("UI/UIFamily/UIFamilyEquipSelPanel");


UIFamilyWarehouse = UIBase:New{Name = "UIFamilyWarehouse"};

local winCtrl = {};

local iLog = iTrace.Log;
local iError = iTrace.Error;


--// 初始化界面
--// 链接所有操作物体
function UIFamilyWarehouse:InitCustom()

    --// 窗口gameObject
    winCtrl.winRootObj = self.gbj;
    --// 窗口transform
    winCtrl.winRootTrans = winCtrl.winRootObj.transform;

    local C = ComTool.Get;
    local T = TransTool.FindChild;

    --------- 获取GO ---------

    winCtrl.recordPanelObj = T(winCtrl.winRootTrans, "RecordCont");
    --// 帮会物品面板物体
    winCtrl.itemPanelObj = T(winCtrl.winRootTrans, "DepotPanel");
    --// 物品选择面板
    winCtrl.equipSelPanelObj = T(winCtrl.winRootTrans, "DepotSelPanel");


    --------- 获取控件 ---------

    local tip = "UI捐献窗口"

    local com = C(UIButton, winCtrl.winRootTrans, "Bg/Title/backBtn", tip, false);
    UIEvent.Get(com.gameObject).onClick = function (gameObject)
        self:Close();
    end;

    --// 初始化记录面板
    UIFamilyRecordPanel:Init(winCtrl.recordPanelObj);
    --// 初始化物品列表面板
    UIFamilyItemPanel:Init(winCtrl.itemPanelObj);
    --// 初始化装备选择面板
    UIFamilyEquipSelPanel:Init(winCtrl.equipSelPanelObj);
    UIFamilyEquipSelPanel:Close();

    winCtrl.closeEnt = EventHandler(self.Close, self);
    EventMgr.Add("QuitFamily", winCtrl.closeEnt);

    winCtrl.init = true;
    --// 窗口是否打开
    winCtrl.mOpen = false;
end

--// 打开窗口
function UIFamilyWarehouse:OpenCustom()
    winCtrl.mOpen = true;
    self:ShowData();
    UIFamilyRecordPanel:ShowData();
    --UIFamilyItemPanel:ShowData();
    UIFamilyItemPanel:Open();
end

--// 关闭窗口
function UIFamilyWarehouse:CloseCustom()

    winCtrl.mOpen = false;
end

--// 更新
function UIFamilyWarehouse:Update()
    UIFamilyItemPanel:Update();

end

--// 销毁释放窗口
function UIFamilyWarehouse:DisposeCustom()
    EventMgr.Remove("QuitFamily", winCtrl.closeEnt);

    UIFamilyRecordPanel:Dispose();
    UIFamilyItemPanel:Dispose();
    UIFamilyEquipSelPanel:Dispose();

    winCtrl.mOpen = false;
    winCtrl.init = false;
end

--// 刷新成员列表数据
function UIFamilyWarehouse:ShowData()
    if winCtrl.mOpen == false then
        return;
    end

    -- self:RenewItemCellNum(20);
    -- for i = 1, 20 do
    -- 	local newItemData = {};
    -- 	newItemData.uId = 10;
    -- 	newItemData.num = 0;
    -- 	newItemData.itemCfg = {};
    -- 	newItemData.itemCfg.icon = "wuqi.png";
    -- 	newItemData.itemCfg.quality = 4;
    -- 	panelCtrl.itemCells[i]:LinkAndConfig(newItemData, true, nil);
    -- end
end

return UIFamilyWarehouse