--[[
装备合成
--]]
T34=TBase:New{Name="T34"}
local My = T34
-- My.eCell=Event()
-- My.eTip=Event()

function My:InitCustom( ... )
	UITool.SetLsnrClick(self.tip.transform,"bg",self.Name,self.ShowTip,self)
end


function My:CreateTb(selectId)
	local U=UITool.SetLsnrSelf
	local TF = TransTool.FindChild
	local CG = ComTool.Get

	local lv = User.instance.MapData.Level
	self.dic = self:GetDic()
	local minTp1,minTp2 = self:SelectLight(selectId)
	local isfirst = true
	for k,v in pairs(self.dic) do
		local isTp1 = true
		local go,tab=nil,nil
		for k1,v1 in pairs(v) do
			local isTp2 = true
			local goo=nil
			for k2,v2 in pairs(v1) do
				if tp1==false and tp2==false and isfirst==false then break end
				local temp = EquipCompound[v2]
				if lv>=temp.lv then 
					if isTp1==true then
						go=self.tt:CreateT(temp.tp1,k)
						tab= CG(UITable,go.transform,"Tween/table",self.Name,false) 
						tab.onCustomSort=function(a,b) return self.tt:SortName(a,b)end
						isTp1=false
					end	
					if isTp2==true then					
						tab.name=k					
						goo=self.tt:CreateTg(tab.transform,temp.tp2,k,k1)
						isTp2=false
					end
				end
			end
			if k==minTp1 and k1==minTp2 and isfirst==true then
				self:OnT(go) 
				self:OnTg(goo) 
				isfirst=false
			end
			if goo then U(goo,self.OnTg,self,self.Name) end
		end
		if go then U(go,self.OnT,self,self.Name, false) end
		tab:Reposition()
	end
	self.tt.table.repositionNow=true
end

function My:SelectLight(selectId)
	local minTp1,minTp2=nil,nil
	local dic = self.dic
	if selectId and selectId~=0 then
		for k,v in pairs(dic) do
			for k1,v1 in pairs(v) do
				for k2,v2 in pairs(v1) do
					if v2==tostring(selectId) then
						local temp = EquipCompound[v2]
						minTp1=k
						minTp2=k1
						break
					end
				end
				if minTp1 and minTp2 then break end
			end
			if minTp1 and minTp2 then break end
		end

	else
		for k,v in pairs(dic) do
			minTp1=self:FindMin(minTp1,k)
		end
		local minDic = dic[tostring(minTp1)]
		for k,v in pairs(minDic) do
			minTp2=self:FindMin(minTp2,k)
		end
	end
	return tostring(minTp1),tostring(minTp2)
end

function My:GetDic()
	local tp = self.sTp
	local dic = nil
	if tp == 7 then
		dic = EquipMgr.equipList[3]
	else
		dic = EquipMgr.equipList[tp - 2]
	end
	return dic
end

function My:PartRed()
	local tp = self.sTp-2
	local dic= self:GetDic()
	local typeDic = dic[tostring(self.tX)]
	local rankDic= typeDic[self.tY]
	local noshowRed = false
	if tp == 1 then
		noshowRed = EquipMgr.noshowRed33
	elseif tp == 2 then
		noshowRed = EquipMgr.noshowRed34
	elseif tp == 5 then
		noshowRed = EquipMgr.noshowRed35
	end
	for part,v2 in pairs(rankDic) do
		local red = false
		if noshowRed==false then 
			local data = EquipCompound[v2]
			local canid = data.canId
			if canid then
				local allNum = 0
				local maxNum = 0
				local prob=data.prob
				for i,v in ipairs(prob) do
					if v.val==10000 then maxNum=v.id break end
				end
				for i2,id in ipairs(canid) do
					local num = PropMgr.TypeIdByNum(id)
					allNum=allNum+num
					if allNum>=maxNum then red=true break end
				end
			end
		end
		local cell = self.partCellList[tonumber(part)]
		cell:PartRed(red)
	end
end

function My:ShowSucced()
	local com = EquipCompound[tostring(self.type_id)]
	if(com==nil)then iTrace.eError("xiaoyu","装备合成表为空 type_id: ".. self.type_id)return end
	 --显示合成成功率
	local suc="成功率：0%"
	local prob=com.prob
	for i,v in ipairs(prob) do
		if(#self.tt.SelectE.idList<v.id)then 
			self.tt.Succed.text=suc 
			return
		else 
			suc=StrTool.Concat("成功率：",tostring(v.val/100),"%")
		end		
	end
	self.tt.Succed.text=suc
end

function My:ClickPartCustom()
	self.tt:UpData(self.type_id,"成功率：0%")
end

function My:OnCbtnCustom( ... )
	local issucced = false
	local count = #self.tt.SelectE.idList
    local data = EquipCompound[self.type_id]
	local prob = data.prob
	local minneed = prob[1].id
	if count<minneed then UITip.Log("合成最少需要"..minneed.."件材料")return issucced end
	local id = tonumber(self.type_id)
	EquipMgr.ReqECompose(id,self.tt.SelectE.idList)
	ListTool.Clear(self.tt.SelectE.idList)
	issucced=true 
	return issucced
end

--显示Tip
function My:ShowTip()
	self.sText:Dispose()
	local type_id = self.type_id
	local com = EquipCompound[type_id]
	if not com then return end
	local id = tostring(com.canId[1])
	local item = ItemData[id]
	local equip = EquipBaseTemp[id]
	local part=(equip.wearParts>=2 and equip.wearParts<=6) and "防具" or UIMisc.WearParts(equip.wearParts)
	self.sText:Apd("当前阶数的多件[66c34e]"):Apd(self:GetQua(item.quality)):Apd("[66c34e]"):Apd(equip.startLv):Apd("[-]星的"):Apd(part):Apd(",[-]可合成该装备")
	UIComTips:Show(self.sText:ToStr(), Vector3(132,-188,0),nil,nil,5,400,UIWidget.Pivot.TopLeft);
end

function My:OpenCustom( ... )
	self:CreateCellList(3)
	self.tipLab.text="放入装备数量越多，成功率越高"
	if self.sTp==3 then
		self.tog.value=EquipMgr.noshowRed33
	elseif self.sTp==4 then
		self.tog.value=EquipMgr.noshowRed34
	elseif self.sTp == 7 then
		self.tog.value=EquipMgr.noshowRed35
	end
end

function My:ClickCell()
	local idList = {}

	local co = EquipCompound[self.type_id]
	local list = co.canId
	for i,type_id in ipairs(list) do
		local tb = PropMgr.typeIdDic[tostring(type_id)]
		if(tb~=nil and #tb~=0)then
			for i1,v1 in ipairs(tb) do
				idList[#idList+1] =v1
			end
		end
	end
	self.tt.SelectE:UpData(idList)
end

function My:OnTog()
	local val = self.tog.value
	if self.sTp==3 then
		EquipMgr.noshowRed33=val
		EquipMgr.SetRed33()
	elseif self.sTp==4 then
		EquipMgr.noshowRed34=val
		EquipMgr.SetRed34()
	elseif self.sTp == 7 then
		EquipMgr.noshowRed35=val
		EquipMgr.SetRed35()
	end
	self:PartRed()
end

--一键添加
function My:OnAKey()
	local idList = self.tt.SelectE.idList
	ListTool.Clear(idList)
	local data=EquipCompound[self.type_id]
	local prob = data.prob
	local maxNum = prob[#prob].id
	local canId = data.canId
	for i,v in ipairs(canId) do
		local dic = self.typeIdDic[tostring(v)]
		if dic then 
			for k,id in pairs(dic) do
				local tb = self.tbDic[tostring(id)]
				if tb then 
					table.insert( idList, id )
				end
				if #idList==maxNum then break end
			end
		end
		if #idList==maxNum then break end
	end

	self:OnSelect()
end

function My:GetQua(qua)
	local color = UIMisc.LabColor(qua)
	local x = UIMisc.GetColorLb(qua)
	return color..x.."[-]"
end

--装备合成返回
-- function My:OnCompose()
-- 	self.tt.Succed.text="成功率：0%"
-- 	ListTool.Clear(self.SelectE.idList)
-- 	for i,cell in ipairs(self.cellList) do
-- 		cell:AddActive(true)
-- 		cell:Clean()
-- 	end
-- end