SpiritGMgr = {Name="SpiritGMgr"}
local My = SpiritGMgr
local Send = ProtoMgr.Send

My.SpiritInfo = {}
My.SpiritDic = {}  -- key:战灵ID, val： unit
My.BagInfo = {}--灵饰背包数据  
My.CurSPId = 0 --当前战灵Id
My.CurEquipId = 0 --当前强化装备ID
My.AdvData = nil --当前进阶装备的数据
My.All = 100
My.strengthExpVal = 0
My.SpRedInfo = {} --key:战灵id   val:红点状态
My.StrSpRedInfo = {} --key:战灵id   val:红点状态
My.EquipRedInfo = {} --key:装备唯一id  val:红点状态
My.StrBtnState = false --灵饰强化按钮红点状态

My.eUpdateSBInfo = Event()     --灵饰数据变动更新
My.eUpdateBagInfo = Event()     --背包数据变动更新
My.eUpdateStrengthInfo = Event()  --灵饰强化数据变动更新
My.eUpdateComposeInfo = Event()  --灵饰分解数据变动更新
My.eUpdateAdvInfo = Event() --灵饰进阶数据变动更新
My.eUpdateRedInfo = Event() --灵饰红点数据变动
My.eUpdateEquipRedInfo = Event()

function My:Init()
	self:Clear()
    self:AddProto()
    self:SetEvent("Add")
end



function My:AddProto()
    PropMgr.eUpdate:Add(self.GetPropNum, self)    --GetPropNum  UpdateRedPoint
    RobberyMgr.eUpdateSpiRefInfo:Add(self.UpdateRedPoint, self)   
    self:ProtoHandler(ProtoLsnr.Add)
end

function My:RemoveProto()
    PropMgr.eUpdate:Remove(self.GetPropNum, self)
    RobberyMgr.eUpdateSpiRefInfo:Remove(self.UpdateRedPoint, self)
    self:ProtoHandler(ProtoLsnr.Remove)
end

function My:ProtoHandler(Lsnr)
	Lsnr(23000, self.RespStateInfo, self)	 -- " m_confine_info_toc  境界信息  "  
	Lsnr(24202, self.RespSpEquipAdd, self)	 -- " m_war_spirit_equip_add_toc  战灵装备背包新增  "  
	Lsnr(24204, self.RespSpEquipDel, self)	 -- " m_war_spirit_equip_del_toc  战灵装备背包删除  "  
	Lsnr(24212, self.RespSpEquipLoad, self)	 -- " m_war_spirit_equip_load_toc  战灵装备穿戴返回  "  
	Lsnr(24214, self.RespSpEquipUnLoad, self)	 -- " m_war_spirit_equip_unload_toc  战灵装备脱下返回  "  
	Lsnr(24222, self.RespSpEquipDecom, self)	 -- " m_war_spirit_equip_decompose_toc  战灵灵饰分解返回  "  
	Lsnr(24224, self.RespSpEquipStreng, self)	 -- " m_war_spirit_equip_refine_toc  战灵灵饰强化返回  "  
	Lsnr(24232, self.RespSpEquipAdv, self)	 -- " m_war_spirit_equip_step_toc  战灵灵饰进阶返回  "  
end

function My:SetEvent()
    -- PropMgr.eUpdate[key](PropMgr.eUpdate, self.OnChangeBag, self)
end

--登陆时返回信息
function My:RespStateInfo(msg)
    self:InitData()

    self.strengthExpVal = msg.refine_all_exp --强化经验（int64)
    local list = msg.bag_list -- 战灵背包
    local spiritTab = msg.war_spirit_list
    for i = 1,#spiritTab do
        local spInfo = spiritTab[i]
        self:UpdateSBInfo(spInfo.id,spInfo)
    end

    for i=1,#list do
        self:AddBagUnit(list[i])
    end
    self:SortBag()
    self:UpdateRedPoint()
end

-- 战灵装备背包新增 返回
function My:RespSpEquipAdd(msg)
    local list = msg.add_list
    for i=1,#list do
        self:AddBagUnit(list[i])
    end
    self:SortBag()
    self:UpdateRedPoint()
    self.eUpdateBagInfo()
    self.eUpdateRedInfo()
end

-- 战灵装备背包删除 返回
function My:RespSpEquipDel(msg)
    local list = msg.del_list
    for i=1, #list do
        self:RemoveBagUnit(list[i])
    end
    self:SortBag()
    self:UpdateRedPoint()
    self.eUpdateBagInfo()
    self.eUpdateRedInfo()
end

-- 战灵装备穿戴返回
function My:RespSpEquipLoad(msg)
    if self:CheckErr(msg.err_code) then return end
    local spId = self.CurSPId
    local equipData = msg.war_spirit
    self:UpdateSBInfo(spId,equipData)
    self:UpdateRedPoint()
    self.eUpdateSBInfo()
    self.eUpdateRedInfo()
end

-- 战灵装备脱下返回
function My:RespSpEquipUnLoad(msg)
    if self:CheckErr(msg.err_code) then return end
    local spId = self.CurSPId
    local equipData = msg.war_spirit
    self:UpdateSBInfo(spId,equipData)
    self:UpdateRedPoint()
    self.eUpdateSBInfo()
    self.eUpdateRedInfo()
end

-- 战灵灵饰分解返回
function My:RespSpEquipDecom(msg)
    if self:CheckErr(msg.err_code) then return end
    UITip.Log("分解成功")
    self.strengthExpVal = msg.refine_all_exp
    self:UpdateRedPoint()
    self.eUpdateComposeInfo()
    self.eUpdateEquipRedInfo()
end

-- 战灵灵饰强化返回
function My:RespSpEquipStreng(msg)
    if self:CheckErr(msg.err_code) then return end

    UITip.Log("强化成功")
    local spId = msg.war_spirit_id
    self:UpdateSBEquip(spId, msg.equip)
    self.strengthExpVal = msg.refine_all_exp -- 强化经验值
    self:UpdateRedPoint()
    -- self:UpdateSBScore(id)
    -- self:UpdateSBAttArdd(id)
    self.eUpdateStrengthInfo()
    self.eUpdateEquipRedInfo()
end

-- 战灵灵饰进阶返回
function My:RespSpEquipAdv(msg)
    if self:CheckErr(msg.err_code) then return end
    UITip.Log("进阶成功")
    local spId = msg.war_spirit_id
    self:UpdateSBEquip(spId, msg.equip)
    -- self:UpdateSBScore(id)
    -- self:UpdateSBAttArdd(id)
    self:UpdateRedPoint()
    self.eUpdateAdvInfo()
end

function My:InitData()
    local cfg = SpiriteCfg
    for k,v in pairs(cfg) do
        self:AddSPUnit(v)
    end
end

function My:AddSPUnit(cfg)
    local unit = self:CreateSPUnit(cfg)       
    self.SpiritDic[tostring(unit.id)] = unit
    table.insert(self.SpiritInfo, unit)
end

--创建战灵数据结构
function My:CreateSPUnit(cfg)
    local unit = {}
    unit.id = cfg.spiriteId
    unit.name = cfg.name
    unit.texture = cfg.mIcon
    unit.state = 0
    unit.condList = self:SwitchCond(1, 2, 3, 4)
    unit.redPointState = false
    return unit
end

--转换条件结构
function My:SwitchCond(...)
    local list = {}
    local arg = {...}
    for i=1,#arg do
        local unit = self:CreateCondUnit(i)
        table.insert(list, unit)
    end
    return list
end

--创建条件单元
function My:CreateCondUnit(type)
    local unit = {}
    unit.type = type
    unit.isUse = false
    unit.equipData = {}
    return unit
end

--更新有装备的魂兽信息
function My:UpdateSBInfo(spid,equipData)
    self:UpdateSBEquipList(spid, equipData.equip_list)
end

function My:GetOrCreateUnit(id)
    local key = tostring(id)
    if not self.SpiritDic[key] then
        self.SpiritDic[key] = {}
    end
    return self.SpiritDic[key]
end

--更新战灵身上的装备信息
function My:UpdateSBEquipList(spid,list)
    local unit = self:GetOrCreateUnit(spid)
    local conds = unit.condList
    for k,v in pairs(conds) do
        self:ClearDic(v.equipData)
        v.isUse = false
    end
    if #list == 0 then
        self.StrBtnState = false
    end
    for i=1,#list do
        self:UpdateSBEquip(spid, list[i])
    end
end

--更新魂兽身上的装备信息
function My:UpdateSBEquip(spid,data)
    local unit = self:GetOrCreateUnit(spid)
    local condList = unit.condList
    local cfg = SpiritEquipCfg[tostring(data.type_id)]
    local key = cfg.equipPart
    local cond = condList[key]
    local equip = cond.equipData
    cond.isUse = true
    self:ClearDic(equip)
    self:CreateEquipUnit(equip, data)
    equip.user = spid
end

--添加背包数据
function My:AddBagUnit(data)
    local unit = {}
    self:CreateEquipUnit(unit, data)
    self:UpdateEquipUp(unit)
    table.insert(self.BagInfo, unit)
end

--创建装备单元
function My:CreateEquipUnit(unit, data)
    local key = tostring(data.type_id)
    local nextKey = tostring(data.type_id + 1)
    local cfg = ItemData[key]
    local sECfg = SpiritEquipCfg[key] --灵饰装备表
    local nextSECfg = SpiritEquipCfg[nextKey] --下一灵饰装备表
    if sECfg.consume[1].value == 0 then
        nextSECfg = sECfg
    end
    local lv = data.refine_level --当前强化等级
    local next = lv + 1
    if lv == 0 then
        lv = 1
    end
    local advCfg = SpiritEStrengthCfg[lv] --灵饰装备强化表
    local nextAdvCfg = SpiritEStrengthCfg[next] --下一等级灵饰装备强化表
    local list = data.excellent_list
    unit.id = tonumber(data.id)
    unit.typeId = data.type_id
    unit.level = data.refine_level
    unit.advExp = data.refine_exp --当前强化经验
    if nextAdvCfg == nil then
        unit.needExp = 99999999
        nextAdvCfg = advCfg
    end
    unit.needExp = nextAdvCfg and nextAdvCfg.sExp
    unit.costExp = nextAdvCfg and nextAdvCfg.costExp
    unit.firstAdvTypeId = data.first_step_type_id --初始进阶的TypeID
    unit.attrList = list
    unit.baseAttrList = PropTool.SwitchAttr(sECfg)
    unit.nextBaseAttrList = nextSECfg and PropTool.SwitchAttr(nextSECfg)
    unit.advAttrList = advCfg and PropTool.SwitchAttr(advCfg)
    unit.nextAdvAttrList = nextAdvCfg and PropTool.SwitchAttr(nextAdvCfg)
    unit.bestGroups = self:GetBestInfo(sECfg)
    unit.type = cfg.type   --道具类型
    unit.name = cfg.name
    unit.part = sECfg.equipPart or 0  --装备部位
    unit.quality = sECfg.equipQ or 0
    unit.star = sECfg.st or 0 --星级
    unit.step = sECfg.step --装备阶级
    unit.maxStep = GlobalTemp["103"].Value3 --装备的最大阶级
    unit.blueNum = sECfg.bluePropN  --蓝色极品属性数量
    unit.purpleNum = sECfg.purplePropN --紫色极品属性数量
    unit.advVal = sECfg.sLimit   --基础强化值
    unit.consumeId = sECfg.consume[1].id
    unit.consumePorp = sECfg.consume[1].value
    unit.maxNeedExp = 0
    unit.limitLv = sECfg.maxSLimit
    unit.suitGId = sECfg.suitGId
    unit.extraVal = advCfg and advCfg.totalExp or 0 --强化拥有的强化值
    unit.up = 0
    unit.user = 0 --装备使用者
    unit.other = false--判断是否其他调用
    unit.isUse = false --部位是否已使用
    local score = 0
    for i=1,#list do
        score = score + list[i].type
    end
    local per = (10000 + score)*0.0001
    local base = PropTool.GetFight(sECfg)
    local nextBase = PropTool.GetFight(nextSECfg)
    unit.score =  math.ceil(base * per)
    unit.nextScore = math.ceil(nextBase * per)
    unit.totalScore = math.ceil((base + PropTool.GetFight(advCfg))*per)
end
--创建装备date信息
function My:CreateDate(itemid)
    local key = tostring(itemid)
    local nextKey = tostring(itemid + 1)
    local cfg = ItemData[key]
    local sECfg = SpiritEquipCfg[key] --灵饰装备表
    local nextSECfg = SpiritEquipCfg[nextKey] --下一灵饰装备表
    if sECfg.consume[1].value == 0 then
        nextSECfg = sECfg
    end
    local lv =0--当前强化等级
    local next = lv + 1
    if lv == 0 then
        lv = 1
    end
    local advCfg = SpiritEStrengthCfg[lv] --灵饰装备强化表
    local nextAdvCfg = SpiritEStrengthCfg[next] --下一等级灵饰装备强化表
    local unit = {}
    unit.typeId = itemid
    unit.level = 0
    unit.advExp =0--当前强化经验
    if nextAdvCfg == nil then
        unit.needExp = 99999999
        nextAdvCfg = advCfg
    end
    unit.needExp = nextAdvCfg and nextAdvCfg.sExp
    unit.attrList = list
    unit.baseAttrList = PropTool.SwitchAttr(sECfg)
    unit.nextBaseAttrList = nextSECfg and PropTool.SwitchAttr(nextSECfg)
    unit.advAttrList = advCfg and PropTool.SwitchAttr(advCfg)
    unit.nextAdvAttrList = nextAdvCfg and PropTool.SwitchAttr(nextAdvCfg)
    unit.bestGroups = self:GetBestInfo(sECfg)
    unit.type = cfg.type   --道具类型
    unit.name = cfg.name
    unit.part = sECfg.equipPart or 0  --装备部位
    unit.quality = sECfg.equipQ or 0
    unit.star = sECfg.st or 0 --星级
    unit.step = sECfg.step --装备阶级
    unit.maxStep = GlobalTemp["103"].Value3 --装备的最大阶级
    unit.blueNum = sECfg.bluePropN  --蓝色极品属性数量
    unit.purpleNum = sECfg.purplePropN --紫色极品属性数量
    unit.advVal = sECfg.sLimit   --基础强化值
    unit.consumeId = sECfg.consume[1].id
    unit.consumePorp = sECfg.consume[1].value
    unit.maxNeedExp = 0
    unit.limitLv = sECfg.maxSLimit
    unit.suitGId = sECfg.suitGId
    unit.extraVal = advCfg and advCfg.totalExp or 0 --强化拥有的强化值
    unit.up = 0
    unit.other = true
    unit.qLimit =unit.quality 
    unit.user = 0 --装备使用者
    unit.isUse = false --部位是否已使用
    local score = 0
    local per = (10000 + score)*0.0001
    local base = PropTool.GetFight(sECfg)
    local nextBase = PropTool.GetFight(nextSECfg)
    unit.score =  math.ceil(base * per)
    unit.nextScore = math.ceil(nextBase * per)
    unit.totalScore = math.ceil((base + PropTool.GetFight(advCfg))*per)
    return unit
end
--更新装备对比强弱状态
function My:UpdateEquipUp(equip)
    local data = self:GetEquipCompInfo(equip.part)
    if not data then
        equip.up = 1
    else
        if data.user == 0 then
            equip.up = 1
        else
            if equip.totalScore > data.totalScore then
                equip.up = 1
            elseif equip.totalScore == data.totalScore then
                equip.up = 0
            else
                equip.up = 2
            end
        end
    end
end

function My:GetBestInfo(equipInfo)
    local tab = {}
    local purpleAdvG = equipInfo.purplePropAdvG
    local prupleAdvN = equipInfo.purplePropAdvN
    local purpleG = equipInfo.purplePropG
    local purpleN = equipInfo.purplePropN
    local blueG = equipInfo.bluePropG
    local blueN = equipInfo.bluePropN
    if purpleAdvG > 0 then
        for i = 1,prupleAdvN do
            table.insert(tab,purpleAdvG)
        end
    end
    if purpleG > 0 then
        for i = 1,purpleN do
            table.insert(tab,purpleG)
        end
    end

    if blueG > 0 then
        for i = 1,blueN do
            table.insert(tab,blueG)
        end
    end
    return tab
end

--获取需要比较的部位装备信息
function My:GetEquipCompInfo(part)
    local info = self.SpiritDic[tostring(self.CurSPId)]
    local data = nil
    if info then
        local cond = info.condList[part]
        if cond and cond.isUse then
            data = cond.equipData
        end
    end
    return data
end

--移除背包数据
function My:RemoveBagUnit(id)
    TableTool.Remove(self.BagInfo, {id = tonumber(id)}, "id")
end

function My:SortBag()
    table.sort(self.BagInfo, function(a,b) return self:Sort(a, b) end)
end

function My:Sort(a, b)
    if a.part ~= b.part then  
        return a.part < b.part
    elseif a.quality ~= b.quality then
        return a.quality > b.quality
    elseif a.star ~= b.star then
        -- return a.star > b.star
    else 
        -- return a.totalScore > b.totalScore
    end 
end

--获取装备基础和强化属性
function My:GetEquipBaseAndAdvAttr(equip)
    local list1 = equip.baseAttrList
    local list2 = equip.advAttrList

    local result = {}
    for i=1,#list1 do
        local t = {}
        t.k = list1[i].k
        t.v = list1[i].v
        t.add = 0
        if list2 then
            for j=1,#list2 do
                if t.k == list2[j].k then
                    t.add = t.add + list2[j].v
                end
            end
        end
        table.insert(result, t)
    end
    return result
end

--获取装备的基础属性
--index---> 1 :当前属性
--index---> 2 :下阶属性
--add------> 下一阶和当前阶的属性差值
--baseAdd------> 初始和当前阶的属性差值
function My:GetEquipBaseAttr(equip,index)
    local list1 = equip.baseAttrList
    local list2 = equip.nextBaseAttrList
    local step = equip.step
    local part = equip.part
    local partL1 = PropTool.SwitchAttr(SpiritEquipCfg["50010101"])
    local partL2 = PropTool.SwitchAttr(SpiritEquipCfg["50010201"])
    local partL3 = PropTool.SwitchAttr(SpiritEquipCfg["50010301"])
    local partL4 = PropTool.SwitchAttr(SpiritEquipCfg["50010401"])
    if list1 == nil then
        return 0
    end
    local result = {}
    for i=1,#list1 do
        local t = {}
        t.k = list1[i].k
        t.v = list1[i].v
        t.add = list2[i].v - list1[i].v
        t.baseAdd = 0
        t.step = step
        if part == 1 then
            t.baseAdd = list1[i].v - partL1[i].v
        elseif part == 2 then
            t.baseAdd = list1[i].v - partL2[i].v
        elseif part == 3 then
            t.baseAdd = list1[i].v - partL3[i].v
        elseif part == 4 then
            t.baseAdd = list1[i].v - partL4[i].v
        end
        table.insert(result, t)
    end
    return result
end

--获取该装备的强化属性(根据基础属性显示强化属性的条目)
function My:GetEquipTotalBaseAttr(equip)
    local baseList = equip.baseAttrList
    local list1 = equip.advAttrList
    local list2 = equip.nextAdvAttrList
    if list2 == nil then
        return
    end
    local baseType1 = baseList[1].k
    local baseType2 = baseList[2].k
    local curLvel = equip.level
    local result1 = {}
    local result2 = {}
    for i=1,#list1 do
        local t = {}
        t.type = list1[i].k
        t.all = list1[i].v
        if curLvel == 0 then
            t.all = 0
        end
        if t.type == baseType1 or t.type == baseType2 then
            table.insert(result1, t)
        end
    end
    for i = 1,#list2 do
        local t = {}
        t.type = list2[i].k
        t.all = list2[i].v
        if t.type == baseType1 or t.type == baseType2 then
            -- table.insert(result1, t)
            table.insert(result2, t)
        end
    end
    return result1,result2
end

--设置当前战灵id
function My:SetCurSPId(id)
    self.CurSPId = id
end

--获取当前战灵Id
function My:GetCurSPId()
    return self.CurSPId
end

function My:SetEquipId(id)
    self.CurEquipId = id
end

function My:GetEquipId()
    return self.CurEquipId
end

function My:GetSpIdAndEquipId()
    return self.CurSPId,self.CurEquipId
end

--设置进阶界面数据  进阶道具不足时，跳转商城要进行记录
function My:SetAdvData(data)
    self.AdvData = data
end

function My:GetAdvData()
    return self.AdvData
end

function My:UpdateRedPoint()
    local list = self.SpiritInfo
    local len = #list
    local spInfo = RobberyMgr.SpiriteInfoTab.spiriteTab
    for i = 1,len do
        local unit = list[i]
        local conds = unit.condList
        unit.redPointState = false
        local spId = unit.id
        local equipNum = self:GetEquipNum(spId) --当前战灵穿戴装备的数量
        local spCfg = SpiriteCfg[tostring(spId)]
        self:GetSpRedInfo(spId,false)
        self:GetStrSpRedInfo(spId,false)
        for j = 1,#conds do
            local cond = conds[j]
            local equipData = cond.equipData
            local data = self:GetBagEquipPQ(cond.type,0)
            local equipQua = self:GetEquipedQuality(data,cond) --已穿戴装备品质
            if not cond.isUse then -- 该部位没有装备
                if #data > 0 and (spInfo ~= nil and spInfo[spId] ~= nil) then --战灵已解锁
                    local spLv = spInfo[spId].lv
                    local curQLimit,curStar = self:GetQuility(spLv,spCfg)
                    for i = 1,#data do
                        local info = data[i]
                        if equipQua == 0 and info.quality <= curQLimit and info.star <= curStar then --战灵未穿戴灵饰
                            unit.redPointState = true
                            self:GetSpRedInfo(spId,true)
                        -- elseif equipQua > 0 and info.quality == equipQua then --战灵已有穿戴的灵饰，只允许同品质的穿戴
                        --     unit.redPointState = true
                        --     self:GetSpRedInfo(spId,true)
                        end
                    end
                end
            else --该部位有装备 
                self:GetEquipRedInfo(equipData.id,false)
                self.StrBtnState = false
                local propId = equipData.consumeId
                -- local propNum = PropMgr.TypeIdByNum(propId)
                local propNum = self.propNum
                local consumeNum = equipData.consumePorp
                if propNum == nil then
                    propNum = 0
                end
                if (equipData.level >= equipData.advVal) and consumeNum ~= 0 and propNum >= consumeNum then --or #data > 0) and equipNum <= 4  then --可进阶
                    unit.redPointState = true
                    self.StrBtnState = true
                    self:GetSpRedInfo(spId,true)
                    self:GetStrSpRedInfo(spId,true)
                    self:GetEquipRedInfo(equipData.id,true)
                elseif tonumber(self.strengthExpVal) > equipData.costExp and equipData.level < equipData.limitLv and equipData.level < equipData.advVal then --可强化
                    unit.redPointState = true
                    self.StrBtnState = true
                    self:GetSpRedInfo(spId,true)
                    self:GetStrSpRedInfo(spId,true)
                    self:GetEquipRedInfo(equipData.id,true)
                elseif #data > 0 and (spInfo ~= nil and spInfo[spId] ~= nil) then --背包中有高于已装备的装备评分
                    local spLv = spInfo[spId].lv
                    local curQLimit,curStar = self:GetQuility(spLv,spCfg)
                    for k = 1,#data do
                        local info = data[k]
                        if equipData.quality <= info.quality and curQLimit >= info.quality and curStar >= info.star then
                            if info.totalScore > equipData.totalScore then
                                unit.redPointState = true
                                self:GetSpRedInfo(spId,true)
                            end
                        end
                    end
                end
            end
        end
    end
    self:UpdateTotalRedPoint()
end

--获取当前战灵可穿戴最高品质装备
function My:GetQuility(spLv,spCfg)
    local quality = spCfg.qLimit
    local curLv = spLv
    local index = 0
    local len = #quality
    for i = 1,len do
        local info = quality[i]
        local lv = info.I
        local qua = info.B
        local star = info.N
        if curLv >= lv then
            index = index + 1
        end
    end
    local cCfg = quality[index]
    if cCfg == nil then
        cCfg = quality[len]
    end
    local cQlv = cCfg.I --等级
    local cQua = cCfg.B --品质
    local cStar = cCfg.N --星级
    return cQua,cStar
end

function My:GetPropNum()
    local propId = 40302
    local num = PropMgr.TypeIdByNum(propId)
    if num == nil or num == 0 then
        num = 0
    end
    self.propNum = num
end

--获取已经穿戴的装备品质
function My:GetEquipedQuality(bagInfo,equipTab)
    local bagLen = #bagInfo
    local quality = 0
    local equipData = equipTab.equipData
    if bagLen <= 0 then return quality end
    if equipTab.isUse then
        quality = equipData.quality
    end
    return quality
end

function My:UpdateTotalRedPoint()
    local actId = ActivityMgr.DJ
    local list = self.SpiritInfo
    local state = false
    for i=1,#list do
        if not state then
            state = list[i].redPointState
        else
            break
        end
    end
    if state then
        SystemMgr:ShowActivity(actId,3)
        RobberyMgr:StateSpRed(2,true) -- 境界界面  战灵按钮  红点
    else
        SystemMgr:HideActivity(actId,3)
        RobberyMgr:StateSpRed(2,false)
    end
end


function My:GetSpRedInfo(spId,redState)
    local spId = tostring(spId)
    self.SpRedInfo[spId] = redState
end

--强化界面战灵红点
function My:GetStrSpRedInfo(spId,state)
    local spId = tostring(spId)
    self.StrSpRedInfo[spId] = state
end


--id 装备唯一id 
function My:GetEquipRedInfo(id,state)
    self.EquipRedInfo[id] = state
end

function My:GetFlagRed()

end

--获取初始极品属性与当前属性差值
--groupId:属性组id
--propKey:属性类型
--propVal：属性数值
function My:GetBestProp(groupId,propKey,propVal)
    if groupId == nil then
        return 0
    end
    local group = math.modf(groupId/100)
    local firstGroup = group * 100 + 1
    local add = 0
    firstGroup = tostring(firstGroup)
    local cfg = SpiritEQualityCfg[firstGroup]
    local defK,defV = cfg.def[2],cfg.def[3]
    local hpK,hpV = cfg.hp[2],cfg.hp[3]
    local atkK,atkV = cfg.atk[2],cfg.atk[3]
    local armK,armV = cfg.arm[2],cfg.arm[3]
    local hitK,hitV = cfg.hit[2],cfg.hit[3]
    local dodgeK,dodgeV = cfg.dodge[2],cfg.dodge[3]
    local critK,critV = cfg.crit[2],cfg.crit[3]
    local tenaK,tenaV = cfg.tena[2],cfg.tena[3]
    local defaddK,defaddV = cfg.defadd[2],cfg.defadd[3]
    local hpaddK,hpaddV = cfg.hpadd[2],cfg.hpadd[3]
    local atkaddK,atkaddV = cfg.atkadd[2],cfg.atkadd[3]
    local armaddK,armaddV = cfg.armadd[2],cfg.armadd[3]
    local hitaddK,hitaddV = cfg.hitadd[2],cfg.hitadd[3]
    local dodgeaddK,dodgeaddV = cfg.dodgeadd[2],cfg.dodgeadd[3]
    local critaddK,critaddV = cfg.critadd[2],cfg.critadd[3]
    local tenaaddK,tenaaddV = cfg.tenaadd[2],cfg.tenaadd[3]
    if propKey == defK then
        add = propVal - defV
    elseif propKey == hpK then
        add = propVal - hpV
    elseif propKey == atkK then
        add = propVal - atkV
    elseif propKey == armK then
        add = propVal - armV
    elseif propKey == hitK then
        add = propVal - hitV
    elseif propKey == dodgeK then
        add = propVal - dodgeV
    elseif propKey == critK then
        add = propVal - critV
    elseif propKey == tenaK then
        add = propVal - tenaV
    elseif propKey == defaddK then
        add = propVal - defaddV
    elseif propKey == hpaddK then
        add = propVal - hpaddV
    elseif propKey == atkaddK then
        add = propVal - atkaddV
    elseif propKey == armaddK then
        add = propVal - armaddV
    elseif propKey == hitaddK then
        add = propVal - hitaddV
    elseif propKey == dodgeaddK then
        add = propVal - dodgeaddV
    elseif propKey == critaddK then
        add = propVal - critaddV
    elseif propKey == tenaaddK then
        add = propVal - tenaaddV
    end
    return add
end

--获取下一阶极品属性与当前属性差值
--groupId:属性组id
--propKey:属性类型
--propVal：属性数值
function My:GetNexttProp(groupId,propKey,propVal)
    if groupId == nil then
        return 0
    end
    local nextGroupId = groupId + 1
    local add = 0
    nextGroupId = tostring(nextGroupId)
    local cfg = SpiritEQualityCfg[nextGroupId]
    if cfg == nil then
        cfg = SpiritEQualityCfg[tostring(groupId)]
    end
    local defK,defV = cfg.def[2],cfg.def[3]
    local hpK,hpV = cfg.hp[2],cfg.hp[3]
    local atkK,atkV = cfg.atk[2],cfg.atk[3]
    local armK,armV = cfg.arm[2],cfg.arm[3]
    local hitK,hitV = cfg.hit[2],cfg.hit[3]
    local dodgeK,dodgeV = cfg.dodge[2],cfg.dodge[3]
    local critK,critV = cfg.crit[2],cfg.crit[3]
    local tenaK,tenaV = cfg.tena[2],cfg.tena[3]
    local defaddK,defaddV = cfg.defadd[2],cfg.defadd[3]
    local hpaddK,hpaddV = cfg.hpadd[2],cfg.hpadd[3]
    local atkaddK,atkaddV = cfg.atkadd[2],cfg.atkadd[3]
    local armaddK,armaddV = cfg.armadd[2],cfg.armadd[3]
    local hitaddK,hitaddV = cfg.hitadd[2],cfg.hitadd[3]
    local dodgeaddK,dodgeaddV = cfg.dodgeadd[2],cfg.dodgeadd[3]
    local critaddK,critaddV = cfg.critadd[2],cfg.critadd[3]
    local tenaaddK,tenaaddV = cfg.tenaadd[2],cfg.tenaadd[3]
    if propKey == defK then
        add = defV - propVal
    elseif propKey == hpK then
        add = hpV - propVal
    elseif propKey == atkK then
        add = atkV - propVal
    elseif propKey == armK then
        add = armV - propVal
    elseif propKey == hitK then
        add = hitV - propVal
    elseif propKey == dodgeK then
        add = dodgeV - propVal
    elseif propKey == critK then
        add = critV - propVal
    elseif propKey == tenaK then
        add = tenaV - propVal
    elseif propKey == defaddK then
        add = defaddV - propVal
    elseif propKey == hpaddK then
        add = hpaddV - propVal
    elseif propKey == atkaddK then
        add = atkaddV - propVal
    elseif propKey == armaddK then
        add = armaddV - propVal
    elseif propKey == hitaddK then
        add = hitaddV - propVal
    elseif propKey == dodgeaddK then
        add = dodgeaddV - propVal
    elseif propKey == critaddK then
        add = critaddV - propVal
    elseif propKey == tenaaddK then
        add = tenaaddV - propVal  
    end
    return add
end


--获取以已经装备的数量
function My:GetEquipNum(spId)
    local index = 0
    local equipId = 0
    local spId = spId
    spId = tostring(spId)
    local spEquipInfo = self.SpiritDic[spId]
    local equipInfo = spEquipInfo.condList
    for i = 1,#equipInfo do
        local info = equipInfo[i]
        if info.isUse == true then
            index = index + 1
        end
    end
    return index
end

--获取灵饰强化红点状态
function My:GetStrenRed(spiritId)
    local isLock = RobberyMgr:IsLockSp(spiritId) --true:未解锁  false:已解锁
    if isLock == true then
        return
    end
    local spEquipInfo = self.SpiritDic[spId]
    local conds = spEquipInfo.condList
    local len = #conds
    if len <= 0 then
        return
    end
    for i=1,#len do
        if conds[i].isUse then
            local equipData = conds[i].equipData
            
        end
    end
end

--获取已经穿戴装备的数量
--返回已经装备的数量和不同套装组中的数量
function My:GetEquipNumAndSuitNum(suitInfo)
    local groupId = suitInfo.suitId
    local quality = suitInfo.suitQ
    local star = suitInfo.suitS
    local index = 0
    local equipId = 0
    local suitIndex = 0
    local spId = self.CurSPId
    spId = tostring(spId)
    local spEquipInfo = self.SpiritDic[spId]
    local equipInfo = spEquipInfo.condList
    for i = 1,#equipInfo do
        local info = equipInfo[i]
        if info.isUse == true then
            local equipQ = info.equipData.quality
            local equipS = info.equipData.star
            equipId = info.equipData.typeId
            equipId = tostring(equipId)
            if quality == equipQ and star == equipS then
                index = index + 1
            end
            local equipSuitTab = SpiritEquipCfg[equipId].suitGId
            if equipSuitTab == nil then
                suitIndex = 0
                return index,suitIndex
            end
            for j = 1,#equipSuitTab do
                local equipSuitId = equipSuitTab[i]
                if groupId == equipSuitId then
                    suitIndex = suitIndex + 1
                end
            end
        end
    end
    return index,suitIndex
end

--获取quality以下的数据
function My:GetBagInfo(quality)
    local list = self.BagInfo
    local info = {}
    for i=1,#list do
        local unit = list[i]
        if unit.quality <= quality then
            unit.up = 0
            table.insert(info, unit)
        end
    end
    return info
end


--获取符合部位，品质以上的背包装备数据
function My:GetBagEquipPQ(part, quality)
    local list = self.BagInfo
    local info = {}
    for i=1,#list do
        local unit = list[i]
        if unit.type == 5 and  unit.part == part and unit.quality >= quality then
            self:UpdateEquipUp(unit)
            table.insert(info, unit)
        end
    end
    return info
end 

--获取指定品质， 星级， 部位的 装备数据
function My:GetBagEquipQS(quality, step)
    if quality == self.All and step == self.All then
        return self:GetAllBagEquip()
    else
        local list = self.BagInfo
        local info = {}
        for i=1,#list do
            local unit = list[i]
            if unit.type == 5 then
                if unit.quality == quality and unit.step == step then
                    self:UpdateEquipUp(unit)
                    table.insert(info, unit)
                elseif quality == self.All and unit.step == step then
                    self:UpdateEquipUp(unit)
                    table.insert(info, unit)
                elseif unit.quality == quality and step == self.All then
                    self:UpdateEquipUp(unit)
                    table.insert(info, unit)
                end
            end
        end
        return info
    end
end

--获取指定阶级装备数据
function My:GetBagEquipS(step)
    if step == self.All then
        return self:GetAllBagEquip()
    else
        local list = self.BagInfo
        local info = {}
        for i=1,#list do
            local unit = list[i]
            if unit.type == 5 and unit.step == step then
                self:UpdateEquipUp(unit)
                table.insert(info, unit)
            end
        end
        return info
    end
end

--获取指定品质的装备数据
function My:GetBagEquipQ(quality)
    if quality == self.All then
        return self:GetAllBagEquip()
    else
        local list = self.BagInfo
        local info = {}
        for i=1,#list do
            local unit = list[i]
            if unit.type == 5 and unit.quality == quality then
                self:UpdateEquipUp(unit)
                table.insert(info, unit)
            end
        end
        return info
    end
end

--获取指定星级的装备数据
function My:GetBagEquipS(star)
    local list = self.BagInfo
    local info = {}
    for i=1,#list do
        local unit = list[i]
        if unit.type == 5 and unit.star == star then
            self:UpdateEquipUp(unit)
            table.insert(info, unit)
        end
    end
    return info
end

--获取指定部位的装备数据
function My:GetAllBagEquip()
    local list = self.BagInfo
    local info = {}
    for i=1,#list do
        local unit = list[i]
        if unit.type == 5 then
            self:UpdateEquipUp(unit)
            table.insert(info, unit)
        end
    end
    return info
end

--获取强化到下一个等级所需强化值
function My:GetNextLvAdvExp(curLv)
    local cfg = SpiritEStrengthCfg
    -- if curLv == 0 then
    --     curLv = 1
    -- end
    local nextlv = curLv+1
    if cfg[nextlv] == nil then
        return nil
    end
    return cfg[nextlv].costExp,cfg[nextlv].sExp
end

-- m_war_spirit_equip_load_tos  战灵装备穿戴
-- war_spirit_id ---> 战灵id
-- equip_id ---> 穿戴哪一件装备 
function My:ReqSpiritEquipLoad(equipId)
    local msg = ProtoPool.GetByID(24211) 
    msg.war_spirit_id = self.CurSPId
    msg.equip_id = equipId --int64
    ProtoMgr.Send(msg)
end

-- m_war_spirit_equip_unload_tos  战灵装备脱下
-- war_spirit_id ---> 战灵id
-- equip_id ---> 脱下哪一件装备 
function My:ReqSpiritEquipUnLoad(equipId)
    local msg = ProtoPool.GetByID(24213) 
    msg.war_spirit_id = self.CurSPId
    msg.equip_id = equipId --int64
    ProtoMgr.Send(msg)
end

-- m_war_spirit_equip_decompose_tos  背包战灵灵饰分解
-- equip_id ---> [分解装备id] 
function My:ReqSpiritEquipDecom(equipIdTab)
    local msg = ProtoPool.GetByID(24221) 
    for k,v in pairs(equipIdTab) do  --//材料列表
        msg.equip_id:append(v.id)    
    end 
    -- msg.equip_id = equipIdTab --[int64]
    ProtoMgr.Send(msg)
end

-- m_war_spirit_equip_refine_tos  战灵灵饰强化
-- war_spirit_id ---> 战灵id
-- equip_id ---> 强化的装备id 
function My:ReqSpiritEquipStr(equipId)
    local msg = ProtoPool.GetByID(24223) 
    msg.war_spirit_id = self.CurSPId
    msg.equip_id = equipId --int64
    ProtoMgr.Send(msg)
end

-- m_war_spirit_equip_step_tos  战灵灵饰进阶
-- war_spirit_id ---> 战灵id
-- equip_id ---> 进阶哪一件装备 
function My:ReqSpiritEquipAdv(equipId)
    local msg = ProtoPool.GetByID(24231) 
    msg.war_spirit_id = self.CurSPId
    msg.equip_id = equipId --int64
    ProtoMgr.Send(msg)
end

function My:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Log(err)
	    return true
    end
    return false
end

function My:ClearDic(tab)
    TableTool.ClearDic(tab)
end

function My:ClearData()
    self.CurSPId = 0
    self.CurEquipId = 0
    self.AdvData = nil
    self.StrBtnState = false
end

function My:Clear()
    self:ClearDic(self.BagInfo)
    self:ClearDic(self.SpiritInfo)
    self:ClearDic(self.SpiritDic)
    self:ClearDic(self.SpRedInfo)
    self:ClearDic(self.EquipRedInfo) 
    self:ClearDic(self.StrSpRedInfo) 
    self:ClearData()
end

function My:Dispose()
	self:RemoveProto()
end

return My