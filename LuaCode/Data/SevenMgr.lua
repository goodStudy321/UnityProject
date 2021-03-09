--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-21 19:45:39
-- 七日登陆数据
--=========================================================================

SevenMgr = {Name = "SevenMgr"}

local My = SevenMgr

function My:Init()
  --已领取数据列表
  --索引天数值1:不能领取,2:可领取,3:已领取
  self.gets = {}
  self.count = 7
  self.isOpen = false
  self:Reset()
  --领取事件
  self.eGet = Event()
  self:SetLsnr("Add")
end

function My:Reset()
  --当前领取的天数
  self.curDay = 0
  self:ResetGets()
end

function My:SetLsnr(fn)
  ProtoLsnr[fn](20360, self.RespGet, self)
end

--设置以领取
function My:ResetGets()
  local gets = self.gets
  for i = 1, self.count do
    gets[i] = 3
  end
end

--获取七天状态
--day(number):天数
function My:GetState(day)
  if day < 1 or day > self.count then return 1 end
  do return self.gets[day] end
end

--请求领取奖励
--day(number):天数
function My:ReqGet(day)
  local msg = ProtoPool.GetByID(20361)
  msg.day = day
  --iTrace.eLog("Loong", "七日请求奖励:", msg)
  ProtoMgr.Send(msg)
end

--响应领取奖励
--msg:m_role_seven_toc
function My:RespGet(msg)
  local err, list = msg.err_code, nil
  self.isOpen = true
  --iTrace.eLog("Loong", "七日获取奖励:", msg)
  if err > 0 then
    MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
  else
    list = msg.list
    local gets = self.gets
    for i, v in ipairs(list) do
      day = v.id
      get = v.val
      gets[day] = get
      if (get > 1) and (day > self.curDay) then
        self.curDay = day
      end
    end
  end
  self.eGet(err, list)
  self:UpRedDot()
end

--更新红点
function My:UpRedDot()
  local isGet = self:IsGetAward()
  LvAwardMgr:UpAction(2, isGet)
end

--判断是否能领取奖励
function My:IsGetAward()
  local isGet = false
  for k,v in pairs(self.gets) do
    if v == 2 then
      isGet = true
    end
  end
  return isGet
end

function My:Clear()
  self:Reset()
  self.eGet:Clear()
  self.isOpen = false
end

--释放资源
function My:Dispose()
  self:SetLsnr("Remove")
end

return My
