--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2017-7-4 10:42:20
-- 采集物管理
--==============================================================================

CollectMgr = {Name = "CollectMgr"}

local My = CollectMgr

--进入采集物范围
My.eEnter = Event()

--响应开始采集事件
My.eRespBeg = Event()

--响应结束采集事件
My.eRespEnd = Event()

--响应停止/中断采集事件
My.einterupt = Event()

--采集状态
CollectState = {Name = "CollectState", None = 0, Wait = 1, Req=2, Running = 3, Interupt = 4}

function My.Init()
	My.Reset()
	--true:停止,通过SetStop设置
	My.isStop = false
	My.filterDic = {}
	local EH = EventHandler
	local Add = EventMgr.Add
	Add("EnterCollect", EH(My.Enter))
	Add("ResetCollect", EH(My.Reset))
	Add("RespBegCollect", EH(My.RespBeg))
	Add("RespEndCollect", EH(My.RespEnd))
	Add("RespStopCollect", EH(My.RespStop))
end

function My.Reset()
	--当前采集物UID
	My.uid = nil
	--当前采集物配置
	My.cfg = nil
	--采集时间
	My.dur = 0
	--状态 0:无 1:等待请求采集,3:采集倒计时 4:中断
	My.state = CollectState.None
end

function My.IsFilter(id)
	local dic = My.filterDic
	if dic[tostring(id)]  then return true end
end

function My.AddFilter(id)
	local dic = My.filterDic
	dic[tostring(id)] = true
end


function My.RemoveFilter(id)
	local dic = My.filterDic
	dic[tostring(id)] = nil
end

--设置状态
function My.SetState(v)
	My.state = v
end

function My:SetStop(val)
	if type(val) ~= "boolean" then return end
	My.isStop = val
end

--设置数据
function My.Enter(uid, id)
	if My.IsFilter(id) then return end
	My.uid = tonumber(tostring(uid))
	My.cfg = BinTool.Find(CollectionTemp, id)
	My.SetState(CollectState.Wait)
	My.eEnter(uid)
	if (My.isStop == true) then return end
	UIMgr.Open("UICollection")
end

function My.Clear()
	My.Reset()
	My.isStop = false
end

function My.EndChgScene()
	My.Reset()
	My.isStop = false
end

--请求开始采集
function My.ReqBeg()
	if My.state == CollectState.Req then return end
	if My.state == CollectState.Running then return end
	if My.state == CollectState.Interupt then return end
	My.state = CollectState.Req
	EventMgr.Trigger("ReqBegCollect")
end

--请求结束采集
function My.ReqStop()
	EventMgr.Trigger("ReqStopCollect")
end

--响应开始采集
function My.RespBeg(uid, dur, err)
	My.SetState(CollectState.Running)
	if err < 1 then My.dur = dur * 0.001 end
	My.eRespBeg(err, uid, My.dur)
end

--响应结束采集
function My.RespEnd(uid, err)
	My.SetState(CollectState.None)
	My.eRespEnd(err, uid)
	My.dur = 0
end

--响应中断
--uid(number):唯一ID
--err(number):错误码
function My.RespStop(uid, err)
	My.SetState(CollectState.Interupt)
	My.einterupt(uid, err)
	My.dur = 0
end

return My
