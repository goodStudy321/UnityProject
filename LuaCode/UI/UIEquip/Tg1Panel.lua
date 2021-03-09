Tg1Panel=EquipPanelBase:New{Name="Tg1Panel"}
local My = Tg1Panel
My.eSort=Event()

function My:SetEvent(fn)
    EquipMgr.eRefine[fn](EquipMgr.eRefine,self.OnRefine,self)
end

function My:OnRefine(tb,part)
    self:ShowPartTip(part,true)
end

--文字内容
function My:ShowPartTip(part,isevent)
    EquipPanel.str:Dispose()
    local tb=EquipMgr.hasEquipDic[part]
	if not tb then return end
    local item = UIMisc.FindCreate(tb.type_id)
    local cell = EquipPanel.cellDic[part]
    local id = EquipMgr.FindType(part)+tb.lv+1
    local next=EquipStr[tostring(id)]
    EquipPanel.str:Line()
    EquipPanel.str:Apd(UIMisc.LabColor(item.quality)):Apd(item.name):Apd("+"):Apd(tb.lv)
    if not next then
		cell:FullState(true)
		if isevent==true then My.eSort() end
    else	
        EquipPanel.str:Line()
		if User.instance.MapData.Level<next.level then  
			EquipPanel.str:Apd("[-][ffffff]"):Apd(next.level):Apd("级才可继续强化") 
			if isevent==true then My.eSort() end
		end
    end
    cell:UpName(EquipPanel.str:ToStr())
end

--红点
function My:ShowPartRed(part)
    local tb=EquipMgr.hasEquipDic[part]
    local cell = EquipPanel.cellDic[part]
    local redDic=EquipMgr.qianghuaPartRed
    local red=redDic[tostring(part)] or false
    if not cell then
        iTrace.eError("xiaoyu","格子为空: "..tostring(part))
    end
    cell:OnRed(red)
end

--排序
function My:Sort(partList)
    if #partList>1 then table.sort(partList, My.SortFull) end
end

function My.SortFull(a,b)
	local tb1 = EquipMgr.hasEquipDic[a]
	local tb2 = EquipMgr.hasEquipDic[b]
	local equip1=EquipBaseTemp[tostring(tb1.type_id)]
	local equip2 = EquipBaseTemp[tostring(tb2.type_id)]
	local next1 = EquipStr[tostring(EquipMgr.FindType(a)+tb1.lv+1)]
	local next2 = EquipStr[tostring(EquipMgr.FindType(b)+tb2.lv+1)]
	if next1 and next2 then
		local x1=My.CanStrengthon(a,b) 
		return x1
	elseif not next1 and not next2 then
		return false
	else
		return next1==nil
	end
end

function My.CanStrengthon(a,b)
	local tb1 = EquipMgr.hasEquipDic[a]
	local tb2 = EquipMgr.hasEquipDic[b]
	local lv1=tb1.lv or 0
	local lv2=tb2.lv or 0
	local id1=tostring(EquipMgr.FindType(tonumber(a))+lv1+1)
	local id2=tostring(EquipMgr.FindType(tonumber(b))+lv2+1)
	local str1=EquipStr[id1]
	if not str1 then iTrace.eError("xiaoyu","装备强化概率表为空 id:"..id1) end
	local str2=EquipStr[id2]
	if not str2 then iTrace.eError("xiaoyu","装备强化概率表为空 id:"..id2) end
	local money = RoleAssets.Silver
	local state1 = money>=str1.money and true or false
	local state2 = money>=str2.money and true or false
	if state1==state2 then
		return My.SortLevel(a,b)
	else
		return state1==true
	end
end

function My.SortLevel(a,b)
	local tb1 = EquipMgr.hasEquipDic[a]
	local tb2 = EquipMgr.hasEquipDic[b]
	local lv1=tb1.lv or 0
	local lv2=tb2.lv or 0
	local id1=tostring(EquipMgr.FindType(tonumber(a))+lv1+1)
	local id2=tostring(EquipMgr.FindType(tonumber(b))+lv2+1)
	local str1=EquipStr[id1]
	local str2=EquipStr[id2]
	local can1 = User.instance.MapData.Level>=str1.level and true or false
	local can2 = User.instance.MapData.Level>=str2.level and true or false
	if can1==can2 then
		return My.SortLv(a,b)
	else
		return can1==true
	end
end

function My.SortLv(a,b)
	local tb1 = EquipMgr.hasEquipDic[a]
	local tb2 = EquipMgr.hasEquipDic[b]
	local lv1=tb1.lv or 0
	local lv2=tb2.lv or 0
	if lv1==lv2 then 
		return My.SortPart(a,b)
	else
		return lv1<lv2
	end 
end

function My.SortPart(a,b)
	local a1 = tonumber(a)
	local a2 = tonumber(b)
	return a1<a2
end