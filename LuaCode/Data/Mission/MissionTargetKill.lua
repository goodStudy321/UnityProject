--region Mission.lua
--
--此文件由[HS]创建生成

MissionTargetKill = baseclass(MissionTarget)
local M = MissionTargetKill
local Error = iTrace.Error

--构造函数
function M:Ctor()
	self.MTemp = nil			--怪物配置表
	self.Wild = nil 			--野外刷新配置表
end

function M:ServerData(t, v, n)
	self:Super("ServerData", t, v, n)
	if self.Num and self.LNum and self.Num >= self.LNum then
		--hMgr.IsAutoSkill = false
		--MissionMgr:Execute(false)
		User.MissionState = false;
		User:ResetMisTarID()
	end
end

--更新目标数据
function M:UpdateTarData(tar)
	self.TID = tar[1] 			--怪物ID
	self.SID = tar[2]
	self.LNum = tar[3]
	local x = tar[4]
	local z = tar[5]
	if x and z then
		self.NavPos = Vector3.New(x / 100, 0, z /100)
	else 
		self.NavPos = nil
	end
	self:Super("UpdateTarData", tar)
end

function M:UpdateTabelData()
	self.MTemp = MonsterTemp[tostring(self.TID)]
	if not self.MTemp then 
   		Error("hs", string.format("怪物ID：%s 不存在！！", self.TID))
   	end
	if not self.STemp or not self.STemp.update then return end
   	local len = #self.STemp.update
   	for i=1, len do
   		local temp = WildMapTemp[tostring(self.STemp.update[i])]
   		if temp and self.TID == temp.mID then
   			self.Wild = temp
   			return
   		else
   			temp = nil
   		end
   	end
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	self.Execute = execute
	if self:IsFlowChartScene() then 
		self:Super("AutoExecuteAction", execute)
	else
		local isHg = Hangup:GetAutoHangup();
		if isHg == false then
			return;
		end
		local wild = self.Wild
		local sid = self.SID
		local name = FlowChartMgr.CurName
		local tree = self.Tree
		--if StrTool.IsNullOrEmpty(name) == false then
		--	iTrace.eError("--------------->>>>   CurName ",name)
		--end
		--if StrTool.IsNullOrEmpty(name) == false and tree and tree.screen == User.SceneId then 
		if tree and tree.screen == User.SceneId then 
			local isHg = Hangup:GetAutoHangup();
			if isHg == true then
				if self.NavPos then
					self:NavPath(self.NavPos, self.STemp.map , 0, self.TID, fly)
				else
					--hMgr.IsAutoSkill = true
					iTrace.eLog("hs","任务目标怪物id：", self.TID)
					User:SetMisTarID(self.TID);
				end
				MissionMgr:Execute(true)
			end
			return 
		end
		if not self.STemp or not wild then 
			--HangupMgr.instance.IsAutoSkill = true
			return 
		end
		local lbPos = wild.lbPos
		local rtPos = wild.rtPos
		self.MPos = Vector3.New((lbPos.x + rtPos.x) / 2 * 0.01, 0, (lbPos.y + rtPos.y) / 2 * 0.01)
		if self.Temp.screen and self.Temp.screen == User.SceneId then
			local mDis = (self:Distance(Vector3.New(lbPos.x, lbPos.y, 0), Vector3.New(rtPos.x, rtPos.y, 0)) * 0.01) / 2
			local rolePos = Vector3.New(User.Pos.x, 0, User.Pos.z)
			local dis = self:Distance(rolePos, self.MPos)
			if dis <= mDis then 
				--hMgr.IsAutoSkill = true
				iTrace.eLog("hs","任务目标怪物id：", self.TID)
				User:SetMisTarID(self.TID);
    			return
			end
		end
		local isRtg = lbPos.x ~= rtPos.x or lbPos.y ~= rtPos.y;
		self:NavPath(self.MPos, sid, 0, self.TID, fly, isRtg)
		MissionMgr:Execute(true)
	end
end

function M:CustomNPComplete()
    --hMgr.IsAutoSkill = true
end

function M:ChangeEndEvent(isLoad)
	self:UpdateFlowChart()
end

--任务描述
function M:TargetDes()
	local des = ""
	local tarName = "怪物名字"
	if self.MTemp then tarName = self.MTemp.name end
	local num = self.Num or 0
	des = string.format("清除[%s]%s[-](%s/%s)", "%s", tarName, num, self.LNum) 
	return des
end

--释放或销毁
function M:Dispose(isDestory)
	--Hangup:SetAutoSkill(false);
	--hMgr.IsAutoHangup = true
	self.MTemp = nil			
	self.Wild = nil 	
	self.MPos = nil		
	self.NavPos = nil
	self:Super("Dispose", isDestory)
end
--endregion
