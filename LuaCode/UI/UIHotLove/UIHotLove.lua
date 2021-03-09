--[[
    全程热恋活动
]]

UIHotLove = Super:New{Name = "UIHotLove"}
local My = UIHotLove;

require("UI/UIHotLove/HotLoveCondItem");
require("UI/UIHotLove/HotLoveItem");

function My:Init(go)
    self.go = go;
    self.go:SetActive(false);

    local root = go.transform
    local des = self.Name
    local CG = ComTool.Get
    local FindC = TransTool.FindChild
    local str1 = "Container/Scroll View/Grid"
    local str2 = "countBg/Scroll View/Grid"

    self.itList = {}
    self.condList = {}
    self.grid = CG(UIGrid, root, str1)
    self.explain = CG(UILabel, root, "spr/lab")
    self.countDown = CG(UILabel, root, "Countdown")
    self.lab = CG(UILabel, root, "countBg/titleBg/lab")
    self.item = FindC(root, str1.."/Cell", des)
    self.condGrid = CG(UIGrid, root, str2)
    self.condItem = FindC(root, str2.."/item", des)


    self:UpTitleLab();
    self:InitAwardItems();
    self:TimeInit();
    self:InitExplainLab();
    self:InitCondItems();
    HotLoveMgr:IsShowRed();
end

--初始化条件项
function My:InitCondItems()
    local itemData = HotLoveMgr.taskList;
    if itemData == nil then return end
    local Add = TransTool.AddChild;
    for i,v in ipairs(itemData) do
        local go = Instantiate(self.condItem)
        local tran = go.transform
        Add(self.condGrid.transform, tran)
        local it = ObjPool.Get(HotLoveCondItem);
        it:Init(tran, v)
        table.insert(self.condList, it)
    end
    self.condItem:SetActive(false)
    self.condGrid:Reposition()
end


--初始化奖励项
function My:InitAwardItems()
    if #self.itList > 0 then return end
    local itemData = HotLoveMgr.rewarList;
    if itemData == nil then return end
    local Add = TransTool.AddChild
    for i,v in ipairs(itemData) do
        local go = Instantiate(self.item)
        local tran = go.transform
        Add(self.grid.transform, tran)
        local it = ObjPool.Get(HotLoveItem);
        it:Init(tran, v)
        table.insert(self.itList, it)
    end
    self.item:SetActive(false)
    self.grid:Reposition()
end

--更新标题文本
function My:UpTitleLab()
    local money = HotLoveMgr.money;
    local keyword = "热点";
    local str = string.format("[EE9A9EFF]当前%s：[F78706FF]%s", keyword, money);
    self.lab.text = str
end

--初始化说明文本
function My:InitExplainLab()
    self.explain.text = InvestDesCfg["2017"].des;
end

--活动时间
function My:TimeInit()
    local data = NewActivMgr:GetActivInfo(2013);
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
    if self.countDown then
        self.countDown.text = string.format("活动结束倒计时:%s", self.timer.remain);
    end
end

--结束倒计时
function My:CompleteCb()
    if self.countDown then
        self.countDown.text = "活动结束"
    end
end

function My:Open( ... )
    if NewActivMgr:ActivIsOpen(2013) == false then
        UITip.Error("活动未开启");
        return ;
    end
    self.go:SetActive(true);
    HotLoveMgr:IsShowRed();
    
end

function My:Close( ... )
    self.go:SetActive(false);
    HotLoveMgr:IsShowRed();
end

--清空计时器
function My:ClearTimer()
	if self.timer then
		self.timer:Stop()
		self.timer:AutoToPool()
		self.timer = nil
	end
end

--清理缓存
function My:Clear()
    self:ClearTimer()
    ListTool.ClearToPool(self.itList)
    ListTool.ClearToPool(self.condList)
end

function My:Dispose()
    self:Clear()
    
    
end

return My;