--[[
    功能预览
]]
require("UI/UIActPreview/FuncPreItem")
UIFuncPre = Super:New{Name = "UIFuncPre"}
local M = UIFuncPre

local GI = GameObject.Instantiate
local AC = TransTool.AddChild
local min = 3 --一个界面所占几个Item

function M:Init(obj,data)
    self.obj = obj
    local trans = self.obj.transform
    local US = UITool.SetBtnClick
    local T = TransTool.FindChild
    local C =ComTool.Get
    self.sv = C(UIScrollView,trans,"sv",self.Name)
    self.grid = C(UIGrid,trans,"sv/grid",self.Name)
    self.pal = C(UIPanel,trans,"sv",self.Name)
    -- self.item = T(self.grid.transform,"UIFuncOpenItem")
    -- self.item:SetActive(false)
    self.svObj = T(trans,"sv")
    self.pos = self.svObj.transform.localPosition
    self.palPos = self.pal.clipOffset
    self.items = {}
    US(trans,"left",self.Name,self.ClickToUp,self)
    US(trans,"right",self.Name,self.ClickToDown,self)
    self:SetLsner("Add")
    self.gridX = self.grid.cellWidth
    self.svX = -885
    self:ShowData()
end

function M:SetLsner(key)
    ActPreviewMgr.eShowData[key](ActPreviewMgr.eShowData, self.SetPos, self)
end

function M:Open()
    self.obj.gameObject:SetActive(true)
end

function M:Close()
    self.obj.gameObject:SetActive(false)
end

function M:ClickToUp()
    local lerp = self:GetLerp()
    local trans = self.svObj.transform
    local palPos = self.pal.clipOffset
    local pos = trans.localPosition
    if pos.x + lerp > self.pos.x then return end
    trans.localPosition = pos + Vector3(lerp,0,0)
    self.pal.clipOffset = palPos - Vector2(lerp,0)
end

function M:ClickToDown()
    local lerp = self:GetLerp()
    local trans = self.svObj.transform
    local pos = trans.localPosition
    local palPos = self.pal.clipOffset
    local num = #self.items
    local long = self.pos.x - (num -3)*self.gridX
    if pos.x - lerp < long then return end
    if lerp == self.gridX then
        trans.localPosition = pos - Vector3(self.gridX,0,0)
        self.pal.clipOffset = palPos + Vector2(self.gridX,0)
        return
    end
    trans.localPosition = pos - Vector3(self.gridX - lerp,0,0)
    self.pal.clipOffset = palPos + Vector2(self.gridX - lerp,0)
end

function M:GetLerp()
    local curSvX = self.svObj.transform.localPosition.x
    local lerp = self.svX - curSvX
    local curLerp = math.floor(lerp % self.gridX)
    if curLerp == 0 then curLerp = self.gridX end
    return curLerp
end

function M:ShowData()
    local info = ActPreviewMgr:GetfuncList()
    local num = #info
    if not info or num <= 0 then return end
    self:ReNewItemNum(num,info)
    -- self:SetPos()
    self:OpenSetPos()
end

function M:UpdateBtn()
    local info = ActPreviewMgr:GetfuncList()
    local num = #info
    for i=1,num do
        self.items[i]:InitItem(info[i])
    end
end

function M:SetPos()
    local info = ActPreviewMgr:GetfuncList()
    local num = #info
    local openList = ActPreviewMgr:GetOpenList()
    local getList = ActPreviewMgr:GetAwardList()
    local index = 0
    local idx = 0
    if getList == nil then return end
    if not openList or not getList or #openList == #getList then return end
    self.svX = self.svObj.transform.localPosition.x
    for i,v in ipairs(openList) do
        if getList[i] and v.lv ~= getList[i].lv then
            index = i
            break
        end
    end
    if index == 0 then index = #getList + 1 end
    if num <= min then return end
    local trans = self.svObj.transform
    local pos = self.pos
    local palPos = self.palPos
    if index > num - min + 1 or index == num then
        local lerp = num - 3
        trans.localPosition = pos - Vector3(self.gridX*lerp,0,0)
        self.pal.clipOffset = palPos + Vector2(self.gridX*lerp,0)
    else
        if not openList[index] then return end
        local data = openList[index]
        for i,v in ipairs(info) do
            if v.level == data.lv and v.id == data.id then
                idx = i - 1
                break
            end
        end
        trans.localPosition = pos - Vector3(self.gridX*idx,0,0)
        self.pal.clipOffset = palPos + Vector2(self.gridX*idx,0)
    end
end

function M:OpenSetPos()
    local info = ActPreviewMgr:GetfuncList()
    local num = #info
    local openList = ActPreviewMgr:GetOpenList()
    local openNum = #openList
    local openIndex = openNum + 1
    local trans = self.svObj.transform
    local pos = self.pos
    local palPos = self.palPos
    openIndex = openIndex >= num and num or openIndex
    openIndex = openIndex - min
    openIndex = openIndex <= 0 and 0 or openIndex
    trans.localPosition = pos - Vector3(self.gridX*openIndex,0,0)
    self.pal.clipOffset = palPos + Vector2(self.gridX*openIndex,0)
end

function M:ReNewItemNum(num,info)
    for i=1,num do
        local cell = ObjPool.Get(FuncPreItem)
        cell:InitLoadPool(self.grid.transform)
        cell:InitItem(info[i])
        self.items[#self.items + 1] = cell
    end
    self.grid:Reposition()
    self.sv:ResetPosition()
end

function M:Dispose()
    self:SetLsner("Remove")
    TableTool.ClearDicToPool(self.items)
    self.items = nil
    self.svX = 0
end

return M