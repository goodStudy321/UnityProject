--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-08-21 19:55:52
-- 1,必须通过Start函数启动
-- 2,尽量不要通过New实例化,而是通过对象池获取
-- 3,回调事件仅在释放时滞空,停止时不清空
-- 4,当需要释放,应该调用AutoToPool方法,而不要调用Dispose,像如下这样：
--        self.timer:AutoToPool()
--        self.timer = nil
--==============================================================================

iTimer = Foolish:New{Name = "iTimer"}
local My, base = iTimer, Foolish

function My:Ctor()

  base.Ctor(self)
  --总时间
  self.seconds = 2

  --间隔时间
  self.interval = 1

  --true忽略时间缩放
  self.ignoreScale = true

  --间隔事件
  self.invlCb = Event()

  --结束回调
  self.complete = Event()
end

--开始
--dur(number):持续时间
--interval(number):间隔时间
function My:Start(dur, interval)
  if self.running then return end
  TimerMgr:Add(self)
  self:Reset()
  if dur then self.seconds = dur end
  if interval then self.interval = interval end
end

--停止
function My:Stop()
  if not self.running then return end
  self.running = false
  self:Reset()
end

--重置
function My:Reset()
  self.pro = 0
  self.cnt = 0
  self.invlCnt = 0
  base.Reset(self)
end

--获取剩余时间（秒）
function My:GetRestTime()
  local rt = self.seconds - self.cnt
  return rt
end

function My:Update()
  if not self.running then return end
  local delta = self.ignoreScale and Time.unscaledDeltaTime or Time.deltaTime

  self.invlCnt = self.invlCnt + delta

  if self.invlCnt > self.interval then
    if self.Invl then self:Invl() end
    self.invlCb()
    self.invlCnt = 0  
  end

  self.cnt = self.cnt + delta
  self.pro = self.cnt / self.seconds
  if self.cnt > self.seconds then
    self:Stop()
    self.complete()
  end
end

function My:Dispose()
  base.Dispose(self)
  self.seconds = 2
  self.interval = 1
  self.ignoreScale = true
  self.invlCb:Clear()
  self.complete:Clear()
end

--创建
function My.Create(mod, invl, sec, invlCb, obj1, cb, obj2)
  local timer = ObjPool.Get(mod)
  timer.seconds = sec
  timer.interval = invl
  if invlCb then timer.invlCb:Add(invlCb, obj1) end
  if cb then timer.complete:Add(cb, obj2) end
end

--倒计时
function My:Restart(sec, invl)
  self:Reset()
  self.seconds = sec
  self.interval = invl
  self:Start()
end

function My:AutoToPool()
  self:Stop()
  base.AutoToPool(self)
end

return My
