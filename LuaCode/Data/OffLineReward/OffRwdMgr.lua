--管理类
OffRwdMgr={Name="OffRwdMgr"}
local My = OffRwdMgr
local prv = {} --定义私有
My.UseOver=Event()  --监听事件


My.OffPassTime=0
--初始化
function My:Init( )
  My.firstUIOpen=true
  self.isOpen = false
  self.fiveId, self.twoId = 31010, 31011
  self.SendMsg={}
  prv.AddLsnr()
  local max = prv.GetMaxTime()
  My.MaxTime= max * 60
  My.Lsnr(  )
end

function My.Lsnr(  )
    EventMgr.Add("OfflFTimeChange",My.isShowRed)
    SceneMgr.eChangeEndEvent:Add(My.isShowRed)
end

function My.isShowRed(  )
    if My.UIisOpen() then
        local num = My.GetOffTime()
        if num<12 and My.firstUIOpen then
            -- LvAwardMgr:UpAction(6,true)
        else
            -- LvAwardMgr:UpAction(6,false)
        end
    end
end

--获取现在剩余离线时间单位小时无小数点向下去整
function My.GetOffTime( )
    local time= math.floor(User.MapData.OfflFTime/60/60)
    return time;
end

--获取最大离线时间
function prv.GetMaxTime()
    local cfg = GlobalTemp["87"]
    if cfg == nil then return 0 end
    return cfg.Value3
end
--监听协议
function prv.AddLsnr()
    ProtoLsnr.AddByName("m_offline_reward_toc",prv.LsnrManage)    
end
--移除监听
function prv.ReLsnr()
    ProtoLsnr.RemoveByName("m_offline_reward_toc",prv.LsnrManage)
end
--处理监听
function prv.LsnrManage(msg)
    My.isOpen = true
    My.SendMsg = msg
    My.OffPassTime=msg.offline_min
    prv.Open()
end
--发送表
  function My.GetMsg()
      return My.SendMsg
  end

  function My.GetGoods( )
    local go = {}
    local lst = My.SendMsg.goods
    for i=1,#lst do
        table.insert( go,lst[i] )
    end
    return go
  end
  function My.GetPetGoods( )
    local go = {}
    local lst = My.SendMsg.pet_goods
    for i=1,#lst do
        table.insert( go,lst[i] )
    end
    return go
  end
--打开面板
function prv.Open()
    local OLR = UIOffLineReward
    local UMG = UIMgr
    UMG.Open(OLR.Name)
end
--得到挂机时间返回一个string类型
function My.GetHaveOffLineTime()
    local time = math.floor(User.MapData.OfflFTime/60)
    local str = My.TimeStr(time)
    return str
end
--加挂机时间优先使用5小时,有2-5的判断
function My.Addtime( )
    local fiveId, twoId = My.fiveId,My.twoId
    local tempf =  prv.getInfo(fiveId)
    local tempt =  prv.getInfo(twoId)
    local fiveCrad = ItemTool.GetNum(fiveId)
    local twoCrad = ItemTool.GetNum(twoId)
    local id = 0
    local time = math.floor(User.MapData.OfflFTime/60)
    local b = ((My.MaxTime-time)>tempf) or not(twoCrad>0)
    if fiveCrad>0 and b then
        My.UseOffItem(fiveId) 
    elseif  twoCrad>0  then
        My.UseOffItem(twoId)  
    else
        -- UITip.Error("离线挂机卡不足")
        MsgBox.ShowYesNo("道具数量不足，是否跳转商城？", prv.OnYes,My)
    end
end
--得到剩余可以使用的数量
function My.getCardNum(id)
    local time =My.MaxTime-math.floor(User.MapData.OfflFTime/60)
    local num = 0
    if id==My.fiveId then
        num=time/300
    elseif id==My.twoId then
        num=time/120
    else
        iTrace.Error("soon","传入非离线挂机卡id,id="..id)
    end
    return math.floor(num)
end

--使用离线挂机道具
function My.UseOffItem(id)
    My.useId=id
    local fiveId, twoId = My.fiveId,My.twoId
    if id~=fiveId and id ~=twoId then
        return 
    end
    if  prv.getInfo(fiveId ) == nil and prv.getInfo(twoId ) == nil then
        iTrace.Error("soon", "道具id 31010 或 31011 为空，请检查配置表")
        return 
    end
    local time = math.floor(User.MapData.OfflFTime/60)
    local maxTime = My.MaxTime
    local temp =  prv.getInfo(id)
    local reTime = My.MaxTime - temp 
    if time>=maxTime then 
        UITip.Error("离线挂机时间已达到上限")
        return 
     end
    if time > reTime then
        local str = string.format("挂机时间不可超过%s个小时，\n是否使用？", prv.GetMaxTime())
        MsgBox.ShowYesNo(str, prv.YesCb,My, "确定", prv.NoCb,My, "取消")
        return
    end
    prv.UseItem(id)  
end
--使用道具
function prv.UseItem(id,num)
    if num==nil then
        num=1
    end
    local uid = PropMgr.TypeIdById(id)
    if uid==nil then return end
    PropMgr.ReqUse(uid, num)
    My.UseOver()
    UITip.Log("离线挂机时间增加")    
end

function My.UIisOpen(  )
    local value = GlobalTemp["44"].Value3
    local lv = User.instance.MapData.Level
    return lv >= value
end

function prv.getInfo(id )
    local cfg = ItemData  
    return  cfg[tostring(id)].uFxArg[1]
end
--点击MsgBox的确定按钮
function prv.YesCb()
    prv.UseItem(My.useId)
    return true
end
--点击MsgBox的取消按钮
function prv.NoCb()
    return false
end
--点击MsgBox的确定按钮（跳转到商城）
function prv.OnYes()
    StoreMgr.OpenStoreId(31010)
    -- StoreMgr.OpenStore(5)
end

--分钟转小时方法
function My.TimeStr( time )
    local t = time
    local h = math.modf(t/60);
    local m = t%60
    local st = {}
    if h==0 then
        st[1]=m;st[2]="分钟";
    elseif m==0 then
        st[1]=h;st[2]="小时";
    else
        st[1]=h;st[2]="小时";st[3]=m;st[4]="分钟";
    end
    local str = table.concat(st)
    return str
end
function My:Clear( )
    My.SendMsg=nil
    My.firstUIOpen=true
end
return My