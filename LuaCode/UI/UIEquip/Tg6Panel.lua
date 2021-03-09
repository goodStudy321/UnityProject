--[[
 	authors 	:Liu
 	date    	:2019-3-1 16:35:00
 	descrition 	:铸魂装备列表
--]]

Tg6Panel = EquipPanelBase:New{Name = "Tg6Panel"}

local My = Tg6Panel

local AssetMgr=Loong.Game.AssetMgr

function My:InitData()
    local CG = ComTool.Get
    local root = UIEquip.root
    self.grid = CG(UIGrid, root, "tg6/right/Panel/Grid")

    self.cDic = {}

    self:InitEquip()
    self:SetEvent("Add")
end

function My:SetEvent(func)
    RoleAssets.eUpAsset[func](RoleAssets.eUpAsset, self.UpState, self)
    -- EquipMgr.eForgeSoul[func](EquipMgr.eForgeSoul, self.UpState, self)
    UIEquipCell.eClick[func](UIEquipCell.eClick, self.ClickCell, self)
end

--更新状态
function My:UpState()
    self:ShowTip()
    self:ShowRed()
end

--点击装备
function My:ClickCell(part)
    for k,v in pairs(self.cDic) do
		v:UpBg(false)
    end
    local it = self.cDic[part]
    if it then
        it:UpBg(true)
    end
end

--文字内容
function My:ShowPartTip(part)
    self:UpPartLab(part)
end

--红点
function My:ShowPartRed(part)
    local it = self.cDic[part]
    if it == nil then return end
    self:UpAction(part, it.red)
end

--初始化装备
function My:InitEquip()
	local list = EquipMgr.hasEquipDic
	if list == nil then return end
	for k,v in pairs(list) do
		self:AddEquip(k)
	end
end

--添加装备
function My:AddEquip(part)
	local del = ObjPool.Get(DelGbj)
	del:Adds(part)
	del:SetFunc(self.LoadEquip,self)
	AssetMgr.LoadPrefab("EquipCell",GbjHandler(del.Execute,del))
end

--加载装备
function My:LoadEquip(go, part)
    self.go = go
    local Add = TransTool.AddChild
    Add(self.grid.transform, go.transform)

	local cell = ObjPool.Get(UIEquipCell)
	cell:Init(go)
    cell:UpData(part)
    self.cDic[part] = cell

    self:UpSort(part)
end

--更新部位装备文本
function My:UpPartLab(part)
	local tb = EquipMgr.hasEquipDic[part]
    if tb == nil then return end
    local item = ItemData[tostring(tb.type_id)]
    if item == nil then return end
    local class = EquipMgr:GetClassFromPart(part)
    if class == nil then return end
    local color = UIMisc.LabColor(item.quality)
    local lv = ""
    local str1 = ""
    local temp1, temp2 = 1, 1
    if class < 7 then
        lv = "[F21919FF]7阶装备可铸魂"
    else
        for i,v in ipairs(ZHTowerPartOpen) do
            if v.part == tonumber(part) then
                local id = EquipMgr:GetId(part)
                local cfg, index = BinTool.Find(CastingSoulCfg, id)
                if cfg == nil then
                    str1 = string.format("[F4DDBDFF]%s阶(Lv.%s)", 1, 0)
                else
                    temp1, temp2 = EquipMgr:GetClass(cfg)
                    str1 = string.format("[F4DDBDFF]%s阶(Lv.%s)", temp1, temp2)
                end
                local str2 = string.format("[F21919FF]通过镇魂塔%s层开启", v.copyId-50000)
                lv = (CopyMgr:IsFinishCopy(v.copyId, false)) and str1 or str2
                break
            end
        end
    end
    local str = string.format("%s%s\n%s", color, item.name, lv)
    self.cDic[part].NameLab.text = str
    self.cDic[part].Grid:SetActive(false)
    --self.cDic[part].maxLv.gameObject:SetActive(false)
end

--更新红点
function My:UpAction(part, go)
    local dic = EquipMgr.red5Dic
    go:SetActive(dic[part])
end

--更新排序
function My:UpSort(part)
    local name = (EquipMgr:IsCasting(part)) and tonumber(part) + 100 or tonumber(part) + 500
    self.go.name = name
    self.grid:Reposition()
end

return My