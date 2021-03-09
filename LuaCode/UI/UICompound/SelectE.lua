--[[
装备合成选择装备
--]]
local GbjPool=Loong.Game.GbjPool.Instance
require("UI/UICompound/SelectCell")
SelectE=Super:New{Name="SelectE"}
local My=SelectE
My.eSelect=Event()

function My:Ctor()
	self.cellDic={}
end

function My:Init(go)
	self.trans=go.transform
	local CG=ComTool.Get
	local TF=TransTool.FindChild

	self.Panel=CG(UIPanel,self.trans,"Panel",self.Name,false)
	self.POS=self.Panel.transform.localPosition
	self.Grid=CG(UIGrid,self.trans,"Panel/Grid",self.Name,false)
	self.pre=TF(self.Grid.transform,"C")
	local U = UITool.SetBtnClick

	U(self.trans,"PutBtn",self.Name,self.OnPut,self)
	U(self.trans,"CloseBtn",self.Name,self.Close,self)

	if not self.idList then self.idList={} end
end

function My:UpData(list)
	self.maxNum=3
	self:Open()
	local tbDic = PropMgr.tbDic
	for i,id in ipairs(list) do	
		local tb = tbDic[tostring(id)]
		self:CreateSelect(i,tb)
	end
	self.Grid.repositionNow=true
	for i,v in ipairs(self.idList) do
		self.cellDic[tostring(v)].select.value=true
	end
end

function My:NatureUpData(id)
	self.maxNum=4
	self:Open()
	local dic=PropMgr.typeId5Dic[tostring(id)]
	if not dic then return end
    local tbDic = PropMgr.tb5Dic
    for k,v in pairs(dic) do
        local tb = tbDic[tostring(v)]
        self:CreateSelect(i,tb)
    end
    self.Grid.repositionNow=true
    for i,v in ipairs(self.idList) do
		self.cellDic[tostring(v)].select.value=true
	end
end

function My:CreateSelect(i,tb)
	local go =  GameObject.Instantiate(self.pre)
	go:SetActive(true)
	go.transform.parent=self.Grid.transform
	go.name=tostring(i)
	go.transform.localPosition=Vector3.zero
	go.transform.localScale = Vector3.one
	
	local cell = ObjPool.Get(SelectCell)
	cell:Init(go)
	cell:UpData(tb,i)
	self.cellDic[tostring(tb.id)]=cell
end

local list = {}
function My:OnPut()
	ListTool.Clear(list)
	for k,cell in pairs(self.cellDic) do
		if cell.select.value==true then list[#list+1]=k end
	end
	local maxNum=self.maxNum
	if not maxNum then return end
	if #list>maxNum then 
		local text="最多可选择".. maxNum.."件装备!"
		UITip.Log(text) 
		return 
	else
		ListTool.Clear(self.idList)
		for i,v in ipairs(list) do
			self.idList[i]=v
		end
	end
	My.eSelect()
	self.isPut=true
	self:Close()
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:Close()
	self:CleanCell()
	self.trans.gameObject:SetActive(false)
	--ObjPool.Add(self)
	if not self.isPut then ListTool.Clear(self.idList) end
end

function My:CleanCell()
	for k,v in pairs(self.cellDic) do
		ObjPool.Add(v)
		self.cellDic[k]=nil
	end
	self.Panel.clipOffset=Vector2.zero
	self.Panel.transform.localPosition=self.POS
end

function My:Dispose()
	self:Close()
	ListTool.Clear(self.idList)
	self.isPut=nil 
end