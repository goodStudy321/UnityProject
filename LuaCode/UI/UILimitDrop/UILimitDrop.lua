--[[
    情缘活动-限时掉落活动
]]

UILimitDrop = Super:New{Name = "UILimitDrop"};
local My = UILimitDrop;

function My:Init(go)

    local G = ComTool.Get
    local FC = TransTool.FindChild
    local trans = go.transform
    local SetB = UITool.SetBtnClick

    self.go = go
    self.go:SetActive(false);
    self.img = G(UITexture, trans, "Img")
    self.des2 = G(UILabel, trans, "Des2")
    self.grid = G(UIGrid, self.des2.transform, "ItemRoot/Grid")
    self.countDown = G(UILabel, trans, "Countdown")

    self.des2.spacingY = 10

    self.cellList = {};
    self:TimeInit();
    self:UpdateDes();
    self:InitDropList();
end

function My:InitDropList()
    local data = GlobalTemp["198"].Value3;
    local list = self.cellList;
    if data then
        local cell = ObjPool.Get(UIItemCell)
        cell:InitLoadPool(self.grid.transform)
        cell:UpData(data)
        table.insert(list, cell)
    end
    self.grid:Reposition()
end


function My:UpdateDes()
    local data = NewActivMgr:GetActivInfo(2014);
    if not data then return end
    local DateTime = System.DateTime;
    local startTime = DateTime.Parse(tostring(DateTool.GetDate(data.startTime))):ToString("MM月dd日HH:mm");
    local endTime = DateTime.Parse(tostring(DateTool.GetDate(data.endTime))):ToString("MM月dd日HH:mm");
    local str = InvestDesCfg["2019"].des;
    self.des2.gameObject:SetActive(true);
    self.des2.text = string.format("[581f2a]活动时间：%s - %s\n%s", startTime, endTime, str);
end


--活动时间
function My:TimeInit()
    local data = NewActivMgr:GetActivInfo(2014);
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
    if NewActivMgr:ActivIsOpen(2014) == false then return end
    self.go:SetActive(true);
end

function My:Close( ... )
    self.go:SetActive(false);
end

function My:Dispose()
    if self.timer then
        ObjPool.Add(self.timer);
    end
    self.timer = nil;
    TableTool.ClearListToPool(self.cellList);
    TableTool.ClearUserData(self);
end


return My;