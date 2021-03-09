require("Fashion/FashionHelper")
require("Fashion/FashionAdv")
require("Fashion/FashionUnit")
FashionMgr = Super:New{Name = "FashionMgr"}

local M = FashionMgr

M.FashionType={
    {id = 1, name = "衣服"},
    {id = 2, name = "武器"},
    {id = 3, name = "气泡"},
    {id = 4, name = "头像框"},
    {id = 5, name = "足迹"},
}

M.eUpdateInfo = Event()
M.eChgFashion = Event()
M.eDecompose = Event()
M.eUpdateRedPoint = Event()
M.eUpdateSuit = Event()

M.fashionInfo = {}
M.fashionDic = {}
M.essenceDic = {}
M.skinList = {}    --切换时装列表 
M.curIdList = {}   --当前时装列表
M.suitList = {}   --套装信息  suitUnit
M.suitDic = {}    --k:套装id  v: suitUnit
--仙侣套装信息列表和字典
M.coupleFashionDic = {}
M.coupleSuitList = {}
M.coupleSuitDic = {}
M.redPoint = {}
M.tState = {}
M.BigRed = false

function M:Init()
    self:Reset()
    self:SetLsnr(ProtoLsnr.Add)
    self:SetEvent()
end

function M:Reset()
    self.isInitServerData = false;
    self:InitFashionInfo()
    self:InitCoupleFashion()
    self:InitEssenceDic()
    self:InitSuitInfo()
end

function M:SetEvent()
    PropMgr.eUpdate:Add(self.UpdateRedPoint, self)
    AdvMgr.eSkinActive:Add(self.UpdateCultivateFashion,self)
end

function M:SetLsnr(fn)
    fn(22670, self.RespFashionInfo, self)
    fn(22672, self.RespFashionChange, self)
    fn(22674, self.RespFashionDecompose, self)
    fn(22676, self.RespFashionSuit, self)
    fn(22660, self.RespFashionUpdate,self)
    fn(22662, self.RespDelFashion,self)
    fn(22664, self.RespCoupleSkin,self)
    fn(22666, self.RespCoupleSkinUpd,self)
    fn(22678, self.RespFashionGive,self)
end

--时装信息提示
function M:RespFashionInfo(msg)
    self.isInitServerData = true;
    self:UpdateFashionData(msg.fashion_list)
    self:UpdateFashionUse(msg.cur_id_list, msg.op_type == 0)
    self:UpdateEssence(msg.essence_list)
    self:UpdateSuit(msg.suit_list)
    self:UpdateRedPoint()
    self.eUpdateInfo()
end

--时装更新
function M:RespFashionUpdate(msg)
    self:SetFashionData(msg.fashion);
    self:UpdateRedPoint()
    self.eUpdateInfo()
end

--删除时装(限时时装过期)
function M:RespDelFashion(msg)
    local baseId = math.floor(msg.fashion_id/100)
    local unit = self.fashionDic[tostring(baseId)];
    if unit  == nil then
        return;
    end
    unit:TimeComplete();
    unit.isActive = false;
    self:UpdateRedPoint()
    self.eUpdateInfo()
end

--仙侣套装信息
function M:RespCoupleSkin(msg)
    self:ClearCoupleSkinActive();
    local skinList = msg.base_id_list;
    if skinList == nil then
        return;
    end
    for i = 1, #skinList do
        self:UpdateCoupleSkinActive(skinList[i]);
    end
    self:UpdateRedPoint()
    self.eUpdateInfo()
    self.eUpdateSuit()
end

--更新仙侣套装
function M:RespCoupleSkinUpd(msg)
    self:UpdateCoupleSkinActive(msg.base_id);
    self:UpdateRedPoint()
    self.eUpdateInfo()
    self.eUpdateSuit()
end

--更换时装
function M:RespFashionChange(msg)
    if msg.err_code == 0 then
        self:UpdateFashionUse(msg.cur_id_list)
        self.eChgFashion()
        self.eUpdateInfo()
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end

--请求更换时装
function M:ReqFashionChange(type, cur_id)
    local msg = ProtoPool.GetByID(22671)
    msg.type = type         --操作类型 1穿 2脱
    msg.cur_id = cur_id     --时装id
    ProtoMgr.Send(msg)
end


--请求激活进阶时装
function M:ReqFashionAdv(id,num)
    PropMgr.ReqUse(id, num, 1)
end

--分解时装返回
function M:RespFashionDecompose(msg)
    if msg.err_code == 0 then
        local data = msg.essence
        self:UpdateEssenceUnit(data.type, data.level, data.exp)
        self.eDecompose()
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end

--请求分解时装
function M:ReqFashionDecompose(id_list)
    local msg = ProtoPool.GetByID(22673)
    for k,v in pairs(id_list) do
        msg.id_list:append(v)    
    end   
    ProtoMgr.Send(msg)
end

--时装套装激活返回
function M:RespFashionSuit(msg)
    if msg.err_code == 0 then
        self:UpdateSuitActive(msg.fashion_suit)
        self:UpdateRedPoint()
        self.eUpdateSuit()
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Log(err)
    end
end

--时装套装激活
function M:ReqFashionSuit(suit_id,actNum)
    local msg = ProtoPool.GetByID(22675)
    msg.suit_id = suit_id
    msg.active_num = actNum;
    ProtoMgr.Send(msg)
end

--赠送套装部件(时装)
function M:ReqFashionGive(baseId)
    local msg = ProtoPool.GetByID(22677);
    msg.base_id = baseId;     
    ProtoMgr.Send(msg)
end

--赠送时装成功
function M:RespFashionGive(msg)
    if msg.err_code == 0 then
        local msg = "赠送成功";
        UITip.Log(msg);
    else
        local err = ErrorCodeMgr.GetError(msg.err_code);
        UITip.Log(err);
    end
end

--==============================--

--初始化fashionInfo
function M:InitFashionInfo()
    for k,v in pairs(FashionCfg) do
        local _type = tostring(v.type)
        if not self.fashionInfo[_type] then
            self.fashionInfo[_type] = {}
        end
        local unit = self:CreateFashionUnit(v.baseid)
        if unit then
            self.fashionDic[k] = unit
            table.insert(self.fashionInfo[_type], unit)
        end
    end
    FashionHelper.CreateSkinUnit(false);
end

--初始化仙侣时装信息
function M:InitCoupleFashion()
    for k,v in pairs(FashionCfg) do
        local unit = self:CreateFashionUnit(v.baseid);
        if unit then
            self.coupleFashionDic[k] = unit;
        end
    end
    FashionHelper.CreateSkinUnit(true);
end

--初始化EssenceDic
function M:InitEssenceDic()
    local list = self.FashionType
    for i=1,#list do
        local _type = list[i].id
        self.essenceDic[tostring(_type)] = {}
        self:UpdateEssenceUnit(_type, 1, 0)
    end
end

function M:InitSuitInfo()
    local data = FashionSuitCfg
    for i=1,#data do
        local cfg = data[i]
        local unit = self:CreateSuitUnit(cfg,false)
        table.insert(self.suitList, unit)
        self.suitDic[tostring(unit.id)] = unit

        self:InitCoupleSuit(cfg)
    end
end

--初始化仙侣套装
function M:InitCoupleSuit(cfg)
    local unit = self:CreateSuitUnit(cfg,true)
    table.insert(self.coupleSuitList, unit)
    self.coupleSuitDic[tostring(unit.id)] = unit
end

--创建suitUnit
function M:CreateSuitUnit(cfg,isCouple)
    local unit = {}
    unit.id = cfg.id
    unit.name = cfg.name
    unit.type = cfg.type;
    unit.isActive = false
    unit.activeNum = 0
    unit.mIcon = cfg.mIcon
    unit.wIcon = cfg.wIcon
    unit.attrList = cfg.suitAttrs;
    local list = FashionHelper.GetSuitAttrList(cfg.suitAttrs);
    unit.fight = PropTool.GetFightByList(list)
    unit.skillInfo = cfg.skillInfo
    local data = cfg.fashionList
    local temp = {}
    for i=1,#data do
        local baseId = data[i]
        local fashionUnit = nil;
        local idStr = tostring(baseId);
        if isCouple == true then
            fashionUnit = self.coupleFashionDic[idStr];
        else
            fashionUnit = self.fashionDic[idStr];
        end
        table.insert(temp, fashionUnit)
    end
    unit.fashionList = temp
    return unit
end


--创建时装数据结构
function M:CreateFashionUnit(baseid)
    local data = FashionCfg[tostring(baseid)]
    if not data then return end

    local unit = ObjPool.Get(FashionUnit);
    unit.baseId = data.baseid   --时装基础id
    unit.uid = data.baseid * 100  --道具Id
    unit.curId = data.baseid * 100   --当前ID
    unit.name = data.name;
    unit.type = data.type   --时装类型
    unit.shopId = data.shopId;
    unit.isLimitTime = data.limitTime == 1;
    unit.isActive = false    --是否激活
    unit.isUse = false  --是否使用
    unit.worth = data.worth   --分解可获得精华数量
    unit.mIcon = data.mIcon; --男图标
    unit.wIcon = data.wIcon; --女图标
    
    local curId = unit.curId;
    if unit.isLimitTime == true then
        curId = curId + 5;
    end
    unit.cfg = self:GetAdvCfg(curId)
    unit.nCfg = self:GetAdvCfg(curId+1)
    return unit
end

--更新时装使用状态
function M:UpdateFashionUse(list, isInit)
    local dic = self.fashionDic

    for k,v in pairs(dic) do
        v.isUse = false
    end

    local len = #list
    if not isInit then
        local curIdList = self.curIdList
        local count = #curIdList
        if len >= count then
            for i=1,len do
                if not self:Contain(curIdList, list[i]) then
                    self:UpdateSkinList(list[i], false)   --穿上
                    UITip.Log("穿戴成功")
                end
            end
        else
            for i=1,count do
                if not self:Contain(list, curIdList[i]) then
                    UITip.Log("卸下成功")
                    self:UpdateSkinList(curIdList[i], true)  --脱下
                end
            end
        end
    end 

    local temp = {}
    for i=1,len do
        local baseId = math.floor(list[i]/100)
        local unit = dic[tostring(baseId)]
        unit.isUse = true
        temp[i] = list[i]
    end

    self.curIdList = temp
end

--更新时装数据
function M:UpdateFashionData(list)
    local dic = self.fashionDic
    for k,v in pairs(dic) do
        if v.type == 3 then
            v.isActive = false;
        end
    end

    local len = #list
    for i=1,len do
        self:SetFashionData(list[i]);
    end
end

--设置时装数据
function M:SetFashionData(fashionInfo)
    local fashionId = fashionInfo.fashion_id
    local endTime = fashionInfo.end_time
    local baseId = math.floor(fashionId/100)
    local unit = self.fashionDic[tostring(baseId)]
    unit.isActive = true
    unit.curId = fashionId
    unit:SetTimer(endTime)
    unit.cfg = self:GetAdvCfg(fashionId)
    unit.nCfg = self:GetAdvCfg(fashionId+1)
end

--玩家自己的养成时装更新
function M:UpdateCultivateFashion(info)
    if info == nil then
        return;
    end
    local type = type(info);
    if type == "table" then
        for k,v in pairs(info) do
             self:SetCultiveteFashion(v.id);
        end
    elseif type == "number" then
        self:SetCultiveteFashion(info);
    end
    self:UpdateRedPoint()
    self.eUpdateInfo()
    self.eUpdateSuit()
end

--设置自己的养成皮肤
function M:SetCultiveteFashion(skinId)
    if skinId == nil then
        return;
    end
    local baseId = math.floor(skinId * 0.01);
    local unit = self.fashionDic[tostring(baseId)]
    if unit == nil then
        return;
    end
    unit.isActive = true;
    unit.endTime = 0;
end

--更新时装精华
function M:UpdateEssence(list)
    local len = #list
    for i=1,len do
        self:UpdateEssenceUnit(list[i].type, list[i].level, list[i].exp)
    end
end

--更新时装精华单元
function M:UpdateEssenceUnit(_type, lv, exp)
    local unit = self.essenceDic[tostring(_type)]
    unit.type = _type --时装类型
    unit.level = lv  --当前等级
    unit.exp = exp  --当前经验
    unit.cfg = self:GetEssenceCfg(_type, lv)
    unit.nCfg = self:GetEssenceCfg(_type, lv+1)
end

function M:UpdateSuit(list)
    for i=1,#list do
        self:UpdateSuitActive(list[i])
    end
end

function M:UpdateSuitActive(fashionSuit)
    local id = fashionSuit.suit_id
    local activeNum = fashionSuit.active_num
    local unit = self:GetSuitUnit(id)
    unit.activeNum = activeNum
    if activeNum == #unit.fashionList then
        unit.isActive = true
    end
end

--更新仙侣皮肤
function M:UpdateCoupleSkinActive(skinBaseId)
    for i = 1, #self.coupleSuitList do
        local unit = self.coupleSuitList[i];
        local fashionList = unit.fashionList;
        local activeNum = 0;
        local len = #fashionList;
        for k = 1, len do
            local fashion = fashionList[k];
            if fashionList[k].baseId == skinBaseId then
                fashion.isActive = true;
            end
            if fashion.isActive == true then
                activeNum = activeNum + 1;
            end
        end
        if activeNum == len then
            unit.activeNum = true;
        end
    end
end

--清除仙侣皮肤激活状态
function M:ClearCoupleSkinActive()
    for i = 1, #self.coupleSuitList do
        local unit = self.coupleSuitList[i];
        local fashionList = unit.fashionList;
        local len = #fashionList;
        for k = 1, len do
            fashionList[k].isActive = false;
        end
    end 
end

--takeOff:true  脱掉脱掉  false 穿上
function M:UpdateSkinList(curId, takeOff)
    local baseId = math.floor(curId/100)
    local curData = self:GetFashionData(baseId)
    local list = self.skinList

    for i=1,#list do
        local tmp = math.floor(list[i]/100)
        local data = self:GetFashionData(tmp)
        if data then
            if data.type == curData.type then
                if list[i] == curId then 
                    if takeOff then
                        table.remove(list, i)
                    end
                else
                    list[i] = curId
                end
                return 
            end
        end
    end

    if not takeOff then
        table.insert(list, curId)
    end 
end

function M:TryGetSkin(curId, takeOff)
    local baseId = math.floor(curId/100)
    local cfg = FashionCfg[tostring(baseId)]
    if cfg then
        if cfg.type ~= 3 and cfg.type ~= 4 then
            local modelName = User.MapData.Sex == 0 and cfg.wMod or cfg.mMod
            if RoleSkin.IsExistAs(modelName) then
                self:UpdateSkinList(curId, takeOff)
                self.eChgFashion()
            else
                UITip.Log("该时装资源正在加载...")
            end
        else
            self.eChgFashion()
        end
    end  
end

function M:UpdateRedPoint()
    if self.isInitServerData == false then
        return;
    end
    self:UpdateFashionRedPoint()
    self:UpdateEssRedPoint()
    self:UpdateSuitRedPoint()

    local state = false

    for _type, dic in pairs(self.redPoint) do
        local tState = false
        for k,v in pairs(dic) do
            if not tState then
                tState = v
            end
            if not state then
                state = v
            end
        end
        self.tState[_type] = tState
    end
    self.eUpdateRedPoint(state)
    M.BigRed = state    
end

function M:UpdateFashionRedPoint()
    for k, data in pairs(self.fashionDic) do
        local state = false
        if data.isLimitTime == true then
            state = self:UpdateFshLimtRedP(data);
        else
            state = self:UpdateNorFshRedP(data);
        end
        if not self.redPoint[tostring(data.type)] then
            self.redPoint[tostring(data.type)] = {}
        end
        self.redPoint[tostring(data.type)][k] = state
    end
end

--设置正常时装红点
function M:UpdateNorFshRedP(data)
    local cfg = data.cfg
    local nCfg = data.nCfg
    local state = false;
    if nCfg then
        local item = cfg.comsume[1]
        local num = PropMgr.TypeIdByNum(item.k)
        state = num>=item.v
    else
        state = false
    end
    return state;
end

--设置限时时装红点
function M:UpdateFshLimtRedP(data)
    local cfg = data.cfg
    local state = false;
    local item = cfg.comsume[1];
    local num = PropMgr.TypeIdByNum(item.k,nil,true);
    state = num>=item.v;
    return state;
end

function M:UpdateEssRedPoint()
    for k,v in pairs(self.fashionInfo) do
        local info = self.essenceDic[k]
        if info then
            local cfg =  FashionEssenceCfg[tostring(info.type*10000 + info.level+1)]
            if not self.redPoint[tostring(k)] then
                self.redPoint[tostring(k)] = {}
            end
            if cfg then
                local data = self:GetAllDepcompose(k)
                self.redPoint[tostring(k)]["1"] = #data>0
            else
                self.redPoint[tostring(k)]["1"] = false
            end
        end
    end 
end

function M:UpdateSuitRedPoint()
    local list = self.suitList
    for i=1,#list do  
        local state = false
        local actNum = FashionHelper.GetActNum(list[i]);
        if actNum ~= nil then
            state = true;
        end
        if not self.redPoint["0"] then
            self.redPoint["0"] = {}
        end
        self.redPoint["0"][tostring(list[i].id)] = state
    end
end


--==============================--



function M:GetEssRedPointState(_type)
    local t = self.redPoint[tostring(_type)]
    return (t and t["1"]) or false
end


function M:GetTogRedPointState(_type)
    return self.tState[tostring(_type)] or false
end



--通过时装类型获取该类型时装数据
function M:GetFashionInfo(_type)
    local key = tostring(_type)
    return self.fashionInfo[key]
end

--通过基础ID获取该时装数据
function M:GetFashionData(baseId)
    return self.fashionDic[tostring(baseId)]
end

--通过类型获取精华数据
function M:GetEssenceData(_type)
    return self.essenceDic[tostring(_type)]
end

--获取该类型时装所有满足分解条件的id
function M:GetAllDepcompose(_type)
    local data = {}
    local info = self:GetFashionInfo(_type) 
    if info then
        for i=1,#info do
            local baseId = info[i].baseId
            if self:CanDepcompose(baseId) then
                local list = PropMgr.GetGoodsByTypeId(baseId*100)
                for i=1,#list do
                    table.insert(data, list[i])
                end
            end
        end
    end
    return data
end

--是否可以分解  
function M:CanDepcompose(baseId)
    local data = self:GetFashionData(baseId)
    if data.isLimitTime == true then
        return false;
    end
    if not data or (data.cfg and data.cfg.star < 5) then 
        return false 
    else
        return true
    end
end

--获取时装升星配置数据
function M:GetAdvCfg(id)
    local cfg = FashionAdvCfg[tostring(id)]
    local tb = nil;
    if cfg then
        tb = ObjPool.Get(FashionAdv);
        tb:SetData(cfg);
    end
    return tb;
end

--获取精华配置数据
function M:GetEssenceCfg( _type, lv)
    local cfg = FashionEssenceCfg[tostring(_type*10000 + lv)]
    local tb = {}
    if cfg then
        tb.needExp = cfg.num
        tb.atk = cfg.atk
        tb.hp = cfg.hp
        tb.def = cfg.def
        tb.arm = cfg.arm  
    else
        tb = nil
    end
    return tb
end

function M:GetSkinList()
    return self.skinList
end

--获取指定的时装列表
function M:GetSpeList(curId)
    local baseId = math.floor(curId/100)
    local curData = self:GetFashionData(baseId)
    local list = self.curIdList

    local temp = {}
    local len = #list
    if len > 0 then   
        for i=1,#list do
            local tmp = math.floor(list[i]/100)
            local data = self:GetFashionData(tmp)
            if data then
                if data.type == curData.type and list[i] ~= curId then
                    table.insert(temp, curId)
                else
                    table.insert(temp, list[i])
                end
            end  
        end
    else
        table.insert(temp, curId)
    end

    return temp
end

--通过类型获取玩家当前穿在身上的时装基础ID
function M:GetCurFasion(fashionType)
    local list = self.curIdList
    for i=1,#list do
        local baseId = math.floor(list[i]/100)
        local temp = FashionCfg[tostring(baseId)]
        if temp and temp.type == fashionType then
            return baseId
        end
    end
end

function M:GetSuitInfo()
    return self.suitList
end

function M:GetSuitUnit(id)
    return self.suitDic[tostring(id)]
end

function M:GetCoupleSuitUnit(id)
    return self.coupleSuitDic[tostring(id)];
end

function M:GetSuitRedPoint(id)
    local dic = self.redPoint["0"]
    if not dic then return false end
    return dic[tostring(id)] or false
end

function M:GetRedPointState(_type, baseId)
    local dic = self.redPoint[tostring(_type)]
    if not dic then 
        return false
    end
    return dic[tostring(baseId)] or false
end


function M:ResetSkinList()
    local list = self.curIdList
    local tmp = {}
    for i=1,#list do
        tmp[i] = list[i]
    end
    self.skinList = tmp
    self.eChgFashion()
end

function M:Contain(list, id)
    for i=1,#list do
        if list[i] == id then
            return true
        end
    end
    return false
end

function M:Clear()
    TableTool.ClearDic(self.fashionInfo)
    TableTool.ClearDicToPool(self.fashionDic)
    TableTool.ClearDic(self.curIdList)
    TableTool.ClearDic(self.skinList)
    TableTool.ClearDic(self.essenceDic)
    TableTool.ClearDic(self.redPoint)
    TableTool.ClearDic(self.state)
    TableTool.ClearDic(self.suitList)
    TableTool.ClearDic(self.suitDic)
    TableTool.ClearDic(self.coupleSuitList)
    TableTool.ClearDic(self.coupleSuitDic)
    self:Reset()
end

return M 