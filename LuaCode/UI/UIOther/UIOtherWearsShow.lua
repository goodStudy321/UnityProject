--[[
其他玩家穿戴装备展示
--]]
local AssetMgr=Loong.Game.AssetMgr
local Camera=UnityEngine.Camera
UIOtherWearsShow=Super:New{Name="UIOtherWearsShow"}
local My=UIOtherWearsShow

local trans=nil
local NameLab=nil
local LvLab = nil
local Vip = nil
local FamilyName = nil
local FamilyTitle = nil
local grid=nil
local cellPre=nil
local Model=nil

local cellDic={}
local bgList = {}
local btns = {"Strengthen"}

function My:Init(go)
	trans=go.transform
	local CG=ComTool.Get
	local TF=TransTool.FindChild
	local name = self.Name
	NameLab=CG(UILabel,trans,"NameLab",name,false)
	LvLab=CG(UILabel,trans,"LvLab",name,false)
	Vip = CG(UISprite, trans, "vip", name, false)
	FamilyName = CG(UILabel, trans, "FamilyName", name, false)
	FamilyTitle = CG(UILabel, trans, "FamilyTitle", name, false)
	grid=CG(UIGrid,trans,"Grid",name,false)
	Model=TF(trans,"Model").transform
	self.bgPre=TF(grid.transform,"F")

	self:InitCell()
end

function My:InitCell()
	self:CreateCell(12)
	self:CreateCell(10)
	self:CreateCell(9)
	self:CreateCell(8)
	self:CreateCell(7)
	self:CreateCell(1)
	self:CreateCell(11)
	self:CreateCell(3)
	self:CreateCell(4)
	self:CreateCell(2)
	self:CreateCell(5)
	self:CreateCell(6)

	grid:Reposition()
end

function My:CreateCell(part)
	local cell = ObjPool.Get(UIItemCell)
	cell:InitLoadPool(grid.transform)
	cellDic[tostring(part)]=cell

	self:CreateBg(cell.trans)
end

function My:CreateBg(parent)
	local b = GameObject.Instantiate(self.bgPre)
	b.transform.parent=parent
	b:SetActive(true)
	b.transform.localScale = Vector3.one
	b.transform.localPosition=Vector3.New(-40.5,40.8,0)
	bgList[#bgList+1]=b
end

function My:UpdateInfo(info)
	if not info then return end
	self:NameLab(info.name)
	self:LvLab(info.lv)
	self:VIP(info.vip)
	self:Family(info)
	self:CreateModel((info.cate * 10 + info.sex) * 1000 + info.lv)
	self:UpdateHasEquip(info.equips)
end

function My:UpdateHasEquip(list)
	if not list then return end
	local len = #list
	for i=1,len do
		local equip = list[i]
		local temp = EquipBaseTemp[tostring(equip.type_id)]
		if temp then
			self:EquipLoad(equip, tostring(temp.wearParts))
		end
	end
end

function My:CreateModel(id)
	local roleAtt=RoleAtt[tostring(id)]
	if(roleAtt==nil)then iTrace.Error("Loong", "角色属性表==null  id: "..tostring(id))return end
	local roleM=RoleBaseTemp[roleAtt.modelId]
	if(roleM==nil)then iTrace.Error("Loong", "角色模型表==null  id: "..roleAtt.modelId)return end
	AssetMgr.LoadPrefab(roleM.uipath,GbjHandler(self.LoadModel,self))
end

function My:LoadModel(go)
	go.transform.parent=Model
	go:SetActive(true)
	go.transform.localScale=Vector3.one
	go.transform.localRotation=Quaternion.New(0,0,0,0)
	go.transform.localPosition=Vector3.zero
	go.layer=19  --UIModel层
	LayerTool.Set(go,19)
end

function My:EquipLoad(tb,part)
	local cell=cellDic[part]
	local item=ItemData[tostring(tb.type_id)]
	local equip = EquipBaseTemp[tostring(tb.type_id)]
	cell:TipData(tb,nil,btns)
	cell:UpBind(tb.bind)
end

function My:NameLab(name)
	if NameLab then
		NameLab.text=name
	end
end

function My:LvLab(lv)
	if LvLab then
		LvLab.text = tostring(lv)
	end
end

function My:VIP(vip)
	local value = vip ~= 0
	if Vip then
		Vip.gameObject:SetActive(value)
		if value == true then
			Vip.spriteName = string.format("vip",vip)
		end
	end
end

function My:Family(info)
	local familyId = tonumber(info.familyId)
	local value = familyId ~= 0
	if FamilyName then
		FamilyName.gameObject:SetActive(value)
		if value == true then
			FamilyName.text = info.familyName
		end
	end
	if FamilyTitle then
		FamilyTitle.gameObject:SetActive(value)
		if value == true then
			FamilyTitle.text = FamilyMgr:GetTitleByIndex(info.family_title)
		end
	end
end

function My:CleanData()
	while(Model.childCount>0)do
		local count=Model.childCount
		local go=Model:GetChild(count-1).gameObject
		go.transform.parent=nil
		GameObject.Destroy(go)
	end
end

function My:Dispose()
	self:CleanData()	
	while #bgList>0 do
		local go = bgList[#bgList]
		GameObject.Destroy(go)
		bgList[#bgList]=nil
	end
	for k,v in pairs(cellDic) do
		v:DestroyGo()
		ObjPool.Add(v)
		cellDic[k]=nil
	end
end