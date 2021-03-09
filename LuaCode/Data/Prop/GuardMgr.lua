--[[
守护
--]]
GuardMgr={Name="GuardTip"}
local My=GuardMgr
require("UI/Cmn/UseTipHelp")
My.eGuardUp=Event()
My.eOverTime=Event()
My.tb=ObjPool.Get(PropTb)
My.bigTb=ObjPool.Get(PropTb)
My.tb.type_id=0 --守护 右
My.bigTb.type_id=0 --大守护 左
My.tb.endTime=0 --过期时间
My.bigEndTime=0
My.Model=nil

-- My.eOpen=Event() 
local tipName=""
local renewId = nil --续费ID
My.overdueId=nil --过期ID
local ishow1 = true
local ishow2 = true
local isoverTimeTip = false
local isfirst = true
My.isendSprite=false
local modelDic = {}

local timer1=ObjPool.Get(DateTimer)
local timer2=ObjPool.Get(DateTimer)

function My.Init()
    My.AddLnsr()
    GetError = ErrorCodeMgr.GetError
end

function My.AddLnsr()
    local Add = ProtoLsnr.Add
    Add(26070,My.ResqGuard)
    Add(26072,My.ResqOverTime)
    --Add(26020,My.ResqOpenGuard)
    
    EventMgr.Add("SetLocalPendantsShowState",My.SetLocalPendantsShowState)
    EventMgr.Add("InitOwner",My.InitOwner)
    SceneMgr.eChangeEndEvent:Add(My.ChangeEnd)
end

function My.ChangeEnd()
    if SceneMgr.IsInitEnterScene~=true then return end	
    My.CheckOver()
end

function My.InitOwner()
    local model1 = modelDic["1"]
    if LuaTool.IsNull(model1)~=true then  My.SetPos(model1,1) end
    local model2 = modelDic["2"]
    if LuaTool.IsNull(model2)~=true then  My.SetPos(model2,2) end
end

function My.SetLocalPendantsShowState(id,isShow,UID)
    if UID~=User.instance.MapData.UID then return end
    My.InitOwner(isShow)
end

------------协议
--角色守护信息
function My.ResqGuard(msg)
    local guard = msg.guard
    local bigGuard=msg.big_guard
    local endTime=msg.end_time
    local bigEndTime=msg.big_end_time
    
    local auto = true
    if guard==0 and bigGuard<=0 then 
        auto=false
    end
    User.instance.MapData.IsAutoPick=auto 

    if My.tb.type_id==0 and guard>0 then ishow1=true end
    if My.bigTb.type_id<=0 and bigGuard>0 then ishow2=true end

    My.tb.type_id=guard
    My.tb.startTime=0
    My.tb.endTime=endTime

    My.bigTb.type_id=bigGuard
    My.bigTb.startTime=0
    My.bigTb.endTime=bigEndTime

    My.GuardUp()
    My.CountTime(1)
    My.CountTime(2)

    My.SetAutoPick()
  
    My.eGuardUp()

    if My.tb.type_id==0 and My.bigTb.type_id<=0 then 
        User.instance.MapData.IsAutoPick=false
    end
end

--上线后端没有推过期提示则自己检测 
function My.CheckOver()
    if User.instance.SceneId==20001 then return end
    if isfirst==false then return end
    isfirst=false
    if isoverTimeTip==true then return end
    if My.tb.type_id~=0 and My.bigTb.type_id>0 then return end
    local openList=QuickUseMgr.openList2
    local isover = My.GetOverTimeId(40001)
    local overid = nil
    if isover==false then 
        isover=My.GetOverTimeId(40003)
        if isover==true then 
            overid=40001
        else
            isover = My.GetOverTimeId(40002)
            if isover==true then 
                overid=40002
            end
        end
    else
        overid=40001
    end

    if overid then 
        openList[#openList+1]=overid 
        My.isendSprite=true
    end
    if QuickUseMgr.isBegin==true and isover==true then
        My.GetOverTimeUse(overid)
    end
    if My.isendSprite~=true then QuickUseMgr.eEndSprite() end
end

--过期提示
function My.GetOverTimeUse(overid)
    local openList = QuickUseMgr.openList2
    table.remove(openList, 1)
    local item=ItemData[tostring(overid)]
    if not item then iTrace.eError("xiaoyu","道具表为空 type_id: "..tostring(overid))return end
    local tipName=item.name.."已过期"
    local des="剩余0小时"    
    QuickUseMgr.OpenQuickUse(overid,1,nil,30,"查看",tipName,des,false) 
end

--快过期提示
function My.GetTimeUse(tb)
    local openList = QuickUseMgr.openList2
    table.remove(openList, 1)

    local id = tb.type_id
    if id==40003 then id=40001 end
    
    local item=ItemData[tostring(id)]
    local tipName=item.name.."即将过期"
    local des=My.ShowTimeTip(tb)
    QuickUseMgr.OpenQuickUse(id,1,nil,30,"查看",tipName,des,false)
end

function My.SetAutoPick()
    local autopick,dec=nil
    if My.tb.type_id~=0 then 
        dec=Decoration[tostring(My.tb.type_id)]
        if not dec then iTrace.eError("xioayu","饰品表为空 id： "..My.tb.type_id)return end
        autopick= dec.autopick
    end
    if autopick~=1 then 
        if My.bigTb.type_id>0 then 
            dec=Decoration[tostring(My.bigTb.type_id)] 
            if not dec then iTrace.eError("xioayu","饰品表为空 id： "..My.bigTb.type_id)return end
            autopick=dec.autopick
        end
    end
    User.instance.MapData.IsAutoPick=(autopick==1)
end

function My.CountTime(tp)
    local timer,endTime = nil
    if tp==1 then
        timer=timer1
        endTime=My.tb.endTime
    elseif tp==2 then
        timer=timer2
        endTime=My.bigTb.endTime
    end
    timer:Stop()
    local now=TimeTool.GetServerTimeNow()*0.001
    local lerp=endTime-now
    if lerp<=0 then 
    else		
        timer.seconds=lerp   
        timer:Start()
    end
end

function My.Complete()
    guardState1=0
    My.tb.type_id=0
    My.tb.endTime=0

    if My.tb.type_id==0 and My.bigTb.type_id<=0 then 
        User.instance.MapData.IsAutoPick=false
    end
end

function My.BigComplete()
    guardState2=0
    My.bigTb.type_id=0
    My.bigTb.endTime=0

    if My.tb.type_id==0 and My.bigTb.type_id<=0 then 
        User.instance.MapData.IsAutoPick=false
    end
end

--续费界面
function My.Renewal(overdueId)
    if overdueId then My.overdueId=overdueId end
    UIMgr.Open(UIElfRenewal.Name,My.RenewalCb)
end

function My.RenewalCb(name)
    local ui = UIMgr.Get(name)
    if ui then 
        ui:UpData(My.overdueId)
    end
end

--角色守护过期
function My.ResqOverTime(msg)
    local openList=QuickUseMgr.openList2
    local tp = msg.type  
    local remind = msg.remind
    local overtime = msg.overtime
    if tp ==1 then
        if remind==true then 
            local id=My.tb.type_id 
            openList[#openList+1]=id
            My.isendSprite=true
            local item = ItemData[tostring(id)]
            local des = nil
            if overtime==true then 
                if QuickUseMgr.isBegin==true then My.GetOverTimeUse(id) end
            else 
                if QuickUseMgr.isBegin==true then My.GetOverTimeUse(My.tb) end
            end           
        end
        if overtime==true then My.Complete() end
    elseif tp==2 then       
        if remind==true then 
            local id=My.bigTb.type_id 
            openList[#openList+1]=id
            My.isendSprite=true
            local item = ItemData[tostring(id)]
            local des = nil
            if overtime==true then
                if QuickUseMgr.isBegin==true then My.isendSprite=My.GetOverTimeUse(id) end           
            else 
                if QuickUseMgr.isBegin==true then My.isendSprite=My.GetOverTimeUse(My.bigTb) end
            end           
        end
        if overtime==true then My.BigComplete() end
    end 
    if overtime==true then My.eOverTime(tp) end
    isoverTimeTip = true
    if My.isendSprite~=true then QuickUseMgr.eEndSprite() end

    My.GuardUp()
end

function My.ShowTimeTip(tb)
    local endTime=tb.endTime 
    local now = TimeTool.GetServerTimeNow()*0.001
    local lerp=endTime-now
    local day,hour = math.modf(lerp/24/3600)
    local hh=math.ceil(hour*24)
    return "剩余"..hh.."小时"
end

-- --开启守护
-- function My.ReqOpenGuard()
--     local msg = ProtoPool.GetByID(26019)
-- 	ProtoMgr.Send(msg)
-- end

-- function My.ResqOpenGuard(msg)
--     local err = msg.err_code
-- 	if err==0 then
--         UITip.Log("开启成功")
--         My.bigTb.type_id=0
--         My.eOpen()       
-- 	else
-- 		UITip.Log(GetError(err))
-- 	end
-- end

-----------方法

function My.GuardUp()
    local id1=My.tb.type_id
    local id2=My.bigTb.type_id
    if id1>0 then My.LoadGuard(id1,1) else  My.CleanModel(1) end
	if id2>0 then My.LoadGuard(id2,2) else  My.CleanModel(2) end
end

function My.LoadGuard(id,index)
    local dec=Decoration[tostring(id)]
	if not dec then iTrace.eError("xiaoyu","饰品表为空 id: "..tostring(id))return end
    local name = dec.model

    local old = modelDic[tostring(index)]
    local oldName = old~=nil and old.name or nil
    if oldName==name then return 
    else
        My.CleanModel(index)
        local del = ObjPool.Get(DelGbj)
	    del:Adds(index,dec.scale)
        del:SetFunc(My.LoadCb)
        LoadPrefab(name,GbjHandler(del.Execute,del))
    end
    
end

function My.LoadCb(go,index,scale)   
    if LuaTool.IsNull(go) then return end
    LayerTool.Set(go.transform, 12)

    local uf = go:AddComponent(typeof(UnitFollow))
    if index==1 then
        uf.mDeltaY=2
        uf.mFollowDistance=2
        uf.mFollowDistanceSqr=4
        uf.mMoveToDistanceSqr=2
    else
        uf.mDeltaY=2
        uf.mFollowDistance=3
        uf.mFollowDistanceSqr=9
        uf.mMoveToDistanceSqr=3
    end
    scale=scale and scale or 1
    go.transform.localScale = Vector3.one*scale
    My.SetPos(go,index,scale)
    AssetMgr:SetPersist(go.name,".prefab",true)
    GameObject.DontDestroyOnLoad(go)
    modelDic[tostring(index)]=go
    --uf:UpdateTitle(temp.name)
end

function My.SetPos(go,index,scale)
    local trans = go.transform
    local target = User.Pos
    trans.eulerAngles = Vector3.zero
    local deltaX = index==1 and 0 or 1
    trans.position = Vector3.New(target.x-deltaX, target.y ,target.z+2)
end

function My.CleanModel(index)   
    local model = modelDic[tostring(index)]
    if not model then return end
    local name = model.name..".prefab"
    GameObject.Destroy(model) 
    AssetMgr:Unload(name,false)
    modelDic[tostring(index)]=nil
end


function My.GetGuardState()
    local id = nil
    local str = nil
    local over = true
    local id1 = My.tb.type_id
    local id2 = My.bigTb.type_id
    local girlId=40002
    if id1==girlId or id2==girlId then return end
    local tb = PropMgr.typeIdDic[tostring(girlId)]
    if tb then 
        for k,v in ipairs(tb) do
            local tb = PropMgr.tbDic[tostring(v)]
            local startTime = tb.startTime
            local endTime = tb.endTime
            if startTime==endTime then over=false break end
            local now=TimeTool.GetServerTimeNow()*0.001
            local lerp = endTime-now
            if lerp>0 then over=false break end
        end
        if over==true then --背包有仙女过期了
            id=1
            str="已过期"
        else --背包有仙女未过期
            id=2
            str="未穿戴"
        end
    else --没有穿小仙女，背包也没有，则提示购买
        id=3
        str="购买"
    end
    return id, str
end

--==============================--
--desc:
--time:2019-06-11 09:51:50
--@return id 0:啥都不提示  1：小仙女   2：小精灵
--==============================--
function My.GetGuardS()
    local id1 = My.tb.type_id
    local id2 = My.bigTb.type_id
    local id = nil
    if id1>0 then
        id=id2>0 and 0 or 1
    else
        id=2
    end
    return id
end

--获取道具在背包是否过期
function My.GetOverTimeId(type_id)
    local isover = false
    local tb = PropMgr.typeIdDic[tostring(type_id)]
    if tb then 
        for k,v in ipairs(tb) do
            local tb = PropMgr.tbDic[tostring(v)]
            local startTime = tb.startTime
            local endTime = tb.endTime
            if startTime==endTime then over=false break end
            local now=TimeTool.GetServerTimeNow()*0.001
            local lerp = endTime-now
            if lerp<0 then isover=true break end
        end
    end
    return isover
end

function My.Clear()
    isfirst=true
    isoverTimeTip = false
	My.tb.type_id=0
    My.tb.endTime=0	
    My.CleanModel()
    guardState1=-1
    guardState2=-1
    My.isendSprite=false
end

function My.Dispose()
	
end

return My