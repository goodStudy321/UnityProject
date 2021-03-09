RobEquipsMgr =  {Name = "RobEquipsMgr"}
local My = RobEquipsMgr;
--装备部位列表
My.parts = {"10","9","8","7","1","3","4","2","5","6"}
--战灵灵器字典
My.equipDic = {}
--战灵灵器开启字典
My.openDic = {}
--战灵装备红点
My.redDic = {}
My.eAddEquip = Event();
My.eOpenLock = Event();
My.eRmEquip = Event();
My.eRfrRed = Event();

function My:Init()
    self:AddLsnr();
end

function My:AddLsnr()
    ProtoLsnr.AddByName("m_war_spirit_armor_load_toc",self.RespArmorLoad,self);
    ProtoLsnr.AddByName("m_war_spirit_armor_unload_toc",self.RespArmorUnload,self);
    ProtoLsnr.AddByName("m_war_spirit_armor_lock_info_toc",self.RespArmorOpenLock,self);
    PropMgr.eAdd:Add(self.BgAddEquip,self);
    PropMgr.eRemove:Add(self.BgRemoveEquip,self);
end

--请求穿戴灵器
function My:ReqArmorLoad(spirId,equipTbl)
    if spirId == nil or equipTbl == nil then
        return;
    end
    local msg = ProtoPool.Get("m_war_spirit_armor_load_tos");
    msg.war_spirit_id = spirId;
    for k,v in pairs(equipTbl) do
        msg.goods_ids:append(v);
    end
    ProtoMgr.Send(msg);
end

--请求脱下灵器
function My:ReqArmorUnload(spirId,equipTbl)
    if spirId == nil or equipTbl == nil then
        return;
    end
    local msg = ProtoPool.Get("m_war_spirit_armor_unload_tos");
    msg.war_spirit_id = spirId;
    for k,v in pairs(equipTbl) do
        msg.type_ids:append(v);
    end
    ProtoMgr.Send(msg);
end

--请求开启灵器部位
function My:ReqArmorOpenLock(spirId,part)
    if spirId == nil or part == nil then
        return;
    end
    local msg = ProtoPool.Get("m_war_spirit_armor_lock_info_tos");
    msg.war_spirit_id = spirId;
    msg.index = tonumber(part);
    ProtoMgr.Send(msg);
end

--初始化战灵装备
function My:InitSpirEquips(spirList)
    if spirList == nil then
        return;
    end
    for k,v in pairs(spirList) do
        self:SetSpirEquips(v.id,v.armor_list);
    end
    self:InitRed();
end

--设置战灵装备部位锁状态
function My:SetSpirEquipsLock(list,isUpdate)
    if list == nil then
        return;
    end
    for i = 1,#list do
        self:SetEquipsOpenLock(list[i],isUpdate);
    end
end

--初始化红点
function My:InitRed()
    local equips = PropMgr.GetBagEquip();
    if equips == nil then
        return nil;
    end
    if #equips == 0 then
        return nil;
    end
    for k,v in pairs(equips) do
        self:BgAddEquip(v,nil,1);
    end
end

--战灵灵器穿戴返回
function My:RespArmorLoad(msg)
    local err = msg.err_code;
    if err ~= 0 then
        local msg = ErrorCodeMgr.GetError(err);
        UITip.Log(msg);
        return;
    end
    local spirId = msg.war_spirit_id;
    local chgEquips = msg.change_armors;
    self:SetSpirEquips(spirId,chgEquips);
end

--设置战灵装备
function My:SetSpirEquips(spirId,chgEquips)
    if chgEquips == nil then
        return;
    end
    for i = 1,#chgEquips do
        self:AddEquip(spirId,chgEquips[i]);
    end
end

--战灵灵器脱下返回
function My:RespArmorUnload(msg)
    local err = msg.err_code;
    if err ~= 0 then
        local msg = ErrorCodeMgr.GetError(err);
        UITip.Log(msg);
        return;
    end
    local delEquips = msg.del_type_ids;
    local spirId = msg.war_spirit_id;
    if delEquips == nil then
        return;
    end
    for i = 1,#delEquips do
        self:RemoveEquip(spirId,delEquips[i]);
    end
end

--战灵灵器部位开启
function My:RespArmorOpenLock(msg)
    local err = msg.err_code;
    if err ~= 0 then
        local msg = ErrorCodeMgr.GetError(err);
        UITip.Log(msg);
        return;
    end
    local list = msg.armors;
    self:SetSpirEquipsLock(list,true);
end

--设置战灵装备锁
function My:SetEquipsOpenLock(list,isUpdate)
    if list == nil then
        return;
    end
    local spirId = list.war_spirit_id;
    local openInfos = list.list;
    for i = 1,#openInfos do
        self:SetLockState(spirId,openInfos[i],isUpdate);
    end
end

--战灵是否有红点
function My:SpirHasRed()
    for k,v in pairs(SpiriteCfg) do
        local spirId = v.spiriteId;
        local red = My.GetSpirRed(spirId);
        if red == true then
            return true;
        end
    end
    return false;
end

--获取战灵红点
function My.GetSpirRed(spirId)
    local equips,parts = My.GetPutOnEqs(spirId,true);
    if #equips ~= 0 then
        return true;
    end
    return false;
end

--背包删除装备
function My:BgRemoveEquip(id,tp,typeId,action)
    if tp ~= 1 then
        return;
    end
    My.eRfrRed();
end

--背包增加装备
function My:BgAddEquip(tb,action,tp)
    if tp ~= 1 then
        return;
    end
    if tb == nil then
        return;
    end
    local id = tb.id;
    id = tostring(id);
    local typeId = tb.type_id;
    local isEquip = My.IsEquip(typeId);
    if isEquip == false then
        return;
    end
    local propTb = PropMgr.tbDic[id];
    if propTb == nil then
        return;
    end
    --如果装备比人物身上的装备高就不显示红点
    if propTb.isUp == true then
        return;
    end
    My.eRfrRed();
end

--是否是装备
function My.IsEquip(typeId)
    local item = UIMisc.FindCreate(typeId);
    if item == nil then
        return false;
    end
    if item.uFx ~= 1 then
        return false;
    end
    return true;
end

--添加装备
function My:AddEquip(spirId,equipInfo)
    local dic = My.equipDic;
    local equips = dic[spirId];
    if equips == nil then
        equips = {};
        dic[spirId] = equips;
    end
    local equipId = equipInfo.type_id;
    local excellents = equipInfo.excellent_list;
    local part = My.GetEquipPart(equipId);
    local equipTb = equips[part];
    if equipTb == nil then
        equipTb = ObjPool.Get(EquipTb);
    end
    equipTb:SetInit(equipId,excellents);
    equips[part] = equipTb;

    My.eAddEquip(spirId,part,equipId);
end

--移除装备
function My:RemoveEquip(spirId,equipId)
    local dic = My.equipDic;
    local equips = dic[spirId];
    if equips == nil then
        return;
    end
    local part = My.GetEquipPart(equipId);
    if equips[part] == nil then
        return;
    end
    local equipTb = equips[part];
    if equipTb ~= nil then
        ObjPool.Add(equipTb);
    end
    equips[part] = nil;
    My.eRmEquip(spirId,part,equipId);
end

--设置锁状态
function My:SetLockState(spirId,openInfo,isUpdate)
    local dic = My.openDic;
    local lockInfos = dic[spirId];
    if lockInfos == nil then
        lockInfos = {};
        dic[spirId] = lockInfos;
    end
    local isOpen = openInfo.is_open;
    local part = openInfo.index;
    self:ShowOpenTip(lockInfos,part,isOpen,isUpdate);
    lockInfos[part] = isOpen;

    My.eOpenLock(spirId,part);
end

--显示开启提示
function My:ShowOpenTip(lockInfos,part,isOpen,isUpdate)
    if isUpdate == nil or isUpdate == false then
        return;
    end
    if isOpen == false then
        return;
    end
    local result = lockInfos[part];
    if result == true then
        return;
    end
    local text = UIMisc.WearParts(part);
    local msg = string.format("【%s】部位开启成功",text);
    UITip.Log(msg);
end

--获取装备部位
function My.GetEquipPart(equipId)
    local equipIdStr = tostring(equipId);
    local info = EquipBaseTemp[equipIdStr];
    if info ~= nil then
        return info.wearParts;
    end
end

--是否可开锁
function My.IsOpenLock(openRobId)
    if openRobId == nil then
        return false;
    end
    if openRobId > RobberyMgr.curState then
        return false;
    end
    return true;
end

--获取开启的渡劫ID
function My.GetOpenRobId(spirId,part)
    spirId = tostring(spirId);
    local openInfo = SpiriteCfg[spirId];
    if openInfo == nil then
        return;
    end
    part = tonumber(part);
    local openRobId = openInfo.equips[part];
    return openRobId;
end

--获取开启需要的物品
function My.GetOpenNeedItem(spirId,part)
    spirId = tostring(spirId);
    local openInfo = SpiriteCfg[spirId];
    if openInfo == nil then
        return;
    end
    part = tonumber(part);
    local needItem = openInfo.needItems[part];
    return needItem;
end

--锁是否已经开启
function My.LockIsOpen(spirId,part)
    local partsInfo = My.openDic[spirId];
    if partsInfo == nil then
        return false;
    end
    part = tonumber(part);
    local isOpen = partsInfo[part];
    if isOpen == nil then
        return false;
    end
    return isOpen;
end

--是否满足境界ID
function My.IsStfRobId(spirId,part)
    local openRobId = My.GetOpenRobId(spirId,part);
    local isStf = My.IsOpenLock(openRobId);
    return isStf;
end

--获取开启描述
function My.GetOpenDes(spirId,part)
    local openRobId = My.GetOpenRobId(spirId,part);
    if openRobId == nil then
        return "";
    end
    local ambit = RobberyMgr:GetCurCfg(openRobId);
    if ambit == nil then
        return "";
    end
    return ambit.floorName;
end

--获取境界开启的战灵装备孔相关信息
function My.GetOpSpirEq(robId)
    for k,v in pairs(SpiriteCfg) do
        local spirId,part = My.GetRobInfo(v,robId);
        if spirId ~= nil then
            return spirId,part;
        end
    end
end

--获取境界开启战灵的信息
function My.GetRobInfo(cfg,robId)
    local robIds = cfg.equips;
    if robIds == nil then
        return;
    end
    local len = #robIds;
    for part = 1,len do
        if robIds[part] == robId then
            local spirId = cfg.spiriteId;
            return spirId,part;
        end
    end
end

--获取部位装备
function My.GetPartEquips(part,isRedUse)
    local equips = PropMgr.GetBagEquip();
    if equips == nil then
        return nil;
    end
    if #equips == 0 then
        return nil;
    end
    local propTbs = {}
    for k,v in pairs(equips) do
        local typeId = tostring(v.type_id);
        local tmpPart = PropTool.FindPart(typeId);
        if tmpPart == part then
            if isRedUse ~= nil then
                if v.isUp == false then
                    table.insert(propTbs,v);
                end
            else
                table.insert(propTbs,v);
            end
        end
    end
    if #propTbs == 0 then
        return nil;
    end
    return propTbs;
end

--获取部位可穿戴装备
function My.GetPartPOEquips(part)
    local equips = PropMgr.GetBagEquip();
    if equips == nil then
        return nil;
    end
    if #equips == 0 then
        return nil;
    end
    local propTbs = {}
    for k,v in pairs(equips) do
        local typeId = tostring(v.type_id);
        local tmpPart = PropTool.FindPart(typeId);
        if tmpPart == part then
            local canPutOn = My.CanPutOn(v);
            if canPutOn == true then
                table.insert(propTbs,v);
            end
        end
    end
    if #propTbs == 0 then
        return nil;
    end
    return propTbs;
end

--是否已穿戴装备
function My.IsWearEquip(spirId,part)
    part = tonumber(part);
    local equips = My.equipDic[spirId];
    if equips == nil then
        return false;
    end
    local eqInfo = equips[part];
    if eqInfo == nil then
        return false;
    end
    return true;
end

--获取对应部位战灵装备
function My.GetSpirEqTb(spirId,part)
    part = tonumber(part);
    if spirId == nil then
        return nil;
    end
    local equips = My.equipDic[spirId];
    if equips == nil then
        return;
    end
    local equipTb = equips[part];
    return equipTb;
end

--获取当前战灵Id
function My.GetCurSpirId()
    local curSpirId = SpItemCom.curSpirId;
    return curSpirId;
end

--获取一键穿戴装备列表
function My.GetPutOnEqs(spirId,isRedUse)
    local equips = My.equipDic[spirId];
    --获取能穿戴的以及比身上的好的装备
    local equipIds = {};
    local parts = {};
    for k,v in pairs(My.parts) do
        local id,hFight = My.GetHFightEquip(spirId,v,isRedUse);
        if id ~= nil then
            local part = tonumber(v);
            local equipTb = nil;
            local index = #equipIds + 1;
            if equips ~= nil then
                equipTb = equips[part];
            end
            if equipTb == nil then
                equipIds[index] = id;
                parts[v] = true;
            else
                local curFight = PropTool.Fight(equipTb);
                if hFight > curFight then
                    equipIds[index] = id;
                    parts[v] = true;
                end
            end
        end
    end
    return equipIds,parts;
end

--获取最高战力可穿戴装备
function My.GetHFightEquip(spirId,part,isRedUse)
    local isOpenLock = My.LockIsOpen(spirId,part);
    if isOpenLock == false then
        return;
    end
    local propTbs = My.GetPartEquips(part,isRedUse);
    if propTbs == nil then
        return;
    end
    local hFight = 0;
    local id = nil;
    for k,v in pairs(propTbs) do
        local canPutOn = My.CanPutOn(v);
        if canPutOn == true then
            local tmpF = PropTool.Fight(v);
            if tmpF > hFight then
                id = v.id;
                hFight = tmpF;
            end
        end
    end
    return id, hFight;
end

--是否可穿戴
function My.CanPutOn(propTb)
    if propTb == nil then
        return false;
    end
    local typeId = propTb.type_id;
    if typeId == nil then
        return false;
    end
    typeId = tostring(typeId);
    local item = ItemData[typeId];
    if item == nil then
        return false;
    end
    if item.canUse ~= 1 then
        return false;
    end
    local lv = item.useLevel or 0;
	local vip = item.useVIP or 0;
	local gg = item.gilgulLv or 0;
	local cate = item.cateLim or 0; --职业
    local realm = item.realm or 0; --境界
    local actData = User.instance.MapData;
	--职业
	if(cate~=0 and actData.Category~=cate)then
		--职业不符
		return false;
	end
	if(lv ~= 0 and actData.Level < lv )then
		--等级不足
		return false;
    end
    local cfg = RobberyMgr:GetCurCfg();
	if(realm ~= 0 and cfg.id < realm )then
		--境界不足
		return false;
    end
    local curVip = VIPMgr.GetVIPLv();
	if(vip ~= 0 and curVip < vip )then
		return false;
	end
	if(gg ~= 0 and RebirthMsg.RbLev < gg)then
		--转生等级不足
		return false;
	end
    return true;
end

function My.yesCb()
	VIPMgr.OpenVIP(1)
end

function My.yesCb2()
	UIMgr.Open(UIV4Panel.Name)
end

--清除装备字典
function My:ClearEquipDic()
    for k,v in pairs(My.equipDic) do
        for part,equipTb in pairs(v) do
            ObjPool.Add(equipTb);
        end
        TableTool.ClearDic(v);
    end
end

--清除开启字典
function My:ClearOpenDic()
    local dic = My.openDic;
    for k,v in pairs(dic) do
        for key,val in pairs(v) do
            v[key] = false;
        end
    end
end

function My:Clear()
    self:ClearEquipDic();
    self:ClearOpenDic();
end

function My:Dispose()
    self:Clear();
    My.equipDic = nil;
    My.eAddEquip = nil;
    My.eRmEquip = nil;
end

return My;