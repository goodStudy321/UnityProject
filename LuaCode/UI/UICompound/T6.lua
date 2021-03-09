--[[
天机印合成
--]]
T6=TBase:New{Name="T6"}
local My = T6

function My:InitCustom()
	self.tog.value=Naturemgr.noshowRed
	self.nameLab=ComTool.Get(UILabel,self.tt.trans,"W1/bg/nameLab",self.Name,false)
end

function My:CreateTb(selectId)
	local U=UITool.SetLsnrSelf
	local TF = TransTool.FindChild
	local CG = ComTool.Get

	self.dic = Naturemgr.tab
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
				local temp = NatureCompose[v2]
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
			if k==minTp1 and k1==minTp2 then
				self:OnT(go) 
				self:OnTg(goo) 
			end
			U(goo,self.OnTg,self,self.Name)
		end
		U(go,self.OnT,self,self.Name, false)
		tab:Reposition()
	end
	self.tt.table.repositionNow=true
end

function My:SelectLight(selectId)
	local minTp1,minTp2=nil,nil
	local dic = self.dic
	if selectId and selectId~=0 then
		local temp = NatureCompose[tostring(selectId)]
		if not temp==nil then iTrace.eError("xiaoyu","天机印合成表为空 id: "..selectId)return end
		for k,v in pairs(dic) do
			for k1,v1 in pairs(v) do
				for k2,v2 in pairs(v1) do
					local temp = NatureCompose[v2]
					local needId = temp.needId
					if needId==tostring(selectId) then
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

function My:PartRed()
	local dic= self.dic
	local typeDic = dic[tostring(self.tX)]
	local rankDic= typeDic[self.tY]
	for part,v2 in pairs(rankDic) do
		local red = false
		if Naturemgr.noshowRed==false then 
			local data = NatureCompose[v2]
			local needid = data.needId
			local needNum = data.needNum
			local has = PropMgr.TypeIdByNum(needid,5)
			red=has>=needNum
		end
		local cell = self.partCellList[tonumber(part)]
		cell:PartRed(red)
	end
end

function My:ClickPartCustom( ... )
	self.tt:UpData(self.type_id)
	self:ShowTip()
end

function My:OnCbtnCustom()
	local issucced=false
	local count = #self.tt.SelectE.idList
	local data = NatureCompose[self.type_id]
	local num = data.needNum
	if count<num then UITip.Log("合成材料不足") return issucced end
	local id = tonumber(self.type_id)
	EquipMgr.ReqNatureCompose(id)
	ListTool.Clear(self.tt.SelectE.idList)
	issucced=true
	return issucced
end


--显示Tip
function My:ShowTip()
	local temp = NatureCompose[self.type_id]
	local id = temp.needId
	local num = temp.needNum
	local needTemp=NatureCompose[id]
	local data = SMSProTemp[id]
	local qua = data.quality
	local star = data.star or 0
	local index = data.index
	local text = string.format( "%s件%s%s%s星[-][66c34e]%s[-]可合成该天机印",num,UIMisc.LabColor(qua),UIMisc.GetColorLb(qua),star,needTemp.name)
	self.tipLab.text=text
	
	self.nameLab.text=UIMisc.LabColor(tonumber(temp.qua))..temp.name
end

function My:OpenCustom( ... )
	self:CreateCellList(4)
end


function My:ClickCell(cell)
	local temp = NatureCompose[self.type_id]
	local needId = temp.needId
	self.tt.SelectE:NatureUpData(needId)
end

function My:OnTog()
	local val = self.tog.value
	Naturemgr.noshowRed=val
	Naturemgr.SetRed()
	self:PartRed()
end

--一键添加
function My:OnAKey()
	local idList = self.tt.SelectE.idList
	ListTool.Clear(idList)
	local temp=NatureCompose[self.type_id]
	local needId = temp.needId
	local maxNum = temp.needNum
	local dic = self.typeIdDic[tostring(needId)]
	if dic then
		for k,id in pairs(dic) do
			local tb = self.tbDic[tostring(id)]
			if tb then 
				idList[#idList+1]=id
			end
			if #idList==maxNum then break end
		end
	end
	self:OnSelect()
end

function My:CloseCustom( ... )
	self.nameLab.text=""
end
