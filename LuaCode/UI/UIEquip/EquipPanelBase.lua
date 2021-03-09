EquipPanelBase=Super:New{Name="EquipPanelBase"}
local My = EquipPanelBase

function My:Init(panelName)
    self.panelName=panelName
    self:InitData()
    self:SetEvent("Add")
end

function My:UpData()
    self:ShowTip()
    self:ShowRed()
end

function My:SetEvent(fn)
    -- body
end

function My:ShowGrid(state)
    local dic = self.panelName==HnEPanel.Name and HnEPanel.cDic or EquipPanel.cellDic
    for k,v in pairs(dic) do
        v:GridState(state)
    end
end

--文字内容
function My:ShowTip(part)
    if part then self:ShowPartTip(part)
    else
        local dic = EquipPanel.cellDic
        for k,v in pairs(dic) do
            self:ShowPartTip(k)
        end
    end
end

--红点
function My:ShowRed(part)
    if part then self:ShowPartRed(part)
    else
        local dic = EquipPanel.cellDic
        for k,v in pairs(dic) do
            self:ShowPartRed(k)
        end
    end
end

function My:ShowPartTip(part)
    -- body
end

function My:ShowPartRed(part)
    -- body
end

--排序
function My:Sort()
    -- body
end

--初始化数据
function My:InitData()
    -- body
end

function My:Dispose( ... )
    self:SetEvent("Remove")
end
