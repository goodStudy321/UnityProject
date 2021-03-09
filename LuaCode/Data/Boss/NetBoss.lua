require("Data/Boss/MapBossInfo")
NetBoss = { Name = "NetBoss" }
local My = NetBoss

My.eUpTieTime = Event();
My.eUpBInfo = Event();
My.eUpBRcd = Event();
My.eUpnormalBRcd=Event()
My.QuitTime = nil;
My.ResetTime = 0;
My.eUpMBInfos = Event();
My.eUpMBInfo = Event();
My.eReChgTime = Event();
My.eRank = Event();
My.eIsland=Event();
My.redLst={}
My.eBossRed=Event();
-- My.eIslandInfo=Event();
My.eKillRcd=Event();  --击败记录返回更新
My.eUseAddIsl=Event();--道具使用
My.eCollect=Event();--采集次数更新
My.eCaveTimes=Event();--洞天疲劳更新
My.eMerge=Event();
--场景Boss信息类表
My.MapBossInfos = {};
--场景小怪信息类表
My.MapMsInfos = {};
My.what3Boss={}
--隐藏boss数量
My.BossNum=0;
--世界boss剩余挑战值
My.WorldTimes = 0;
--世界boss恢复时间
My.resumeTime = 0;
--世界boss恢复次数
My.resumeTimes = 0;
--世界boss购买次数
My.WldBuyTimes = 0 ;
--洞天福地疲劳次数
My.CaveTimes=0
--洞天援助剩余次数
My.CaveAssistTimes=0
--当前层人数
My.CurLayerRole = 0 ;
--刷新bossID
My.CareId=0;
--关注boss列表
My.careLst={};
--关注的boss刷新id
My.CareRelife=0
My.CareCanClose=true
--当前服务器发的boss列表
My.BossLst={};
--排行字典
My.ranklst={};
--神兽岛疲劳
My.islTimes=0;
--物品增加神兽岛疲劳次数
My.islAddTimes=0;
--龙灵水晶次数
My.collectTimes=0;
--凤血次数更新
My.collect2Times=0;
--神兽岛击败记录
My.islKillLst={};

--采集物剩余数量
My.collectNum=0;
My.monsterNum=0;--怪物
--采集时间
My.curColTime=0;
--最大等级击败
My.worlMaxKill=0;
--场景进入次数
My.enterLst={};
--世界boss指引状态,0没打1打一次2打完
My.isGuide  =2;
My.eBossBlood=Event()
--打开集合
My.OpenLst={};
--boss关注是否打开
My.careType = 1;

--合并几次
My.merge_times=0;

function My:Init()
  self:AddLsnr();
  My.OnceOpen=true
end

function My:AddLsnr()
  local PA =  ProtoLsnr.AddByName;
  PA("m_cave_times_update_toc",self.reCaveTime,self)
  PA("m_world_boss_info_toc", self.RespUpBInfo, self);
  PA("m_world_boss_times_toc", self.RespTieTime, self);
  PA("m_world_boss_quit_time_toc", self.RespWBQuitTime, self);
  PA("m_world_boss_log_toc", self.RespWBLog, self);
  PA("m_world_boss_map_info_toc", self.RespMapBInfo, self);
  PA("m_world_boss_map_update_toc", self.RespMapBInfUp, self);
  PA("m_world_boss_care_info_toc", self.CareLst, self);
  PA("m_world_boss_care_toc", self.careToc, self);
  PA("m_world_boss_care_notice_toc", self.CareRelf, self);
  PA("m_world_boss_rank_toc", self.reRank, self);
  PA("m_mythical_boss_times_toc", self.reIsland, self);
  PA("m_world_boss_kill_toc", self.reIslKillTos, self);
  PA("m_world_boss_seek_help_toc", self.reHelpofter, self);
  PA("m_mythical_times_update_toc",self.UpTimesAddIsl,self);
  PA("m_mythical_collect_times_toc",self.UpColect1,self);
  PA("m_mythical_collect2_times_toc",self.UpColect2,self);
  PA("m_world_boss_all_toc",self.AllGet,self);
  PA("m_world_boss_buy_times_toc",self.ReBossBuy,self);
  -- PA("m_world_boss_max_kill_toc",self.maxKill,self);
  PA("m_map_enter_times_toc",self.mapEntr,self);
  PA("m_world_boss_guide_toc",self.ReIsGuide,self);
  PA("m_world_boss_first_kill_toc",self.PleaseGoOut,self);
  PA("m_world_boss_merge_times_toc",self.MegChange,self);
  UICollection.eInCollect:Add(self.reColTime,self);
  CollectMgr.einterupt:Add(self.stopcol,self);
  -- OpenMgr.eOpen:Add(My.WorldBossRed)
  OpenMgr.eOpenNow:Add(My.BossOpenSet)
  UIOperationTip.eClose:Add(My.BossOpen)
  ActivStateMgr.eUpActivState:Add(My.doubleOpen)
  EventMgr.Add("OnChangeScene", My.changesence)
  EventMgr.Add("BossBlood", My.BossBlood)
  ActivStateMgr.eUpActivState:Add(self.BossOpen,self);
end

--双倍奖励
My.doubleOpenId=1031
My.doubleISOpen=false
My.doubleEndTime=0
My.doubleStartTime=0
My.edouble=Event()
function My.doubleOpen( id )
  if id==nil then
    My.doubleOpenDo(  )
  elseif id ==My.doubleOpenId then 
    My.doubleOpenDo(  )
  end
end

function My.send3ci( times)
  local msg = ProtoPool.Get("m_world_boss_merge_times_tos")
  msg.merge_times=times
  ProtoMgr.Send(msg)
end

function My:MegChange( msg )
  if msg.err_code ~= 0 then
    local err = ErrorCodeMgr.GetError(msg.err_code);
    UITip.Log(err)
  else
    My.merge_times = msg.merge_times;
    My.eMerge()
  end
end

function My.doubleOpenDo(  )
  local tab = LivenessInfo:GetActInfoById(My.doubleOpenId)
  if tab==false then
    My.doubleISOpen=false
    My.edouble()
    return
  end
  local val = tab.val
  if val==2 then
    My.doubleISOpen=false
    My.edouble(false)
    UIBossOpenTip:OnClose( )
    return
  end
  if val==1 then
    My.doubleStartTime=tab.sTime
    My.doubleEndTime=tab.eTime
    My.doubleISOpen=true
    My.edouble()
    UIBossOpenTip:OpenChoose(1840)
  end
end

function My.BossOpen( )
  -- if My.OpenLst[1]==false and OpenMgr:IsOpen("42") then
  --   My.OpenLst[1]=OpenMgr:IsOpen("42") 
  --   UIBossOpenTip:OpenChoose(1)
  -- end
  if My.OpenLst[3]==false and OpenMgr:IsOpen("411") then
    My.OpenLst[3]=OpenMgr:IsOpen("411") 
    UIBossOpenTip:OpenChoose(3)
  end
  if My.OpenLst[2]==false and OpenMgr:IsOpen("412") then
    My.OpenLst[2]=OpenMgr:IsOpen("412") 
    UIBossOpenTip:OpenChoose(2)
  end
end

function My.BossBlood( id,hp )
  hp=tonumber(hp)*100
  hp = math.floor( hp )
  My.eBossBlood(id,tonumber(hp))
end

function My:reCaveTime( msg)
  My.CaveTimes=msg.cave_times
  My.CaveAssistTimes=msg.cave_assist_times
  My.eCaveTimes()
end
function My.GetAllCaveAssistTimes(  )
  local info = GlobalTemp["127"].Value2
  return info[3];
end

function My.GetAllCaveTimes(  )
  local lvStr = VIPMgr.GetVIPLv()
  -- local base = GlobalTemp["127"].Value3 
  local vipinfo = 0
  if lvStr~=0 and lvStr~=nil then
    local info =soonTool.GetVipInfo(lvStr)
     vipinfo = info.caveInto;
  end
  return vipinfo;
end

function My.GetLessCaveTimes(  )
  local time = My.GetAllCaveTimes()-My.CaveTimes;
  return time<0 and 0 or time
end
function My.BossOpenSet(isUpdate, list )
  if isUpdate==0 then
    -- My.OpenLst[1]=OpenMgr:IsOpen("42") 
    My.OpenLst[2]=OpenMgr:IsOpen("412") 
    My.OpenLst[3]=OpenMgr:IsOpen("411") 
  end
  My.WorldBossRed()
end



function My.sendBossBuy(  )
  local msg = ProtoPool.Get("m_world_boss_buy_times_tos")
  ProtoMgr.Send(msg)
end
function My.sendBossHelp(  )
  local msg = ProtoPool.Get("m_world_boss_seek_help_tos")
  ProtoMgr.Send(msg)
end
function My:reHelpofter( msg  )
  if msg.err_code ~= 0 then
    local err = ErrorCodeMgr.GetError(msg.err_code);
    UITip.Log(err)
  end
end
--boss购买返回
function My:ReBossBuy( msg )
  if msg.err_code ~= 0 then
    local err = ErrorCodeMgr.GetError(msg.err_code);
    UITip.Log(err)
  else
    My.WorldTimes = msg.times;
    My.WldBuyTimes = msg.buy_times;
    My.resumeTime= msg.resume_time;
    My.eUpTieTime();
    My.WorldBossRed()
  end
end

function  My.changesence(  )
  local mapId=User.instance.SceneId;
  local scenceInfo=SceneTemp[tostring(mapId)];
  if My.OnceOpen then
    local bossPlace = scenceInfo.mapchildtype; 
    if User.instance.MapData.Level>=GlobalTemp["138"].Value3 then
      if bossPlace==3 then
        --提示小仙女
        UseTipHelp:CheckBossSence(40002)
        My.OnceOpen=false
      elseif bossPlace==1 then
        --提示小仙女
        UseTipHelp:CheckBossSence(40002)
        My.OnceOpen=false
      end
    end
  end
  BossCareTip.changesence()
end

--引导退出？！
function My:PleaseGoOut(  )
  UIMgr.Open(BossKillOut.Name,self.OpenCB,self);
end
function My:OpenCB(name)
	local ui = UIMgr.Get(name)
  if ui then 
    ui:UpdateData(GlobalTemp["114"].Value3)
  end
end


function My.WorldBossRed()
    local isopen=OpenMgr:IsOpen("42") 
    if isopen~=true then
      return
    end
    if My.WorldTimes>0 then
      My.redLst[1]=true;
      SystemMgr:ShowActivity(ActivityMgr.BOSS, 1)
    else
      My.redLst[1]=false;
      SystemMgr:HideActivity(ActivityMgr.BOSS, 1)
    end
end

--场景进入次数
function My:mapEntr( msg )
  soonTool.ClearList( My.enterLst )
  for i,v in ipairs(msg.enter_list) do
    -- iTrace.eError(v.id,v.val)
    My.enterLst[v.id]=v.val
  end
end

--上线推送
function My:AllGet( msg )
  My.WorldTimes = msg.times;
  My.resumeTime= msg.resume_time;
  My.resumeTimes=msg.resume_times;
  My.CaveTimes=msg.cave_times
  My.CaveAssistTimes=msg.cave_assist_times
  My.WldBuyTimes = msg.buy_times;
  My.islTimes=msg.mythical_times;
  My.islAddTimes=msg.mythical_item_times;
  My.collectTimes=msg.mythical_collect_times;
  My.collect2Times=msg.mythical_collect2_times;
  My.isGuide=msg.is_guide;
  My.merge_times=msg.merge_times
  self:CareLst( msg )
  PropMgr.InitTimeDic()
  local kv = msg.collect_open_list
  for i,v in ipairs(kv) do
    PropMgr.TimeDic[tostring(v.id)]=v.val
  end
  
  -- self:maxKill( msg )
  self:candoIsland();
--发送协议
  self.eIsland();
  self.eUpTieTime();
  self.eCollect();
  self.eUseAddIsl();
  My.eCaveTimes()
  -- EventMgr.Trigger("BossTie",msg.times,msg.item_add_times);
  My.WorldBossRed()
end
-- --最大击败等级boss
-- function My:maxKill( msg )
--   if msg.max_type_id==nil or SBCfg[tostring(msg.max_type_id)]==nil then
--     My.worlMaxKill=nil
--   else
--     My.worlMaxKill= msg.max_type_id 
--   end
-- end


function My:ReIsGuide( msg )
  My.isGuide=msg.is_guide;
end

--杀记录请求
function My:islKillTos(mosId)
  local msg = ProtoPool.Get("m_world_boss_kill_tos");
  msg.type_id=tonumber(mosId);
  ProtoMgr.Send(msg);
end
--击败记录查看
function My:reIslKillTos(msg)
  soonTool.ClearList(self.islKillLst);
  local err_code = msg.err_code;
  if err_code==0 then
    local klst = msg.kill_list;
    for i=1,#klst do
      self.islKillLst[i]=klst[i];
    end
    self.eKillRcd();
  else
    local err = ErrorCodeMgr.GetError(msg.err_code);
    UITip.Log(err)
  end
end

--采集次数变更
function My:UpColect1( msg )
  My.collectTimes=msg.collect_times;
  self:candoIsland();
  self.eCollect();
  self:CollectTxt(1)  
end
--采集次数变更
function My:UpColect2( msg )
  My.collect2Times=msg.collect2_times;
  self:candoIsland();
  self.eCollect();
  self:CollectTxt(2);
end
--采集文本
function My:CollectTxt( num )
  local col1 , col2 =self:CollectId( )
  local col = nil;
  local time = nil;
  if num==1 then
    col=col1
    time= My.Col1Isltime()
  elseif num==2 then
    col=col2
    time= My.Col2Isltime()
  end  
  local mt= BinTool.Find(CollectionTemp,tonumber(col))
  
  local str =  string.format("采集成功，%s水晶剩余采集%s次",mt.name,time)
  UITip.Log(str,3)
end
--采集物id
function My:CollectId( )
  local mapId = tostring(User.instance.SceneId) 
  local info = tIslCollect[mapId]
  if info ~=nil then
    return info.col1,info.col2
  else
    return 100039,100040,100041,100042;
  end
end
--扣血文本
function My:reColTime( num )
  if CollectMgr.cfg==nil then return; end
  local id = CollectMgr.cfg.id;
  local col1 , col2 =self:CollectId( )
  if col1~=id and col2~=id then
    return;
  end
  if math.floor(num) >My.curColTime then
    UITip.Log("采集时百分比扣除生命值");
    My.curColTime=num;
  end
end
--中断处理
function My:stopcol( )
  My.curColTime=0;
end

--疲劳变更
function My:UpTimesAddIsl( msg )
  My.islTimes=msg.times;
  My.islAddTimes=msg.item_add_times;
  self.eUseAddIsl();
end
--神兽岛数据更新
function My:reIsland(msg)
  self.islTimes=msg.times;
  self.islAddTimes=msg.item_add_times;
  self.collectTimes=msg.collect_times;
  self.collect2Times=msg.collect2_times;
  local kv = msg.item_times
  for i,v in ipairs(kv) do
    PropMgr.TimeDic[tostring(v.id)]=v.val
  end
  self:candoIsland();
  self.eIsland();
end
--神兽岛是否采集判断
function My:candoIsland()
  local col1 , col2,col3,col4 =self:CollectId( )
  if My.Col1Isltime()==0 then
    CollectMgr.AddFilter(col1)
    CollectMgr.AddFilter(col3)
  else
    CollectMgr.RemoveFilter(col1)
    CollectMgr.RemoveFilter(col3)
  end
  if My.Col2Isltime()==0 then
    CollectMgr.AddFilter(col2)
    CollectMgr.AddFilter(col4)
  else
    CollectMgr.RemoveFilter(col2)
    CollectMgr.RemoveFilter(col4)
  end
  My.curColTime=0;
end

--boss每个排行
function My:reRank(msg)
  soonTool.ClearList(My.ranklst);
  local len = #msg.ranks 
  for i=1,len do
    local info = msg.ranks[i];
      self.ranklst[info.rank] = info;
  end
  self.eRank();
end
--关注的刷新了
function My:CareRelf(msg)
  local id = msg.boss_type_id;
  My.CareRelife=id;
  My.careType = msg.type;
  if My.careType==0 then
    My.CareCanClose=false
    BossCareTip.id=tostring(id)
    BossCareTip.changesence()
  else
    local ui = UIMgr.Get(BossCareTip.Name)
    if ui then
      My.CareCanClose=true
      BossCareTip:doClose();
    end
  end
end
--关注返回
function My:careToc( msg )
  local err_code = msg.err_code;
  if err_code==0 then
    local type = 1;
    local id = msg.boss_type_id;
    if msg.type == 1 then
      My.careLst[id]=1;
    else
      My.careLst[id]=nil;
    end
  else
    local err = ErrorCodeMgr.GetError(msg.err_code);
    UITip.Log(err)
  end
end
--关注的boss列表
function My:CareLst( msg )
  local lst = msg.care_list;
  for i=1,#lst do
    My.careLst[lst[i]]=1;
  end
end
--获取是否存在
function My:GetIsCare(bossId)
  local id = My.careLst[bossId];
  if id==1 then
    return true;
  else
    return false;
  end
end

--发送boss关注
function My:ResCare(careId,value )
  local msg = ProtoPool.Get("m_world_boss_care_tos");
  msg.boss_type_id=careId;
  local type = value and 1 or 0 ;
  msg.type= type;
  ProtoMgr.Send(msg);
end
--请求世界Boss信息
function My:ReqUpBInfo(type, layer)
  local msg = ProtoPool.Get("m_world_boss_info_tos");
  msg.type = type;
  msg.floor = layer;
ProtoMgr.Send(msg);
end

--世界Boss信息反馈
function My:RespUpBInfo(msg)
  table.sort(msg.boss_list, self.doSort);
  My.BossNum=0;
  self.BossLst=msg.boss_list;
  My.CurLayerRole = msg.role_num ;
  if BossHelp.curType==7 then
    local len=#self.BossLst
    local ishave = false
    local lst = {}
    for i=len,1,-1 do
      local lsInfo =  self.BossLst[i]
      local what = SBCfg[tostring(lsInfo.type_id)].what
      if what == 3 then
        My.BossNum=My.BossNum+self.BossLst[i].remain_num;
        if ishave then
          local toty3 =  table.remove( self.BossLst,i )
          table.insert( lst, toty3 )
        else
          ishave=true
        end
      end
    end
    self.what3Boss=lst;
  end
  self.eUpBInfo(msg.boss_list);
end 

--疲劳值反馈
function My:RespTieTime(msg)
  My.WorldTimes = msg.times;
  My.resumeTime= msg.resume_time;
  My.resumeTimes=msg.resume_times;
  My.eUpTieTime();
  My.WorldBossRed()
  -- EventMgr.Trigger("BossTie",msg.times,msg.item_add_times);
end

--世界Boss地图结束时间
function My:RespWBQuitTime(msg)
  local serverTime = TimeTool.GetServerTimeNow();
  serverTime = serverTime / 1000;
  local time = msg.quit_time - serverTime;
  self.QuitTime = time;
  self.eReChgTime()
end

--请求世界Boss记录
function My:ReqWBLog()
  local msg = ProtoPool.Get("m_world_boss_log_tos");
  ProtoMgr.Send(msg);
end

--世界boss记录返回
function My:RespWBLog(msg)
  self.eUpBRcd(msg.log_list);
  self.eUpnormalBRcd(msg.normal_log_list);
end

--更新地图Boss信息
function My:RespMapBInfo(msg)
  if msg.boss_list == nil then
    return;
  end
  local len = #msg.boss_list;
  if len == 0 then
    return;
  end
  self:ClearMBInfos();
  table.sort(msg.boss_list, self.doSort);
    --17号远古遗迹判断
    local mapId=User.instance.SceneId;
    local scenceInfo=SceneTemp[tostring(mapId)];
    local bossPlace = scenceInfo.mapchildtype;
  for i = 1, len do
    local info = msg.boss_list[i];
    mbInfo = MapBossInfo:New();
    mbInfo:SetData(info);
    if mbInfo.what~=0 and mbInfo.what~=1 and bossPlace == 17 then
      if mbInfo.what==2 then
        self.MapMsInfos[mbInfo.typeId] = mbInfo;
      end
    else
      self.MapBossInfos[i] = mbInfo;
    end
  end
  self.eUpMBInfos();
end
--boss排序
function My.doSort(a,b)
  local r = true;
  local astr = tostring(a.type_id)
  local bstr = tostring(b.type_id)
  local sca = SBCfg[astr].what;
  local scb = SBCfg[bstr].what;
  if sca~=0 or scb ~=0 then
    if sca~=0 and scb ==0 then
      r=true
    elseif sca == 0 and scb ~= 0 then 
      r=false;
    else
      r=sca<scb;
    end
    return r;
  end
  local a1 = MonsterTemp[astr].level;
  local a2 = MonsterTemp[bstr].level;
  r=a1<a2;
  return r;
end
--更新场景boss数据
function My:RespMapBInfUp(msg)
  local bossInfo = msg.map_boss;
  if self.MapBossInfos == nil then
    return;
  end
  for k,info in pairs(self.MapBossInfos) do
    if info.typeId == bossInfo.type_id then
      info:SetData(bossInfo);
      self.eUpMBInfo(info,k,true);
      return;
    end
  end
  for k,info in pairs(self.MapMsInfos) do
    if k == bossInfo.type_id then
      info:SetData(bossInfo);
      self.eUpMBInfo(info,k,false);
      return;
    end
  end
end

--清除场景boss信息
function My:ClearMBInfos()
  if self.MapBossInfos == nil then
    return;
  end
  soonTool.ClearList(self.MapBossInfos)
end


function My:Dispose()
  self.MapBossInfos = nil;
  My.QuitTime = nil;
  My.ResetTime = nil;
end

--获取世界boss疲劳总次数
function My.GetBossAllTime()
    local time = GlobalTemp["122"].Value2[1]
    return time;
end
--获取神兽岛疲劳总次数
function My.GetAllIslTimes( )
  return 3 + My.islAddTimes;
end
--获取龙灵的剩余次数
function My.Col1Isltime( )
  local x =  GlobalTemp["84"].Value3-My.collectTimes;
  return x;
end
--获取凤血水晶剩余次数
function My.Col2Isltime( )
  local x =  GlobalTemp["85"].Value3-My.collect2Times;
  return x;
end
--获取进入次数
function My.GetEnterTime(mapType)
  local enterTime = My.enterLst[mapType];
  if enterTime==nil then
    enterTime=0;
  end
  return enterTime;
end

function My:Clear(isReconnect)
  if isReconnect then
    return
  end
  self:ClearMBInfos();
  My.QuitTime = nil;
  My.ResetTime = 0;
  My.curColTime=0;
  My.worlMaxKill=0;
  My.islTimes=0;
  My.enterLst={};
  My.MapMsInfos = {};
  My.CareCanClose=true
  My.CareRelife=1
  BossCareTip:doClose()
end

return My
