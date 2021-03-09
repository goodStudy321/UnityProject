ReviveMgr={Name="ReviveMgr"}
local My = ReviveMgr;

--选择复活类型
My.reviveType=1;
----是否强制限制不允许关闭和打开其他面板
My.CanNotClose=false;
--秒数事件
My.eSecond=Event();
--击败玩家
My.killerName=nil;
My.isHangUp=false;
function My:Init( )
    EventMgr.Add("RefreshReviveData", My.RefreshReviveData);
    EventMgr.Add("ReLife", My.ReLife);
    -- EventMgr.Add("UnitRevive", My.ReLife);
    EventMgr.Add("OnChangeScene", My.ReLife);
    My.isHangUp=false
end

function My.SetUIMgr(  )
    UIMgr.SetCanClose(My.CanNotClose);
end

function My.RefreshReviveData(killerName, reviveTime, freeReviveTime)
    My.CanNotClose=true;    
    My.reLife=false
    My.killerName=killerName;
    local nowTime =  TimeTool.GetServerTimeNow() / 1000; 
    reviveTime =  math.ceil(reviveTime -nowTime)
    My.freeReviveTime=freeReviveTime
    local senceId =tostring(User.instance.SceneId)
	local senceInfo = SceneTemp[senceId]
    local reviveType = senceInfo.reviveType;
    if reviveType==nil or reviveType==0 then
        reviveType=1;
        iTrace.Error("特殊处理,检查场景置表id="..senceId); 
    end
    My.reviveTime=reviveTime<=0 and senceInfo.reviveTime or reviveTime;
    My.reviveType=reviveType;
    if reviveType==5 then
        My.toSend(0)
        My.hangUp(2);
        return;
    end
    UIMgr.Open(UIRevive.Name,My.OpenBack);
end

function My.OpenBack(  )
    My.TimeStart(My.reviveTime)
    UIRevive:Choose( )
    My.SetUIMgr(  )
end

function My.TimeStart( reviveTime)
    My.timer = ObjPool.Get(iTimer);    
    My.timer.invlCb:Add(My.Tick);
    My.timer.complete:Add(My.TimeDone);
    if My.timer.running == true then
        return;
    end
    My.timer.seconds = reviveTime;
    My.timer.cnt =0;
    My.timer.ignoreScale = true
    My.timer:Start();
end

--间隔计时
function My.Tick()
    local time = My.timer:GetRestTime();
    time= math.round(time)
    My.eSecond(time);
    
end

--复活倒计时完成
function My.TimeDone()
    My.eSecond(-1);
    if My.reLife==false then
        My.timer.seconds = 1;
        My.timer:Start();
    end
end

function My.toSend(num )
    NetRevive.RequestRoleRevive(num);
end

function My.hangUp(num )
	local b = false;
	if num==1 then
		b=true;
	elseif num==2 then
		local id= tostring(User.instance.SceneId)
		if SceneTemp[id].relifeHungUp==1 then
			b=true;
		end
	end
    My.isHangUp=b
end

--复活
function My.ReLife( )
    if My.CanNotClose==false then   return;  end
    My.reLife=true
    My:Clear()
    My.SetUIMgr( )
    UIMgr.Close(UIRevive.Name)
    Hangup:SetSituFight(My.isHangUp);
    UIMainMenu:SetAutoFight(My.isHangUp);
    My.isHangUp=false
end

function My:Clear( )
    My.CanNotClose=false;
    if  My.timer then
        My.timer.cnt =0;
        My.timer:AutoToPool();
        My.timer = nil
    end
end

function My.ComPlet( ... )
    -- body
end

function My.GetReviveCost()
	local sceneId = tostring(User.instance.SceneId);
	if sceneId == "0" then
		return 0;
	end
	if SceneTemp[sceneId] == nil then
		return 0;
	end
	return SceneTemp[sceneId].costcoin;
end


return My;