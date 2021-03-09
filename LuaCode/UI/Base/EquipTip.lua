--[[
装备Tip
--]]
local AssetMgr=Loong.Game.AssetMgr
EquipTip=UIBase:New{Name="EquipTip"}
local My=EquipTip
My.pos=nil
My.width=nil
My.showDepotPoint=nil
My.isInWarehouse = false

function My:InitCustom()
	local CG=ComTool.Get
	local TF=TransTool.FindChild

	self.grid=CG(UIGrid,self.root,"Grid",self.Name,false)
	self.grid.gameObject:SetActive(false)
	self.hasGo=TF(self.root,"Grid/EquipHas")
	self.hasGo:SetActive(false)
	self.selfGo=TF(self.root,"Grid/EquipSelf")
	self.selfGo:SetActive(false)
	--操作按钮
	self.BtnGrid=CG(UIGrid,self.root,"Grid/EquipSelf/Btn",self.Name,false)
	self.btn=TF(self.BtnGrid.transform,"Btn")
	UITool.SetLsnrClick(self.root,"Mask",self.Name,self.Close,self)
	

	self.str=ObjPool.Get(StrBuffer)
	if not self.Btns then self.Btns={} end
	if not self.dic then self.dic = {} end
end

function My:OffSetPos()
	self.grid.gameObject:SetActive(true)
	local wordPos = My.pos
	if wordPos==nil then return end
	if self.isCompare==true then 
		self.grid.transform.localPosition=Vector3.New(116.36,-36,0)
		return 
	end
	self.grid.transform.position=wordPos

	local w = Screen.width/2
	local x = self.grid.transform.localPosition.x 
	if x<-435 then x=x+200 
	elseif x>430 then x=x-200 
	else
		--x=x-200
	end
	self.grid.transform.localPosition=Vector3.New(x,-36.08,0)
end

function My:ShowBtn(btnList,clickCell)
	local islimit = self:LimitBtn(clickCell)
	if (clickCell.item.worth > 0 or clickCell.item.cost > 0) and clickCell.showDepotPoint then
		if btnList then
			for i,btnName in ipairs(btnList) do
				if (isWayExit==false and btnName==UIContentY.btnList[18]) or btnName~=UIContentY.btnList[18] then
					self:AddBtn(btnName)
				end
			end
		end
	elseif islimit==true then
		self:AddBtn(UIContentY.btnList[3])
	else
		local isWayExit = false
		local isAuction = UIMgr.GetActive(UIAuction.Name) 
		if self.item.getwayList and isAuction == -1 then 
			self:AddBtn(UIContentY.btnList[18])
			isWayExit=true
		end
		local iscompound = self:CompoundBtn(clickCell)
		if iscompound==true then
			self:AddBtn(UIContentY.btnList[4])
		end
		if btnList then 
			for i,btnName in ipairs(btnList) do
				if (isWayExit==false and btnName==UIContentY.btnList[18]) or btnName~=UIContentY.btnList[18] then 
					self:AddBtn(btnName)
				end
			end
		end
	end
	self.BtnGrid:Reposition()
end

function My:LimitBtn(clickCell)
	-- 判断限时道具
	if self.tb and self.tb.id then
		if self.tb.id >= 1 and self.tb.id <= 1000 then
			local isBag = true
			if clickCell then isBag=clickCell.isBag end
			if not isBag then return false end
			local sec = self.item.AucSecId or 0
			local now =  TimeTool.GetServerTimeNow()*0.001
			local endTime = now - self.tb.market_end_time
			if self.tb.market_end_time and self.tb.market_end_time == 0 then
				return false
			end
			if self.item.startPrice and endTime and sec~=0 then
				return self.tb.market_end_time == 1 or endTime>0
			end
		end
	end
end

function My:CompoundBtn(clickCell)
	local tb = self.tb
	if not tb then return end
	if not tb.id then return end
	local tp,dic=PropMgr.GetTp(tb.id)
	if tp~=1 then return end 
	local isBag = true
	if clickCell then isBag=clickCell.isBag end
	if isBag~=true then return end --背包
	local type_id = tostring(self.item.id)
	local lv = User.instance.MapData.Level
	local equip = EquipBaseTemp[type_id]
	local part = equip.wearParts
	local dic = part<=6 and EquipMgr.equipList[1] or EquipMgr.equipList[2]
	for k,v in pairs(dic) do
		for k1,v1 in pairs(v) do
			for k2,v2 in pairs(v1) do
				local data = EquipCompound[v2]
				local canId = data.canId
				for i,id in ipairs(canId) do
					if tostring(id)==type_id and lv>=data.lv then 
						return true
					end
				end
			end
		end		
	end
	return false
end

function My:AddBtn(name)
	local go = GameObject.Instantiate(self.btn)
	go:SetActive(true)
	go.name=name
	go.transform.parent=self.BtnGrid.transform
	go.transform.localPosition = Vector3.zero
	go.transform.localScale=Vector3.one
	UITool.SetBtnSelf(go,self[name],self,self.Name)
	local lab = ComTool.Get(UILabel,go.transform,"Label",self.Name,false)
	lab.text=UIContentY.btnNameList[name]
	self.Btns[#self.Btns+1]=go
end

-- 使用(限时道具专用)
function My:Use()
	local endTime = self.tb.market_end_time
	local now = TimeTool.GetServerTimeNow()*0.001
	-- local time = endTime - now
	if now - endTime > 0 and endTime ~= 0 then
		UIMgr.Open(ShelfTip.Name,self.ShelfTipCB,self)
	end
	self:Close()
end

function My:ShelfTipCB(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpData(self.tb)
	end
end

--合成
local rankPartList = {}
function My:Compound()
	local lv = User.instance.MapData.Level
	ListTool.Clear(rankPartList)
	local type_id=tostring(self.item.id)
	local part = self.equip.wearParts
	local dic = part<=6 and EquipMgr.equipList[1] or EquipMgr.equipList[2]
	for k,v in pairs(dic) do
		for k1,v1 in pairs(v) do
			for k2,v2 in pairs(v1) do
				local data = EquipCompound[v2]
				local canId = data.canId
				for i,id in ipairs(canId) do
					if tostring(id)==type_id and lv>=data.lv then 
						table.insert(rankPartList,v2)
						break
					end
				end
			end
		end
	end
	local tp = part<=6 and 3 or 4
	if #rankPartList>1 then
		table.sort(rankPartList, My.SortRankPart )
	end
	UICompound:SwitchTg(tp,nil,rankPartList[1])
end

function My.SortRankPart(a,b)
	return a>b
end

--装备
function My:Equip()
	EquipMgr.SetCurEquipTipData(self.item,self.equip,self.tb)
	EquipMgr.OnEquip(self.isSpir)
	self:Close()
end

--出售
function My:Sale()
	if(self.item.price==nil)then UITip.Log("该装备不可出售") return end		
	self.str:Dispose()
	self.str:Apd("你确定要出售"):Apd(self.item.name):Apd("装备吗？")
	self.str:Line()
	self.str:Apd("[00FF00FF](出售可获得"):Apd(self.item.price):Apd("银两)[-][-]")
	local title=self.str:ToStr()		
	MsgBox.ShowYesNo(title, self.SaleCb,self)			
	self:Close()
end

function My:SaleCb()
	TableTool.ClearDic(self.dic)
	self.dic[tostring(self.tb.id)]=self.tb.num
	PropMgr.ReqSell(self.dic)
end

function My:PropSTipCB(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpData(self.item, self.tb)
	end
end

-- 选取（神秘宝藏用）
function My:Choose()
	self:Close()
	TreaFeverMgr:OnChoose()
end

-- 取消选取（神秘宝藏用）
function My:EseChoose()
	TreaFeverMgr:EseChoose()
	self:Close()
end

-- --上架
-- function My:PutAway()
-- 	if MarketMgr:OnShelfBuyGoodsNum() > 10 then
-- 		UITip.Error("最大上架数量为10");
-- 		return;
-- 	end
	
-- 	PropSale.limitNum = 1;
-- 	PropSale.limitPrice = 999999;
-- 	UIMgr.Open(PropSale.Name,self.PutCb,self)
-- 	self:Close()
-- end

-- function My:PutCb(name)
-- 	local ui = UIMgr.Get(name)
-- 	if(ui)then
-- 		if self.item.time then
-- 			ui:ShowWidge(true)
-- 		else
-- 			ui:ShowWidge(false)
-- 		end
-- 		ui:UpData(self.item, self.tb.id)
-- 	end
-- end

--强化
function My:Strengthen()
	self:Close()
	EquipMgr.OpenEquip(1)
end


--取出
function My:GetOut()
	local tp,dic=PropMgr.GetTp(self.tb.id)
	PropMgr.ReqDepot(tp,1,self.tb.id)
	self:Close()
end

--放入
function My:PutIn()
	local tp,dic=PropMgr.GetTp(self.tb.id)
	PropMgr.ReqDepot(1,2,self.tb.id)
	self:Close()
end

--购买
function My:Buy()
	self:Close()

end

--下架
function My:SoldOut()


	self:Close()
end

--兑换
function My:Exchange()
 --// LY add begin
 	if self.tb ~= nil and self.tb.id ~= nil then
 		FamilyMgr:ReqFamilyExcDepot(self.tb.id, 1);
 	else
 		iTrace.Error("LY", "Exchange error !!! ");
 	end
 --// LY add end

 	self:Close()
end

--捐献
function My:Donate()
 --// LY add begin
 	if self.tb ~= nil and self.tb.id ~= nil then
 		local itemUIdTbl = {self.tb.id};
 		FamilyMgr:ReqFamilyDonate(itemUIdTbl);
 	else
 		iTrace.Error("LY", "Donate error !!! ");
 	end
 --// LY add end

 	self:Close()
end

--获取途径
function My:GetWay()
	GetWayFunc.ItemGetWay(self.type_id)
end

function My:UpData(obj,isCompare,suit,attWhat,isSpir)
	if(isCompare==true)then
		if(type(obj)=="table")then 
			self.tb=obj  
			self.type_id=tostring(self.tb.type_id )
		elseif(type(obj)=="string")then
			self.type_id=obj
		else
			self.type_id=tostring(obj)
		end

		self.equip = EquipBaseTemp[self.type_id]
		local part = self.equip.wearParts
		local tb = nil;
		if isSpir == nil or isSpir == false then
			self.isSpir = false;
			part = tostring(part)
			tb = EquipMgr.hasEquipDic[part]
		else
			self.isSpir = true;
			local spirId = RobEquipsMgr.GetCurSpirId();
			tb = RobEquipsMgr.GetSpirEqTb(spirId,part);
		end
		if(tb~=nil)then
			if(self.equipHas==nil)then
				self.equipHas=ObjPool.Get(EquipRoot)
				self.equipHas:Init(self.hasGo)
			end
			self.equipHas:UpData(tb)
			self.equipHas.cell:UpBind(tb.bind)
			self.equipHas:Open()
			self.isCompare=true
		end		
	end

	if(self.equipSelf==nil)then
		self.equipSelf=ObjPool.Get(EquipRoot)
		self.equipSelf:Init(self.selfGo)
	end
	self.equipSelf:UpData(obj,suit,attWhat)
	self.equipSelf:ShowlimTime()
	self.equipSelf.cell:UpBind(self.isBind)
	self.equipSelf:Open()

	self.item=self.equipSelf.item
	self.tb=self.equipSelf.tb
	if self.tb and self.isSpir~=true then 
		self.equipSelf.cell:IconUp(self.tb.isUp)
		self.equipSelf.cell:IconDown(self.tb.isDown)
	end
	self.grid:Reposition()
	self:OffSetPos()
end

function My:ClearBtn()
	while(#self.Btns>0)do
		local btn = self.Btns[#self.Btns]
		Destroy(btn)
		self.Btns[#self.Btns]=nil
   end
end

function My:CloseCustom()
	self.isCompare=nil
	if(self.equipHas~=nil)then
		ObjPool.Add(self.equipHas)
	end
	if(self.equipSelf~=nil)then
		ObjPool.Add(self.equipSelf)
	end
	self.equipHas=nil
	self.equipSelf=nil
	My.showDepotPoint=nil
	My.isInWarehouse = false
	My.pos=nil
	My.width=nil
	self:ClearBtn()
end

return My