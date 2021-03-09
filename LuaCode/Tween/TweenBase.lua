--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 00:01:33
-- 1.必须通过Start函数启动
-- 2.子类型必须重写Sample
-- 3.尽量不要通过New实例化,而是通过对象池获取
-- 4.回调事件仅在释放时滞空,停止时不清空
-- 5.当需要释放,应该调用AutoToPool方法,而不要调用Dispose,像如下这样：
--        self.tween:AutoToPool()
--        self.tween = nil
--=========================================================================

TweenBase = Foolish:New{Name = "TweenBase"}
local My, base = TweenBase, Foolish
LoopMode = {Name = "LoopMode", Once = 1, Loop = 2, PingPang = 3}

function My:Ctor()
  base.Ctor(self)
  --结束事件
  self.complete = Event()
end

function My:Clear()
  --时间插值
  self.t = 0
  --true:等待中
  self.isDelay = false
  --时间的倒数
  self.inverse = 0
  --持续时间
  self.dur = 1
  --等待时间
  self.delay = 0

  self.isPause = false
  --true:忽略时间缩放
  self.ignoreScale = false
  --循环模式
  self.mode = LoopMode.Once

  base.Clear(self)
end

function My:Start(dur, delay)
  if self.running then return end
  TweenMgr:Add(self)
  self.isPause = false
  self.dur = dur or 1
  self.delay = delay or 0
  if(self.dur == 0) then
    self:Stop()
  elseif self.delay > 0 then
    self.isDelay = true
    self.inverse = 1 / self.delay
  else
    self.inverse = 1 / self.dur
  end
end

function My:Update()
  local delta = self.ignoreScale and Time.unscaledDeltaTime or Time.deltaTime
  self.t = self.t + delta * self.inverse

  if (self.isDelay) then
    if self.t < 1 then return end
    self.t = self.t - 1
    self.isDelay = false
  elseif(self.mode == LoopMode.Once) then
    if(self.t > 1) then
      self:Stop()
      self:Sample(1)
      self:Complete()
    else
      self:Sample(self.t)
    end
  elseif(self.mode == LoopMode.Loop) then
    if(self.t > 1) then
      self.t = self.t - 1
      self:Sample(1)
      self:Complete()
    else
      self:Sample(self.t)
    end
  elseif (self.mode == LoopMode.PingPang) then
    if(self.t > 1) or (self.t < 0) then
      self.inverse = -self.inverse
      self:Sample(math.floor(self.t))
      self:Complete()
    else
      self:Sample(self.t)
    end
    self:Sample(self.t)
  end
end

--采样
function My:Sample(t)

end

function My:Complete()
  self.complete()
end

function My:Reset()
  self.t = 0
  self.inverse = 0
end

function My:Stop()
  if self.running == false then return end
  self.running = false
  self:Reset()
end


function My:Dispose()
  base.Dispose(self)
  self.complete:Clear()
end

return My
