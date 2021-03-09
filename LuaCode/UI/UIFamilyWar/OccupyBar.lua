OccupyBar = Super:New{Name = "OccupyBar"}

local M = OccupyBar

function M:Init(root)
    self.eUpdatePoint = Event()
    self.max = 10000
    self.isStart = false
    local G =   ComTool.Get
    self.go = root.gameObject
    self.greenBar = G(UISprite, root, "GreenBar")
    self.redBar = G(UISprite, root, "RedBar")    
end

function M:UpdateTrend()
    local mgr = FamilyWarMgr
    local data = mgr:GetGreenCampData()
    self:UpdateGreenData(data.occupyScore, data.trend, data.change)
    -- iTrace.eError("阵营1", "camp:"..data.camp..",我算的当前秒的分数："..self.curGreenValue.. ",服务器发的当前秒的分数:".. data.occupyScore .. ",change:"..data.change..",trend:".. data.trend..",nextGreenScore:"..self.nextGreenScore)

    data = mgr:GetRedCampData()
    self:UpdateRedData(data.occupyScore, data.trend, data.change)
    -- iTrace.eError("阵营2", "camp:"..data.camp..",我算的当前秒的分数："..self.curRedValue  .. ",服务器发的当前秒的分数:".. data.occupyScore.. ",change:"..data.change..",trend:".. data.trend..",nextRedScore:"..self.nextRedScore)
end

function M:UpdateGreenData(score, trend, change)
    self.curGreenValue = score
    if trend == 1 then
        self.nextGreenScore = self.curGreenValue + change
        if self.nextGreenScore > self.max then
            self.nextGreenScore = self.max
        end
    else
        self.nextGreenScore = self.curGreenValue - change
    end
    self.greenChange = change
    self.greenTrend = trend
end

function M:UpdateRedData(score, trend, change)
    self.curRedValue = score
    if trend == 1 then
        self.nextRedScore = self.curRedValue + change
        if self.nextRedScore > self.max then
            self.nextRedScore = self.max
        end
    else
        self.nextRedScore = self.curRedValue - change
    end
    self.redChange = change
    self.redTrend = trend
end

function M:SetActive(bool)
    self.go:SetActive(bool)

    if bool then
        local mgr = FamilyWarMgr
        local data = mgr:GetGreenCampData()
        self.curGreenValue = data.occupyScore
        self:UpdateGreenBar(self.curGreenValue)
        self:UpdateGreenData(0, 0, 0)


        data = mgr:GetRedCampData()
        self.curRedValue = data.occupyScore
        self:UpdateRedBar(self.curRedValue)
        self:UpdateRedData(0, 0, 0)

        self.isStart = true
    else
        self.isStart = false
    end
end

function M:Update()
    if not self.isStart then return end

    local greenTemp = self.curGreenValue

    local greenAve = self.greenChange*Time.unscaledDeltaTime
    if self.greenTrend == 1 then
        self.curGreenValue = self.curGreenValue + greenAve
        if self.curGreenValue >= self.nextGreenScore then
            self.curGreenValue = self.nextGreenScore
        end   
    else
        self.curGreenValue = self.curGreenValue - greenAve 
        if self.curGreenValue <= self.nextGreenScore then
            self.curGreenValue = self.nextGreenScore
        end      
    end
    self:UpdateGreenBar(self.curGreenValue)

    local redTemp = self.curRedValue

    redAve = self.redChange*Time.unscaledDeltaTime
    if self.redTrend == 1 then
        self.curRedValue = self.curRedValue + redAve
        if self.curRedValue >= self.nextRedScore then
            self.curRedValue = self.nextRedScore
        end
    else
        self.curRedValue = self.curRedValue - redAve
        if self.curRedValue <= self.nextRedScore then
            self.curRedValue = self.nextRedScore
        end
    end

    self:UpdateRedBar(self.curRedValue)

    local limit = self.max*0.5
    if greenTemp < limit and self.curGreenValue >= limit then
        local camp, curPoint = FamilyWarMgr:CurPointOwner()
        if camp == FamilyWarMgr.Red then
            FamilyWarMgr.eUpdateRegion(3, curPoint)
        end
    elseif redTemp < limit and self.curRedValue >= limit then
        local camp, curPoint = FamilyWarMgr:CurPointOwner()
        if camp == FamilyWarMgr.Green then
            FamilyWarMgr.eUpdateRegion(3, curPoint)
        end
    end
end

function M:UpdateGreenBar(value)
    self.greenBar.fillAmount = value/self.max
end

function M:UpdateRedBar(value)
    self.redBar.fillAmount = value/self.max
end

function M:Dispose()
    TableTool.ClearUserData(self)
    self.max = nil
    self.nextGreenScore = nil
    self.greenChange = nil
    self.greenTrend = nil
    self.curGreenValue = nil
    self.nextRedScore = nil
    self.redChange = nil
    self.redTrend = nil
    self.curRedValue = nil
    self.isStart = nil
end

return M