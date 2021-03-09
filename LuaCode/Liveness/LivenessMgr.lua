--[[
 	authors 	:Liu
 	date    	:2018-4-9 12:28:08
 	descrition 	:活跃度管理
--]]

LivenessMgr = {Name = "LivenessMgr"}

local My = LivenessMgr

require("Liveness/CustomInfo")
require("Liveness/CustomMod")
local Info = require("Liveness/LivenessInfo")

--挂机点的场景id
My.jumpSceneId = 0
--挂机点的坐标
My.jumpScenePos = Vector3.zero

My.eUpLiveness = Event()
My.eUpAward = Event()
My.eUpCount = Event()

function My:Init()
	Info:Init()
	self:AddLnsr()
	NavPathMgr.eNavPathEnd:Add(self.NavPathEnd, self)
	self:CreateTimer()
end

--添加监听
function My:AddLnsr()
	self:SetLnsr(ProtoLsnr.Add)
end

--移除监听
function My:RemoveLsnr()
	self:SetLnsr(ProtoLsnr.Remove)
end

--设置监听
function My:SetLnsr(func)
	func(20004,self.RespGetAward, self)
	func(20002,self.RespLivenessState, self)
end

--请求获取奖励
function My:ReqGetAWard(type)
	local msg = ProtoPool.GetByID(20003)
	msg.type = type
	ProtoMgr.Send(msg)
end

--响应获取奖励
function My:RespGetAward(msg)
	local err = msg.err_code
	--输出错误码
	if (err>0) then
		MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
		return
	end
	--拿到已领取奖励列表
	local list = msg.list
	local id = nil
	for i,v in ipairs(list) do
		id = tostring(v)
		Info.awardDic[id] = true
		table.insert(Info.getsList, v)
	end
	self.eUpAward(Info.awardDic, id)
	self:UpRedDot()
end

--活跃度状态返回
function My:RespLivenessState(msg)
	--拿到玩家当前活跃度
	Info.liveness = msg.liveness
	local list = msg.list
	for i,v in ipairs(list) do
		local it = list[i]
		local id = tostring(it.id)
		Info.countDic[id] = it.val
	end
	self.eUpCount(list)
	My.eUpLiveness()
	self:UpRedDot()
end

--更新红点
function My:UpRedDot()
	local cfg = LivenessAwardCfg
	local livenessVal = Info.liveness
	local actId = ActivityMgr.HY
	local max = 0;
	for i=1,#cfg do
		if(i ~= #cfg) then
			if (livenessVal >= cfg[i].id and livenessVal < cfg[i+1].id) then
				max = i;
				break;
			end
		else 
			if (livenessVal >= cfg[i].id) then
				max = i;
				break;
			end
		end
	end

	if max > #Info.getsList or FindBackMgr.Red then
		if #Info.getsList >= #cfg then return end
		SystemMgr:ShowActivity(actId)
	else
		SystemMgr:HideActivity(actId)
	end
end

--前往挂机点寻路结束
function My:NavPathEnd(type, id)
    if User.SceneId == My.jumpSceneId then
		local pPos = FindHelper.instance:GetOwnerPos()
		local x = math.abs(pPos.x - My.jumpScenePos.x)
		local z = math.abs(pPos.z - My.jumpScenePos.z)
		if x < 2 and z < 2 then
			My.jumpSceneId = 0
			My.jumpScenePos = Vector3.zero
			self:UpTimer(1)
		end
	end
end

--自动跳转到挂机点
function My:AutoHangup()
    local sceneId, pos = self:GetJumpData()
    if (sceneId == 0) or (pos == Vector3.zero) then
        UITip.Log("无法匹配与你等级相符的挂机点")
        return
	end
	if VIPMgr.vipLv == nil then
		return;
	end
    if VIPMgr.vipLv > 0 then
        User:FlyShoes(pos, sceneId, -1, 0)
    else
        User:StartNavPath(pos, sceneId, -1, 0)
    end
    My.jumpSceneId = sceneId
    My.jumpScenePos = pos
end

--获取挂机点数据（场景id，坐标）
function My:GetJumpData()
    local tempId = 0
    local sceneId = 0
    local pos = Vector3.zero
    local lv = User.MapData.Level
    for k,v in pairs(WildMapTemp) do
        if lv >= v.minLvl and lv <= v.maxLvl then
            tempId = tonumber(k)
            pos = Vector3.New((v.lbPos.x + v.rtPos.x) / 200, 0, (v.lbPos.y + v.rtPos.y) / 200)
        end
    end
    for k,v in pairs(SceneTemp) do
        if v.maptype == 1 then
            if v.update then
                for i1,v1 in ipairs(v.update) do
                    if v1 == tempId then
                        sceneId = v.id
                    end
                end
            end
        end
    end
    return sceneId, pos
end

--获取已完成次数
function My:GetCount(cfg)
    local id = (cfg.id == 19) and 16 or cfg.id
    local key = tostring(id)
    local count = Info.countDic[key]
    local val = (count==nil) and 0 or count
    return val
end

--判断任务是否已完成
function My:IsComplete(id)
	local cfg, index = BinTool.Find(LivenessCfg, id)
	if cfg then
		local val = self:GetCount(cfg)
		if val >= cfg.count and cfg.count ~= 0 then
			return true
		end
	end
	return false
end

--更新计时器
function My:UpTimer(rTime)
	local timer = self.timer
	timer:Stop()
	timer.seconds = rTime
	timer:Start()
end

--创建计时器
function My:CreateTimer()
    if self.timer then return end
    self.timer = ObjPool.Get(DateTimer)
    local timer = self.timer
    timer.invlCb:Add(self.InvCountDown, self)
    timer.complete:Add(self.EndCountDown, self)
end

--间隔倒计时
function My:InvCountDown()

end

--结束倒计时
function My:EndCountDown()
	Hangup:SetSituFight(true)
end

--清理缓存
function My:Clear()
	Info:Clear()
	if self.timer then self.timer:Stop() end
end

--释放资源
function My:Dispose()
	self:RemoveLsnr()
	TableTool.ClearFieldsByName(self,"Event")
	NavPathMgr.eNavPathEnd:Remove(self.NavPathEnd, self)
end

return My