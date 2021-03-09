OccupyPoint = Super:New{Name = "OccupyPoint"}

local M = OccupyPoint

function M:Ctor()
    self.redEffList = {}
    self.greenEffList = {}
end

function M:Init()
    local FG = TransTool.FindChild

    local camp1 = GameObject.Find("Camp_1")
    local trans = camp1.transform

    for i=0,4 do
        local t = trans:GetChild(i)
        t.name = i+1
        t.gameObject:SetActive(false)
        table.insert(self.greenEffList, t.gameObject)
    end

    local camp2 = GameObject.Find("Camp_2")
    local trans = camp2.transform
    for i=0,4 do
        local t = trans:GetChild(i)
        t.name = i+1
        t.gameObject:SetActive(false)
        table.insert(self.redEffList, t.gameObject)
    end

    self.greenEffList[5].transform.position = Vector3(-4.15, 0, 6.63)
    self.redEffList[5].transform.position =  Vector3(-4.15, 0, 6.63)
    self.greenEffList[4].transform.position = Vector3(-45.6,0,-37)
    self.redEffList[4].transform.position = Vector3(-45.6,0,-37)
    self.greenEffList[3].transform.position = Vector3(44.87, 0, -36.8)
    self.redEffList[3].transform.position =Vector3(44.87, 0, -36.8)
    self.greenEffList[2].transform.position = Vector3(44.01, 0, 47.54)
    self.redEffList[2].transform.position =Vector3(44.01, 0, 47.54)
    self.greenEffList[1].transform.position = Vector3(-47.38, 0, 48.69)
    self.redEffList[1].transform.position = Vector3(-47.38, 0, 48.69)
end

function M:InitEff()
    local m = FamilyWarMgr
    local data = m:GetGreenCampData()
    local occupyList = data.occupyList
    local list = self.greenEffList
    for i=1,#occupyList do
        local index = occupyList[i]
        if list[index] then
            list[index]:SetActive(true)
        end
    end

    
    local _data = m:GetRedCampData()
    local _occupyList = _data.occupyList
    local _list = self.redEffList
    for i=1,#_occupyList do
        local index = _occupyList[i]
        if _list[index] then
            _list[index]:SetActive(true)
        end
    end
end

function M:UpdateEff(camp, index)
    if not self.redEffList[index] then return end
    if not self.greenEffList[index] then return end
    if camp == 3 then
        self.redEffList[index]:SetActive(false)
        self.greenEffList[index]:SetActive(false)
    else
        local state = camp == tonumber(FamilyWarMgr.Green)
        self.redEffList[index]:SetActive(not state)
        self.greenEffList[index]:SetActive(state)
    end
end


function M:Dispose()
    TableTool.ClearDic(self.redEffList)
    TableTool.ClearDic(self.greenEffList)
end

return M