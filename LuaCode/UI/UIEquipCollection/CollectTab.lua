--[[
左边标签页
]]
require("UI/UIEquipCollection/CollectSelect")

CollectTab=Super:New{Name="CollectTab"}
local My = CollectTab

function My:Init(go)
    if not self.dic then self.dic={} end
    local trans = go.transform
    local CG = ComTool.Get
    local TF = TransTool.FindChild
    self.grid=CG(UIGrid,trans,"Grid",self.Name,false)
    self.grid.onCustomSort=self.SortName
    self.pre=TF(trans,"Grid/Pre",self.Name,false)
end

function My.SortName(a,b)
    local num1 = tonumber(a.name)
	local num2 = tonumber(b.name)
	if(num1<num2)then
		return -1
	elseif (num1>num2)then
		return 1
	else
		return 0
	end
end

function My:UpData()
    local min = nil
    for k,v in pairs(EquipCollData) do
        local isred = EquipCollectionMgr.redDic[k] or false
        local rank = v.rank
        local cell = self.dic[k]
        if not cell then
            if not min or min>tonumber(k) then
                min=tonumber(k)
            end
            local go=GameObject.Instantiate(self.pre)
            go:SetActive(true)
            go.name=k
            local trans = go.transform
            trans.parent=self.grid.transform
            trans.localPosition = Vector3.zero
            trans.localScale=Vector3.one
            local cell = ObjPool.Get(CollectSelect)
            cell.id=k
            cell:Init(go)
            cell:ShowLab(UIMisc.NumToStr(rank,"阶"))
            cell:ShowRed(isred)
            self.dic[k]=cell
        end
    end
    self.grid:Reposition()
    local minCell = self.dic[tostring(min)]
    minCell:OnClick()
end

function My:ShowRed()
    for k,cell in pairs(self.dic) do
        local isred = EquipCollectionMgr.redDic[k] or false
        cell:ShowRed(isred)
    end
end

function My:Dispose()
    TableTool.ClearDicToPool(self.dic)
end