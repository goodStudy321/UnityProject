Tg5Panel=EquipPanelBase:New{Name="Tg5Panel"}
local My = Tg5Panel

function My:SetEvent(fn)
	EquipMgr.eSealPunch[fn](EquipMgr.eSealPunch,self.OnPunch,self)
	EquipMgr.eSealRemove[fn](EquipMgr.eSealRemove,self.OnPunch,self)
	EquipMgr.eASealKey[fn](EquipMgr.eASealKey,self.OnASealKey,self)
end

function My:OnASealKey(tp)
	for k,v in pairs(EquipMgr.hasEquipDic) do
		local cell = EquipPanel.cellDic[k]
    	self:ShowGem(v,cell.tList)
	end
end

function My:OnPunch(tb,part)
    local cell = EquipPanel.cellDic[part]
    self:ShowGem(tb,cell.tList)
end

--文字内容
function My:ShowPartTip(part)
    local cell = EquipPanel.cellDic[part]
    EquipPanel.str:Dispose()
    local tb=EquipMgr.hasEquipDic[part]
    local item = UIMisc.FindCreate(tb.type_id)
    EquipPanel.str:Apd(UIMisc.LabColor(item.quality)):Apd(item.name)
	cell:UpName(EquipPanel.str:ToStr())
	cell:GridState(true)
    self:ShowGem(tb,cell.tList)
end

function My:ShowGem(tb,tList)
	local dic=tb.slDic
	for i,v in pairs(tList) do
		v.spriteName="xq_0"
	end
	tList[#tList].gameObject:SetActive(false)
	local index = 1
	for k,v in pairs(dic) do
		local gem=tSealData[tostring(v)]
		local tp = gem.type
		tList[index].spriteName=EquipColor[20+tp]
		index=index+1
	end
end

--红点
function My:ShowPartRed(part)
    local tb=EquipMgr.hasEquipDic[part]
    local cell = EquipPanel.cellDic[part]
    local redDic=EquipMgr.wenyinPartDic
    local red=redDic[tostring(part)]
    cell:OnRed(red)
end

--排序
function My:Sort(partList)
    table.sort(partList,My.SortCanGem) 
end

function My.SortCanGem(a,b)
	local tb1 = EquipMgr.hasEquipDic[a]
	local tb2 = EquipMgr.hasEquipDic[b]
	local equip1=EquipBaseTemp[tostring(tb1.type_id)]
	local equip2 = EquipBaseTemp[tostring(tb2.type_id)]
	local add = 0
	local vip = VIPMgr.GetVIPLv()
	local vipInfo = soonTool.GetVipInfo(vip)
	if vipInfo.sealVip== 1 then  add=1 end
	local num1 = equip1.SealholesNum or 0
	num1=num1+add
	local num2 = equip2.SealholesNum or 0
	num2=num2+add
	local can1,can2=false,false
	local gemList1 = PropMgr.GetSealByPart(a)
	local gemList2 = PropMgr.GetSealByPart(b)
	local gemNum1 = TableTool.GetDicCount(tb1.slDic)
	local gemNum2 = TableTool.GetDicCount(tb2.slDic)
	if num1>gemNum1 and gemList1 and #gemList1>0 then
		can1=true
	end
	if num2>gemNum2 and gemList2 and #gemList2>0 then
		can2=true
	end
	if can1==true and can2==true then
		local lerp1 = num1-gemNum1
		local lerp2 = num2-gemNum2
		return My.SortCanNum(lerp1,lerp2,a,b)
	elseif can1==false and can2==false then 
		return My.SortCanLv(a,b)
	else 
		return can1==true
	end
end

function My.SortCanNum(lerp1,lerp2,a,b)
	if lerp1==lerp2 then
		return tonumber(a)<tonumber(b)	
	else
		return lerp1>lerp2
	end
end

function My.SortCanLv(a,b)
	local better1,better2,num1,num2=0,0,0,0
	local tb1 = EquipMgr.hasEquipDic[a]
	local tb2 = EquipMgr.hasEquipDic[b]
	local gemList1 = PropMgr.GetSealByPart(a)
	local gemList2 = PropMgr.GetSealByPart(b)
	local gemDic1 = tb1.slDic
	local gemDic2 = tb2.slDic
	if gemList1 then 
		for k,v in pairs(gemDic1) do
			local gem = tSealData[tostring(v)]
			for i1,v1 in ipairs(gemList1) do
				local da = tSealData[tostring(v1)]
				if da.lv>gem.lv then 
					better1=da.lv
					num1=num1+1
				end
			end
		end
	end

	if gemList2 then 
		for k,v in pairs(gemDic2) do
			local gem = tSealData[tostring(v)]
			for i1,v1 in ipairs(gemList2) do
				local da = tSealData[tostring(v1)]
				if da.lv>gem.lv then 
					better2=da.lv
					num2=num2+1
				end
			end
		end
	end
	if better1~=0 and better2~=0 then
		return My.SortBetterNum(num1,num2,a,b)
	elseif better1==0 and better2==0 then
		return My.SortGemUp(gemList1,gemList2,a,b)
	else
		return better1~=0
	end
end

function My.SortBetterNum(num1,num2,a,b)
	if num1==num2 then 
		return tonumber(a)<tonumber(b)
	else
		return num1>num2
	end
end

function My.SortGemUp(gemList1,gemList2,a,b)
	local isup1,isup2 
	local lv1,lv2,num1,num2=0,0,0,0
	if gemList1 then 
		for i,v in ipairs(gemList1) do
			local isup=EquipMgr.GetSealUp(v,a)
			local gem = tSealData[tostring(v)]
			if isup==true then 
				isup1=true 
				if gem.lv<lv1 then lv1=gem.lv end
				num1=num1+1
			end
		end
	end
	if gemList2 then 
		for i,v in ipairs(gemList2) do
			local isup=EquipMgr.GetSealUp(v,b)
			local gem = tSealData[tostring(v)]
			if isup==true then 
				isup2=true 
				if not lv2 then lv2=0 end
				if gem.lv<lv2 then lv2=gem.lv end
				num2=num2+1
			end
		end
	end
	if isup1==true and isup2==true then
		return My.SortUpLv(lv1,lv2,num1,num2,a,b)
	elseif isup1~=true and isup2~=true then
		return tonumber(a)<tonumber(b)
	else
		return isup1==true
	end
end

function My.SortUpLv(lv1,lv2,num1,num2,a,b)
	if lv1==lv2 then 
		if num1==num2 then
			return tonumber(a)<tonumber(b)
		else
			return num1>num2
		end
	else
		return lv1<lv2
	end
end