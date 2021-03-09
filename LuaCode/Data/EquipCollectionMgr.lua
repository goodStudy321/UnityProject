--[[
z装备收集
]]
EquipCollectionMgr={Name="EquipCollectionMgr"}
local My = EquipCollectionMgr
local GetError = ErrorCodeMgr.GetError

My.eUpInfo=Event()
My.nextId={}
My.infoDic={} --套装ID 套装信息
My.redDic={} --key: id value:bool
My.skillRedDic={} --技能红点
My.eRed=Event()
My.collRed=nil

function My.Init( ... )
    My.AddLnsr()
    EquipMgr.eLoad:Add(My.SetRed)
    OpenMgr.eOpen:Add(My.Open)
end

function My.Open(id)
    if id==20 then 
        My.SetRed()
    end
end

--添加事件
function My.AddLnsr()
    local Add = ProtoLsnr.Add
    Add(27002, My.ResqCollectInfo)
    Add(27004, My.ResqSuitActive)
    Add(27006, My.ResqSkillActive)   
end

--装备收集系统信息推送
function My.ResqCollectInfo(msgs)
    local equip_list = msgs.equip_list
    for i,v in ipairs(equip_list) do
        My.SetInfo(v)
    end
    My.SetRed()
end

--套装激活
function My.ReqSuitActive(id,suit_num,ids)
    local msg = ProtoPool.GetByID(27003)
    msg.id=id
    msg.suit_num=suit_num
    for i,v in ipairs(ids) do
        msg.ids:append(v)
    end
    ProtoMgr.Send(msg)
end

--套装激活返回
function My.ResqSuitActive(msgs)
    local err = msgs.err_code
    if err==0 then
        My.SetInfo(msgs)
        My.SetRed()
        My.eUpInfo(msgs.id,1)
    else
        UITip.Log(GetError(err))
    end
end

--数据解析
function My.SetInfo(msgs)
    local id = msgs.id
    local suit_num = msgs.suit_num or 0
    local ids = msgs.ids
    local is_active = msgs.is_active or false
    local data = My.infoDic[tostring(id)]
    if not data then data={} My.infoDic[tostring(id)]=data end
    data.id=id
    data.suit_num=suit_num
    data.is_active=is_active
    local idss = data.ids
    if not idss then
        idss={}
        data.ids=idss
    end
    if ids then
        for i,v in ipairs(ids) do
            idss[i]=v
        end
    end
end

--激活技能
function My.ReqSkillActive(id)
    local msg = ProtoPool.GetByID(27005)
    msg.id=id
    ProtoMgr.Send(msg)
end

--激活技能返回
function My.ResqSkillActive(msgs)
    local err = msgs.err_code
    if err==0 then
        UITip.Log("成功领取")
        local id = msgs.id
        local data = My.infoDic[tostring(id)]
        data.is_active=true
        My.SetRed()
        My.eUpInfo(id)
    else
        UITip.Log(GetError(err))
    end
end

--==============================--
--desc:私有方法
--time:2019-08-14 11:55:39
--@args:装备收集红点
--@return 
--==============================------------------
function My.SetRed()   
    local isopen = OpenMgr:IsOpen(20)
    if isopen==false then return end
    TableTool.ClearDic(My.redDic)
    TableTool.ClearDic(My.skillRedDic)
    local RED = false
    for k,v in pairs(EquipCollData) do
        local isred = false
        local rank = v.rank
        local star = v.star
        local qua = v.qua
        local numList = v.numList
        local num = My.RankStarQuaGetEquipNum(rank,star,qua)
        local suit_num = 0
        local info = My.infoDic[k]
        if info then suit_num=info.suit_num end
        local nextNum = 0
        local maxSuitNum = numList[#numList]
        local maxNum = v.skillList.id
        if suit_num==maxSuitNum and info.is_active~=true and num==maxNum then
            My.skillRedDic[k]=true
            isred=true
            RED=true
        else
            if suit_num==0 then
                nextNum=numList[1]
            elseif suit_num<numList[#numList]then 
                for i,v in ipairs(numList) do
                    if v==suit_num then nextNum=numList[i+1] break end
                end
            end
            if nextNum>0 then isred=num>=nextNum end
        end  
        My.redDic[k]=isred
        if isred==true then RED=true end
    end
    if RED~=My.collRed then 
        My.collRed=RED 
        local actId=ActivityMgr.LB2
        if My.collRed==true then
            SystemMgr:ShowActivity(actId,6)
        else
            SystemMgr:HideActivity(actId,6)
        end
        My.eRed()
    end
end

function My.RankStarQuaGetEquipNum(rank,star,qua,info)
    local num = 0
    for k,v in pairs(EquipMgr.hasEquipDic) do
        local hasActive = My.IsHasActive(info,tonumber(k))
        if hasActive==true then num=num+1
        else
            local iscan = My.IsCanActive(v,rank,star,qua,info)
            if iscan==true then num=num+1 end
        end
    end
    return num
end

--获取下级激活部位id
function My.GetActiveNextIds(nextNum,id)
    local info = My.infoDic[tostring(id)]
    local nextIds = {}
    if info and info.ids then 
        for i,v in ipairs(info.ids) do
            nextIds[i]=v
        end
    end
    local data = EquipCollData[tostring(id)]
    for i=1,10 do
        local wear = EquipMgr.hasEquipDic[tostring(i)]
        local hasActive = My.IsHasActive(info,i)
        if hasActive~=true then
            local isActive = My.IsCanActive(wear,data.rank,data.star,data.qua)
            if isActive==true then 
                table.insert(nextIds,i)
                if #nextIds==nextNum then return nextIds end
            end
        end
    end
    return nextIds
end

--能否激活
function My.IsCanActive(wear,rank,star,qua)
    local iscan = false
    if not wear then return iscan end
    local id = tostring(wear.type_id)
    local item = UIMisc.FindCreate(id)
    local equip = EquipBaseTemp[id]
    local eRank = equip.wearRank or 0
    local eStar = equip.startLv or 0
    local eQua = item.quality or 0
    if eRank>=tonumber(rank) then
        if (eQua>=tonumber(qua)) or (eQua==tonumber(qua) and eStar>=tonumber(star)) then 
            iscan=true
        end
    end
    return iscan
end

--是否已经被激活
function My.IsHasActive(info,id)
    local ishas = false
    if not info then return ishas end
    if info and info.ids then
        for i,v in ipairs(info.ids) do
            if v==id then ishas=true break end
        end
    end
    return ishas
end

function My.Clear()
    for k,v in pairs(My.infoDic) do
        ListTool.Clear(v.ids)
    end
    TableTool.ClearDic(My.infoDic)
    TableTool.ClearDic(My.skillRedDic)
    TableTool.ClearDic(My.redDic)
end

return My