--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 1/2/2019, 2:09:57 AM
--=============================================================================


PackCtrl = {Name = "PackCtrl"}

local My = PackCtrl

function My.Init()
  My.size = "0M"
  My.total = 0
  My.count = 0
  My.eSetTotal = Event()
  My.eSetCount = Event()
  --下载&校验完成事件
  My.eComplete = Event()
  --下载完成事件
  My.eDownloaded = Event()
  My.eGetReward = Event()
  My.isDownloaded = false
  --true:已经领取过奖励
  My.isGetRewarded = false
  EventMgr.Add("PackDlComplete", My.Complete)
  My.AddLsnr()
end

function My.AddLsnr()
  ProtoLsnr.Add(20038, My.RespReward)
end

function My.RespReward(msg)
  local err = msg.err_code
  if err > 0 then
    UITip.Error(GetErr(err))
  else
    local isGetRewarded = msg.is_reward
    My.isGetRewarded = isGetRewarded
    My.eGetReward(isGetRewarded)
  end
end

function My.SetTip(val)

end

function My.SetCount(count)
  My.count = count
  My.eSetCount(count)
end

function My.SetTotal(size, total)
  My.size = size
  My.total = total
  My.eSetTotal(size, total)
end

function My.Downloaded()
  My.isDownloaded = true
  My.eDownloaded()
  iTrace.Log("Loong", "Pack downloaded")
end

function My.Complete()
  local isGetRewarded = My.isGetRewarded
  local tip = "所有资源下载完成"
  My.eComplete(isGetRewarded)
  if not isGetRewarded then
    tip = tip .. ",可点击按钮领取奖励"
  end
  UITip.Log(tip)
end

function My.ReqGetReward()
  local msg = ProtoPool.GetByID(20037)
  if msg == nil then return end
  ProtoMgr.Send(msg)
end

function My.Clear()

end


return My
