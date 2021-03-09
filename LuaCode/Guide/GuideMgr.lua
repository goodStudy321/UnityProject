--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-02-05 11:54:33
-- 新手引导管理
--=========================================================================

local CondFty = require("Guide.GuideCondFty")

GuideMgr = {Name = "GuideMgr"}

local My = GuideMgr


function My.Init()
  --k:已经触发的ID,v:true
  My.trigedDic = {}
  My.Reset()
  My.AddLsnr()
  My.timer = ObjPool.Get(iTimer)
  My.timer.complete:Add(My.Beg)
  CondFty.Init(My.CondSuc)
  SceneMgr.eChangeEndEvent:Add(My.OnSceneChanged)

  if App.isEditor then require("Guide/EditGuideTrigger") end
end

function My.OnSceneChanged(isLoad)
  local cfg = My.cacheCfg
  if cfg then
    My.CondSuc(My.curCond, cfg)
  end
end

function My.SetCache(cond, cfg)
  My.curCond = cond
  My.cacheCfg = cfg
end

function My.Reset()
  --当前引导条件
  My.cond = nil
  --当前引导配置
  My.curCfg = nil
  --引导UI 0:关闭,1:打开
  My.guideAt = 0
  My.hasEnd = false
end

--设置条件
function My.SetCond()
  local tDic, k = My.trigedDic, nil
  local setCfg = CondFty.SetCfg
  for i, v in ipairs(GuideCfg) do
    k = tostring(v.id)
    if not tDic[k] then
      setCfg(v)
    end
  end
end

--检查过滤条件
--retrun(bool):可以执行
function My.CheckScene(cfg)
  if cfg == nil then return false end
  local sFilter = cfg.sFilter
  if sFilter ~= 1 then return true end
  local sceneID = SceneMgr.nextSceneId
  local sCfg = SceneTemp[tostring(sceneID)]
  if sCfg == nil then return true end
  local mt = sCfg.maptype
  if mt == 1 then return true end
  if mt == 2 then 
    if FlowChartMgr.CurName then
      return true 
    end
  end
  do return false end
end

--触发条件达成
function My.CondSuc(cond, cfg)
  if not My.CheckScene(cfg) then 
    My.SetCache(cond, cfg)
  else
    My.SetCache(nil, nil)
    local ui = cfg.ui
    local at = UIMgr.GetActive(ui)
    if App.IsDebug then
      iTrace.sLog("Loong", "达成:", cond.Name, ", ID:", cfg.id, " ui:", ui)
    end
    if at == 1 then
      My.End(true)
      My.curCfg = cfg
      My.Start()
    else
      if My.guideAt == 0 then
        My.ChkResumeHangup(My.curCfg)
        My.curCfg = cfg
      end

      local autoOn = cfg.autoOn or 0
      if autoOn == 1 then
        UIMgr.Open(ui)
      end
    end
  end
end


function My:Start()
  local cfg = My.curCfg
  if cfg == nil then return end
  local delay = cfg.delay or 0
  if delay > 0 then
    local tm = delay * 0.001
    local timer = My.timer
    timer:Reset()
    timer:Start(tm)
    My.ChkPauseHangup(cfg)
  else
    My.Beg()
  end
end

--开始引导
function My.Beg()
  My.guideAt = 1
  My.ReqTrig()
  My.ChkPauseHangup(My.curCfg)
  UIMgr.Open("UIGuide")
end

--检查暂停挂机
function My.ChkPauseHangup(cfg)
  if cfg == nil then return end
  local pause = cfg.pause
  if pause == 1 then
    Hangup:Pause(GuideMgr.Name)
    if App.IsDebug then
      iTrace.sLog("Pause", "Pause AutoHangup:", cfg.id);
    end
  end
end

--检查继续挂机
function My.ChkResumeHangup(cfg)
  if cfg == nil then return end
  local pause = cfg.pause
  if pause == 1 then
    if App.IsDebug then
      iTrace.sLog("Rusume", "Resume AutoHangup:", cfg.id);
    end
    Hangup:Resume(GuideMgr.Name)
  end
end

--结束引导
function My.End(closeGuide)
  My.timer:Stop()
  My.ChkResumeHangup(My.curCfg)
  if My.guideAt == 0 then return end
  if closeGuide then UIMgr.Close("UIGuide") end
  My.guideAt = 0
  local cfg = My.curCfg
  My.curCfg = nil
  if cfg == nil then return end
  --My.ChkResumeHangup(cfg)
  GuideLinkCond:ChkTrig(cfg)
end


--UI打开监听
function My.UIOpenLsnr(name)
  if My.guideAt == 1 then return end
  local cfg = My.curCfg
  if cfg == nil then return end
  if name ~= cfg.ui then return end
  if My.timer.running then return end
  --My.Beg()
  My.Start()
end

--UI关闭监听
function My.UICloseLsnr(name)
  local cfg = My.curCfg
  if cfg == nil then return end
  if name == UIGuide.Name then 
    My.ChkResumeHangup(cfg) 
  end
  if My.hasEnd then return end
  My.hasEnd = true
  if name == UIGuide.Name then
    My.End()
  elseif name == cfg.ui then
    My.ChkResumeHangup(cfg) 
    My.End(true)
  end
  My.hasEnd = false
end

--请求完成
function My.ReqTrig()
  if My.curCfg == nil then return end
  local id = My.curCfg.id
  local msg = ProtoPool.GetByID(20011)
  msg.guide_id = id
  ProtoMgr.Send(msg)
  --iTrace.eLog("Loong", "请求结束引导: ", id)
end


--上线时,获取所有已触发ID
--msg:m_role_guide_toc
function My.RespInfo(msg)
  local tDic = My.trigedDic
  TableTool.ClearDic(tDic)
  local k = nil
  for i, v in ipairs(msg.guide_id_list) do
    k = tostring(v)
    tDic[k] = true
  end
  My.SetCond()
  --iTrace.eLog("Loong", "Guide RespInfo:", msg)
end

function My.AddLsnr()
  ProtoLsnr.Add(20012, My.RespInfo)
  euiopen:Add(My.UIOpenLsnr)
  euiclose:Add(My.UICloseLsnr)
end

function My.Clear()
  My.Reset()
  My.timer:Stop()
  CondFty.Clear()
  My.ChkResumeHangup(My.curCfg)
  euiclose:Remove(My.UICloseCb)
end

function My.Dispose()

end

return My
