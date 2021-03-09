TreaFeverMgr = Super:New{Name = "TreaFeverMgr"}
local My = TreaFeverMgr

My.eUpState = Event()
My.eUpdateFeverRewawrd = Event()
My.eRed=Event()
My.isFirstOpen=true
My.FindRed=false
function My:Init()
    My.isFirstOpen=true
    self.curAwardIds = {} --当前中奖ID
    self.isEnterTwo = false

    self.layerStatus = {}

    self.curPoint = 0
    self.allPoint = 0
    --self.mapId = 0
    self.bossId = 0
    self.curPrice = 0
    self.openNum = {}
    self.copyReward= {}
    self.awardList1 = {}  --自选奖池
    self.awardList2 = {}  --稀有奖池
    self.awardList3 = {}  --大奖奖池
    self.awardList4 = {}  --普通奖池

    self.storeList = {} -- 商城列表

    self.eChooseOrNo = Event()
    self.eUpStore = Event()
    self.eHideCell = Event()
    self.eOpenAni = Event()
    self.eUpFeverName = Event()
    self.eUpChooseBtn = Event()
    self.eUpTwoBtnEff = Event()
    self.eBuyBack=Event()--购买成功就会发
    self.OpenState = false

    self:InitNorAward()
    self:SetLsner(ProtoLsnr.Add)
end

function My:InitNorAward()
    for i=1,2 do
        local tempList = {}
        for i=1,25 do
            local temp = {}
            temp.id = i
            temp.value = false
            temp.isAward = false
            temp.type_id = 0
            table.insert(tempList,temp)
        end
        table.insert( self.awardList4,tempList)
    end
end

function My:SetLsner(fun)
    fun(26418,self.ResFeverInfo,self)
    fun(26424,self.RespOpen,self)
    fun(26426,self.RespCopyInfo,self)
    fun(26428,self.RespStoreInfo,self)
    fun(26430,self.RespChoose,self)
end

--==============协议处理================--
-- 神秘宝藏上线推送
function My:ResFeverInfo(msg)
    FestivalActMgr:SetData(msg)

    self.curPrice = msg.gold
    FeverHelp.OnePrice=self.curPrice 
    local price_region = msg.price_region

    local rareAwardList = msg.rare
    local norAwardList = msg.normal
    local rare_choice = msg.rare_choice
    local normal_choice = msg.normal_choice
    local open_id = msg.open_id
    
    self:SetAwardList(rareAwardList,self.awardList2,2,rare_choice)
    self:SetAwardList(norAwardList,self.awardList3,3,normal_choice)

    self:SetChoseData(rare_choice,1)
    for i,v in ipairs(normal_choice) do
        self:SetChoseData(v,1)
    end

    self:SetOpenNum(1,open_id)

    local rareAwardListI = msg.rare_i
    local norAwardListI = msg.normal_i
    local rare_choice_i = msg.rare_choice_i
    local normal_choice_i = msg.normal_choice_i
    local open_id_i = msg.open_id_i

    self:SetAwardList(rareAwardListI,self.awardList2,2,rare_choice_i)
    self:SetAwardList(norAwardListI,self.awardList3,3,normal_choice_i)

    self:SetChoseData(rare_choice_i,2)
    for i,v in ipairs(normal_choice_i) do
        self:SetChoseData(v,2)
    end
    self:SetOpenNum(2,open_id_i)

    self:SetCurKeyNum(price_region)
    local curOpenLayer = msg.open_layer
    self:SetIsEnterTwo(curOpenLayer ~= 1)
    self.OpenState = true
    self:SetLayerStatus()
    My.eUpState(self.OpenState)

    local id = msg.info.icon
    local img = ActIconCfg[id].icon
    self.eUpFeverName(msg.info.icon_name,img)
    self:SetActDes(msg.info)
    self:SetAllRed( )
end

function My:SetAllRed( )
    local red = false
    if My.isFirstOpen then
        red=true
    end
    My.FindRed=false
    local needKey1,haveKey1 = FeverHelp.GetAllPrice(1,1)
    if needKey1~=0 and needKey1<=haveKey1 then
        red=true
        My.FindRed=true
    end
    if self:IsEnterTwo() then
        local needKey2,haveKey2 = FeverHelp.GetAllPrice(1,2)
        if needKey2~=0 and needKey2<=haveKey2 then
            red=true
            My.FindRed=true
        end
    end
    if red then
        SystemMgr:ShowActivity(ActivityMgr.SMBZ)
    else
        SystemMgr:HideActivity(ActivityMgr.SMBZ)
    end
    if My:GetIsChoseRed( 1 ) or My:keyIsRed( 1 ) then
        My.FindRed=true
   end   
    if self:IsEnterTwo() then
        if My:GetIsChoseRed( 2 ) or My:keyIsRed( 2 ) then
             My.FindRed=true
        end   
    end
    My.eRed(My.FindRed)
end

function My:GetIsChoseRed( layer )
    local value = self.layerStatus[layer]
    return not value
end

function My:keyIsRed( layer )
    local Red=false
    local needKey1,haveKey1 = FeverHelp.GetAllPrice(1,1)
    if needKey1~=0 and needKey1<=haveKey1 then
        Red=true
    end
    return Red
end

function My:ReqChoose(list)
    local msg = ProtoPool.GetByID(26429)
    local idlist = msg.list
    for i,v in ipairs(list) do
        idlist:append(v)
    end
    ProtoMgr.Send(msg)
end

function My:RespChoose(msg)
    if msg.err_code == 0 then
        local list = msg.list
        local layer = msg.layer
        self:SetLayerStatus()
        self.eUpChooseBtn(layer)
        UITip.Log("选取成功")
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Error(err)
        return
    end
    self:SetAllRed( )
end

-- 宝藏开箱
function My:ReqOpen(times)
    local msg = ProtoPool.GetByID(26423)
    local layer = FeverHelp.curLayer
    msg.times = times
    msg.layer = layer
    ProtoMgr.Send(msg)
end

-- 宝藏开箱返回
function My:RespOpen(msg)
    if msg.err_code == 0 then
        self.openTimes = msg.times
        local award = msg.reward
        local layer = msg.layer
        self:SetNorItem(layer,award)
        self.curAwardIds[layer] = {}
        local ids = self.curAwardIds[layer]
        for i,v in ipairs(award) do
            table.insert(ids,v.id)
        end
        local curOpenLayer = msg.open_layer
        self:SetIsEnterTwo(curOpenLayer ~= 1)
        if curOpenLayer ~= 1 and layer == 1  then
            self.eUpTwoBtnEff(true)
        end
        local len = #award
        self:SetCurOpenNum(len)
        self:AddOpenNum(layer,len)
        self.eBuyBack()
        self:SetAllRed( )
    else
        local err = ErrorCodeMgr.GetError(msg.err_code)
        UITip.Error(err)
        return
    end
end

-- 副本上线推送
function My:RespCopyInfo(msg)
    FestivalActMgr:SetData(msg)
    self.curPoint = msg.check_point
    self.allPoint = msg.all_check_point
    self.bossId = msg.boss
    local reward = msg.reward
    self.copyReward = {}
    self:SetAward(reward,self.copyReward)
end

--
function My:RespStoreInfo(msg)
    FestivalActMgr:SetData(msg)
    local info = msg.info
    local awardList = info.entry_list
    self:SetStoreList(awardList,self.storeList)
end

--==============数据处理================--
-- 处理珍稀 大奖
function My:SetAwardList(tempList,List,num,choseList)
    local tpList = {}
    for i,v in ipairs(tempList) do
        local temp = {}
        temp.id = v.id
        temp.type_id = v.type_id
        temp.num = v.num
        temp.isBind = v.is_bind
        temp.isEffect = v.special_effect
        temp.type = num
        temp.state = true
        if choseList then
            if (type(choseList) == "table") then
                for i,v1 in ipairs(choseList) do
                    if v1 == v.type_id then
                        temp.state = false
                    end
                end
            else
                if choseList == v.type_id then
                    temp.state = false
                end
            end
        end
        table.insert( tpList, temp )
    end
    table.insert( List,tpList)
end

-- 处理自选奖励
function My:SetChoseData(type_id,layer)
    if type_id == 0 then return end
    --local tempList = {}
    local temp = {}
    if data == nil then end
    temp.type_id = type_id
    temp.type = 1
    if not self.awardList1[layer] then
        self.awardList1[layer] = {}
    end
    table.insert( self.awardList1[layer],temp )
end

-- 处理副本奖励
function My:SetAward(list,List)
    for i,v in ipairs(list) do
        local temp = {}
        temp.k = v.type_id
        temp.v = v.num
        table.insert( List,temp )
    end
    self.eUpdateFeverRewawrd()
end

-- 处理商城奖励
function My:SetStoreList(list,List)
    for i,v in ipairs(list) do
        local temp = {}
        temp.id = v.sort
        local items = v.items
        for i,v1 in ipairs(items) do
            temp.type_id = v1.type_id
            temp.num = v1.num
        end
        local itemData = ItemData[tostring(temp.type_id)]
        local qua = UIMisc.LabColor(itemData.quality)
        temp.name = qua..itemData.name
        temp.type = v.status
        temp.price = v.num
        temp.canBuyNum = v.target
        temp.resBuyNum = v.schedule
        table.insert( List, temp )
    end
end

-- 更新商城道具数量,一次只能减少1和num无关
function My:UpStoreData(id,num)
    local data = nil
    for i,v in ipairs(self.storeList) do
        if id == v.id then
            v.resBuyNum = v.resBuyNum - 1
            data=v
            break;
        end
    end
    self.eUpStore(id,data)
end

function My:AddOpenNum( layer,num )
    local now = self.openNum[layer]
    self.openNum[layer] = now+num
end

function My:SetOpenNum(layer,list)
    local num = 0
    for i,v in ipairs(list) do
        if v.val ~= 0 then
            num = num + 1
            local data = self.awardList4[layer]
            local id = v.id
            data[id].value = v.val~=0
            -- for k,v1 in ipairs(self.awardList1[layer]) do
                -- if v1.type_id == v.val then
                    data[id].isAward = true
                    data[id].type_id = v.val
                -- end
            -- end
        end
    end
    self.openNum[layer] = num
end

function My:SetNorItem(layer,list)
    local data = self.awardList4[layer]
    for i,v in ipairs(list) do
        for k,v1 in ipairs(data) do
            if v1.id == v.id then
                if v.val == 1 then
                    v1.isAward = true
                else
                    v1.isAward = false
                end
                v1.type_id = v.type
                v1.value = true
            end
        end
    end
end

function My:GetResNorAwardNum()
    local num = 0
    local data = self.awardList4[FeverHelp.curLayer]
    for i,v in ipairs(data) do
        if not v.value then
            num = num + 1
        end
    end
    return num
end

-- 一次开箱几次
function My:SetCurOpenNum(num)
    self.curOpenNum = num
end

function My:GetCurOpenNum()
    return self.curOpenNum
end

-- 得到已经打开的普通大奖数量
function My:GetOpenNum()
    return self.openNum
end

function My:SetCurKeyNum(list) 
    local Region = {}
    local len =#list 
    for i=1,len do
        local info = list[i]
        local ls = {}
        ls.start=info.id
        ls.over=info.val
        ls.num=info.type
        Region[i]=ls
    end
    FeverHelp.priceRegion=Region
end

function My:SetCurChoseCell(curCell)
    self.curCell = curCell
end

-- 得到选择cell下标
function My:GetCurChoseCell()
    return self.curCell
end

-- 选择
function My:OnChoose()
    local curLayer = FeverHelp.curLayer
    local data = self.curCell
    local dataList = {}
    local type = data.type
    if type == 2 then
        dataList = self.awardList2[curLayer]
        local num = 0
        for i,v in ipairs(dataList) do
            if not v.state then
                num = num + 1
            end
        end
        if num >= 1 then return end
    elseif type == 3 then
        dataList = self.awardList3[curLayer]
        local num = 0
        for i,v in ipairs(dataList) do
            if not v.state then
                num = num + 1
            end
        end
        if num >= 3 then return end
    end
    self:SetItemState(data,dataList,false)
    if not self.awardList1[curLayer] then
        self.awardList1[curLayer] = {}
    end
    table.insert(self.awardList1[curLayer],data)
    
    self.eChooseOrNo(curLayer)
end

function My:SetActDes(info)
    local des = info.explain
    local cfg = string.gsub(des,'\\n','\n')
    self.actDes = cfg
end

function My:GetActDes()
    return self.actDes
end

-- 取消选择
function My:EseChoose()
    local curLayer = FeverHelp.curLayer
    local data = self.curCell
    local type = data.type
    if type == 2 then
        self:SetItemState(data,self.awardList2[curLayer],true)
    elseif type == 3 then
        self:SetItemState(data,self.awardList3[curLayer],true)
    end
    local list = self.awardList1[curLayer]
    for i=#list,1,-1 do
        if list[i].type_id == data.type_id then
            self.eHideCell(i)
            table.remove( list,i )
        end
    end
    self.eChooseOrNo(curLayer)
end

function My:SetItemState(data,List,state)
    for i,v in ipairs(List) do
        if v.type_id == data.type_id then
            v.state = state
        end
    end
end

-- 判断是否可以开箱
function My:IsCanOpen()
    local max = self.openNum[FeverHelp.curLayer]
    if max>=25 then
        UITip.Error("已经抽完")
        return false
    end
    local value = self.layerStatus[FeverHelp.curLayer]
    if not value then
        UITip.Error("请选取奖励并确定")
        return false
    else
        return true
    end
end

-- 设置是否可以进二层
function My:SetIsEnterTwo(value)
    self.isEnterTwo = value
end

-- 判断是否可以进入二层
function My:IsEnterTwo()
    return self.isEnterTwo
end

-- 自选奖池
function My:GetChoseAward()
    return self.awardList1
end

-- 稀有奖池列表
function My:GetRareAward()
    return self.awardList2
end

-- 大奖奖池
function My:GetBigAward()
    return self.awardList3
end

-- 普通奖池
function My:GetNorAward()
    return self.awardList4
end

-- 奖池花费
function My:GetCurPrice()
    return self.curPrice
end


-- 商城列表
function My:GetStoreAward()
    return self.storeList
end

-- 当前开箱中奖ID
function My:GetCurAwardIds()
    return self.curAwardIds[FeverHelp.curLayer]
end

-- 当前副本关卡
function My:GetCurPoint()
    return self.curPoint
end

-- 副本总关卡
function My:GetAllPoint()
    return self.allPoint
end

-- 地图Id
function My:GetMapId()
    local mapId = 80001+self.curPoint-1
    return mapId
end

-- bossId
function My:GetBossId()
    return self.bossId
end

-- 副本奖励
function My:GetCopyAward()
    return self.copyReward
end

-- 开箱次数
function My:GetTimes()
    return self.openTimes
end

function My:GetCurLayer(  )
   return FeverHelp.curLayer
end

-- 设置是否播放动画
function My:SetIsOn(value)
    self.isOn = value
end

function My:GetIsOn()
    return self.isOn
end

function My:SetLayerStatus()
    for i=1,2 do
        if self.awardList1[i] then
            self.layerStatus[i] = true
        else
            self.layerStatus[i] = false
        end
    end
end

-- 层数选取状态
function My:GetLayerStatus()
    return self.layerStatus
end

function My:Clear()
    My.FindRed=false
    My.isFirstOpen=true
    self.OpenState = false
    My.eUpState(self.OpenState)
    self.curPoint = 0
    self.allPoint = 0
    -- self.mapId = 0 
    self.bossId = 0
    self.curPrice = 0
    self.isEnterTwo = false
    TableTool.ClearDic(self.curAwardIds)
    TableTool.ClearDic(self.openNum)
    TableTool.ClearDic(self.copyReward)
    TableTool.ClearDic(self.awardList1)
    TableTool.ClearDic(self.awardList2)
    TableTool.ClearDic(self.awardList3)
    TableTool.ClearDic(self.awardList4)
    self:InitNorAward()
    TableTool.ClearDic(self.storeList)
end

return My