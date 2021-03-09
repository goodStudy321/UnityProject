HeavenLoveMgr={Name="HeavenLoveMgr"}
local My = HeavenLoveMgr
My.redList={true,true,true,true,true,true}

function My.Init( ... )
    SystemMgr:ShowActivity(ActivityMgr.TDQY) --红点
    LoveAtFirstMgr.eRed:Add(My.OnRed)
    MoonLoveMgr.eRed:Add(My.OnRed)
    GoodByeSingleMgr.eRed:Add(My.OnRed)
    HotLoveMgr.eRed:Add(My.OnRed)
end

function My.OnRed(isred,index)
    My.redList[index]=isred
    local isred = false
    for i,v in ipairs(My.redList) do
        if v==true then isred=true break end
    end
    local actId = ActivityMgr.TDQY
    if isred==true then
        SystemMgr:ShowActivity(actId) --红点		
    else
        SystemMgr:HideActivity(actId)
    end
end

function My.OpenUI(tp)
    local isopen = NewActivMgr:ActivIsOpen(2012) or false
    if isopen==false then UITip.Log("活动暂未开启") return end
    UITabMgr.OpenByIdx(UIHeavenLove.Name,tp)
end

function My.Clear()
    My.redList={true,true,true,true,true,true}
end

return My