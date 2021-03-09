require("UI/PracticeSec/Prac/PracMisIt")
PracMission = Super:New{Name = "PracMission"}

local My = PracMission

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local TF = TransTool.Find
	local US = UITool.SetLsnrSelf
	local TFC = TransTool.FindChild

	self.go = root.gameObject
	self.grid = CG(UIGrid,root,"ScrollView/Grid",des)
	self.prefab = TFC(root,"ScrollView/Grid/mIt",des)
	self.prefab:SetActive(false)
	
    self.itemTab = {}
    self:RefreshData()

	self:SetLnsr("Add")
end

function My:SetLnsr(func)
    PracSecMgr.ePracMisInfo[func](PracSecMgr.ePracMisInfo, self.RefreshData, self)
    PracSecMgr.ePracMisGotRew[func](PracSecMgr.ePracMisGotRew, self.RefreshData, self)
    PracSecMgr.ePracMisChange[func](PracSecMgr.ePracMisChange, self.RefreshData, self)
end


--更新显示
function My:UpShow(state)
	self.go:SetActive(state)
 end

 function My:RefreshData()
    local data = PracSecMgr.pracInfoTab.missionTab
    local len = #data
    local itemTab = self.itemTab
    local count = #itemTab
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            itemTab[i]:UpdateData(data[i])
            itemTab[i]:SetActive(true)
        elseif i <= count then
            itemTab[i]:SetActive(false)
		else
            local go = Instantiate(self.prefab)
            TransTool.AddChild(self.grid.transform,go.transform)
            local item = ObjPool.Get(PracMisIt)
            item:Init(go)
            item:SetActive(true)
            item:UpdateData(data[i])
            table.insert(self.itemTab,item)
        end
    end
    self.grid:Reposition()
end

function My:Dispose()
	self:SetLnsr("Remove")
	TableTool.ClearListToPool(self.itemTab)
end

return My
