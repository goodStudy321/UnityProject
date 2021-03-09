FeverCircle={Name="FeverCircle"}
local My = FeverCircle

--是否在播放
My.isOn=false
--是否不去播放
My.notToPlay=false;
--时间
My.AllTime=100;
--开始
My.StartCell={0,0};
My.startIndex = 1
My.timer=nil;
--执行几个
My.running=0
My.runRcd=1
My.rwdls=nil

function My.InitTime(  )
    if  My.timer ~=nil then
        return;
    end
    My.timer = ObjPool.Get(iTimer);    
    My.timer.invlCb:Add(My.NextCell);
    My.timer.complete:Add(My.ShowAll);
end

function My.DoAnim(timce,rwdls)
    My.isOn=true
    if not My.notToPlay then
        My.timce=timce
        My.running=0
        My.runRcd=1
        My.rwdls=rwdls
        local endId= rwdls[My.runRcd]
        if endId==nil then
            iTrace.eError("soon","无内容第"..My.runRcd.."个奖励")
            My.Over( )
            return
        end
        My.TimeStart(endId  )
    else
        My.Over( )
    end
end

function My.TimeStart( endId )
    My.InitTime()
    My.startIndex = My.StartCell[FeverHelp.curLayer]
    My.AllNUm=50-My.startIndex + endId    
    My.NextCell(  )
    My.timer:Start(My.AllTime, interval)
end

function My.GetBackTime(  )
    if My.running<9 then
        return 0.45-0.05* My.running
    elseif My.running+5 < My.AllNUm then
        return 0.04
    else
        return 0.04+0.08*(My.AllNUm - My.running)
    end
end

function My.NextCell(  )
    My.timer.cnt = 0
    My.running=My.running+1
    FeverFindView:selctCb()
    if My.notToPlay then
        My.Over( )
        return
    end
    if My.running>=My.AllNUm then
        My.TimeDone(  )
        return
    end
    My.timer.interval=My.GetBackTime( )
end

function My.TimeDone(  )
    My.running=0
    My.timer:Stop()
    My.timer:Reset()
    FeverFindView:onceOpen( )
    My.NextStart( )
end

function My.NextStart(  )
    My.runRcd=My.runRcd+1
    if My.runRcd> My.timce then
        My.Over( )
        return
    end
    My.TimeStart(My.rwdls[My.runRcd])
end

function My.Over( )
    My.startIndex = 0
    My.running=0
    if My.isOn then
        My.isOn=false
        My.rwdls=nil
        if My.timer then
            My.timer:Stop()
            My.timer:Reset()
            My.timer:Start(0.5, 10)
        else
            My.ShowAll(  )
        end
    end
end

function My.ShowAll(  )
    FeverFindView:ShowAll()
end

function My.Clear( )
    My.startIndex = 0
    My.running=0
    My.isOn=false
    My.rwdls=nil
    if  My.timer then
        My.timer:AutoToPool();
        My.timer = nil
    end
end

return My;