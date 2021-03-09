UISkyMysterySealPreviewView = {}

local M = UISkyMysterySealPreviewView

function M:New(go, parent)
    self.Root = go
    self.Parent = parent
    local trans = go.transform
	local C = ComTool.Get
    local T = TransTool.FindChild
    local name = "UISkyMysterySealPreviewView"
    self.ScoreLab = C(UILabel, trans, "Score", name, false)
    self.SV = C(UIScrollView, trans, "ScrollView", name, false)
    self.Panel = C(UIPanel, trans, "ScrollView", name, false)
    self.Grid = C(UIGrid, trans, "ScrollView/Grid", name, false)
    self.Prefab = T(trans, "ScrollView/Grid/Item")
    self.Toggles = {}
    for i=1,30 do
        self:AddToggle(i)
    end
    self.SSV = C(UIScrollView, trans, "ProsSV", name, false)
    self.SPanel = C(UIPanel, trans, "ProsSV", name, false)
    self.Suits = {}
    for i=1,10 do
        local info = ObjPool.Get(UISkyMysterySealSuitItem)
        info:Init(T(trans,string.format("ProsSV/Root/%s", i)))
        table.insert(self.Suits, info)
    end
    self.SPanelPos = self.SPanel.transform.localPosition
    self.Score = 0
    return self
end

function M:AddToggle(index)
    local info = {}
    local go = GameObject.Instantiate(self.Prefab)
    info.Root = go
	go.name = tostring(index)
	go.transform.parent = self.Grid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale = Vector3.one
    local C = ComTool.Get
    local trans = go.transform
    local name = "PreviewView"
    info.Toggle = go:GetComponent("UIToggle")
    info.Name = C(UILabel, trans, "Name", name, false)
    info.Rate = C(UILabel, trans, "Rate", name, false)
    table.insert(self.Toggles, info)
    UITool.SetLsnrSelf(info.Root, self.OnClickToggleBtn, self)
    self.CurSelect = nil
end

-----------------------------------------------------
function M:UpdateData()
    self:UpdateToggles()
    self:UpdateScore()
    if self.CurSelect == nil then
        local item = self.Toggles[1]
        if item then 
             item.Toggle:Set(true, true, false)
            self:OnClickToggleBtn(item.Root)
        end
    else
        self:OnClickToggleBtn(self.CurSelect.Root)
    end
end

function M:UpdateToggles()
    local indexs = SMSMgr.SuitIndex
    local infos = SMSMgr.SuitInfos
    local len = #indexs
	if len > 1 then
		table.sort(indexs,function(a, b) return a > b end)
	end
    for i=1,len do
        local info = infos[tostring(indexs[i])]
        if info and #info > 0 then
            self:UpdateToggle(i, info)
        end
    end
    if self.SSV then
        self.SSV.isDrag = len >= 8
    end
end

function M:UpdateScore()
    self.ScoreLab.text = tostring(math.floor(self.Score))
end

function M:UpdateToggle(index, info)
    local toggles = self.Toggles
    if #toggles < index then 
        local prefab = toggles[1].Root
        local go = GameObject.Instantiate(prefab)
        go.name = tostring(index)
        go.transform.parent = self.Grid.transform
        local item = ObjPool.Get(UISkyMysterySealSuitItem)
        item:Init(go)
        table.insert(self.Suits, item)
    end
    local limit = #info
    if limit > 1 then table.sort(info, function(a,b) return a<b end)  end
    local temp = SMSSuitProTemp[tostring(info[limit])]
    if not temp then return end
    local status, aNum = SMSMgr:GetSuitActiveStatusAllType(temp, temp.num)
    toggles[index].Name.text = string.format("%s%s[-]", UIMisc.LabColor(temp.quality), temp.name)
    toggles[index].Rate.text = string.format("【%s/%s】", aNum, temp.num)
    toggles[index].Root:SetActive(true)
    toggles[index].Info = info
    toggles[index].Temp = temp
end

function M:UpdateSuit(index)
    self:ResetSuits()
    local toggles = self.Toggles
    if #toggles < index then return nil end
    local info = toggles[index].Info
    if not info then 
        return nil
    end
    local len = #info
    if #self.Suits >= len then
		table.sort(info,function(a, b) return SMSMgr:SuitProSort(a, b) end)
        local pos = Vector3.zero
        for i=1,len do
            local item = self.Suits[i]
            item:UpdateID(info[i])
            item:UpdatePos(pos)
            pos.y = pos.y - item.Height - 50
            self.Score = self.Score + item.Score
        end
        if self.SSV then
            self.SSV.isDrag = math.abs(pos.y) > 484
        end
    end
    self:ResetSuitsPos()
    return info
end
-----------------------------------------------------
function M:OnClickToggleBtn(go)
    self.Score = 0
    local index = tonumber(go.name)
    self.CurSelect = self.Toggles[index]
    local info = self:UpdateSuit(index)
    self:UpdateScore()
    if not info then return end
    SMSControl:ShowPreview(info)
end
-----------------------------------------------------

function M:Reset()
    self.Score = 0
    self:ResetToggles()
    self:ResetSuits()
end

function M:ResetToggles()
    local toggles = self.Toggles
    if not toggles then return end
    local len = #toggles
    if len > 0 then
        for i=1,len do
            local info = toggles[i]
            if info and info.Root and info.Root.activeSelf == true then
                info.Name.text = ""
                info.Rate.text = ""
                info.Root:SetActive(false)
            end
        end
    end
end

function M:ResetSuits()
    local suits = self.Suits
    if not suits then return end
    local len = #suits
    if len > 0 then
        for i=1,len do
            local info = suits[i]
            if info then
                info:SetActive(false)
                info:Reset()
            end
        end
    end
    self:ResetSuitsPos()
end

function M:ResetSuitsPos()
    local panel = self.SPanel
    if panel then
        panel.gameObject:SetActive(false)
        panel.transform.localPosition = self.SPanelPos
        panel.clipOffset = Vector3.zero
        panel.gameObject:SetActive(true)
    end
end

function M:DestroyToggles()
    local toggles = self.Toggles
    if not toggles then return end
    local len = #toggles
    while len > 0 do
        local info = toggles[len]
        table.remove(toggles, len)
        TableTool.ClearDic(info)
        info = nil
        len = #toggles
    end
end

function M:DestroySuits()
    self:ResetSuitsPos()
    local suits = self.Suits
    if not suits then return end
    local len = #suits
    while len > 0 do
        local info = suits[len]
        table.remove(suits, len)
        info:Dispose()
        TableTool.ClearDic(info)
        len = #suits
    end
end

function M:Dispose()
    self:DestroyToggles()
    self:DestroySuits()
end

return M