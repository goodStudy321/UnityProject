AresMgr = {Name = "AresMgr"}

local M = AresMgr

M.MainView = 1
M.AdvView = 2
M.DecompView = 3

M.MaxPro = 10

M.AresList = {}
M.AresDic = {}
M.MaterialDic = {}
M.MaterialEquipDic = {}  --k:materialId, V:equip

M.DecomposeRedPoint = false   --分解红点， 仅判断 玄晶灵石
M.AresPartActiveRedPoint = false --装备部件激活红点
M.AresSuitActiveRedPoint = false  --套装激活红点
M.AresAdvRedPoint = false   --装备开光红点


M.eClickEquip = Event()
M.eOpenView = Event()
M.eRefresh = Event()
M.eUpdateRedPoint = Event()
M.eUpdateAdvFx = Event()
M.eUpdateSuitAdvFx =Event()


function M:Init()
    self:InitData()
    self:AddEvent()
    self:SetLsnr(ProtoLsnr.Add)
end

function M:AddEvent()
    RobberyMgr.eUpdateSpiInfo:Add(self.UpdateSpiRefInfo, self)
    PropMgr.eAdd:Add(self.PropAdd, self)
    PropMgr.eRemove:Add(self.PropRemove, self)
    PropMgr.eUpNum:Add(self.PropUpNum, self)
end

function M:SetLsnr(Lsnr)
    Lsnr(23000, self.RespConfineInfo, self)
    Lsnr(24242, self.RespWarGodPieceActive, self)
    Lsnr(24248, self.RespWarGodActive, self)
    Lsnr(24250, self.RespWarGodRefine, self)
    -- Lsnr(24252, self.RespWarGodPieceUpdate, self)
    Lsnr(24254, self.RespWarGodDecompose, self)  
end

function M:PropAdd(tb,action,tp)
    if tp ~= 1 then return end
    self:UpdateAllMaterial()
end

function M:PropRemove(id,tp,type_id,action,index)
    if tp ~= 1 then return end
    self:UpdateAllMaterial()
end

function M:PropUpNum(tb,tp,num,action)
    if tp ~= 1 then return end
    self:UpdateAllMaterial()
end

--// 境界信息
function M:RespConfineInfo(msg)
    local list = msg.war_god_list
    for i=1,#list do
        local data = list[i]
        local id = data.id
        self:UpdateAresState(id, data.is_active)
        local equipList = data.equip_list
        for j=1,#equipList do
            self:UpdateAresEquip(id, equipList[j])
        end  
        self:UpdateAresLevel(id, true) 
        self:UpdateCurAttr(id) 
        self:UpdateAresEquipLvCount(id)
    end

    -- local pieces = msg.war_god_pieces
    -- for i=1, #pieces do
    --     self:UpdateMaterial(pieces[i].id, pieces[i].val)   
    -- end
    self:UpdateAllMaterial()
    self:UpdateAllRedPoint()
end

--// 战神碎片碎片激活部位返回
function M:RespWarGodPieceActive(msg)
    if self:CheckErr(msg.err_code) then
        local id = msg.war_god_id
        self:UpdateAresEquip(id, msg.war_god_equip)
        self:UpdateAresLevel(id)  
        self:UpdateCurAttr(id)   
        self:UpdateAresEquipLvCount(id) 
        self:UpdateAllRedPoint()
        self.eRefresh()
        self.eUpdateRedPoint()
    end
end

--// 战神碎片碎片激活部位
function M:ReqWarGodPieceActive(war_god_id, equip_id)
    local msg = ProtoPool.GetByID(24241)
    msg.war_god_id = war_god_id
    msg.equip_id = equip_id --int64
    ProtoMgr.Send(msg)
end

--// 战神套装激活返回
function M:RespWarGodActive(msg)
    if self:CheckErr(msg.err_code) then
        local id = msg.war_god_id
        self:UpdateAresState(id, true)
        self:UpdateAresFight(id)
        self:UpdateAllRedPoint()
        self:ShowGetCPM(id)
        self.eRefresh()
        self.eUpdateRedPoint()
    end
end

--// 战神套装激活
function M:ReqWarGodActive(war_god_id)
    local msg = ProtoPool.GetByID(24247)
    msg.war_god_id = war_god_id
    ProtoMgr.Send(msg)
end

--//战神装备开光返回
function M:RespWarGodRefine(msg)
    if self:CheckErr(msg.err_code) then
        local id = msg.war_god_id
        self:UpdateAdvFx(id, msg.war_god_equip)
        self:UpdateAresEquip(id, msg.war_god_equip)
        self:UpdateAresLevel(id)  
        self:UpdateCurAttr(id)  
        self:UpdateAresEquipLvCount(id)    
        self:UpdateAllRedPoint()
        self.eRefresh()
    end
end

--// 战神装备开光
function M:ReqWarGodRefine(war_god_id, equip_id)
    local msg = ProtoPool.GetByID(24249)
    msg.war_god_id = war_god_id
    msg.equip_id = equip_id
    ProtoMgr.Send(msg)
end

-- --//  战神套装碎片更新
-- function M:RespWarGodPieceUpdate(msg)
--     local pieces = msg.pieces
--     for i=1,#pieces do
--         self:UpdateMaterial(pieces[i].id, pieces[i].val)   
--     end
--     self:UpdateAllRedPoint()
--     self.eRefresh()
--     self.eUpdateRedPoint()
-- end

--// 战神碎片分解返回
function M:RespWarGodDecompose(msg)
    if self:CheckErr(msg.err_code) then
        self:UpdateAllRedPoint()
        self.eRefresh()
        self.eUpdateRedPoint()
    end
end

--// 战神碎片分解
function M:ReqWarGodDecompose(piece_ids)
    local msg = ProtoPool.GetByID(24253)
    for k,v in pairs(piece_ids) do  --//材料列表
        msg.piece_ids:append(tonumber(v))    
    end   
    ProtoMgr.Send(msg)
end

function M:CheckErr(errCode)
    if errCode ~= 0 then
		local err = ErrorCodeMgr.GetError(errCode)
        UITip.Log(err)
	    return false
    end
    return true
end

--==============================--




--初始化数据
function M:InitData()
    self.DecomposeRedPoint = false
    self.AresPartActiveRedPoint = false --装备部件激活红点
    self.AresSuitActiveRedPoint = false  --套装激活红点
    self.AresAdvRedPoint = false   --装备开光红点

    local list = AresBaseCfg
    local len = #list
    for i=1, len do
        local unit = self:CreateAresUnit(list[i])
        table.insert(self.AresList, unit)
        self.AresDic[tostring(list[i].id)] = unit
    end
end

--创建套装单元
function M:CreateAresUnit(data)
    local unit = {}
    unit.id = data.id  --套装Id
    unit.name = data.name --套装名字
    unit.texture = data.texture  --图片
    unit.modelId = data.modelId
    unit.modelPath = self:GetModelPath(data.modelId)
    unit.state = false  --套装是否激活
    unit.level = 0  --套装阶数
    unit.per = 0  --套装基础属性加成系数
    unit.baseAttrList = PropTool.SwitchAttr(data)  --套装基础属性列表
    unit.equipList = {}  --套装的装备列表   
    unit.equipDic = {}
    unit.redPointState = false   --该套装总的红点状态
    unit.equipRedPointState = false   --该套装的装备开光红点
    unit.levelList = self:CreateAresLvList(unit.id)
    unit.maxLv = #unit.levelList   --该套装能达到的最大阶数
    for i=1,4 do
        local equip = self:CreateAresEquip(data, i, unit.maxLv)
        table.insert(unit.equipList, equip)
        unit.equipDic[tostring(equip.id)] = equip         
        self:UpdateMaterial(equip.materialId, 0)
        self.MaterialEquipDic[tostring(equip.materialId)] = equip
    end  
    unit.curAttrList = PropTool.SwitchAttr(data)   --当前属性列表，包括装备属性和加成 
    unit.fight = 0  --套装战斗力
    return unit
end

--创建套装装备单元
function M:CreateAresEquip(data, index, maxLv)
    local equip = {}
    equip.user = data.id  --该装备所属的套装Id
    equip.id = data["part"..index] or 0   --装备Id
    equip.level = 0   --装备的阶数
    equip.materialId = data["arg"..index].k or 0
    equip.needCount = data["arg"..index].v or 0    --碎片需要数量
    equip.materialName = ItemData[tostring(equip.materialId)].name
    equip.state = false  --是否激活
    equip.attrList = {}
    equip.consume = 0 --装备当前阶数的开光价格
    equip.progress = 0  --开光进度
    local item = ItemData[tostring(equip.id)]
    equip.quality = item.quality  --装备品质
    equip.getPath = item.des  --装备的获取途径
    equip.name = item.name  --装备的名字
    equip.canActive = false  --是否可以激活
    equip.redPointState = false   --装备的开光红点
    equip.maxLv = maxLv  --改装备能达到的最大阶数
    return equip
end

--创建开光阶数列表
function M:CreateAresLvList(id)
    local list = {}
    local len = #AresCfg
    for i=1,len do
        local data = AresCfg[i]
        if data.id == id then
            local temp = {}
            temp.attr = data.attr
            temp.level = data.level
            temp.maxCount = 4
            temp.curCount = 0   --当前符合阶数的装备数量
            list[temp.level] = temp
        end
    end
    return list
end




--==============================--
--Update
--战灵激活
function M:UpdateSpiRefInfo()
    self:UpdateAllRedPoint()
    self.eUpdateRedPoint()
    self.eRefresh()
end

--更新所有套装红点
function M:UpdateAllRedPoint()
    self.AresSuitActiveRedPoint = false  
    self.AresAdvRedPoint = false
    self.AresPartActiveRedPoint = false

    local list = self.AresList
    for i=1,#list do
        local id = list[i].id
        self:UpdateEquipRedPoint(id)
        self:UpdateRedPoint(id)
    end
    self:UpdateTotalRedPoint()
end

--更新套装红点
function M:UpdateRedPoint(id)
    local unit = self:GetAresById(id)
    unit.redPointState = false
    unit.equipRedPointState = false
    local equipList = unit.equipList
    if not unit.state then  --套装没激活
        local state = true
        for i=1,#equipList do
            local equip = equipList[i]
            if not unit.redPointState then
                unit.redPointState = equip.canActive
            end
            if state then
                state = equip.state
            end
            if not self.AresPartActiveRedPoint then
                self.AresPartActiveRedPoint = equip.canActive
            end
        end
        if state then  --该套装已经激活所有装备
            local isOpen = not RobberyMgr:IsLockSp(unit.id)  --该战灵是否解锁
            unit.redPointState = isOpen
            if not self.AresSuitActiveRedPoint then
                self.AresSuitActiveRedPoint = isOpen
            end
        end
    else --套装已激活
        for i=1,#equipList do
            local equip = equipList[i]
            local state = equip.redPointState
            if not unit.redPointState then
                unit.redPointState = state
            end 
            if not unit.equipRedPointState then
                unit.equipRedPointState = state
            end
            if not self.AresAdvRedPoint then
                self.AresAdvRedPoint = state
            end
        end
    end
end

--更新所有套装综合红点
function M:UpdateTotalRedPoint()
    local list = self.AresList
    local state = false
    for i=1,#list do
        if list[i].redPointState then
            state = true
        end
    end 
    local totalState = state or self.DecomposeRedPoint
    RobberyMgr:StateSpRed(3, totalState)
    SystemMgr:ChangeActivity(totalState, ActivityMgr.DJ, 4)
    SystemMgr:ChangeActivity(self.DecomposeRedPoint, ActivityMgr.DJ, 4, 1)
    SystemMgr:ChangeActivity(self.AresPartActiveRedPoint, ActivityMgr.DJ, 4, 2)
    SystemMgr:ChangeActivity(self.AresSuitActiveRedPoint, ActivityMgr.DJ, 4, 3)
    SystemMgr:ChangeActivity(self.AresAdvRedPoint, ActivityMgr.DJ, 4, 4)
end


--更新装备开光红点
function M:UpdateEquipRedPoint(id)
    local unit = self:GetAresById(id)
    local equipList = unit.equipList
    for i=1,#equipList do
        local equip = equipList[i]
        equip.redPointState =  equip.level < equip.maxLv and equip.consume <= RoleAssets.AresCoin
    end 
end

function M:UpdateDecomposeRedPoint(id, num)
    if id ~= "1000001" then return end
    self.DecomposeRedPoint = num > 0
    SystemMgr:ChangeActivity(self.DecomposeRedPoint, ActivityMgr.DJ, 4, 1)
end

--更新当前属性
function M:UpdateCurAttr(id)
    self:UpdateAresPer(id)
    local unit = self:GetAresById(id)
    local baseList = unit.baseAttrList
    local equipList = unit.equipList
    TableTool.ClearDic(unit.curAttrList)
    for i=1, #baseList do
        local base = baseList[i]
        local temp = {}
        temp.k = base.k
        temp.v = base.v
        for j=1, #equipList do
            local attrList = equipList[j].attrList
            for z=1, #attrList do
                local data = attrList[z]
                if base.k == data.k then
                    temp.v = temp.v + data.v
                end
            end           
        end
        temp.v = math.floor(temp.v * (1+unit.per*0.0001))
        table.insert(unit.curAttrList, temp)
    end
    self:UpdateAresFight(id)
end


--更新套装激活状态
function M:UpdateAresState(id, state)
    local unit = self:GetAresById(id)
    unit.state = state
end


--更新套装上的装备信息， id:套装id
function M:UpdateAresEquip(id, data)
    local unit = self:GetAresById(id)
    local equipDic = unit.equipDic
    local equip = equipDic[tostring(data.equip_id)]
    equip.level = data.refine_level
    equip.progress = data.refine_exp
    if equip.level == equip.maxLv then
        equip.progress = self.MaxPro
    end
    equip.state = true
    equip.canActive = false
    self:UpdateEquipAttr(equip)
    self:UpdateEquipConsume(equip)
end

--判断开光特效， id:套装id
function M:UpdateAdvFx(id, data)
    local isBaoji = false
    local unit = self:GetAresById(id)
    local equipDic = unit.equipDic
    local equip = equipDic[tostring(data.equip_id)]
    if equip.level <= data.refine_level then
        isBaoji = data.refine_exp - equip.progress > 1      
    else
        isBaoji = self.MaxPro-equip.progress+data.refine_exp > 1
    end
    self.eUpdateAdvFx(isBaoji)
end



--更新套装装备阶数数量
function M:UpdateAresEquipLvCount(id)
    local unit = self:GetAresById(id)
    local levelList = unit.levelList
    local equipList = unit.equipList
    for i=1,#levelList do
        levelList[i].curCount = self:GetEquipLvCount(equipList, levelList[i].level)
    end
end

function M:UpdateAllMaterial()
    TableTool.ClearDic(self.MaterialDic)
    local typeIdList =  PropMgr.UseEffGet(73)  
    local len = #typeIdList
    if len == 0 then
        self:UpdateDecomposeRedPoint("1000001", 0);
        return 
    end
    local isHaveXJLS = false;

    for i=1,len do
        local typeId = typeIdList[i]
        local num = PropMgr.TypeIdByNum(typeId)
        if (typeId == "1000001") then
            isHaveXJLS = true;
        end
        self:UpdateMaterial(typeId, num)
    end
    if (isHaveXJLS == false) then
        self:UpdateDecomposeRedPoint("1000001", 0);
    end
    
    self:UpdateAllRedPoint()
    self.eRefresh()
    self.eUpdateRedPoint()
end

--更新碎片数量
function M:UpdateMaterial(id, num)
    self.MaterialDic[tostring(id)] = num
    self:UpdateEquipActive(id, num)
    self:UpdateDecomposeRedPoint(id, num)
end

--更新该碎片对应的装备是否可以激活
function M:UpdateEquipActive(id, num)
    local equip = self.MaterialEquipDic[tostring(id)]
    if not equip then return end
    equip.canActive = num >= equip.needCount and not equip.state
end

--更新套装阶数
function M:UpdateAresLevel(id, isInit)
    local unit = self:GetAresById(id)
    local equipList = unit.equipList
    local level = 10000
    for i=1, #equipList do
        local equip = equipList[i]
        if not equip.state then
            level = 0
            break
        end
        if level > equip.level then
            level = equip.level
        end
    end
    if not isInit and unit.level ~= level then
        self.eUpdateSuitAdvFx()
    end
    unit.level = level
end

--更新套装阶数属性加成
function M:UpdateAresPer(id)
    local unit = self:GetAresById(id)
    local level = unit.level
    local len = #AresCfg
    local per = 0
    if unit.state then
        for i=1,len do
            local data = AresCfg[i]
            if data.id == id and data.level <= level then
                if per < data.per then
                    per = data.per
                end
            end
        end
    end
    unit.per = per
end


--更新套装战力
function M:UpdateAresFight(id)
    local unit = self:GetAresById(id)

    if unit.state then
        unit.fight = PropTool.GetFightByList(unit.curAttrList)
    else
        local equipList = unit.equipList
        local fight = 0
        for i=1, #equipList do
            local equip = equipList[i]
            if equip.state then
                fight = fight + PropTool.GetFightByList(equip.attrList)
            end
        end
        unit.fight = fight
    end
end



--更新该装备当前阶数的属性
function M:UpdateEquipAttr(equip)
    local list = AresAdvCfg
    local len = #list
    for i=1,len do
        local data = list[i]
        if data.id == equip.id and data.level == equip.level then
            TableTool.ClearDic(equip.attrList)
            local temp = PropTool.SwitchAttr(data)
            for i=1,#temp do
                table.insert(equip.attrList, temp[i])
            end
            break
        end
    end
end


--更新该装备当前阶数开光价格
function M:UpdateEquipConsume(equip)
    local list = AresAdvCfg
    local len = #list
    for i=1,len do
        local data = list[i]
        if data.id == equip.id and data.level == equip.level then
            equip.consume = data.consume
            break
        end
    end
end



--展示激活的套装模型
function M:ShowGetCPM(id)
    local unit = self:GetAresById(id)
    UIShowGetCPM.OpenCPM(unit.modelId, 4)
end





--==============================--
--get


function M:GetTotalRedPointState()
    local list = self.AresList
    local state = false
    for i=1,#list do
        if list[i].redPointState then
            state = true
            break
        end
    end
    return state or self.DecomposeRedPoint
end

--获取可以分解的材料信息
function M:GetCanDecompMateralData()
    local list = {}
    local dic = self.MaterialDic
    for k,v in pairs(dic) do  
        if v > 0 then   
            local equip = self.MaterialEquipDic[tostring(k)] 
            if k == "1000001" or (equip and equip.state)then
                local temp = {}
                temp.id = k
                temp.num = v
                table.insert(list, temp)
            end
        end
    end
    return list
end

--获取碎片数量
function M:GetMaterialCount(id)
    return self.MaterialDic[tostring(id)] or 0
end

--获取装备列表中符合该阶数的装备数量
function M:GetEquipLvCount(equipList, level)
    local num = 0
    for i=1,#equipList do
        if equipList[i].level >= level then
            num = num+1
        end
    end
    return num
end

--通过套装id获取unit
function M:GetAresById(id)
    local unit = self.AresDic[tostring(id)]
    if not unit then
        iTrace.Error("XGY", string.format("不存在套装id为：%s的套装",id))
    end
    return unit
end

--获取模型路径
function M:GetModelPath(modelId)
    local modelData = RoleBaseTemp[tostring(modelId)]
    if modelData and modelData.uipath then
        return modelData.uipath  --模型名字
    else
        iTrace.Error("XGY", "角色模型表不存在该模型数据，找思恒")
    end
end

--获取所有的套装数据
function M:GetAresData()
    return self.AresList
end

--获取符合强化条件的所有套装
function M:GetCanAdvAresData()
    local data = {}
    local list = self.AresList
    for i=1,#list do
        if list[i].state then
            table.insert(data, list[i])
        end
    end
    return data
end

--获取该装备可达到的最大阶数
function M:GetEquipMaxLevel(equipId)
    local level = 0
     for i=1,#AresAdvCfg do
         if AresAdvCfg[i].id == equipId then
            if level < AresAdvCfg[i].level then
                level = AresAdvCfg[i].level
            end
         end
     end
     return level
end

--组合装备当前阶数属性和下一阶属性
function M:GetEquipNextAttr(equip)
    local data = {}
    local curList = equip.attrList
    local id = equip.id
    local nLv = equip.level+1
    local nextList = {}
    for i=1,#AresAdvCfg do
        local temp = AresAdvCfg[i]
        if temp.id == id and temp.level == nLv then
            nextList = PropTool.SwitchAttr(temp)
            break
        end
    end
    for i=1,#curList do
        local temp = {}
        temp.k = curList[i].k
        temp.v = curList[i].v
        temp.add = 0
        for j=1,#nextList do
            local next = nextList[j]
            if temp.k == next.k then
                temp.add = next.v-temp.v
                break
            end
        end
        table.insert(data, temp)
    end
    return data
end

--获取套装下一阶属性
function M:GetAresNextLvAttr(id, curLevel)
    local nextLv = curLevel + 1
    local nAttr = nil
    for i=1, #AresCfg do
        local temp = AresCfg[i]
        if temp.id == id and temp.level == nextLv then
            nAttr = temp.attr
        end
    end
    return nAttr
end

--是否可以激活该套装
function M:CanActiveSuit(id)
    local unit = self:GetAresById(id)
    if unit.state then
        return false
    end
    local list = unit.equipList
    local state = true
    for i=1,#list do
        if not list[i].state then
            state = false
            break
        end
    end

    if state then
        state =  not RobberyMgr:IsLockSp(id)
    end
    return state
end

--获取材料分解价值
function M:GetDecompValue(id)
    return ItemData[tostring(id)].uFxArg[1]
end

function M:GetDecomposeRedPointStatus()
    return self.DecomposeRedPoint
end

function M:Clear()
    TableTool.ClearDic(self.AresList)
    TableTool.ClearDic(self.AresDic)
    TableTool.ClearDic(self.MaterialDic)
    TableTool.ClearDic(self.MaterialEquipDic)
    self:InitData()
end

return M