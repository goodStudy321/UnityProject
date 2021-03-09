OccupyInfo = Super:New{Name = "OccupyInfo"}

local M = OccupyInfo

function M:Ctor()
    self.pointList = {}
    self.posList = {}
end

function M:Init(root)
    local G = ComTool.Get
    local F = TransTool.Find
    local FC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self.root = root

    local scoreInfo = F(root, "ScoreInfo")
    self.labTimer = G(UILabel, scoreInfo, "Timer")
    self.greenName = G(UILabel, scoreInfo, "FamilyA")
    self.greenCount = G(UILabel, scoreInfo, "OccupyNumA")
    self.redName = G(UILabel, scoreInfo, "FamilyB")
    self.redCount = G(UILabel, scoreInfo, "OccupyNumB")

    local mapInfo = F(root, "MapInfo")

    for i=1,5 do
        local point = F(mapInfo, tostring(i))
        S(point, self.OnClickPoint, self)
        local sprite = G(UISprite, point, "State")
        local select = FC(point, "Select")
        sprite.spriteName = "none"
        select:SetActive(false)
        local temp = {}
        temp.sprite = sprite
        temp.select = select
        self.pointList[i] = temp
    end

    local points = GameObject.Find("OccupPoint")
    local parent = points.transform
    for i=1,5 do
        local trans = F(parent, "Goal_"..i)
        local pos = trans.position
        self.posList[i] = pos
    end
end

function M:OnClickPoint(go)
    local index = tonumber(go.name)
    local list = self.pointList
    for i=1,#list do
        list[i].select:SetActive(i==index)
    end
    self.selectIndex = index
    MapHelper.instance:TryMoveToNewPos2(self.posList[index], -1)
end

function M:StartNav()
    if self.selectIndex then
        MapHelper.instance:TryMoveToNewPos2(self.posList[self.selectIndex], -1)
    end
end

function M:InitInfo()
    self:ScreenChange(ScreenMgr.orient)

    local mgr = FamilyWarMgr
    local data = mgr:GetGreenCampData()
    self:UpdateGreenName(data.familyName)
    self:UpdateGreenCount(data.occupyCount)


    data = mgr:GetRedCampData()
    self:UpdateRedName(data.familyName)
    self:UpdateRedCount(data.occupyCount)

    self:UpdateMapInfo()

    self:CreateTimer()
end

function M:ScreenChange(orient)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, nil, nil, true)
	elseif orient == ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.root, nil, nil, true, true)
	end
end

function M:UpdateOccupy()
    local mgr = FamilyWarMgr
    local data = mgr:GetGreenCampData()
    self:UpdateGreenCount(data.occupyCount)
    data = mgr:GetRedCampData()
    self:UpdateRedCount(data.occupyCount)
end

function M:UpdateMapInfo()
    local green = FamilyWarMgr:GetGreenCampData()
    local list1 = green.occupyList
    local red = FamilyWarMgr:GetRedCampData()
    local list2 = red.occupyList

    local list = self.pointList
    for i=1,#list do
        local sprite = list[i].sprite
        if TableTool.Contains(list1, i) ~= -1 then
            sprite.spriteName = "bhz_map_"..FamilyWarMgr.Green
        elseif TableTool.Contains(list2, i) ~= -1 then
            sprite.spriteName = "bhz_map_"..FamilyWarMgr.Red
        else
            sprite.spriteName = "none"
        end
    end
end

function M:UpdateGreenName(name)
    self.greenName.text = name
end

function M:UpdateRedName(name)
    self.redName.text = name
end

function M:UpdateGreenCount(count)
    self.greenCount.text = string.format("[99886b]占领：[-] [66c34e]%d[-]",count)
end

function M:UpdateRedCount(count)
    self.redCount.text = string.format("[99886b]占领：[-] [f39800]%d[-]",count)
end

function M:CreateTimer()
    local seconds = FamilyWarMgr:GetRemainTime()
    if seconds <= 0 then 
        self:CompleteCb()
        return 
    end
    if not self.timer then
        self.timer = ObjPool.Get(DateTimer)
    end
    local timer = self.timer
    timer.seconds = seconds
    timer.fmtOp = 3
    timer.apdOp = 1
    timer.invlCb:Add(self.TimerCb, self)
    timer.complete:Add(self.CompleteCb, self)
    timer:Start()
    self:TimerCb()
end

function M:TimerCb()
    self.labTimer.text = string.format("[f4ddbd]剩余时间[-]  [f21919]%s[-]", self.timer.remain)
end

function M:CompleteCb()
    self.labTimer.text = "已结束"
end

function M:Dispose()
    TableTool.ClearUserData(self)
    if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
    end
    TableTool.ClearDic(self.pointList)
    TableTool.ClearDic(self.posList)
    self.selectIndex = nil
end

return M