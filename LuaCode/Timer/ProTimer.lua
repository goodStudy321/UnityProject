--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-09-22 14:44:35
-- 0-1之间进度显示
--==============================================================================

ProTimer = Super:New{Name = "ProTimer"}

local Time = UnityEngine.Time

local My = ProTimer

--进度值
My.pro = 0

--值为1时的回调
My.cb1 = nil

--结束回调
My.cb = nil

--启动
--cycle(number) 循环次数 可以是浮点数
--scale(number) 缩放系数 可以是浮点数
function My:Start(cycle, scale)
  if self.running then return end
  if type(cycle) ~= "number" then return end
  scale = scale or 1
  self.pro = 0
  self.cycle = cycle
  self.scale = scale
  self.running = true
end

function My:Update()
  if not self.running then return end
  self.pro = self.pro + Time.deltaTime * self.scale
  if self.cycle < 1 then
    if self.pro > self.cycle then
      if self.cb then self.cb() end
      self:Stop()
    end
  else
    if self.pro > 1 then
      self.pro = 0
      self.cycle = self.cycle - 1
      if self.cb1 then self.cb1() end
    end
  end
end

function My:Reset()
  self.pro = 0
end

function My:Stop()
  self.running = false
end

function My:Dispose()
  self.cb1 = nil
  self.cb = nil
  self.running = false
  self:Reset()
end
