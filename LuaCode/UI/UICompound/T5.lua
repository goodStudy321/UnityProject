--[[
首饰合成    by：he
--]]
T5 = Super:New{Name = "T5"}
local M = T5

local C=ComTool.Get
local T=TransTool.FindChild
local US=UITool.SetBtnClick
local cellList={}
local lbs ={}

function M:Init(go,tt)
    self.tt = tt
    self.go = go
    local trans = go.transform
    eEquip = ObjPool.Get(EquipPanel)
    self.item1 = T(trans,"left/item1")
    self.item2 = T(trans,"left/item2")
    self.nameLb = C(UILabel,trans,"left/name",self.Name,self)
    self.nameLb.text = ""
    local ka = T(trans,"left/bg/center/ku").transform
    self.cell = ObjPool.Get(UIItemCell)
    self.cell:InitLoadPool(ka,1.4)

    US(trans,"btn",des,self.OnJump,self)
    self.equipGrid = C(UIGrid,trans,"right/Panel/grid")
    
    for i=1,2 do
        local tip = "tip"..i
        local tipObj = T(trans,"left/"..tip).transform
        local labs = {}
        labs.all = T(tipObj,"lab")
        local lab = labs.all.transform
        labs.js = C(UILabel,lab,"jieshu",self.Name,self)
        labs.co = C(UILabel,lab,"color",self.Name,self)
        labs.att = C(UILabel,lab,"att",self.Name,self)
        labs.jia = C(UILabel,lab,"jia",self.Name,self)
        labs.num = C(UILabel,lab,"num",self.Name,self)
        lbs[#lbs + 1] = labs

        local cg = T(trans,"left/".."item"..i)
		local cell=ObjPool.Get(UIItemCell)
		cell:InitLoadPool(cg.transform,0.8,nil,nil,nil,Vector3.New(-10,0,0))
		cellList[i]=cell
    end

    self.cellDic = {}
    self:ShowData()
    self:SetLsner("Add")
end

function M:SetLsner(func)
    UIEquipCell.eClick[func](UIEquipCell.eClick, self.ShowEq, self)
    EquipMgr.eJewelry[func](EquipMgr.eJewelry, self.ShowData, self)
end

function M:OnJump()
    if self.type_id then
        EquipMgr.ReqJewelry(self.type_id)
    end
end

function M:GetQua(qua)
	local color = UIMisc.LabColor(qua)
	local x = UIMisc.GetColorLb(qua)
	return color..x.."[-]"
end

function M:UpGroup(need)
	if need==nil then
		self:SetLock(1,2,1)
    elseif(#need==1)then
		self:Need(2,need[2][1],need[2][2])
		cellList[2]:Lock(0.001)
		cellList[1]:Lock(1)
    else
        for i,v in ipairs(need)do
            if type(v)=="number" then self:Need(i,v,1)
            else self:Need(i,need[i][1],need[i][2]) end
        end
		self:SetLock(1,#need,0.001)
		self:SetLock(#need+1,2,2)
	end	
end

-- 打开关闭进阶信息以及名称
function M:IsOpen(bool)
    for i=1,#lbs do
        lbs[i].all:SetActive(bool)
    end
    self.nameLb.text = ""
    if bool == false then
        self:CleanCell()
        self.cell:Clean()
        self:UpGroup()
    end
end

-- 显示信息
function M:ShowData()
    local num = TableTool.GetDicCount(self.cellDic)
    for i=9,10 do
        part = tostring(i)
        if num ~= 2 then
            self:CreateEquipCell(part)
        end
        local tb = EquipMgr.hasEquipDic[part]
        local cell = self.cellDic[part]
        cell:SetPart(part)
        if i == 9 then
            cell:UpName("进阶部位：戒指\n7阶橙色戒指可进阶")
        else
            cell:UpName("进阶部位：手镯\n7阶橙色手镯可进阶")
        end
        if tb then
            local type_id = tb.type_id
            local itemData = ItemData[tostring(type_id)]
            local qua = UIMisc.LabColor(itemData.quality)
            local pj = EquipBaseTemp[tostring(type_id)].wearRank
            local name = qua..itemData.name.."\n["..pj.."阶]"
            if  itemData.quality >= 4 and pj >= 7  then
                cell:UpData(part)
                cell:UpName(name)
                local JewelryData = JewelryList[tostring(type_id)]
                if not JewelryData then
                    cell:FullState(true)
                else
                    cell:FullState(false)
                    self:HaveAll(type_id)
                end 
            end
        else
            cell.cell:Lock(1)
        end
    end
    if self.part then
        self:ShowEq(self.part)
    end
    self:OnRed()
end

function M:ShowEq(part)
    if self.part and self.part ~= part then
        local cell = self.cellDic[self.part]
        cell:UpBg(false)
    end
    self.part = part
    self.cellDic[self.part]:UpBg(true)
    local tb = EquipMgr.hasEquipDic[part]
    if not tb then
        self:IsOpen(false)
        return
    end
    local type_id = tb.type_id
    self.type_id = type_id
    local JewelryData = JewelryList[tostring(type_id)]
    self:IsOpen(true)
    if not JewelryData then
        self:IsOpen(false)
        return
    end
    self:HaveAll(type_id)
end

function M:CreateEquipCell(part)
    local del = ObjPool.Get(DelGbj)
	del:Adds(part)
	del:SetFunc(self.LoadCb,self)
    LoadPrefab("EquipCell",GbjHandler(del.Execute,del))
    self.equipGrid:Reposition()
end

function M:LoadCb(go,part)
    go:SetActive(true)
    go.transform.parent = self.equipGrid.transform
	go.transform.localScale = Vector3.one
	go.transform.localPosition = Vector3.zero
    local cell =ObjPool.Get(UIEquipCell)
	cell:Init(go)
	self.cellDic[part]=cell
end

-- 显示已有材料
function M:HaveAll(id)
    local JewelryData = JewelryList[tostring(id)]
    local newId = JewelryData.newId
    local item = ItemData[tostring(newId)]
    self.cell:UpData(newId)
    self:ShowName(item.name)
    EquipMgr:ClearJJInfo()
    EquipMgr:SetJJInfo(id)
    EquipMgr:SetJJInfo(newId)
    local n = {JewelryData.id,JewelryData.needId}
    self:UpGroup(n)
    self:ShowInfo()
end

-- 显示进阶前后信息
function M:ShowInfo()
    local infos = EquipMgr.jjInfos
    for i=1,#lbs do
        lbs[i].js.text = infos[i].js
        lbs[i].co.text = infos[i].co
        lbs[i].att.text = infos[i].att
        lbs[i].jia.text = infos[i].jia
        lbs[i].num.text = infos[i].num
    end
end

function M:CleanCell()
	for i,v in ipairs(cellList) do
		v:Clean()
	end
end


function M:SetLock(start,ed,a)
    for i=start,ed do
		cellList[i]:Lock(a)
	end
end

function M:Need(index,v,num)
	local type_id=v
	local item=ItemData[tostring(type_id)]
	if(item==nil)then iTrace.Error("Loong", "道具==null id:".. type_id) return end
    local cell=cellList[index]
    if not num then num=1 end
    local curNum = 0
    if index == 1 then
        curNum = 1+ PropMgr.TypeIdByNum(type_id)
    else
        curNum = PropMgr.TypeIdByNum(type_id)
    end
    local numStr = StrTool.Concat(tostring(curNum),"/",tostring(num))
    local color = curNum == 0 and "[f21919]" or "[FFFFFF]"
	cell:UpData(item,color..numStr)
end

-- 显示名称
function M:ShowName(name)
    self.nameLb.text = name
end

function M:OnRed()
    local dic = EquipMgr.redT5Dic
    for k,v in pairs(dic) do
        self.cellDic[k]:OnRed(v)
    end
end

function M:CreateTb()
    -- body
end

-- 打开面板
function M:Open()
    self.go:SetActive(true)
    self:ShowEq("9")
end

-- 关闭面板
function M:Close()
    self.go:SetActive(false)
end

-- 释放
function M:Dispose()
    self:SetLsner("Remove")
    self.part = nil
    if self.cell then
		self.cell:DestroyGo()
		ObjPool.Add(self.cell)
		self.cell=nil
    end
    
    while #cellList>0 do
		local cell = cellList[#cellList]
		cell:DestroyGo()
		ObjPool.Add(cell)
		cellList[#cellList] = nil
    end

    while #lbs>0 do
        lbs[#lbs]=nil
    end
    
    TableTool.ClearDicToPool(self.cellDic)
	self.cellDic = nil
end

return M