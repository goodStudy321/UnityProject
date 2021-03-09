SPSuitInfo = Super:New{Name = "SPSuitInfo"}
require("UI/Robbery/SpiritG/SPSuitCell")

local My = SPSuitInfo

function My:Ctor()
    self.cellList = {}
end

function My:Init(go)
    local trans = go.transform
    local G = ComTool.Get
    local FC = TransTool.FindChild
    local F = TransTool.Find
    local S = UITool.SetLsnrSelf

    self.go = go
    self.btnClose = FC(trans, "btnClose")
    self.grid = G(UIGrid,trans,"scrollV/grid")
    self.prefab = FC(trans,"scrollV/grid/prefab")
    self.prefab:SetActive(false)
    S(self.btnClose, self.Close, self)
end

function My:UpdateData(data)
    self.data = data
    self:UpdateItem()
end

function My:UpdateItem()
    local data = self.data
    local len = #self.data
    local list = self.cellList
    local count = #list
    local max = count >= len and count or len
    local min = count + len - max
    local equipIndex = 0 --已经装备的数量
    local suitIndex = 0 --不同套装的数量
    for i=1, max do
        if i <= min then
            list[i]:SetActive(true)
            local id = data[i]
            id = tostring(id)
            local suitInfo = SpiritSuitCfg[id]
            equipIndex,suitIndex = SpiritGMgr:GetEquipNumAndSuitNum(suitInfo)
            list[i]:UpdateData(suitInfo,equipIndex,suitIndex)
        elseif i <= count then
            list[i]:SetActive(false)
        else
            local go = Instantiate(self.prefab)
            local c = go.transform
            local item = ObjPool.Get(SPSuitCell)
            item:Init(go)
            TransTool.AddChild(self.grid.transform, c)
            item:SetActive(true)
            local id = data[i]
            id = tostring(id)
            local suitInfo = SpiritSuitCfg[id]
            equipIndex,suitIndex = SpiritGMgr:GetEquipNumAndSuitNum(suitInfo)
            item:UpdateData(suitInfo,equipIndex,suitIndex)
            table.insert(list, item)
        end
    end
    self.grid:Reposition()
end

function My:UpdateBase()
    self:CreateSB()
    local sb = self.sb
    local data =  SpiritGMgr:GetEquipBaseAttr(self.data,1)
    local len = #data
    for i=1, len do
        local arg = ""
        arg = string.format("[99886BFF]%s  %d", PropName[data[i].k].name, data[i].v)
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.base.text = str
end

function My:CreateSB()
    if not self.sb then
        self.sb = ObjPool.Get(StrBuffer)
    end
    self.sb:Dispose()
end

function My:UpdateBest()
    self:CreateSB()
    local sb = self.sb
    local data = self.data.attrList
    local len = #data
    for i=1, len do
        local cfg = PropName[data[i].id]
        local str = cfg.show == 1 and string.format("%d%%", data[i].val*0.01) or data[i].val
        local color = "[008ffc]"
        if i<= self.data.purpleNum then
            color = "[b03df2]"
        end
        local arg = string.format("%s%s  %s", color , cfg.name, str)
        sb:Apd(arg)
        if i<len then
            sb:Line()
        end
    end
    local str = sb:ToStr()
    self.best.text = str
end

function My:SetActive(state)
    self.go.gameObject:SetActive(state)
end

function My:Open(data)
    self:UpdateData(data)
    self:SetActive(true)
end

function My:Close()
    self:SetActive(false)
end

--将item放入对象池
function My:ItemToPool()
    local items = self.cellList
	if items then
		local len = #items
		while len > 0 do
			local cell = items[len]
			if cell then
				cell:Dispose()
				table.remove(items, len)
				ObjPool.Add(cell)
			end
			len = #items
		end
	end
end

function My:Dispose()
    self:ItemToPool()
    TableTool.ClearUserData(self)
end

return My