SuitMgr = {Name = "SuitMgr"}
local My = SuitMgr
My.suitList={} --先分类型 后分转生 再分部位
My.suitAttList={} --套装属性表
My.suitInfo={} --套装信息
-- My.redList={} --红点列表
My.eSuit=Event()
My.eRed=Event()
My.partList={"手镯","戒指","项链","护符","武器","头盔","衣服","护腕","裤子","鞋子"}
local redList = {}
local commonRankList = {}
My.rankRed1 = {}
My.rankRed2 = {}

function My.Init()
    My.SortTb()
    GetError = ErrorCodeMgr.GetError
    My.AddLnsr()
end

function My.AddLnsr()
    local Add = ProtoLsnr.Add
    Add(28100,My.ResqRoleSuit)
    Add(28102,My.ResqUpgradeStar)
    Add(28104,My.ResqResolve)


    PropMgr.eUpdate:Add(My.CompareFightRed)
    --OpenMgr.eOpenNow:Add(My.OnOpenNow)
    OpenMgr.eOpen:Add(My.OnOpen)
end

--==============================--
--desc: 协议
--time:2019-05-10 07:51:29
--@return 
--==============================------------------
function My.ResqRoleSuit(msgs)
     --套装信息
     for i1,v1 in ipairs(My.suitList) do
        for i2,v2 in ipairs(v1) do
            My.SetSuitInfo(i1,i2,v2[1])
        end
    end
    
    local list = msgs.suit_info
    for i,v in ipairs(list) do
        local bType = v.type
        local sType=v.subtype
        local partList = v.place
        My.AnalysisMethod(bType,partList)
    end

    My.CompareFightRed()
end

function My.AnalysisMethod(bType,partList)
    local pList = My.suitInfo[bType]
    for i,v in ipairs(partList) do
        local id=tostring(v)
        local data = SuitStarData[id]
        local part = data.part
        pList[part]=id
    end
end

--升阶
function My.ReqUpgradeStar(id)
    local msg = ProtoPool.GetByID(28101)
	msg.place_id=id
	ProtoMgr.Send(msg)
end

--升阶返回
function My.ResqUpgradeStar(msgs)
    local err = msgs.err_code
    if err==0 then
        local partId = tostring(msgs.place_id)
        local data=SuitStarData[partId]
        local part=data.part
        local bType = data.bType
        local list=My.suitInfo[bType]
        list[part]=partId
        My.CompareFightRed()
        My.eSuit(bType,part,partId)
        local text = data.rank==1 and "激活成功" or "升阶成功"
        UITip.Log(text)
    else
        UITip.Log(GetError(err))
    end
end

function My.ReqResolve(id)
    local msg = ProtoPool.GetByID(28103)
	msg.place_id=id
	ProtoMgr.Send(msg)
end

function My.ResqResolve(msgs)
    local err = msgs.err_code
    if err==0 then
        local partId = tostring(msgs.place_id)
        local data=SuitStarData[partId]
        local part=data.part
        local bType = data.bType
        local list=My.suitInfo[bType]
        local zeroId = My.SetZeroRankPart(bType,part)
        list[part]=zeroId
        My.CompareFightRed()
        My.eSuit(bType,part,zeroId)

        UITip.Log("分解成功")
    else
        UITip.Log(GetError(err))
    end
end

--==============================--
--desc:  私有方法
--time:2019-05-10 07:51:55
--@return 
--==============================--

function My.SetZeroRankPart(bType,part)
    local list = My.suitList[bType]
    local partList = list[part]
    local partId = partList[1]
    return partId
end

function My.SortTb()
    --套装升星表
    for k,v in pairs(SuitStarData) do
        local bType = v.bType
        local part=v.part
        local rank=v.rank
        local bList=My.suitList[bType]
        if not bList then bList={} My.suitList[bType]=bList end
        local typeList = bList[part]
        if not typeList then typeList={} bList[part]=typeList end
        typeList[#typeList+1]=k
    end
    for i1,v1 in ipairs(My.suitList) do
        for i2,v2 in ipairs(v1) do
            table.sort(v2, My.SortRank)
        end
    end

    --套装属性表
    for k,v in pairs(SuitAttData) do
        local bType = v.bType
        local bTypeList = My.suitAttList[bType]
        if not bTypeList then bTypeList={} My.suitAttList[bType]=bTypeList end
        local sType = v.sType
        local sTypeList = bTypeList[sType]
        if not sTypeList then sTypeList={} bTypeList[sType]=sTypeList end
        sTypeList[#sTypeList+1]=k
    end
    for i1,v1 in ipairs(My.suitAttList) do
        for i2,v2 in ipairs(v1) do
            table.sort(v2, My.SortAttRank)
        end
    end
end

function My.SetSuitInfo(bType,part,partId)
    local list=My.suitInfo[bType]
    if not list then list={} My.suitInfo[bType]=list end
    list[part]=partId
end

function My.SortRank(a,b)
    local data1 = SuitStarData[a]
    local data2 = SuitStarData[b]
    return data1.rank<data2.rank
end

function My.SortAttRank(a,b)
    local data1 = SuitAttData[a]
    local data2 = SuitAttData[b]
    return data1.rank<data2.rank
end

function My.SortAttRbLv(a,b)
    local data1 = SuitAttData[a]
    local data2 = SuitAttData[b]
    return data1.sType<data2.sType
end

function My.SortPart(a,b)
    local data1 = SuitStarData[a]
    local data2 = SuitStarData[b]
    return data1.part<data2.part
end

local tpp = nil
function My.OpenSuit(tp)
    tpp=tp
    UIMgr.Open(UISuit.Name,My.SuitCb)
end

function My.SuitCb(name)
    local ui = UIMgr.Get(name)
    if ui then
        ui:SwitchTg(tpp)
    end
end

function My.OnOpenNow(isUpdate, list)
    if isUpdate~=0 then return end
    My.CompareFightRed()
end

function My.OnOpen(id)
    if id ~=701 then return end
    My.CompareFightRed()
end

function My.CompareFightRed()
    if OpenMgr:IsOpen(701)==false then return end
    for i,info in ipairs(My.suitInfo) do
        local isopen = OpenMgr:IsOpen(701)
        if isopen==true and i==2 then
            local global = GlobalTemp["134"]
            local lv = global.Value2[1]
            if User.instance.MapData.Level<lv then isopen=false end
        end
        if isopen==true then 
            local rankRed = i==1 and My.rankRed1 or My.rankRed2
            TableTool.ClearDic(rankRed)
            My.GetStpRed(info,1,rankRed)
            My.GetStpRed(info,2,rankRed)
        end
    end

    local tog1=My.rankRed1["0"]
    My.rankRed1["0"]=tog1
    local tog2=My.rankRed2["0"]
    My.rankRed2["0"]=tog2
    local actId = ActivityMgr.LB1
    if tog1==true or tog2==true then 
        SystemMgr:ShowActivity(actId)
    else
        SystemMgr:HideActivity(actId)
    end


    -- for k,v in pairs(My.rankRed1) do
    --     iTrace.eError("xioayu111111111","  k: "..k.."  v: "..tostring(v))
    -- end
    -- for k,v in pairs(My.rankRed2) do
    --     iTrace.eError("xioayu22222222","  k: "..k.."  v: "..tostring(v))
    -- end
    My.eRed()
end

function My.GetStpRed(dic,sTp,rankRed)
    local statrIndex = 1
    local endIndex = 5
    if sTp==2 then statrIndex=6 endIndex=10 end
 
    ListTool.Clear(redList)
 
    for i=statrIndex,endIndex do
        local partid = dic[i]
        table.insert( redList, partid)
        table.sort( redList, My.SortRed )
    end
    for i1,v in ipairs(redList) do  
        ListTool.Clear(commonRankList) 
        local isred = false
        local data = SuitStarData[v]
        local suit = SuitAttData[tostring(data.suitId)]
        local nextData = SuitStarData[tostring(data.nextId)]
        if nextData then
            local rank = data.rank
            local sTp = data.sType
            --下阶-当前
            local has = PropMgr.TypeIdByNum(nextData.needList[1])
            local lp = nextData.needList[2]-data.needList[2]
            local need=lp>0 and lp or nextData.needList[2]
            local lerp = has-need
            if lerp>=0 then     
                table.insert(commonRankList, v)   
                --够再看其他同阶的
                local nextIndex = i1+1
                for j=nextIndex,#redList do
                    local common = SuitStarData[redList[j]]
                    if common.rank==rank then 
                        local nextCommon = SuitStarData[tostring(common.nextId)]
                        local cd = nextCommon.needList[2]-common.needList[2]
                        local commonNeed = cd>0 and cd or nextCommon.needList[2]
                        local nowlerp=lerp-commonNeed
                        if nowlerp>=0 then lerp=nowlerp  table.insert(commonRankList, redList[j]) end
                    end
                end
                if #commonRankList==1 and rank~=0 then--没有同阶的看下一阶的
                    for j=nextIndex,#redList do
                        local common = SuitStarData[redList[j]]
                        if common.rank==rank+1 then 
                            table.insert(commonRankList, redList[j])
                        end
                    end
                end
                
                local attList = suit.attList
                local curNum = attList==nil and #commonRankList or 0
                if attList then 
                    for i3,kv in ipairs(attList) do
                        local num = kv.num
                        if #commonRankList>=num then curNum=num end
                    end
                end
                if curNum>0 then
                    for i4=1,curNum do
                        isred=true
                        local curData = SuitStarData[commonRankList[i4]]
                        local state = curData.rank==rank and true or false
                        rankRed[tostring(curData.part)]=state
                    end
                    -- for i=curNum+1,#commonRankList do
                    --     local curData = SuitStarData[commonRankList[i4]]
                    --     rankRed[tostring(curData.part)]=false
                    -- end
                    rankRed["0"]=isred
                    if isred==true then break end    
                end                        
            end
        end
    end
end

function My.SortRed(a,b)
    local data1 = SuitStarData[a]
    local data2 = SuitStarData[b]
    if data1.rank==data2.rank then
        if data1.nextId==0 and data2.nextId==0 then 
            return false
        elseif data1.nextId==0 then
            return false
        elseif data2.nextId==0 then
            return true
        end
        local nextdata1 = SuitStarData[tostring(data1.nextId)]
        local nextdata2 = SuitStarData[tostring(data2.nextId)]
        local need1 = nextdata1.needList[2]-data1.needList[2]
        local need2 = nextdata2.needList[2]-data2.needList[2]
        if need1==need2 then
            return data1.part<data2.part
        else
            return need1<need2
        end
    else
        return data1.rank<data2.rank
    end
end

function My.Dispose()
    -- body
end


function My.Clear()
    for i,v in ipairs(My.suitInfo) do
        ListTool.Clear(v)
    end
    ListTool.Clear(My.suitInfo)
    ListTool.Clear(redList)
    TableTool.ClearDic(My.rankRed1)
    TableTool.ClearDic(My.rankRed2)
end

return My