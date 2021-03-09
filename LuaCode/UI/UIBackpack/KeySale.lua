--[[
道具一键出售
--]]
KeySale=Super:New{Name="KeySale"}
local My = KeySale
local cellDic = {}	--key:id value:Cell
local clickDic = {} --key:id value:bool
local dic = {}
local totalPrice = 0
My.eLock=Event()
My.isLock=false

function My:Init(go)
	self.trans=go.transform
	local TF = TransTool.FindChild
	local CG = ComTool.Get

	self.Money=CG(UILabel,self.trans,"Money",self.Name,false)
	UITool.SetBtnClick(self.trans,"Auto",self.Name,self.Auto,self)
	UITool.SetBtnClick(self.trans,"Confirm",self.Name,self.Confirm,self)
	UITool.SetBtnClick(self.trans,"Close",self.Name,self.Close,self)
	self.Grid=CG(UIGrid,self.trans,"Panel/Grid",self.Name,false)
end

function My:OnRemove(id,tp)
	id=tostring(id)
	if(tp~=1)then return end
	local cell = cellDic[tostring(id)]
	if(cell~=nil)then
		cell.OnClick=nil
		cell:DestroyGo()
		ObjPool.Add(cell)
		cellDic[id]=nil
		clickDic[id]=nil
	end
	self.Grid:Reposition()
end

function My:OnAdd(idTb,action,tp)
	if tp ~=1 then return end
	local item=ItemData[tostring(idTb.type_id)]
	if((item.price~=nil) and (item.type==1) and (item.quality<=2))then --品质白蓝
		self:CreateCell(item,tostring(idTb.id))
		self.Grid:Reposition()
		self:UpMoney()
	end
end

function My:InitData()
	local tb = PropMgr.UseEffGet(1)
	if(tb==nil)then return end
	for i,v in ipairs(tb) do
		local item=ItemData[tostring(v)]
		if(item==nil)then iTrace.eError("xiaoyu", "道具配置表==null id:".. v)return end
		if (item.price~=nil and item.quality<=2) then --品质白蓝
			local ttb = PropMgr.typeIdDic[tostring(v)]
			for i,v in ipairs(ttb) do
				self:CreateCell(item,tostring(v))
			end			
		end
	end
	self.Grid:Reposition()

	self:UpMoney()

	PropMgr.eRemove:Add(self.OnRemove,self)
	PropMgr.eAdd:Add(self.OnAdd,self)
end

function My:CreateCell(item,id)
	local cell = ObjPool.Get(Cell)
	cell:InitLoadPool(self.Grid.transform,0.945)
	cell.trans.name=id
	cell:UpData(item)
	cell.OnClick=self.OnCell
	cellDic[id]=cell

	clickDic[id]=true
	cell:Select(true)
	--加
	totalPrice=totalPrice+cell.item.price

	UITool.SetLsnrSelf(cell.trans.gameObject,self.OnCell,self,self.Name, false)

end

function My:OnCell(go)
	local state = clickDic[go.name]
	local cell = cellDic[go.name]
	if(state==true)then 
		state=false 
		cell:Select(false)
		--减
		totalPrice=totalPrice-cell.item.price
	else 
		state=true
		cell:Select(true)
		--加
		totalPrice=totalPrice+cell.item.price
	end
	clickDic[go.name]=state

	self:UpMoney()
end

--跳转设置界面自动出售
function My:Auto()
	UIMgr.Open(UISetting.Name,self.AutoCb,self)
end

function My:AutoCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:ChooseOpen(2)
	end
end

function My:Confirm()
	for k,v in pairs(clickDic) do
		if(v==true)then
			dic[k]=1
		end
	end
	PropMgr.isSort=true
	PropMgr.ReqSell(dic)
	TableTool.ClearDic(dic)
	totalPrice=0
	self:UpMoney()
	self:Close()
	--TableTool.ClearDic(clickDic)
end

function My:UpMoney()
	self.Money.text=tostring(totalPrice)
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:Close()
	self.trans.gameObject:SetActive(false)
	self:CleanData()
end

function My:CleanData()
	PropMgr.eRemove:Remove(self.OnRemove,self)
	PropMgr.eAdd:Remove(self.OnAdd,self)
	for k,cell in pairs(cellDic) do
		cell.OnClick=nil
		cell:DestroyGo()
		ObjPool.Add(cell)
		cellDic[k]=nil
	end
	TableTool.ClearDic(clickDic)
	TableTool.ClearDic(dic)
	totalPrice=0
end

function My:Dispose()
	self:CleanData()
	TableTool.ClearUserData(self)
end