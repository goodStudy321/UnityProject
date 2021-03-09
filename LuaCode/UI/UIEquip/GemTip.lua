--[[
点击宝石 卸下、镶嵌Tip
--]]
GemTip=Super:New{Name="GemTip"}
local My = GemTip

My.clickIndex=nil
My.gemId=nil

-- function My:Ctor()
My.gemList={}
-- end

function My:Init(go)
	self.gemList={}
	local TF = TransTool.FindChild
	local CG = ComTool.Get
	self.trans=go.transform
	self.panel=ComTool.Get(UIScrollView,self.trans,"Panel",self.Name,false)
	self.grid=ComTool.Get(UIGrid,self.panel.transform,"Grid",self.Name,false)

	UITool.SetLsnrClick(self.trans,"Mask",self.Name,self.Close,self)
	self.Grid=CG(UIGrid,self.trans,"Grid",self.Name,false)
	local grid = self.Grid.transform
	self.Up=TF(grid,"Up")
	self.Down=TF(grid,"Down")
	--self.Jewel=TF(self.trans,"Grid/Jewel")
	local US = UITool.SetBtnSelf
	US(self.Up,self.OnUp,self,self.Name) 
	US(self.Down,self.OnDown,self,self.Name)
	--US(self.Jewel,self.OnJewel,self,self.Name)

	self.NoGem=TF(self.trans,"Panel/Grid/NoGem")
	self.NoGemName=CG(UILabel,self.NoGem.transform,"Name")
	UITool.SetLsnrSelf(self.NoGem,self.OnClickNoGem,self,self.Name)
	local no = self.NoGem.transform
	self.noGemCell=ObjPool.Get(Cell)
	self.noGemCell:InitLoadPool(no,0.75,nil,nil,nil,Vector3.New(-89,0,0))
	
	UIGemCell.eClick:Add(self.Close,self)
end

function My:UpData(title,tipList,isSeal)
	self.isSeal=isSeal and true or false;	
	self.title=title
	self.tipList=tipList
	self:Open()
	self:CleanList()
	local tb = EquipMgr.hasEquipDic[EquipPanel.curPart]
	if tb==nil then	return	end
	self.equipid=tb.type_id
	local equip=EquipBaseTemp[tostring(self.equipid)]
	if(equip==nil)then iTrace.Error("xiaoyu", "装备表为空 type_id: "..self.equipid)return end
	local tbb = nil
	local id = 0
	if  self.isSeal then
		tbb= PropMgr.GetSealByPart(equip.wearParts)
		id = tb.slDic[tostring(My.clickIndex)] or 0
		self.NoGemName.text="前往寻宝抽取纹印";
	else
		tbb= PropMgr.GetGemByPart(equip.wearParts)
		id = tb.stDic[tostring(My.clickIndex)] or 0
		self.NoGemName.text="前往商城可购买宝石";
	end
	self.Down:SetActive(id~=0)  
	self.Up:SetActive((#self.tipList)>0)
	self.Grid:Reposition()
	self.NoGem:SetActive(tbb==nil)
	if(tbb==nil)then 
		local lstdata = self.isSeal and tSealData or GemData
		for k,v in pairs(lstdata) do
			local parts=v.parts
			if parts then
				for i1,v1 in ipairs(parts) do
					if v1==equip.wearParts then 
						if v.type==3 then self.nogemid= self.isSeal and 30029 or 30001
						elseif v.type==1 then self.nogemid= self.isSeal and 30039 or 30011 end
						self.noGemCell:UpData(self.nogemid)
						return 
					end
				end
			end
		end
	else
		for i,v in ipairs(tbb) do
			self:CreateGem(v,v>id)
		end
	end	
end

--宝石
function My:UpDataGem()
	local part = EquipPanel.curPart
	local tb = EquipMgr.hasEquipDic[part]
	local gemDic = PropMgr.GetGemByPart(part)
	local id = tb.stDic[tostring(My.clickIndex)] or 0
	if gemDic then 
		for i,v in ipairs(gemDic) do
			self:CreateGem(v,v>id)
		end
	else
		local gemId = self:GetGemId(part,"30001")
		if not gemId then
			gemId = self:GetGemId(part,"30011")
		end
		if not gemId then iTrace.eError("xiaoyu","找不到gemId")return end
		self.nogemid=tonumber(gemId)
		self.noGemCell:UpData(gemId)
	end
	self.NoGem:SetActive(gemDic==nil)
	self.Up:SetActive(false)
	self.Down:SetActive(id~=0)
end

function My:GetGemId(part,gemid)
	local id = nil
	local gem = GemData[gemid]
	local partList = gem.parts
	for i,v in ipairs(partList) do
		if v==tonumber(part) then 
			id=gemid
		end
	end
	return id
end

--纹印
function My:UpDataSeal(title,tipList,isSeal)
	-- body
end

function My:CreateGem(type_id,red)
	local del = ObjPool.Get(DelGbj)
	del:Adds(type_id,red)
	del:SetFunc(self.LoadGem,self)
	LoadPrefab("GemCell",GbjHandler(del.Execute,del))	
end

function My:LoadGem(go,type_id,red)
	go.transform.parent=self.grid.transform
	go:SetActive(false)
	go:SetActive(true)
	go.transform.localScale=Vector3.one
	go.transform.localPosition=Vector3.zero
	self.grid:Reposition()
    local gem=ObjPool.Get(UIGemCell)
	gem:Init(go)
	gem:UpData(type_id, self.isSeal,red)
	self.gemList[#self.gemList+1]=gem
end

function My:OnClickNoGem()
	if self.nogemid== 30029 or self.nogemid== 30039 then
		UITreasure:OpenTab(3)
	else
		StoreMgr.OpenStoreId(self.nogemid)
	end
end

function My:CleanList()
	ListTool.ClearToPool(self.gemList)
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:Close()
	self.panel:ResetPosition()
	--ObjPool.Add(self)
	self.trans.gameObject:SetActive(false)
	self:Clean()
end

--升级
function My:OnUp()
	MsgBox.ShowYesNo(self.title,self.UpCb,self,nil,self.Close,self)
end

function My:UpCb()
	local count = #self.tipList
	if count>0 then
		if self.isSeal then
			EquipMgr.ReqESealCompose(self.equipid,My.clickIndex,self.tipList)
		else
			EquipMgr.ReqESCompose(self.equipid,My.clickIndex,self.tipList)
		end
		self:Close()
	end
end

--卸下
function My:OnDown()
	if self.isSeal then
		EquipMgr.ReqSealRemove(self.equipid,My.clickIndex)
	else
		EquipMgr.ReqRemove(self.equipid,My.clickIndex)
	end
	self:Close()
end

-- --镶嵌
-- function My:OnJewel()
-- 	if not My.gemId then UITip.Error("请点击镶嵌的宝石")return end
	
-- 	self:Close()
-- end

function My:Clean()
	self:CleanList()
	My.clickIndex=nil
	My.gemId=nil
	self.isSeal=false;
end

function My:Dispose()
	self:Close()
	UIGemCell.eClick:Remove(self.Close,self)
	if self.noGemCell then self.noGemCell:DestroyGo() ObjPool.Add(self.noGemCell) self.noGemCell=nil end
end