SoulBearstMgr = Super:New{Name = "SoulBearstMgr"}

local M = SoulBearstMgr

M.ColorName = {"白色", "蓝色", "紫色", "橙色", "红色", "粉色"}
M.PartName = {"兽首", "旁肢", "元中", "定垂", "偏足"}

M.SoulBearstInfo = {} --unit
M.SoulBearstDic = {}  -- key:魂兽ID, val： unit
M.BagInfo = {}--魂兽背包数据   

M.CurSBId = 0 --当前神兽Id
M.CurEquipId = 0 --当前强化装备ID

M.totalSBNum = 0  --可以激活的魂兽数量
M.actSBNum = 0 --已经激活的魂兽数量

M.All = 100

M.SBOpenState = false  --魂兽系统是否开启
M.IsDouble = false  --是否双倍强化
M.EnoughGold = false  --元宝是否足够
M.UnLockSB = false    --解锁神兽红点
M.AdvRedPoint = false  --装备强化红点(仅针对五元真晶)
M.ChangeEquipRedPoint = false    --神兽换装红点
M.ActiveSBRedPoint = false   --神兽激活红点


M.eUpdateSBInfo = Event()     --魂兽数据变动更新
M.eUpdateBagInfo = Event()  --背包数据变动更新
M.eUpdateSBNum = Event()    --魂兽激活数量更新
M.eUpdateSBList = Event()   --魂兽列表变动更新
M.eUpdateSBAct = Event()    --更新魂兽激活状态
M.eUpdateExpAndGold = Event()   --更新选择强化道具可以增加的强化值和需要的元宝
M.eChangeDoubleAdv = Event()   --更改双倍强化状态
M.eUpdateUnLockSB = Event()   --更新解锁神兽按钮红点
M.ePlayFx = Event()   --播放解锁特效
M.eUpdateRedPoint = Event()  --更新红点




function M:Init()
    self:SetLsnr(ProtoLsnr.Add)
    self:SetEvent("Add")
end

function M:SetLsnr(Lsnr)
    Lsnr(23900, self.RespMythicalEquipInfo, self)
    Lsnr(23902, self.RespMythicalEquipAdd, self)
    Lsnr(23904, self.RespMythicalEquipDel, self)
    Lsnr(23912, self.RespMythicalEquipLoad, self)
    Lsnr(23914, self.RespMythicalEquipUnload, self)
    Lsnr(23920, self.RespMythicalEquipStatus, self)
    Lsnr(23922, self.RespMythicalEquipAddNum, self)
    Lsnr(23932, self.RespMythicalRefine, self)
    Lsnr(23942, self.RespMythicalCompose, self)
end

function M:SetEvent(key)
    UserMgr.eLvEvent[key](UserMgr.eLvEvent, self.OnChangeLevel, self)
    VIPMgr.eVIPLv[key](VIPMgr.eVIPLv, self.OnChangeVip, self)
    PropMgr.eUpdate[key](PropMgr.eUpdate, self.OnChangeBag, self)
end

function M:OnChangeBag()
    if #self.SoulBearstInfo == 0 then return end
    self:UpdataUnLockSB()
end

function M:OnChangeVip()
    if #self.SoulBearstInfo == 0 then return end
    self:UpdataUnLockSB()
end

function M:OnChangeLevel()
    if #self.SoulBearstInfo == 0 then return end
    self:UpdateSoulBearstInfo()
    self:UpdataUnLockSB()
end


--协议

--// 神兽信息推送
function M:RespMythicalEquipInfo(msg)
    self:InitData()

    self:UpdateTotalSBNum(msg.soul_num)

    local list = msg.soul_list
    for i=1,#list do
        self:UpdateSBInfo(list[i])
    end 

    local list = msg.bag_list
    for i=1,#list do
        self:AddBagUnit(list[i])
    end
    self:SortBag()
    self:UpdateRedPoint()
    self:UpdataUnLockSB()
end

--// 神兽装备背包新增
function M:RespMythicalEquipAdd(msg)
    local list = msg.add_list
    for i=1,#list do
        self:AddBagUnit(list[i])
    end
    self:SortBag()
    self:UpdateRedPoint()
    self.eUpdateSBList()
    self.eUpdateBagInfo()
end

--// 神兽装备背包删除
function M:RespMythicalEquipDel(msg)
    local list = msg.del_list
    for i=1, #list do
        self:RemoveBagUnit(list[i])
    end
    self:SortBag()
    self:UpdateRedPoint()
    self.eUpdateSBList()
    self.eUpdateBagInfo()
end

--// 神兽穿上装备返回
function M:RespMythicalEquipLoad(msg)
    if self:CheckErr(msg.err_code) then
        self:UpdateSBInfo(msg.soul)
        self.eUpdateSBInfo()
    end
end

--// 神兽卸除装备返回
function M:RespMythicalEquipUnload(msg)
    if self:CheckErr(msg.err_code) then
        self:UpdateSBInfo(msg.soul)
        self.eUpdateSBNum()
        self.eUpdateSBInfo()
    end
end

--// 激活取消激活神兽返回
function M:RespMythicalEquipStatus(msg)
    if self:CheckErr(msg.err_code) then
        self:UpdateSBState(msg.soul_id, msg.status)
        self:UpdateActSBNum()
        self:UpdateRedPoint()
        self.eUpdateSBNum()
        self.eUpdateSBList()
        self.eUpdateSBAct()
    end
end

--// 神兽最大数量新增返回
function M:RespMythicalEquipAddNum(msg)
    if self:CheckErr(msg.err_code) then
        self:UpdateTotalSBNum(msg.soul_num)
        self:UpdateRedPoint()
        self:UpdataUnLockSB()
        self.eUpdateSBNum()
        self.eUpdateSBList()
        self.ePlayFx()
    end
end

--// 神兽装备强化返回
function M:RespMythicalRefine(msg)
    if self:CheckErr(msg.err_code) then
        UITip.Log("强化成功")
        local id = msg.soul_id
        self:UpdateSBEquip(id, msg.equip)
        self:UpdateSBScore(id)
        self:UpdateSBAttrAdd(id)
        self.eUpdateSBInfo()
    end
end

--// 神兽装备合成返回
function M:RespMythicalCompose(msg)
end


--// 神兽穿上装备
--//神兽ID 魂兽装备唯一id
function M:ReqMythicalEquipLoad(id)
    local msg = ProtoPool.GetByID(23911)
    msg.soul_id = self.CurSBId
    msg.id = id --int64
    ProtoMgr.Send(msg)
end

--// 神兽卸除装备
--//神兽ID 魂兽装备唯一id
function M:ReqMythicalEquipUnload(soul_id, id)
    local unit = self.SoulBearstDic[tostring(soul_id)]
    if not unit then return end

    local function Send(soul_id, id)
        local msg = ProtoPool.GetByID(23913)
        msg.soul_id = soul_id
        msg.id = id --int64
        ProtoMgr.Send(msg)
    end

    if unit.state == 2 then
        MsgBox.ShowYesNo("神兽正处于激活状态，卸载装备则激活状态将取消，是否继续?", function() Send(soul_id, id) end)
        return
    else
        Send(soul_id, id)
    end
end


--// 激活取消激活神兽
function M:ReqMythicalEquipStatus(soul_id, status)
    local msg = ProtoPool.GetByID(23919)
    msg.soul_id = soul_id
    msg.status = status --//当前神兽状态 1、2
    ProtoMgr.Send(msg)
end

--// 神兽最大数量新增
function M:ReqMythicalEquipAddNum()
    local msg = ProtoPool.GetByID(23921)
    ProtoMgr.Send(msg)
end

--// 神兽装备强化
function M:ReqMythicalRefine(material_list)
    local msg = ProtoPool.GetByID(23931)
    msg.soul_id = self.CurSBId   --//神兽ID
    msg.id = self.CurEquipId         --//强化的装备ID
    for k,v in pairs(material_list) do  --//材料列表
        msg.material_list:append(v.id)    
    end   
    msg.is_double = self.IsDouble  --//是否勾选双倍强化
    ProtoMgr.Send(msg)
end

--// 神兽装备强化合成
function M:ReqMythicalCompose(compose_id, material_list)
    local msg = ProtoPool.GetByID(23919)
    msg.compose_id = compose_id  -- //合成ID
    for k,v in pairs(material_list) do  --//材料列表
        msg.material_list:append(v)    
    end   
    ProtoMgr.Send(msg)
end


--Init

function M:InitData()
    local lv = User.MapData.Level
    local cfg = SoulBearstCfg
    local len = #cfg
    for i=1,len do
        if cfg[i].level <= lv then
            self:AddSBUnit(cfg[i])
        end
    end
    self.SBOpenState = true
end


function M:AddSBUnit(cfg)
    local unit = self:CreateSBUnit(cfg)       
    self.SoulBearstDic[tostring(unit.id)] = unit
    table.insert(self.SoulBearstInfo, unit)
end

--创建魂兽数据结构
function M:CreateSBUnit(cfg)
    local unit = {}
    unit.id = cfg.id
    unit.name = cfg.name
    unit.level = cfg.level
    unit.spriteName = cfg.spriteName
    unit.texture = cfg.texture
    unit.state = 0
    unit.redPointState = false
    unit.score = PropTool.GetFightByList(cfg.attrList)
    unit.totalScore = unit.score
    unit.condList = self:SwitchCond(cfg.qua1, cfg.qua2, cfg.qua3, cfg.qua4, cfg.qua5)
    unit.attrList = self:SwitchAttr(cfg.attrList)
    unit.skillList = self:SwitchSkill(cfg.skillList)
    return unit
end

--转换条件结构
function M:SwitchCond(...)
    local list = {}
    local arg = {...}
    for i=1,#arg do
        local unit = self:CreateCondUnit(i, arg[i])
        table.insert(list, unit)
    end
    return list
end

--转换属性结构
function M:SwitchAttr(data)
    local list = {}
    for i=1,#data do
        local unit = self:CreateAttrUnit(data[i])
        table.insert(list, unit)
    end
    return list
end

--转换技能结构
function M:SwitchSkill(data)
    local list = {}
    for i=1,#data do
        local unit = self:CreateSkillUnit(data[i])
        table.insert(list, unit)
    end
    return list
end

--创建条件单元
function M:CreateCondUnit(type, quality)
    local unit = {}
    unit.type = type
    unit.quality = quality
    unit.typeName = string.format("%s%s%s", UIMisc.LabColor(quality), self.ColorName[quality], self.PartName[type])
    unit.isUse = false
    unit.redPointState = false
    unit.equipData = {}
    return unit
end

--创建属性单元
function M:CreateAttrUnit(data)
    local unit = {}
    unit.type = data.k
    unit.base = data.v
    unit.add = 0
    return unit
end

--创建技能单元
function M:CreateSkillUnit(id)
    local sTemp = SkillLvTemp[tostring(id)]
    local unit = {}
    unit.id = id
    unit.texture = sTemp.icon
    unit.name = sTemp.name
    unit.des = sTemp.desc
    return unit
end


--创建装备单元
function M:CreateEquipUnit(unit, data)
    local key = tostring(data.type_id)
    local cfg = ItemData[key]
    local sb = SBEquipCfg[key]
    local lv = data.refine_level
    local advCfg = SBEquipAdvCfg[lv]
    local list = data.excellent_list
    unit.id = tonumber(data.id)
    unit.typeId = data.type_id
    unit.level = lv
    unit.advExp = data.refine_exp
    unit.attrList = list
    unit.baseAttrList = PropTool.SwitchAttr(sb)
    unit.advAttrList = advCfg and PropTool.SwitchAttr(advCfg)
    unit.type = cfg.type   --道具类型
    unit.name = cfg.name
    unit.part = sb.type or 0  --装备部位
    unit.quality = sb.quality or 0
    unit.star = sb.star or 0
    unit.blueNum = sb.blueNum  --蓝色极品属性数量
    unit.purpleNum = sb.purpleNum --紫色极品属性数量
    unit.advVal = sb.AdvVal   --基础强化值
    unit.extraVal = advCfg and advCfg.totalExp or 0 --强化拥有的强化值
    unit.up = 0
    unit.user = 0 --装备使用者
    local score = 0
    for i=1,#list do
        score = score + list[i].type
    end
    local per = (10000 + score)*0.0001
    local base = PropTool.GetFight(sb)
    unit.score =  math.ceil(base * per)
    unit.totalScore = math.ceil((base + PropTool.GetFight(advCfg))*per)
end


--update

--更新 self.SoulBearstInfo
function M:UpdateSoulBearstInfo()
    local lv = User.MapData.Level
    local list = self.SoulBearstInfo
    local len = #list
    if len == 0 then return end
    local maxLv = list[len].level
    if lv <= maxLv then return end
    --当前等级大于 maxLv
    local cfg = SoulBearstCfg
    local count = #cfg
    for i=1,count do
        if cfg[i].level > maxLv and cfg[i].level <= lv then
            self:AddSBUnit(cfg[i])
        end
    end
    self.eUpdateSBList()
end

--更新装备对比强弱状态
function M:UpdateEquipUp(equip)
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

--//可以激活的魂兽数量
function M:UpdateTotalSBNum(num)
    self.totalSBNum = num
end

--更新已经激活的魂兽数量
function M:UpdateActSBNum()
    local list = self.SoulBearstInfo
    local num = 0
    for i=1, #list do
        local unit = list[i]
        if unit.state == 2 then
            num = num + 1
        end
    end
    self.actSBNum = num
end

--更新有装备的魂兽信息
function M:UpdateSBInfo(data)
    local id = data.soul_id
    self:UpdateSBState(id, data.status)
    self:UpdateSBEquipList(id, data.equip_list)
    self:UpdateSBScore(id)
    self:UpdateSBAttrAdd(id)
    self:UpdateActSBNum()
end

--更新魂兽增加的属性
function M:UpdateSBAttrAdd(id)
    local unit = self:GetOrCreateUnit(id)
    local attrList = unit.attrList
    local condList = unit.condList
    for _, attr in ipairs(attrList) do
        attr.add = 0
        for _, cond in ipairs(condList) do
            local equip = cond.equipData
            local temp1 = equip.attrList
            if temp1 then
                for _, v in ipairs(temp1) do
                    if attr.type == v.id then
                        attr.add = attr.add + v.val
                    end
                end
            end
            local temp2 = equip.baseAttrList
            if temp2 then
                for _,v in ipairs(temp2) do
                    if attr.type == v.k then
                        attr.add = attr.add + v.v
                    end
                end
            end
            local temp3 = equip.advAttrList
            if temp3 then
                for _,v in ipairs(temp3) do
                    if attr.type == v.k then
                        attr.add = attr.add + v.v
                    end
                end
            end
        end
    end
end

--更新魂兽激活状态
function M:UpdateSBState(id, state)
    local unit = self:GetOrCreateUnit(id)
    unit.state = state
end

--更新魂兽身上的装备信息
function M:UpdateSBEquipList(id, list)
    local unit = self:GetOrCreateUnit(id)
    local conds = unit.condList
    for k,v in pairs(conds) do
        self:ClearDic(v.equipData)
        v.isUse = false
    end
    for i=1,#list do
        self:UpdateSBEquip(id, list[i])
    end
end

--更新魂兽身上的装备信息
function M:UpdateSBEquip(id, data)
    local unit = self:GetOrCreateUnit(id)
    local condList = unit.condList
    local cfg = SBEquipCfg[tostring(data.type_id)]
    local key = cfg.type
    local cond = condList[key]
    cond.isUse = true
    local equip = cond.equipData
    self:ClearDic(equip)
    self:CreateEquipUnit(equip, data)
    equip.user = id
end

function M:UpdateSBScore(id)
    local unit = self:GetOrCreateUnit(id)
    local list = unit.condList
    local score = 0
    for k,v in pairs(list) do
        local equip = v.equipData
        if equip.totalScore then
            score = score + equip.totalScore
        end
    end
    unit.totalScore = unit.score + score
end

--添加背包数据
function M:AddBagUnit(data)
    local unit = {}
    self:CreateEquipUnit(unit, data)
    self:UpdateEquipUp(unit)
    table.insert(self.BagInfo, unit)
end

--移除背包数据
function M:RemoveBagUnit(id)
    TableTool.Remove(self.BagInfo, {id = tonumber(id)}, "id")
end


--更新红点
function M:UpdateRedPoint()
    local list = self.SoulBearstInfo
    local len = #list
    local isMax = self.actSBNum >= self.totalSBNum
    self.ActiveSBRedPoint = false
    self.ChangeEquipRedPoint = false
    for i=1,len do
        local unit = list[i]     
        local state = unit.state
        local conds = unit.condList
        for j=1,#conds do
            conds[j].redPointState = false
        end
        if state == 0 then  --未激活的
            if isMax then 
                unit.redPointState = false      
            else
                local conds = unit.condList
                unit.redPointState = true
                self.ActiveSBRedPoint = true
                for j=1,#conds do
                    local cond = conds[j]
                    if not cond.isUse then  --该部位没有装备
                        local data = self:GetBagEquipPQ(cond.type, cond.quality)
                        if #data==0 then
                            unit.redPointState = false
                            self.ActiveSBRedPoint = false
                            break
                        end
                    else  --该部位有装备  比较装备强弱
                        --todo
                    end
                end   
            end         
        elseif state == 1 then    --未使用的
            unit.redPointState = not isMax
            if not self.ActiveSBRedPoint then
                self.ActiveSBRedPoint = not isMax
            end
        else --激活的比较装备强弱
            unit.redPointState = false
            local conds = unit.condList
            for j=1,#conds do
                local cond = conds[j]
                local data = self:GetBagEquipPQ(cond.type, cond.quality)
                cond.redPointState = false
                for k=1,#data do
                    if cond.redPointState then break end
                    local temp = data[k]
                    cond.redPointState = cond.equipData.score < temp.score
                end
                if not unit.redPointState then
                    unit.redPointState = cond.redPointState
                end
                if not self.ChangeEquipRedPoint then
                    self.ChangeEquipRedPoint =  cond.redPointState
                end
            end
        end
    end
    self:UpdateAdvRedPoint()
    self:UpdateTotalRedPoint()
end

function M:UpdateTotalRedPoint()
    local list = self.SoulBearstInfo
    local state = false
    for i=1,#list do
        if state then break end
         state = list[i].redPointState
    end
    local totalState = state or self.UnLockSB or self.AdvRedPoint
    SystemMgr:ChangeActivity(self.UnLockSB, ActivityMgr.TJ, 2, 1)
    SystemMgr:ChangeActivity(self.ActiveSBRedPoint, ActivityMgr.TJ, 2, 2)
    SystemMgr:ChangeActivity(self.ChangeEquipRedPoint, ActivityMgr.TJ, 2, 3)
    SystemMgr:ChangeActivity(self.AdvRedPoint, ActivityMgr.TJ, 2, 4)
    self.eUpdateRedPoint(totalState)
end

--更新装备强化红点（仅检测背包是否有五元真晶）
function M:UpdateAdvRedPoint()
    local hasActiveSB = self:HasActiveSB()
    if not hasActiveSB then
        self.AdvRedPoint = false
    else
        local list = self.BagInfo
        local state = false
        for i=1,#list do
            if list[i].typeId == 20000001 then
                state = true
                break
            end
        end
        self.AdvRedPoint = state
    end
end

--是否可以解锁神兽
function M:UpdataUnLockSB()
    local lv = User.MapData.Level
    local vip = VIPMgr.vipLv
    local cfg = SBOpenCfg
    local num = self.totalSBNum  --已解锁数量
    local nNum = num+1
    local temp = cfg[nNum]
    local b1, b2 = false, false
    if temp then 
        b1 = lv >= temp.level or (temp.vip and vip >= temp.vip)
        b2 = true
        local item = temp.item
        if item then
            if PropMgr.TypeIdByNum(item.k) < item.v then
                b2 = false
            end
        end
    end
    self.UnLockSB = b1 and b2
    self:UpdateTotalRedPoint()
    self.eUpdateUnLockSB()
end



--set

function M:SetCurSBId(id)
    self.CurSBId = id
end

function M:SetDouble(state)
    self.IsDouble = state
    self.eChangeDoubleAdv()
end

function M:SetEquipId(id)
    self.CurEquipId = id
end

function M:SetGoldState(state)
    self.EnoughGold = state
end

--get

function M:GetGoldState()
    return self.EnoughGold
end

function M:GetCurSBId()
    return self.CurSBId
end

function M:GetEquipId()
    return self.CurEquipId
end

function M:GetOrCreateUnit(id)
    local key = tostring(id)
    if not self.SoulBearstDic[key] then
        self.SoulBearstDic[key] = {}
    end
    return self.SoulBearstDic[key]
end


function M:GetSBInfo()
    return self.SoulBearstInfo
end

function M:GetSBInfoById(id)
    return self.SoulBearstDic[tostring(id)]
end

function M:GetActiveSBinfo()
    local data = {}
    local list = self.SoulBearstInfo
    for i=1,#list do
        if list[i].state == 2 then
            table.insert(data, list[i])
        end
    end
    return data
end


function M:HasActiveSB()
    local list = self.SoulBearstInfo
    local state = false
    for i=1,#list do
        if list[i].state == 2 then
            state = true
            break
        end
    end
    return state
end

function M:CanOpenAdv()
    local unit = self.SoulBearstDic[tostring(self.CurSBId)]
    return unit and unit.state==2
end


--获取quality以下的数据
function M:GetBagInfo(quality)
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
function M:GetBagEquipPQ(part, quality)
    local list = self.BagInfo
    local info = {}
    for i=1,#list do
        local unit = list[i]
        if unit.type == 4 and  unit.part == part and unit.quality >= quality then
            self:UpdateEquipUp(unit)
            table.insert(info, unit)
        end
    end
    return info
end 

--获取指定品质， 星级， 部位的 装备数据
function M:GetBagEquipQS(quality, star)
    if quality == self.All and star == self.All then
        return self:GetAllBagEquip()
    elseif star == self.All then
        return self:GetBagEquipQ(quality)
    elseif quality == self.All then
        return self:GetBagEquipS(star)
    else
        local list = self.BagInfo
        local info = {}
        for i=1,#list do
            local unit = list[i]
            if unit.type == 4 and unit.quality == quality and unit.star == star then
                self:UpdateEquipUp(unit)
                table.insert(info, unit)
            end
        end
        return info
    end
end

--获取指定品质的装备数据
function M:GetBagEquipQ(quality)
    local list = self.BagInfo
    local info = {}
    for i=1,#list do
        local unit = list[i]
        if unit.type ==4 and unit.quality == quality then
            self:UpdateEquipUp(unit)
            table.insert(info, unit)
        end
    end
    return info
end

--获取指定星级的装备数据
function M:GetBagEquipS(star)
    local list = self.BagInfo
    local info = {}
    for i=1,#list do
        local unit = list[i]
        if unit.type == 4 and unit.star == star then
            self:UpdateEquipUp(unit)
            table.insert(info, unit)
        end
    end
    return info
end

--获取指定部位的装备数据
function M:GetAllBagEquip()
    local list = self.BagInfo
    local info = {}
    for i=1,#list do
        local unit = list[i]
        if unit.type == 4 then
            self:UpdateEquipUp(unit)
            table.insert(info, unit)
        end
    end
    return info
end

--获取已经激活的魂兽
function M:GetActSBNum()
    return self.actSBNum
end

--获取可以激活的魂兽数量
function M:GetCanActNum()
    return self.totalSBNum
end

function M:GetUnLockState()
    return self.UnLockSB
end

--获取需要比较的部位装备信息
function M:GetEquipCompInfo(part)
    local info = self.SoulBearstDic[tostring(self.CurSBId)]
    local data = nil
    if info then
        local cond = info.condList[part]
        if cond and cond.isUse then
            data = cond.equipData
        end
    end
    return data
end

--获取强化到下一个等级所需强化值
function M:GetNextLvAdvExp(curLv)
    local cfg = SBEquipAdvCfg
    if cfg[curLv+1] then
        return cfg[curLv+1].exp
    end
end

--当前等级lv增加addExp可以转化的等级
function M:GetResultLvCfg(lv, exp, addExp)
    local cfg = SBEquipAdvCfg
    local bExp = lv > 0 and cfg[lv].totalExp or 0
    local totalExp = bExp + exp + addExp
    local len = #cfg
    local data = nil
    for i=1, len do
        if totalExp >= cfg[i].totalExp then
            data = cfg[i]
        end
    end
    --经验不足够升到下一级
    if not data or data.lv == lv then
        data = cfg[lv+1]
    end
    return data
end

--获取该装备的基础属性
function M:GetEquipTotalBaseAttr(equip)
    local list1 = equip.baseAttrList
    local list2 = equip.advAttrList

    local result = {}
    for i=1,#list1 do
        local t = {}
        t.type = list1[i].k
        t.all = list1[i].v
        t.base = 0
        t.add = 0
        if list2 then
            for j=1,#list2 do
                if t.type == list2[j].k then
                    t.all = t.all + list2[j].v
                    t.base = list2[j].v
                    break
                end
            end
        end
       
        table.insert(result, t)
    end
    return result
end

--获取装备基础和强化属性
function M:GetEquipBaseAndAdvAttr(equip)
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


--计算装备强化值和消耗元宝
function M:CalExpAndGold(list)
    local price = GlobalTemp["89"].Value3
    local doubleExp = 0
    local totalExp = 0
    local cost = 0
    for i=1,#list do
        if list[i].level == 0 then
            if self.IsDouble then
                doubleExp = doubleExp + list[i].advVal * 2
                totalExp = totalExp + list[i].advVal * 2 + list[i].extraVal
            else
                totalExp = totalExp + list[i].advVal + list[i].extraVal
            end
        else
            totalExp = totalExp + list[i].advVal + list[i].extraVal
        end
    end
    if self.IsDouble then
        cost = math.ceil(doubleExp*0.5*0.01)*price
    end
    self:SetGoldState(RoleAssets.Gold >= cost)
    self.eUpdateExpAndGold(totalExp, cost)
end


--魂兽系统是否开启
function M:IsOpen()
    return self.SBOpenState 
end


--tool
function M:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Log(err)
	    return false
    end
    return true
end

function M:SortBag()
    table.sort(self.BagInfo, function(a,b) return self:Sort(a, b) end)
end

function M:Sort(a, b)
    if a.quality ~= b.quality then
        return a.quality > b.quality
    elseif a.part ~= b.part then
        return a.part < b.part
    elseif a.star ~= b.star then
        return a.star > b.star
    else 
        return a.totalScore > b.totalScore
    end 
end


function M:ClearDic(tab)
    TableTool.ClearDic(tab)
end

function M:ClearData()
    self.CurSBId = 0
    self.CurEquipId = 0
    self.IsDouble = false
end

function M:Clear()
    self:ClearDic(self.BagInfo)
    self:ClearDic(self.SoulBearstInfo)
    self:ClearDic(self.SoulBearstDic)
    self:ClearData()
    self.totalSBNum = 0
    self.actSBNum = 0
    self.SBOpenState = false
    self.UnLockSB = false
    self.AdvRedPoint = false
    self.ChangeEquipRedPoint = false
    self.ActiveSBRedPoint = false
end

return M