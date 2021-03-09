--[[
    一见钟情活动
]]
UILoveAtFirst = Super:New{Name = "UILoveAtFirst"};
local My = UILoveAtFirst;

local TFC = TransTool.FindChild;
local USS = UITool.SetLsnrSelf;
local CG = ComTool.Get;

function My:Init(go)
    local trans = go.transform;
    self.go = go;
    self.timeLabel = CG(UILabel, trans, "Bg/TimeLabel");
    self.contentLabel = CG(UILabel, trans, "Bg/ContentLabel/Label");
    self.btn1 = TFC(trans, "Award1/Btn1");
    self.btn2 = TFC(trans, "Award2/Btn1");
    self.grid1 = TFC(trans, "Award1/ScrollView/Grid");
    self.grid2 = TFC(trans, "Award2/ScrollView/Grid");
    self.lable1 = TFC(trans, "Award1/Label");
    self.lable2 = TFC(trans, "Award2/Label");
    self.scrollView1 = CG(UIPanel, trans, "Award1/ScrollView");
    self.scrollView2 = CG(UIPanel, trans, "Award2/ScrollView");
    self.red1 = TFC(trans, "Award1/Btn1/red");
    self.red2 = TFC(trans, "Award2/Btn1/red");
    self.red1:SetActive(false);
    self.red2:SetActive(false);

    USS(self.btn1, self.OnBtnToday, self, nil, false);
    USS(self.btn2, self.OnBtnIsDouble, self, nil, false);

    self.awardList1 = nil;
    self.awardList2 = nil;
    self.cellList1 = nil;
    self.cellList2 = nil;

    self:SetLuaEvent("Add");
    self:InitLabel();
    self:UpdateBtnState();
    self:InitAwardList();
end

function My:SetLuaEvent(fn)
    LoveAtFirstMgr.eUpdateBtnState[fn](LoveAtFirstMgr.eUpdateBtnState, self.UpdateBtnState, self);
end


function My:InitLabel()
    local info = NewActivMgr:GetActivInfo(2012);
    local DateTime = System.DateTime;
    local startTime = DateTool.GetDate(info.startTime):ToString("MM月dd日HH:mm");
    local endTime = DateTool.GetDate(info.endTime):ToString("MM月dd日HH:mm");
    local str1 = "【活动时间】";
    self.timeLabel.text = StrTool.Concat(str1, startTime, " - ", endTime);
    
    self.contentLabel.text = InvestDesCfg["2015"].des;
  
end

function My:UpdateBtnState()
    self.red1:SetActive(false);
    self.red2:SetActive(false);
    local award1 = LoveAtFirstMgr.award1State;
    local award2 = LoveAtFirstMgr.award2State;
    local btnSprite1 = self.btn1:GetComponent(typeof(UISprite));
    local btnSprite2 = self.btn2:GetComponent(typeof(UISprite));
    local label1 = CG(UILabel, self.btn1.transform, "Label");
    local label2 = CG(UILabel, self.btn2.transform, "Label");
    if award1 then
        btnSprite1.spriteName = "btn_figure_down_avtivity";
        label1.text = "[FCF5F5FF]已领取[-]";
    else
        btnSprite1.spriteName = "btn_figure_non_avtivity";
        label1.text = "[772A2AFF]领 取[-]";
        self.red1:SetActive(true);
    end
    if MarryInfo.data.coupleInfo ~= nil then
        if award2 then
            btnSprite2.spriteName = "btn_figure_down_avtivity";
            label2.text = "[FCF5F5FF]已领取[-]";
        else
            btnSprite2.spriteName = "btn_figure_non_avtivity";
            label2.text = "[772A2AFF]领 取[-]";
            self.red2:SetActive(true);
        end
    else
        btnSprite2.spriteName = "btn_figure_non_avtivity2";
        label2.text = "[09564CFF]前往结婚[-]";
    end
end

function My:OnBtnToday()
    local award1 = LoveAtFirstMgr.award1State;
    if award1 == false then
        LoveAtFirstMgr:ReqAward(1);
    else
        UITip.Error("已领取");
    end
end


function My:OnBtnIsDouble()
    local award2 = LoveAtFirstMgr.award2State;
    if MarryInfo.data.coupleInfo ~= nil then
        if award2 == false then
            LoveAtFirstMgr:ReqAward(2);
        else
            UITip.Error("已领取");
        end
    else
        UIMarry:OpenTab(1);
    end
end

function My:InitAwardList()
    local configNum = NewActivMgr:GetActivInfo(2012).configNum;
    local cfg = LoveAtFirstCfg;
    self:ClearList();
    for i,v in ipairs(cfg) do
        if v.configNum == configNum then
            if v.type == 1 then
                self.awardList1 = v.award;
            elseif v.type == 2 then
                self.awardList2 = v.award;
            end
        end
    end
    if self.awardList1 ~= nil and self.awardList2~= nil then
        self:UpdateAwardCell();
    end
end

function My:UpdateAwardCell()
    local parent1 = self.grid1.transform;
    local parent2 = self.grid2.transform;
    ListTool.ClearToPool(self.cellList1);
    ListTool.ClearToPool(self.cellList2);
    self.cellList1 ={};
    self.cellList2 ={};
    self.scrollView1:SetRect(0, 0, #self.awardList1 * 74, 80); 
    self.scrollView2:SetRect(0, 0, #self.awardList1 * 74, 80); 
    for i,v in ipairs(self.awardList1) do
        local cell = ObjPool.Get(UIItemCell);
        cell:InitLoadPool(parent1, 0.79);
        cell.trans.name = v.I;
        local isQua = false;
        if v.N == 1 then
            isQua = true;
        end
        cell:UpData(v.I, v.B, isQua);
        table.insert( self.cellList1, cell);
    end
    for i,v in ipairs(self.awardList2) do
        local cell = ObjPool.Get(UIItemCell);
        cell:InitLoadPool(parent2, 0.79);
        cell.trans.name = v.I;
        local isQua = false;
        if v.N == 1 then
            isQua = true;
        end
        cell:UpData(v.I, v.B, isQua);
        table.insert( self.cellList2, cell);
    end
    self.grid1:GetComponent(typeof(UIGrid)):Reposition();
    self.grid2:GetComponent(typeof(UIGrid)):Reposition();
end


function My:Open( ... )
    self.go:SetActive(true);
    LoveAtFirstMgr:UpdateAction();
end

function My:Close( ... )
    self.go:SetActive(false);
    LoveAtFirstMgr:UpdateAction();
end

function My:ClearList()
    if self.awardList1 == nil then return end
    if #self.awardList1 >0 then
        for i,v in ipairs(self.awardList1) do
            v = nil;
        end
    end
    if self.awardList2 == nil then return end
    if #self.awardList2 >0 then
        for i,v in ipairs(self.awardList2) do
            v = nil;
        end
    end
    self.awardList1 = nil;
    self.awardList2 = nil;
end


function My:Dispose()
    self:ClearList();
    ListTool.ClearToPool(self.cellList1);
    ListTool.ClearToPool(self.cellList2);
end

return My;