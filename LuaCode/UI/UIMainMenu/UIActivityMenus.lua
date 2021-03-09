UIActivityMenus = {}

local M = UIActivityMenus
local aMgr = ActivityMgr
local aTemp = ActivityTemp

M.eAddItem = nil
M.eRemoveItem= nil
M.MenuTips = nil
M.eClickItem = nil
M.eUpdateAction = nil

function M:Init()
	self.OnClickMenuTipAction = EventHandler(self.ClickMenuTipAction, self)
    return self
end

function M:AddEvent()
    
    if self.MenuTips then
        self.MenuTips.enabled = true
     end
    EventMgr.Add("ClickMenuTipAction", self.OnClickMenuTipAction)
end

function M:RemoveEvent()
    self.MenuTips = nil
    EventMgr.Remove("ClickMenuTipAction", self.OnClickMenuTipAction)
end

function M:AddItem(t)
	local k = tostring(t.layer)
	local temp = ActivityTemp[k]
	if not temp then return end
    if self.eAddItem then
        self.eAddItem(temp) 
    end
	if self.MenuTips then  
		aMgr:UpdateMenus(self.MenuTips)
	end
end

function M:RemoveItem(t)
    --local k = tostring(t.layer)
    --[[
	local tempList = aMgr.Info[tostring(t.layer)]
	local value, index = nil, -1
	if tempList then
		value,index = BinTool.FindProName(tempList, t.id, "id")
	end
	if value then
		table.remove(tempList, index)
	end
	if #tempList == 0 then
        local temp = ActivityTemp[tostring(t.layer)]
        if self.eRemoveItem then
            self.eRemoveItem(temp, index)
        end
    end
    ]]--
	if self.MenuTips then  
		aMgr:UpdateMenus(self.MenuTips)
	end
end

function M:UpdateAction(type, isAdd)
    if not self.MenuTips then return end
	local list = aMgr.Info[tostring(aMgr.CDGN)]
	if list then
		for i,v in ipairs(list) do
			if v.type == type then
                self.MenuTips:UpdateAction(i - 1, isAdd)
			end
		end
	end
    if self.eUpdateAction then self.eUpdateAction(aMgr.CDGN, self:GetActivity()) end
end

function M:ClickMenuTipAction(name, tt, str, index)
    if tt ~= MenuType.ActivityBtn then return end
	local list = aMgr.Info[tostring(aMgr.CDGN)]
	if list then
		local temp = list[index + 1]
		if temp and self.eClickItem then
			self.eClickItem(temp.type)
		end
	end
end

function M:GetActivity()
	local list = aMgr.Info[tostring(aMgr.CDGN)]
    if list then
        for i,v in ipairs(list) do
            if SystemMgr:GetActivity(v.type) == true then
                return true
            end
        end
    end
    return false
end

function M:Clear()
    self:RemoveEvent()
end

function M:Dispose()
    TableTool.ClearUserData(self)
end

return M