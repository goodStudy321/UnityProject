--消费排行榜模块
require("UI/UIFestivalAct/UIActRankInfo")
UIActComViewCR = Super:New{Name = "UIActComViewCR"}
local My = UIActComViewCR;
local GO = UnityEngine.GameObject;
My.timer = nil;
My.isInit = false;

function My:Ctor()
    --第2-5名条目列表
    self.ItemList = {}
    --第1名奖励列表
    self.TheFirstRwds = {}
end

function My:Init(go)
    local root = go.transform;
    local name = self.Name;
    local CG = ComTool.Get;
    local TFC = TransTool.FindChild;
    self.go = go;
    
    self.ItemTable = CG(UITable,root,"ScrollView/Table",name,false);
    self.ItemInfo = TFC(root,"ScrollView/Table/ItemInfo",name);
    self.ItemInfo:SetActive(false);
    self.TFRwdTable = CG(UITable,root,"FirstRwdTbl",name,false);
    self.MyRank = CG(UILabel,root,"MyRank",name,false);
    self.MyCost = CG(UILabel,root,"MyCost",name,false);
    self.ActTime = CG(UILabel,root,"ActTime",name,false);
    self.ActRule = CG(UILabel,root,"ActRule/Label",name,false);
end

--设置监听
function My:SetLnsr(key)
    local mgr = FestivalActMgr;
    mgr.eUpCostGold[key](mgr.eUpCostGold, self.UpdateCostGold, self);
end

--更新数据
function My:UpdateData(data)
    self.data = data
    self:UpdateItemList();
end

--更新条目列表
function My:UpdateItemList()
    self:SetTFRwds();
    self:SetItems();
    self:SetMyRank();
    self:UpdateCostGold();
    self:UpActTime();
    self:UpActRule();
end

--设置第一名奖励
function My:SetTFRwds()
    local firstItem = self.data.itemList[1];
    if firstItem == nil then
        return;
    end
    if #self.TheFirstRwds > 0 then
        return;
    end
    local rwds = firstItem.rewardList;
    for i = 1,#rwds do
        local item = ObjPool.Get(UIItemCell);
        item:InitLoadPool(self.TFRwdTable.transform,1,self);
        item:UpData(rwds[i].id, 1);
        table.insert(self.TheFirstRwds, item);
    end
end

--加载奖励格子完成
function My:LoadCD(go)
    self.TFRwdTable:Reposition();
end

--设置条目
function My:SetItems()
    local itemList = self.data.itemList;
    for i = 1,4 do
        local index = i + 1;
        local data = itemList[index];
        local itemInfo = self.ItemList[i];
        if itemInfo == nil then
            local go = self:CloneItem();
            go.name = tostring(data.id);
            local item = ObjPool.Get(UIActRankInfo);
            item:SetData(go,data);
            self.ItemList[i] = item;
        else
            itemInfo:RfrData(data);
        end
    end
    if self.isInit == false then
        self:SetTimer();
    else
        self.ItemTable.repositionNow = true;
    end
end

--设置计时器
function My:SetTimer()
    if self.timer == nil then
        self.timer = ObjPool.Get(iTimer);
        self.timer.complete:Add(self.CompleteCb, self);
    end
    self.timer.seconds = 0.1;
    self.timer:Start();
    self.isInit = true;
end

function My:CompleteCb()
    self.ItemTable.repositionNow = true;
end

--设置我的排名
function My:SetMyRank()
    if self.MyRank == nil then
        return;
    end
    local rank = self:GetMyRank();
    if rank == nil then
        rank = "[ffffff]未上榜[-]";
    else
        rank =string.format( "[00ff00]%s[-]",rank);
    end
    self.MyRank.text = rank;
end

--获取玩家自己的排名
function My:GetMyRank()
    local itemList = self.data.itemList;
    for i = 1,#itemList do
        local name = itemList[i].des;
        local myName = User.MapData.Name;
        if name == myName then
            return itemList[i].id;
        end
    end
    return nil;
end

--更新消费元宝
function My:UpdateCostGold()
    local costGold = self.data.costGold;
    self.MyCost.text = tostring(costGold);
end

--更新活动时间
function My:UpActTime()
    local data = self.data;
    local DateTime = System.DateTime;
    local stDate = tostring(DateTool.GetDate(data.sDate));
    local endDate = tostring(DateTool.GetDate(data.eDate));
    local sTime = DateTime.Parse(stDate):ToString("yyyy年MM月dd日HH:mm");
    local eTime = DateTime.Parse(endDate):ToString("yyyy年MM月dd日HH:mm");
    local text = string.format("%s - %s",sTime,eTime);
    self.ActTime.text = text;
end

--更新活动规则
function My:UpActRule()
    local data = self.data;
    self.ActRule.text = data.explain;
end

--打开
function My:Open(data)
    self:SetActive(true);
    self:SetLnsr("Add");
    self:UpdateData(data);
    FestivalActMgr.XFPHRedState = false;
    local type = FestivalActMgr.XFPH;
    FestivalActMgr:UpdateXFPHRedState();
    UIFestivalAct:UpdateRedPoint(false,type);
end

--关闭
function My:Close()
    self:SetActive(false);
    self:SetLnsr("Remove");
    self:ClearList();
end

--设置状态
function My:SetActive(state)
    self.go:SetActive(state)
end

--克隆对象
function My:CloneItem()
    local go = self.ItemInfo;
    local root = GO.Instantiate(go);
    local parent = go.transform.parent;
    TransTool.AddChild(parent,root.transform);
    root.gameObject:SetActive(true);
    return root;
end

--清理列表
function My:ClearList()
    TableTool.ClearListToPool(self.TheFirstRwds)
    TableTool.ClearDicToPool(self.ItemList)
end

-- 释放资源
function My:Dispose()
    self:ClearList();
    self.isInit = false;
end

return My