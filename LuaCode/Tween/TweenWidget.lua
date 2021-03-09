--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-09-28 10:02:58
-- widget的区域插值动画
--=========================================================================


TweenWidget = TweenBase:New{Name = "TweenWidget"}

local My, base = TweenWidget, TweenBase


function My:Sample(t)
  local x = self.fromX + (self.toX - self.fromX) * t
  local y = self.fromY + (self.toY - self.fromY) * t
  x = math.floor(x)
  y = math.floor(y)
  if (x%2) ~= 0 then x = x + 1 end
  if (y%2) ~= 0 then y = y + 1 end
  self.widget.width = x
  self.widget.height = y
end


function My:Start(fromX, fromY, toX, toY, widget, dur, delay)
  if self.running then return end
  self.widget = widget
  self.fromX = fromX
  self.fromY = fromY
  self.toX = toX
  self.toY = toY
  base.Start(self, dur, delay)
end

--from(Vector2):起始区域
--to  (Vector2):结束区域
--widget(UIWidget):挂件
function My:StartBySize(from, to, widget, dur, delay)
  self:Start(from.x, from.to.x, to.y, widget, dur, delay)
end

return My
