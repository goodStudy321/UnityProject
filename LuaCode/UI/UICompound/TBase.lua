--[[
装备合成，饰品合成，天机印合成基类
]]
TBase=Super:New{Name="TBase"}
local My = TBase


function My:Init(go,tt,T)
	if not self.partCellList then self.partCellList={} end
	if not self.cellList then self.cellList = {} end
	self.sText = ObjPool.Get(StrBuffer)
	self.tt=tt
    self.trans=go.transform
    self.T=T
	local CG=ComTool.Get
	local T=TransTool.FindChild

	self.tip=T(self.trans,"Tip")
    self.tipLab=CG(UILabel,self.trans,"Tip",self.Namem,false)
	self.Grid=CG(UIGrid,self.trans,"Grid",self.Name,false)
	self.p=CG(UIGrid,self.trans,"pGrid",self.Name,false)
	
	self.tog=CG(UIToggle,self.trans,"tog",self.Name,false)
	UITool.SetBtnSelf(self.tog.gameObject,self.OnTog,self,self.Name)

	self.AKeyBtn=T(self.trans,"AKeyBtn")
	UITool.SetBtnSelf(self.AKeyBtn,self.OnAKey,self,self.Name)
    
	--设置俩按钮位置 -245
	self.AKeyBtn:SetActive(true)	

	self.islong=false

	self:InitCustom()
end

function My:InitCustom( ... )
	
end

function My:SetEvent(fn)
	EquipPartCell.eClick[fn](EquipPartCell.eClick,self.ClickPart,self)
end

function My:CreateTb(selectId)
    -- body
end

function My:FindMin(min,k)
	if not min then min=tonumber(k)
	elseif min>tonumber(k) then min=tonumber(k) end
	return min
end

function My:CreateCellList(num)
	local U=UITool.SetLsnrSelf
	for i=1,num do
		local cell = ObjPool.Get(UIEquipItemCell)
		cell:InitLoadPool(self.Grid.transform)
		U(cell.trans.gameObject,self.ClickCell,self,self.Name, false)		
		self.cellList[i]=cell
	end
	self.Grid:Reposition()
end

function My:DataCustom(tp)
    self.tbDic=PropMgr.tbAll["tp"..tp]
    self.typeIdDic=PropMgr.typeIdAll["tp"..tp]
end

--大分类
function My:OnT(go)
	self.tX=tonumber(go.name)
end

--品阶
function My:OnTg(go,selectId)
	if self.curBg then self.tt:TgState(self.curBg,false) end
	self.tY=go.name
	self.tX=tonumber(go.transform.parent.name)
	local bg = go:GetComponent(typeof(UISprite))
	self.tt:TgState(bg,true)
	self:UpData()
	self:PState(true)
	self.curBg=bg
	if selectId then
		self:ClickPart(selectId)
	end
end

--显示部位
function My:UpData()
	--隐藏
	for i,v in ipairs(self.partCellList) do
		v:ShowState(false)
	end

	local tb = self.dic
	local ttb = tb[tostring(self.tX)]
	local tttb = ttb[self.tY]
	for part,type_id in pairs(tttb) do
		self:ShowP(tonumber(part),type_id)
	end
	self.p:Reposition()

	--部位红点
	self:PartRed()
end

function My:ShowP(part,id)
	local cell = self.partCellList[part]
	cell:ShowState(true)
    cell:UpData(id)
end

function My:PartRed( ... )
    -- body
end

--选择装备
function My:OnSelect()
    for i,v in ipairs(self.cellList) do
		v:Clean()
		v:AddActive(true)
	end
	local list = self.tt.SelectE.idList
	if #list==0 then UITip.Log("添加材料为空")return end
	for i,v in ipairs(list) do
		local cell = self.cellList[i]
		cell:AddActive(false)
		local tb = self.tbDic[tostring(v)]
		if tb then 
			local item = ItemData[tostring(tb.type_id)]
			if(item==nil)then iTrace.eError("xiaoyu","道具表为空 type_id: ".. tb.type_id)return end
			cell:UpData(item)
		end
	end
	self:ShowSucced()
end

function My:ShowSucced( ... )
    -- body
end

function My:ClickPart(type_id)
	for i,cell in ipairs(self.cellList) do
		cell:Clean()
		cell:AddActive(true)
	end
	ListTool.Clear(self.tt.SelectE.idList)
	self.type_id=type_id
	self:PState(false)
	self:ClickPartCustom()
	self.Grid:Reposition()
end

function My:ClickPartCustom( ... )
    -- body
end

function My:ClickCell( ... )
    -- body
end

function My:OnTog( ... )
    -- body
end

-- function My:OnAKey( ... )
--     -- body
-- end

function My:OnCompose( ... )
    -- body
end

--点击品阶级state==true显示p，反之false
function My:PState(state)
	self.p.gameObject:SetActive(state)
	self.tt.CBtn:SetActive(not state)
	self.tt.bg:SetActive(not state)
	self.AKeyBtn:SetActive(not state)
	self.Grid.gameObject:SetActive(not state)
	self.tip:SetActive(not state)
	if self.tt.Cell then self.tt.Cell.trans.gameObject:SetActive(not state) end
end

function My:OnCbtn()
    local count = #self.tt.SelectE.idList
	if(count==0)then UITip.Log("合成材料为空，合成失败") return end
	--self.sText:Dispose()
    local issucced=self:OnCbtnCustom()
    if issucced==true then
        for i,v in ipairs(self.cellList) do
            v:Clean()
            v:AddActive(true)
        end
    end
end

function My:OnCbtnCustom( ... )

end

function My:OpenData()
    self.tt.CBtn.transform.localPosition=Vector3.New(-5,-294.7,0)
	local T=TransTool.FindChild
	local p=self.p.transform
	for i=1,10 do
		local g = T(p,tostring(i))
		local cell = ObjPool.Get(self.T)
		cell:Init(g)
		self.partCellList[i]=cell
    end	
	self:SetEvent("Add")
end

function My:Open()
    self.trans.gameObject:SetActive(true)
    self:OpenCustom()
    self:OpenData()
end

function My:OpenCustom()
    -- body
end

function My:Close()
    self:SetEvent("Remove")
	self.trans.gameObject:SetActive(false)
	self.tt:CleanData()
	ListTool.ClearToPool(self.partCellList)
	while(#self.cellList>0)do
		local cell = self.cellList[#self.cellList]
		cell:DestroyGo()
		ObjPool.Add(cell)
		self.cellList[#self.cellList]=nil
	end
	if self.tt.CBtn then self.tt.CBtn.transform.localPosition=Vector3.New(-102,-294.7,0)end
	self:CloseCustom()
end

function My:CloseCustom( ... )
	-- body
end

function My:Dispose()
    self:Close()
	ListTool.ClearToPool(self.partCellList)
	if self.sText then ObjPool.Get(self.sText) self.sText=nil end
    self:DisposeCustom()
end

function My:DisposeCustom( ... )
    -- body
end