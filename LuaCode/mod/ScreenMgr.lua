--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-12-13 17:34:40
-- 编辑器下默认初始方向是Left
--=========================================================================

ScreenMgr = {Name = "ScreenMgr"}

--屏幕方向 Left:home键在右,Right:home键在左
ScreenOrient = {Up = 1, Down = 2, Left = 3, Right = 4}

local My = ScreenMgr

function My:Init()
  self.eChange = Event()
  self:SetDefaultOrient()
  local cb = EventHandler(self.Change, self)
  EventMgr.Add("ScreenOrient", cb)
end

function My:Change(orient)
  self.orient = orient
  --iTrace.Error("Loong","ScreenOrient Change:", orient)
  self.eChange(orient)
end


function My:SetDefaultOrient()
	if App.isEditor then
		self.orient = ScreenOrient.Left
	else
		self.orient = User.ScreenOrient
	end
end

function My:Clear()

end

return My
