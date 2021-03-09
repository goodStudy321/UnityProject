AlchemyMgr = Super:New{Name = "AlchemyMgr"}

local M = AlchemyMgr

M.OnceNeed = GlobalTemp["171"].Value3

M.mBestAlchemyData = {}   --仙品炼丹数据
M.mCommonAlchemyData = {}  --凡品炼丹数据


M.eUpdateTimes = Event()
M.eUpdatePro = Event()
M.eUpdateRedPoint = Event()
M.eAlchemySuccess = Event()
M.eUpdateBestTempBag = Event()
M.eUpdateCommonMaterialBag = Event()



M.IsOpenCommonAlchemy = false


function M:Init()
    self:SetLsnr(ProtoLsnr.Add)
    self:SetEvent()
end

function M:SetEvent()
    PropMgr.eAdd:Add(self.PropAdd, self)
    PropMgr.eRemove:Add(self.PropRemove, self)
    PropMgr.eUpNum:Add(self.PropUpNum, self)
end

function M:SetLsnr(Lsnr)
    Lsnr(26458, self.RespRoleBgAlchemyOne, self)
    Lsnr(26460, self.RespRoleBgAlchemyTwo, self)
    Lsnr(26462, self.RespRoleBgAlchemySubmit, self)
    Lsnr(26464, self.RespRoleBgAlchemyDraw, self)
end

function M:PropAdd(tb,action,tp)
    if tp == 1 then
        self:UpdateCommonMaterials()
        self:UpdateBestMaterialCount()
    elseif tp == 6 then
        self:UpdateBestTempBag()
    end
end

function M:PropRemove(id,tp,type_id,action,index)
    if tp == 1 then
        self:UpdateCommonMaterials()
        self:UpdateBestMaterialCount()
    elseif tp == 6 then
        self:UpdateBestTempBag()
    end
end

function M:PropUpNum(tb,tp,num,action)
    if tp == 1 then
        self:UpdateCommonMaterials()
        self:UpdateBestMaterialCount()
    elseif tp == 6 then
        self:UpdateBestTempBag()
    end
end


--// 后台新仙品丹炉  仙品
function M:RespRoleBgAlchemyOne(msg)
    self:MsgLog("RespRoleBgAlchemyOne", msg)
    TableTool.ClearDic(self.mBestAlchemyData)
    self:InitBestAlchemyData(msg)
end

--// 新仙品丹炉  凡品
function M:RespRoleBgAlchemyTwo(msg)
    self:MsgLog("RespRoleBgAlchemyTwo", msg)
    M.IsOpenCommonAlchemy = true
    self:ClearCommonAlchemyData()
    self:UpdateCommonTimes(msg.times)
    self:UpdateCommonProgress(msg.schedule)
    self:UpdateCommonList()
    self:UpdateCommonMaterials()
end

--// 后台新仙品丹炉  凡品   提交材料
function M:RespRoleBgAlchemySubmit(msg)
    self:MsgLog("RespRoleBgAlchemySubmit", msg)
    if UIMisc.CheckErr(msg.err_code) then
        self:UpdateCommonTimes(msg.times)
        self:UpdateCommonProgress(msg.schedule)
        self.eUpdatePro()
        self.eUpdateTimes()
    end
end

--// 后台新仙品丹炉  凡品   提交材料
function M:ReqRoleBgAlchemySubmit(list)
    local msg = ProtoPool.GetByID(26461)
    for k,v in pairs(list) do  --//材料列表
        msg.bag:append(v)    
    end   
    ProtoMgr.Send(msg)
end

--// 后台新仙品丹炉  抽取
function M:RespRoleBgAlchemyDraw(msg)
    self:MsgLog("RespRoleBgAlchemyDraw", msg)
    if UIMisc.CheckErr(msg.err_code) then
        local type = msg.type
        if type == 1 then --1 - 仙品 2- 凡品

        elseif type == 2 then 
            self:UpdateCommonTimes(msg.times)
            self.eUpdateTimes()
        end
        self.eAlchemySuccess(type)
    end
end

--// 后台新仙品丹炉  抽取
function M:ReqRoleBgAlchemyDraw(times, type)
    local msg = ProtoPool.GetByID(26463)
    msg.times = times  --//可抽取次数
    msg.type = type    -- //1 - 仙品 2- 凡品
    ProtoMgr.Send(msg)
end




--Init
function M:InitBestAlchemyData(data)
    local unit = self.mBestAlchemyData
    unit.MaterialId = data.need_item
    unit.MaterialCount = 0
    unit.OnceGold = data.once_gold
    unit.TenGold = data.ten_gold
    unit.BtnOneName = data.btn_text
    unit.BtnTenName = data.btn_text_i
    unit.ImmortalList = self:SwithPItemI(data.list_one)    --仙品丹药 item
    unit.BestList = self:SwithPItemI(data.list_two)        --极品丹药 item
    unit.CommonList = self:SwithPItemI(data.list_three)      --凡品丹药 item
    unit.TempBagList = {}   --临时背包数据
    self:UpdateBestMaterialCount()
    self:UpdateBestTempBag()
end

function M:SwithPItemI(data)
    local list = {}
    for i=1,#data do
        local temp = {}
        temp.ID = data[i].type_id
        temp.Num = data[i].num
        table.insert(list, temp)
    end
    return list
end


--材料背包数据单元
function M:CreateMarterialUnit(data)
    local unit = {}
    unit.ID = data.id
    unit.TypeId = data.type_id
    unit.Num = data.num
    unit.Cost = ItemData[tostring(data.type_id)].uFxArg[1]
    return unit
end






--update
--更新仙品炼丹剩余次数
function M:UpdateBestMaterialCount()
    local typeId = self.mBestAlchemyData.MaterialId
    if not typeId then return end
    local num = PropMgr.TypeIdByNum(typeId)
    self.mBestAlchemyData.MaterialCount = num
    self:UpdateBestAlemyRedPoint()
end

--更新仙品临时仓库
function M:UpdateBestTempBag()
    if not self.mBestAlchemyData.TempBagList then
        self.mBestAlchemyData.TempBagList = {}
    end
    local list = self.mBestAlchemyData.TempBagList
    TableTool.ClearDic(list)
    local dic = PropMgr.tb6Dic
    for k,v in pairs(dic) do
        table.insert(list, v)
    end
    self:UpdateBestAlemyRedPoint()
    self.eUpdateBestTempBag()
end

--更新仙品炼丹红点
function M:UpdateBestAlemyRedPoint()
    local s1 = self.mBestAlchemyData.MaterialCount > 0
    local s2 = #self.mBestAlchemyData.TempBagList > 0
    local state = s1 or s2
    SystemMgr:ChangeActivity(state, ActivityMgr.Alchemy, 1)
    self.eUpdateRedPoint(FestivalActMgr.BestAlchemy, state)
end


--更新凡品炼丹红点
function M:UpdateCommonAlchemyRedPoint()
    local s1 = self:GetCommonAlchemyMaterialStatus()
    local count = self.mCommonAlchemyData.RemainCount
    local s2 = count and count > 0
    local state = self.IsOpenCommonAlchemy and (s1 or s2)
    self.mCommonAlchemyData.RedPointState = state
    SystemMgr:ChangeActivity(state, ActivityMgr.DJ, 13)
    self.eUpdateRedPoint(FestivalActMgr.CommonAlchemy, state)
end

--更新凡品奖励展示
function M:UpdateCommonList()
    local list = self.mCommonAlchemyData.CommonList
    if not list then
        self.mCommonAlchemyData.CommonList = {}
        list = self.mCommonAlchemyData.CommonList
    end  
    TableTool.ClearDic(list)
    local cfg = CommonAlchemyCfg
    for i=1,#cfg do
        local data = cfg[i]
        local temp = {}
        temp.ID = data.ItemId
        temp.Num = data.Num
        table.insert(list, temp)
    end
end


--更新凡品炼丹材料
function M:UpdateCommonMaterials()
    local items =  PropMgr.GetItemsByUseEff(90)   --凡品提交材料 
    local len = #items
    if not self.mCommonAlchemyData.MaterialBagList then
        self.mCommonAlchemyData.MaterialBagList = {}
    end  
    local list = self.mCommonAlchemyData.MaterialBagList
    TableTool.ClearDic(list)
    for i=1,len do
        local unit = self:CreateMarterialUnit(items[i])
        table.insert(list, unit)
    end
    self:UpdateCommonAlchemyRedPoint()
    self:eUpdateCommonMaterialBag()
end

--更新凡品炼丹剩余次数
function M:UpdateCommonTimes(times)
    self.mCommonAlchemyData.RemainCount = times
    self:UpdateCommonAlchemyRedPoint()
end
--更新凡品炼丹当前进度
function M:UpdateCommonProgress(pro)
    self.mCommonAlchemyData.CurProgress = pro
end






--get
--获取仙品炼丹数据
function M:GetBestAlchemyData()
    return self.mBestAlchemyData
end


--获取临时背包数据
function M:GetTempBagData()
    return self.mBestAlchemyData.TempBagList
end

--获取凡品炼丹数据
function M:GetCommonAlchemyData()
    return self.mCommonAlchemyData
end

--获取凡品炼丹剩余次数
function M:GetCommonAlchemyRemainTime()
    return self.mCommonAlchemyData.RemainCount
end

--获取凡品炼丹材料提交进度
function M:GetCommonAlchemyCurProgress()
    return self.mCommonAlchemyData.CurProgress
end

--获取材料背包中的材料是否满足炼丹一次的条件
function M:GetCommonAlchemyMaterialStatus()
    local list = self.mCommonAlchemyData.MaterialBagList
    if not list then return false end
    local total = 0
    for i=1,#list do
        local data = list[i]
        total = total + data.Num * data.Cost
    end
    return total >= self.OnceNeed
end

--获取材料背包数据
function M:GetMaterialBagData()
    local list = self.mCommonAlchemyData.MaterialBagList
    table.sort(list, function(a,b) return self:Sort(a,b) end)
    return list
end

function M:GetCommonRedPointStatus()
    return self.mCommonAlchemyData.RedPointState or false
end


function M:Sort(a,b)
    return a.TypeId > b.TypeId
end


--tool
function M:MsgLog(name, msg)
    -- iTrace.Error(name, tostring(msg))
end


function M:ClearCommonAlchemyData()
    local data = self.mCommonAlchemyData
    data.RemainCount = 0
    data.CurProgress = 0
    data.RedPointState = false
    TableTool.ClearDic(data.CommonList)
    TableTool.ClearDic(data.MaterialBagList)
end

function M:Clear()
    M.IsOpenCommonAlchemy = false
    self:ClearCommonAlchemyData()
    TableTool.ClearDic(self.mBestAlchemyData)
end

return M