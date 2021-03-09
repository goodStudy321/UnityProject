--[[
    通天宝塔活动界面
]]

UITongTianTower = UIBase:New{Name = "UITongTianTower"};
local My = UITongTianTower;

require("TongTianTower/TongTianTowerBag");
require("TongTianTower/UITongTianModel");

local C = ComTool.Get;
local TF = TransTool.Find;
local TFC = TransTool.FindChild;
local AddC = TransTool.AddChild;
--自定义初始化
function My:InitCustom()
    self.tip = "通天宝塔活动";
    self.trans = self.root;
    self.go = self.trans.gameObject;

    self.closeBtn = TFC(self.trans, "CloseBtn");
    self.onceBtn = TFC(self.trans, "OnceBtn");
    self.autoBtn = TFC(self.trans, "AutoBtn");
    self.helpBtn = TFC(self.trans, "HelpBtn");
    self.bagBtn = TFC(self.trans, "BagBtn");

    self.hCamera = TFC(self.trans, "HCamera");
    self.modelCamera = TFC(self.trans, "ModleCamera");
    self.action = TFC(self.trans, "BagBtn/Action");
    self.action:SetActive(false);

    self.bag = TFC(self.trans, "bag");
    self.autoLabel = C(UILabel, self.trans, "AutoBtn/Label1");
    self.goldLabel = C(UILabel, self.trans, "OnceBtn/GoldSprite/GoldLabel")
    self.timeLab = C(UILabel, self.trans, "TimeLable");
    self.ignoreTog = C(UIToggle, self.trans, "IgnoreTog");
    self.ignoreTog.value = false;

    self.hintLable = C(UILabel, self.trans, "Bg/Label");

    self.scrollGroup = {};
    self.itemGroup = {{},{},{},{},{},{}};

    self.highLightItem = TFC(self.trans, "AwardItem/HighLightItem");
    self.highLightItem:SetActive(false);
    self.highLightGroup = {{},{},{},{},{},{}};

    self.model = ObjPool.Get(UITongTianModel);
    self.model:Init(self.go);

    self.fx1 = TFC(self.trans, "FX_k01");
    self.fx1:SetActive(false);
    self.fx2 = TFC(self.trans, "FX_k02");
    self.fx2:SetActive(false);
    self.fx3Group = {};


    --跑马灯
    --// 正常跑动速度
    self.moveSpeed = 2100;
    --// 缓慢跑动速度
    self.slowSpeed = 500;
    --// 跑动距离
    self.moveDistance = 2000;

    --// 当前选择阶段(0:停止；1：正常；2：减速)
    self.state = 0;
    --// 起始位置
    self.beginLocation = 0;
    --// 当前位置
    self.curLocation = 0;
    --// 停止位置
    self.stopLocation = 0;
    --// 当前高亮索引
    self.curHLightIndex = 0;
    --// 当前高亮层
    self.layer = 0;
    --// 最终位置索引
    self.endLocationIndex = 0;
    self.oldLayer = 0;
    --// 是否在选择
    self.isChoose = false;

    --// 是否能点击抽奖
    self.isClickPlay = true;

    --// 是否播放动画
    self.isPlay = true;

    --// 弹窗等待时间
    self.wTimer = 0;

    --// 自动抽奖
    self.autoDraw = false;

    --// 自动次数
    self.autoCount = 0;

    --物品列表
    self.ItemList = {};
    --// 背包
    self.TongTianBag = nil;
    if self.TongTianBag == nil then
        self.TongTianBag = ObjPool.Get(TongTianTowerBag);
        self.TongTianBag:Init(self.bag.transform);
    end

    TongTianTowerMgr:GetActivInfo();
    self:InitItemList();
    
    self:InitNextLayer();
    self:InitScrollGroup();
    self:SetBtnEvent();
    self:InitItem();
    self:ShowModel();
    self:InitLabel();
    self:TimeInit();
    self:SetLuaEvent("Add");
    self:ShowIgnoreBtn();
    self:SetHintLable();
end

--监听事件
function My:SetLuaEvent(fn)
    TongTianTowerMgr.eGetAward[fn](TongTianTowerMgr.eGetAward, self.OncePlayMove, self);
    TongTianTowerMgr.eGetAward[fn](TongTianTowerMgr.eGetAward, self.AutoDraw, self);
    TongTianTowerMgr.eUpAction[fn](TongTianTowerMgr.eUpAction, self.UpdateAction, self);
end


--设置按钮事件
function My:SetBtnEvent()
    local USC = UITool.SetLsnrClick;
    local USS = UITool.SetLsnrSelf;

    local closeBtn = self.closeBtn;
    local onceBtn = self.onceBtn;
    local autoBtn = self.autoBtn;
    local helpBtn = self.helpBtn;
    local bagBtn = self.bagBtn;
    local ignoreBtn = self.ignoreTog.transform;
    if onceBtn then
        USS(onceBtn, self.OnOnceBtn, self, nil, false);
    end
    if closeBtn then
        USS(closeBtn, self.Close, self, nil, false);
    end
    if autoBtn then
        USS(autoBtn, self.OnAutoBtn, self, nil, false);
    end
    if helpBtn then
        USS(helpBtn, self.OnHelpBtn, self, nil, false);
    end
    if bagBtn then
        USS(bagBtn, self.OnBagBtn, self, nil, false);
    end
    if ignoreBtn then
        USS(ignoreBtn, self.OnIgnoreBtn, self, nil, false);
    end
end

--下层特效
function My:InitNextLayer()
    for i = 1,5 do
        local str1 = "FX_k03_";
        local str = StrTool.Concat(str1, i);
        local fx = TFC(self.trans, str);
        fx:SetActive(false);
        table.insert(self.fx3Group, fx);
    end
end

--显示下层特效
function My:ShowNextFx()
    for i=1,#self.fx3Group do
        if self.layer > i then
            self.fx3Group[i]:SetActive(true);
        else
            self.fx3Group[i]:SetActive(false);
        end
    end
end

function My:SetHintLable()
    local temp = GlobalTemp["190"];
    local str1 = tostring(temp.Value2[1]);
    local str2 = tostring(temp.Value3);
    local str3 = "元宝购买";
    local str4 = "银两赠送1次抽奖机会";
    local str = StrTool.Concat(str2, str3, str1, str4);
    self.hintLable.text = str;
end


--更新红点
function My:UpdateAction()
    local isShow = TongTianTowerMgr:ActionState();
    self.action:SetActive(isShow);
end


--设置动画是否播放
function My:OnIgnoreBtn()
    local val = self.ignoreTog.value;
	local index = 0;
	if val == true then
        index = 1;
    else
        index = 0;
    end
    PlayerPrefs.SetInt("TongTianTowerTog", index);
    self.isPlay = not self.ignoreTog.value;
end

function My:ShowIgnoreBtn()
    local isVal = false;
	if PlayerPrefs.HasKey("TongTianTowerTog") then
        local val = PlayerPrefs.GetInt("TongTianTowerTog")
        if val == 1 then
            isVal = true
        else
            isVal = false
		end
	end
    self.ignoreTog.value = isVal;
    self.isPlay = not self.ignoreTog.value;
end

--点击背包按钮
function My:OnBagBtn()

    if self.TongTianBag == nil then
        self.TongTianBag = ObjPool.Get(TongTianTowerBag);
        self.TongTianBag:Init(self.bag.transform);
    end
    self:ModelShow(false);
    self.TongTianBag:UpShow(true);
end

--模型显示
function My:ModelShow(state)
    self.hCamera:SetActive(state);
    self.modelCamera:SetActive(state);
end

--抽奖一次
function My:OnOnceBtn()
    if self:GetBagState() == false then
        MsgBox.ShowYes("临时仓库空间不足\n请清理后进行操作",self.yesCb)
        return ;
    end
    local canDraw = self:IsCanDraw();
    if canDraw == false then
        return ;
    end
    self.isClickPlay = false;
    --self:OncePlayMove();
    
    TongTianTowerMgr:ReqAward();
end

function My:yesCb()
    My:OnBagBtn();
end

-- 播放跑动
function My:OncePlayMove()
    if self.autoDraw == true then return end
    if self:GetBigAward() == true then return end
    
    self:HideHighLight();
    if self.isPlay == false then
        self:OpenRewardPannel();
        self.isClickPlay = true;
    else
        
        local layer = TongTianTowerMgr.layer;
        local count = #self.highLightGroup[self.layer];
        local dis = count * 86;

        self.moveSpeed = 2100;
        self.slowSpeed = 500;
       
        self.isChoose = true;

        self.state = 1;
        self.curLocation = self.curLocation % dis;
        self.moveDistance = dis * 3;

        

        self.stopLocation = self:GetLocationByIndex(self:EndHithtLigtLocation());
    end
end

--自动抽奖按钮
function My:OnAutoBtn()
    local isOpen = NewActivMgr:ActivIsOpen(2009);
    if isOpen == false then
        UITip.Error("活动已经结束");
        return ;
    end 

    if self:GetBagState() == false then
        MsgBox.ShowYes("临时仓库空间不足\n请清理后进行操作",self.yesCb)
        return ;
    end
    if self:GoldEnough() == false then 
        StoreMgr.JumpRechange();
        return ;
    end
    if self.autoDraw == false then
        if self.isChoose == true or self.isClickPlay == false then 
            UITip.Error("抽奖中");
            return ;
        end
    end
    
    
    self.autoDraw = not self.autoDraw and true or false;
    if self.autoDraw == true then
        self.autoLabel.text = "[09564CFF]取消爬塔[-]";
        TongTianTowerMgr:ReqAward();
        --self:AutoDraw();
    elseif self.autoDraw == false then
        self.autoCount = 0;
        self.autoLabel.text = "[09564CFF]自动爬塔[-]";
    end

    
end

--自动抽奖
function My:AutoDraw()
    if self.autoDraw == false then return end
    if self:GetBigAward() == true then return end
    local isOpen = NewActivMgr:ActivIsOpen(2009);
    if isOpen == false then
        self:OpenRewardPannel();
        UITip.Error("活动已经结束");
        return ;
    end 
    self:HideHighLight();
    local layer = TongTianTowerMgr.layer;
    local count = #self.highLightGroup[self.layer];
    local dis = count * 86;

    self.moveSpeed = 3000;
    self.slowSpeed = 1000;
    
    self.moveDistance = dis*2;
    if self.isPlay == false then 
        self.state = 3;
    else 
        self.state = 1;
    end
    self.autoCount = 0;
    self.wTimer = 0.8;
    self.curLocation = self.curLocation % dis;

    self.isChoose = true;
    
    

    self.stopLocation = self:GetLocationByIndex(self:EndHithtLigtLocation());

end

function My:GetAward()
    if self.autoCount > 0 then
        if self.isChoose == false and self.autoDraw == false then
            self:OpenRewardPannel();
            self.autoLabel.text = "[09564CFF]自动爬塔[-]";
            self.autoCount = 0;
        end
    end
end

--背包空间(false为不足)
function My:GetBagState()
    local bagNum = TongTianTowerBag:GetBagCell();
	if bagNum <= 0 then
		return false;
    end
    return true;
end

--元宝是否足够
function My:GoldEnough()
    local cfg = GlobalTemp["190"];
    local costNum = cfg.Value3;
    local isEnGold = RoleAssets.IsEnoughAsset(2,costNum);
    if isEnGold == false then
        self.autoLabel.text = "[09564CFF]自动爬塔[-]";
    end
    return isEnGold;
end

--抽到大奖
function My:GetBigAward()
    local item = TongTianTowerMgr.awardItem;
    
    if item.k == self.itemGroup[6][1].tId then
        self:OpenRewardPannel();
        self:InitItemList();
        self:UpdateItem();
        self:ShowModel();
        self.autoLabel.text = "[09564CFF]自动爬塔[-]";
        self.curLocation = 0;
        self.stopLocation = 0;
        self.isChoose = false;
        self.layer = TongTianTowerMgr.layer;
        self.oldLayer = self.layer;
        self.isClickPlay = true;
        self.autoDraw = false;
        self.isPlay = not self.ignoreTog.value;
        self.autoCount = 0;
        return true;
    end
    
    return false;
end



--是否能抽奖
function My:IsCanDraw()
    local isCanDraw = true;
    local isOpen = NewActivMgr:ActivIsOpen(2009);
    if isOpen == false then
        UITip.Error("活动已经结束");
        isCanDraw = false;
        return isCanDraw;
    end
    isCanDraw = self:GoldEnough();
    if isCanDraw == false then
        StoreMgr.JumpRechange();
    end
    if self:GoldEnough() and self.autoDraw == true then
        UITip.Error("自动爬塔中");
        isCanDraw = false;
    elseif (self.isChoose == true or self.isClickPlay == false) and self.autoDraw == false then 
        UITip.Error("操作过快，请稍后再试");
        isCanDraw = false;
    end

    return isCanDraw;
end


--点击帮助按钮
function My:OnHelpBtn()
    local str = InvestDesCfg["2013"].des;
    local pos = Vector3.New(-206,222,0);
    UIComTips:Show(str, pos, nil, nil, nil, nil, UIWidget.Pivot.TopLeft)
end

--物品组
function My:InitScrollGroup()
    for i=1,6 do
        local str = StrTool.Concat("AwardItem/ScrollView",tostring(i),"/Grid");
        self.scrollGroup[i] = TFC(self.trans, str);
    end
end

function My:InitItemList()
    local cfg = TongTianTowerCfg;
    self.ItemList = {};
    for k,v in pairs(cfg) do
        if v.configNum == TongTianTowerMgr.configNum then
            if v.poolId == TongTianTowerMgr.pool then
                table.insert(self.ItemList, v);
            end
        end
    end
    table.sort(self.ItemList, function(a,b) return a.id < b.id end);
end

--更新物品格子
function My:UpdateItem()
    local list = self.ItemList;
    for i,v in ipairs(list) do
        local n = 1;
        local groupId = 0;
        if i <= 6 then 
            groupId = 1;
        elseif i <= 11 then
            groupId = 2;
        elseif i <= 15 then
            groupId = 3;
        elseif i <= 18 then     
            groupId = 4;
        elseif i <= 20 then         
            groupId = 5;
        else
            groupId = 6;
        end  
        if i <= 6 then
            n = i;
        elseif 11 >= i and i > 6 then
            n = i - 6;
        elseif 15 >= i and i > 11 then
            n = i - 11;
        elseif 18 >= i and i > 15 then
            n = i - 15;
        elseif 20 >= i and i > 18 then
            n = i - 18;
        elseif i > 20 then
            n = i - 20;
        end
        local cell = self.itemGroup[groupId][n]
        cell.trans.name = v.id;
        if groupId == 6 then
            cell:UpData(v.itemId, v.count);
        else
            cell:UpData(v.itemId, v.count, false);
        end
        self.highLightGroup[groupId][n].transform.name = v.id;
    end
end

--初始化物品格子
function My:InitItem()

    local list = self.ItemList;
    local sg = self.scrollGroup;

    self.highLightGroup = {{},{},{},{},{},{}};
    for i,v in ipairs(list) do
        local cell = ObjPool.Get(UIItemCell);
        local groupId = 0;
        if i <= 6 then 
            groupId = 1;
        elseif i <= 11 then
            groupId = 2;
        elseif i <= 15 then
            groupId = 3;
        elseif i <= 18 then
            groupId = 4;
        elseif i <= 20 then
            groupId = 5;
        else
            groupId = 6;
        end
        cell:InitLoadPool(sg[groupId].transform, 0.9);
        
        cell.trans.name = v.id;
        if groupId == 6 then
            cell:UpData(v.itemId, v.count);
        else
            cell:UpData(v.itemId, v.count, false);
        end
        table.insert(self.itemGroup[groupId], cell);

        local go = Instantiate(self.highLightItem);
        local parent = cell.trans;
        local trans = go.transform;
        go:SetActive(false);
        trans.localPosition = parent.localPosition;
        trans.name = v.id;
        AddC(parent, trans);
        if i == 6 or i==11 or i == 15 or i == 18 or i == 20 then 
            local go1 = Instantiate(self.fx1);
            local trans1 = go1.transform;
            go1:SetActive(true);
            trans1.localPosition = parent.localPosition;
            AddC(parent, trans1);
        end
        local grid =sg[groupId]:GetComponent(typeof(UIGrid));
        grid:Reposition();
        table.insert(self.highLightGroup[groupId], go);
    end
end

--模型展示
function My:ShowModel()
    local modelId = self.itemGroup[6][1].tId;
    self.model:UpData(modelId);
end

function My:ClearModel()
    if self.model then
        self.model:Dispose();
    end
    self.model = nil;
end

--初始化文本
function My:InitLabel()
    self.goldLabel.text = tostring(GlobalTemp["190"].Value3);
end

--活动时间
function My:TimeInit()
    local data = TongTianTowerMgr.activInfo;
    if not data then
        return ;
    end 
    local endTime = data.endTime;
    local seconds = endTime-TimeTool.GetServerTimeNow()*0.001
    --local seconds = 60;
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.invlCb:Add(self.InvlCb, self)
            self.timer.complete:Add(self.CompleteCb, self)
            --self.timer.apdOp = 3
        else
            self.timer:Stop()
        end
        self.timer.seconds = seconds
        self.timer:Start()
        self:InvlCb()
    end
end

--间隔倒计时
function My:InvlCb()
    if self.timeLab then
        local str1 = "[E9A88BFF]剩余时间:[-][54FF68FF]"
        local str2 = string.format("%s", self.timer.remain);
        local str3 = "[-]"
        local str = StrTool.Concat(str1, str2, str3);
        self.timeLab.text = str;
    end
end

--结束倒计时
function My:CompleteCb()
    if self.timeLab then
        self.timeLab.text = "[E9A88BFF]活动结束[-]"
    end
end

--当前位置转换高亮区域
function My:GetIndexByLocation(location)
    local lac = location;
    local layer = TongTianTowerMgr.layer;
    local count = #self.highLightGroup[self.layer];
    local dis = count * 86;
    local l = lac % dis;
    local index = math.floor(l / 86) + 1;
    return index;
end

--获取最终位置
function My:GetLocationByIndex(index)
    local idx = index;
    local layer = TongTianTowerMgr.layer;
    local count = #self.highLightGroup[self.layer];
  
    local dis = count * 86;
    local location = ((idx - 1) * 86) % dis + self.moveDistance + dis;
    return location;
end

--最终高亮下标
function My:EndHithtLigtLocation()
    local endId = TongTianTowerMgr.awardItemId;
   
    local layer = TongTianTowerMgr.layer;
    for i,v in ipairs(self.highLightGroup[self.layer]) do
        if v.name == tostring(endId) then
            self.endLocationIndex = i;
            return i;
        end
    end
    return 0;
end

function My:HideHighLight()
    local group = self.highLightGroup;
    for i,v in ipairs(group) do
        for _,v in ipairs(v) do
            v:SetActive(false);
        end
    end
end

--更新高亮位置
function My:UpdateHighLight(index)
    if self.curHLightIndex == index then
        return ;
    end
    local layer = TongTianTowerMgr.layer;
    
    if self.curHLightIndex > 0 then
        if self.oldLayer ~= self.layer then
            self.highLightGroup[self.oldLayer][self.curHLightIndex]:SetActive(false);
            self.oldLayer = self.layer;
            
        else
            self.highLightGroup[self.layer][self.curHLightIndex]:SetActive(false);
            
        end
    end

    self.curHLightIndex = index;

    self.highLightGroup[self.layer][self.curHLightIndex]:SetActive(true);
end

--更新跑马灯
function My:UpdateMove()
    if self.isChoose == false then
        return ;
    end 

    local dT = Time.deltaTime;
    if self.state == 1 then
        self.curLocation = self.curLocation + self.moveSpeed * dT;
        if self.curLocation >= self.moveDistance then
            self.curLocation = self.moveDistance;
            self.state = 2;
        end
        self:UpdateHighLight(self:GetIndexByLocation(self.curLocation));
    elseif self.state == 2 then
        if self.curLocation >= self.stopLocation - 0.01 then
            self.curLocation = self.stopLocation;
            self:UpdateHighLight(self:GetIndexByLocation(self.curLocation));
            self.state = 3;
            self.wTimer = 0;
            self:ChooseFx();
            return;
        end
        self.curLocation = self.curLocation + self.slowSpeed * dT;
        self:UpdateHighLight(self:GetIndexByLocation(self.curLocation));
    elseif self.state == 3 then
        self.wTimer = self.wTimer +dT;
        if self.wTimer >= 1 then
            self.wTimer = 0;
           
            
            local layer = TongTianTowerMgr.layer;
            if layer ~= self.layer then
                self.oldLayer = self.layer;
                self.layer = layer;
                self:ShowNextFx();
            end
           
            if self.autoDraw == false then
                if self.autoCount == 0 then

                    self:OpenRewardPannel();
                    self.isClickPlay = true;
                    self.isChoose = false;

                end
            elseif self.autoDraw == true then
                if self:GetBagState() == false then
                    self:OpenRewardPannel();
                    MsgBox.ShowYes("临时仓库空间不足\n请清理后进行操作",self.yesCb)
                else
                    if self:GoldEnough() == false then 
                        self.autoDraw = false;
                    else
                        TongTianTowerMgr:ReqAward();
                        self.autoCount = self.autoCount + 1;
                    end 
                end
                  
            end

           
        end
    end
end

--选择特效
function My:ChooseFx()
    self.fx2:SetActive(false);
    local cell = self.itemGroup[self.layer][self.endLocationIndex].trans;
    local parent = TFC(cell, cell.name);
    AddC(cell,self.fx2.transform);
    self.fx2.transform.localPosition = parent.transform.localPosition;
    self.fx2:SetActive(true);
end



--奖励弹窗
function My:OpenRewardPannel()
    if #TongTianTowerMgr.awardList > 0 then
        UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self);
    end
end

function My:RewardCb(name)
	local ui = UIMgr.Get(name)
    if(ui)then
        ui:UpdateData(TongTianTowerMgr.awardList);
    end
    TongTianTowerMgr:ClearList();
    
    self.curLocation = 0;
    self.stopLocation = 0;
    self.isChoose = false;
    self.isPlay = not self.ignoreTog.value;
    self.autoDraw = false;
    self.autoLabel.text = "[09564CFF]自动爬塔[-]";
    self.autoCount = 0;
    local layer = TongTianTowerMgr.layer;
    if layer ~= self.layer then
        self.layer = layer;
        self:ShowNextFx();
    end
end





function My:Update()
    self:UpdateMove();
    
    self:GetAward();
    
end


--自定义打开
function My:OpenCustom()
    self.layer = TongTianTowerMgr.layer;
    self.oldLayer = self.layer;
    self:OnIgnoreBtn();
    self:ShowNextFx();
    self:UpdateAction();
end

--自定义关闭
function My:CloseCustom()
    if #TongTianTowerMgr.awardList > 0 then
        self:OpenRewardPannel();
    end
end

--自定义释放
function My:DisposeCustom()
    self:Clear();
    ObjPool.Add(self.TongTianBag);
    self.TongTianBag = nil;
end

--清理
function My:Clear()
    ObjPool.Add(self.TongTianBag);
    self.TongTianBag = nil;
    self:SetLuaEvent("Remove");
    self.scrollGroup = nil;
    self:ClearModel();
    self.state = 0;
    self.beginLocation = 0;
    self.curLocation = 0;
    self.stopLocation = 0;
    self.curHLightIndex = 0;
    self.layer = 0;
    self.oldLayer = 0;
    self.isChoose = false;
    self.isClickPlay = true;
    self.isPlay = true;
    self.wTimer = 0;
    self.autoDraw = false;
    self.autoCount = 0;
    self.ItemList = {};
end

return My;