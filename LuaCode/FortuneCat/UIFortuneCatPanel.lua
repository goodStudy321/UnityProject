--[[
    招财猫活动
]]


UIFortuneCatPanel = UIBase:New{Name = "UIFortuneCatPanel"};
local My = UIFortuneCatPanel;

local C = ComTool.Get;
local TF = TransTool.Find;
local TFC = TransTool.FindChild;

--// 转盘分块
local piece = 8;
--// 转盘角速度（s）
local aglSpd = 1200;
--// 正常旋转角度
local norRotAgl = 1440;


--自定义初始化
function My:InitCustom()
    self.tip = "招财猫";
    self.trans = self.root;
    self.Scroll = TFC(self.trans, "LogTitle/ScrollView");
    self.Grid = TFC(self.trans, "LogTitle/ScrollView/Grid");
    self.Item = TFC(self.Grid.transform, "Container");
    self.Item:SetActive(false);
    self.grid = C(UIGrid, self.Scroll.transform, "Grid");
    self.timeLab = C(UILabel, self.trans, "Time/EndTime");

    self.LogsItemList = {};
    self.BtnLabToggle = {};
    self.HigtLightList = {};
    self.Btn = TFC(self.trans, "CircleBg/Button");
    self.CloseBtn = TFC(self.trans, "Close");

    --转盘
    self.isChoose = false;

    self.isClickPlay = false;
    --起始位置
    self.beginAgl = 0;

    --// 当前转盘角度
    self.curAgl = 0;
    --// 当前转盘阶段(0:停止；1：正常；2：减速)
    self.state = 0;
    --// 当前高亮索引
    self.chooseNum = 0;
    --// 停止位置
    self.stopAgl = 0;

    self.wTimer = 0;

    self.needChoose = 0;

    self:SetLuaEvent("Add");
    self:BtnEvent();
    self:InitBtnLab();
    self:InitHithLight();
    self:TimeInit();
end
    
--监听事件
function My:SetLuaEvent(fn)
    FortuneCatMgr.eUpdateLog[fn](FortuneCatMgr.eUpdateLog, self.LogsUpdate, self);
    FortuneCatMgr.eUpdateRate[fn](FortuneCatMgr.eUpdateRate, self.ShowRollEff, self);

end

--按钮事件
function My:BtnEvent()
    local USC = UITool.SetLsnrClick;
    local USS = UITool.SetLsnrSelf;

    local btn = self.Btn;
    local closeBtn = self.CloseBtn;

    if btn then
        USS(btn, self.OnClickBtn, self, nil, false);
    end
    if closeBtn then
        USS(closeBtn, self.Close, self, nil, false);
    end
end

--投入
function My:OnClickBtn()
    local canRoll = self:CheckRoll()
    if canRoll == false then
        return
    end
    self.isClickPlay = true;
    FortuneCatMgr:ReqAward();
end

--判断是否可以抽奖
function My:CheckRoll()
    local index = 0
    local isCanRoll = true
    local len = FortuneCatMgr.CfgNum
    local curNum = FortuneCatMgr.drawCount
    local strNum = tostring(curNum)
    local cfg = FortuneCatCfg[strNum]
    if cfg == nil or curNum > len then
        UITip.Error("抽奖次数已经用完了哦")
        isCanRoll = false
        return isCanRoll
    end
    local costNum = cfg.ingot
    local isEnGold = RoleAssets.IsEnoughAsset(2,costNum)
    local isOpen = NewActivMgr:ActivIsOpen(2001)
    if isEnGold == false then
        StoreMgr.JumpRechange()
        isCanRoll = false
    elseif isOpen == false then
        UITip.Error("活动已经结束")
        isCanRoll = false
    end
    if self.isChoose == true then 
        UITip.Error("抽奖中");
        isCanRoll = false;
    end 
    return isCanRoll
end

--按钮显示始化
function My:InitBtnLab()
    for i=1,4 do
        local btnLab =TFC(self.trans, string.format("CircleBg/Button/%s", i));
        if i == 3 then
            btnLab:SetActive(true);
        else
            btnLab:SetActive(false);
        end
        table.insert(self.BtnLabToggle, btnLab);
    end
end

--物品高亮初始化
function My:InitHithLight()
    for i=1,8 do
        local higtLight = TFC(self.trans, string.format("CircleBg/Grid/%s/HighLight", i));
        higtLight:SetActive(false);
        table.insert(self.HigtLightList, higtLight);
    end
end



--按钮Lab显示
function My:ShowBtnLab()
    local cfg = FortuneCatCfg;
    
    if FortuneCatMgr.drawCount > FortuneCatMgr.CfgNum then
        self:OpenBtnLab(1);
        return;
    end

    local v = cfg[tostring(FortuneCatMgr.drawCount)];
    if not v then return end
        if v.count == FortuneCatMgr.drawCount then
            if v.ingot < 100 then
                self:OpenBtnLab(2);   
            elseif v.ingot < 1000 then
                self:OpenBtnLab(3);
            elseif v.ingot < 100000 then
                self:OpenBtnLab(4);
            end
            if self.btNumLab ~= nil then
                self.btNumLab.text = tostring(v.ingot);
            end
        end
        
end

--开启按钮Lab
function My:OpenBtnLab(value)
    for i,v in ipairs(self.BtnLabToggle) do
        if i == value then
            self.BtnLabToggle[i]:SetActive(true);
            if value ~= 1 then
                self.btNumLab = C(UILabel, self.BtnLabToggle[i].transform, "numLabel");
            end
        else
            self.BtnLabToggle[i]:SetActive(false);
        end
    end
end
    
--克隆Log
function My:CloneItem()

    local AddC = TransTool.AddChild;
    local go = Instantiate(self.Item);
    local parent = self.Grid.transform;
    local tran = go.transform;

    go:SetActive(true);

    local GbjName = "";
    if #self.LogsItemList + 1 < 10 then
        GbjName = StrTool.Concat("0",tostring(#self.LogsItemList + 1));
    else
        GbjName = tostring(#self.LogsItemList + 1);
    end
    go.name = GbjName;
    AddC(parent, tran);

    table.insert(self.LogsItemList, go);
    
end

--设置log数量
function My:ReLogsNum(number)
    for i=1,#self.LogsItemList do
        self.LogsItemList[i]:SetActive(false);
    end

    local realNum = number;

    if realNum <= #self.LogsItemList then
        for i=1,realNum do
            self.LogsItemList[i]:SetActive(true);
        end
    else
        for i=1,#self.LogsItemList do
            self.LogsItemList[i]:SetActive(true);
        end

        local needNum = realNum - #self.LogsItemList;
        for a=1,needNum do
            self:CloneItem();
        end
    end
    self.grid:Reposition();
end


--Logs添加
function My:LogsUpdate()
    if self.isClickPlay == true or self.isChoose == true then
        return;
    end
    local logList = FortuneCatMgr.LogList;
    self:ReLogsNum(#logList);

    for i,k in ipairs(self.LogsItemList) do
        local tran = self.LogsItemList[i].transform;
        local Lab = C(UILabel, tran, "logItem");
        local str1 = "[E9A88BFF]恭喜[-]";
        local str2 = StrTool.Concat("[FCF5F5FF]",logList[i].name,"[-]");
        local str3 = "[E9A88BFF]花费[-]";
        local str4 = StrTool.Concat("[54FF68FF]元宝x",tostring(logList[i].consumeGold),"[-]");
        local str5 = "[E9A88BFF], 喜得[-]";
        local str6 = StrTool.Concat("[54FF68FF]",tostring(logList[i].rate),"[-]");
        local str7 = "[E9A88BFF]倍招财猫赐福,共计[-]";
        local str8 = StrTool.Concat("[54FF68FF]",tostring(logList[i].addGold),"元宝![-]");
        Lab.text = StrTool.Concat(str1, str2, str3, str4, str5, str6, str7, str8);
    end
    
end



--活动时间
function My:TimeInit()
    local data = NewActivMgr:GetActivInfo(2001);
    if not data then
        return ;
    end 
    local endTime = data.endTime;
    local seconds =  endTime-TimeTool.GetServerTimeNow()*0.001
    if seconds <= 0 then
        self:CompleteCb()
    else
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.invlCb:Add(self.InvlCb, self)
            self.timer.complete:Add(self.CompleteCb, self)
            self.timer.apdOp = 3
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
        self.timeLab.text = string.format("%s", self.timer.remain);
    end
end

--结束倒计时
function My:CompleteCb()
    if self.timeLab then
        self.timeLab.text = "活动结束"
    end
end


--获取最终高亮区域
function My:EndHigtLightArea()
    local cfg = FortuneCatCfg;
    local rateList = cfg[tostring(FortuneCatMgr.drawCount - 1)].multiple;
    self.needChoose = FortuneCatMgr.rate;
    for i,v in ipairs(rateList) do
        if rateList[i]["id"] == self.needChoose then
            return i;
        end
    end
    return 0;
end

--// 根据角度获得转盘索引
function My:GetIndexByAgl(angle)
    local rAgl = angle % 360;
    local idx = math.floor(rAgl / 45) + 1;
    return idx;
end

function My:GetEndAglByIndex(index)
    local idx = index;
    local rAgl = ((idx - 1) * 45) % 360 + norRotAgl + 360;
    return rAgl;
end

function My:ShowRollEff(suc)
    if suc == false then
        self.isClickPlay = false;
        return;
    end
    if FortuneCatMgr.CfgNum + 1 < FortuneCatMgr.drawCount then return end
    self:PlayRoll();
end

--// 开始播放转盘
function My:PlayRoll()
    if self.isChoose == true then
        UITip.Log("抽奖中");
        return;
    end

    self.isChoose = true;
    self.isClickPlay = false;
    self.curAgl = 0;
    self.state = 1;
    if self.chooseNum > 0 then
        self.HigtLightList[self.chooseNum]:SetActive(false);
    end
    self.chooseNum = 0;




    self.stopAgl = self:GetEndAglByIndex(self:EndHigtLightArea());
end

--// 更新转盘
function My:UpdateRoll()
    if self.isClickPlay == true or self.isChoose == false then
        return;
    end

    local dT = Time.deltaTime;
    if self.state == 1 then
        self.curAgl = self.curAgl + aglSpd * dT;
        if self.curAgl >= norRotAgl then
            self.curAgl = norRotAgl
            self.state = 2;
        end
        self:ChangePieceShow(self:GetIndexByAgl(self.curAgl));

    elseif self.state == 2 then
        if self.curAgl >= self.stopAgl - 0.01 then
            self.curAgl = self.stopAgl;
            self:ChangePieceShow(self:GetIndexByAgl(self.curAgl));
            self.state = 3;
            self.wTimer = 0;

            return;
        end
        self.curAgl = self.curAgl + 240 * dT;
        
        self:ChangePieceShow(self:GetIndexByAgl(self.curAgl));
    elseif self.state == 3 then
        self.wTimer = self.wTimer + dT;
        if self.wTimer >= 1 then
            self.isChoose = false;
            self.state = 0;
            --// 弹框，显示奖励
            self:OpenRewardPannel();
            self:LogsUpdate();
        end
    end
end

--// 转换高亮显示
function My:ChangePieceShow(index)
    if self.chooseNum == index then
        return;
    end

    if self.chooseNum > 0 then
        self.HigtLightList[self.chooseNum]:SetActive(false);
    end
    self.chooseNum = index;
    self.HigtLightList[self.chooseNum]:SetActive(true);
end


--弹窗
function My:OpenRewardPannel()
    UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self);
end

function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
        ui:UpRareData(FortuneCatMgr.wardItem);
	end
end

function My:Update()
    self:UpdateRoll();
end
--自定义打开
function My:OpenCustom()
    self:ShowBtnLab();
    self:LogsUpdate();
end
    
--清理
function My:Clear()
    self.BtnLabToggle = {};
    self.HigtLightList = {};
    self.LogsItemList = {};
    self:SetLuaEvent("Remove");
end

--自定义关闭
function My:CloseCustom()
    if self.isChoose then self:OpenRewardPannel(); end
    self:SetLuaEvent("Remove");
end
    
--自定义释放
function My:DisposeCustom()
    self.BtnLabToggle = {};
    self.HigtLightList = {};
    self.LogsItemList = {};
end

return My;
