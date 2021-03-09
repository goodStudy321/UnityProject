--region Mission.lua
--Cell基类 只有Icon
--此文件由[HS]创建生成

MissionTarget = baseclass()
local M = MissionTarget

--构造函数
function M:Ctor()
	self.Temp = nil        --任务配置表
	self.T = nil			--服务器返回目标类型
	self.Value = nil		--服务器返回目标ID
	self.Num = nil			--当前完成数量
	self.TID = nil 		--目标ID
	self.SID = nil		--场景ID
	self.LNum = nil 	--完成数量
	self.STemp = nil    --场景
	self.Tree = nil 	--流程树
	self.IsEndFlowChart = false
	self.IsFCCallbackInit = false
	self.Miss = nil
	self.Execute = MExecute.None
end

function M:Init(mission)
	self.Miss = mission
end

--更新任务配置表
function M:UpdateMTemp(temp)
	self.Temp = temp
	self.Tree = temp.tree
end

--更新服务器数据
function M:ServerData(t, v, n)
	self.T = t
	self.Value = v
	self.Num = n
end

--更新目标数据
function M:UpdateTarData(tar)
	self:UpdateScene()
	self:UpdateTabelData()
	self:TargetDes()
   	self:UpdateFlowChart()
end

--更新场景数据
function M:UpdateScene()
	if self.SID then
		self.STemp = SceneTemp[tostring(self.SID)]
		if not self.STemp then 
   			iTrace.eError(string.format("场景ID：%s 不存在！！", self.SID))
	   end
	end
end

--更新读表数据
function M:UpdateTabelData()
	-- body
end

function M:IsComplete()
	if self.Num == nil or self.LNum == nil then 
		return false
	end
	if self.LNum == 0 then return false end
	return self.Num >= self.LNum
end

--执行任务目标
function M:AutoExecuteAction(fly, execute)
	self.Execute = execute
	self:UpdateFlowChart()
end
            
--执行流程树
function M:UpdateFlowChart()
	if self.Miss then
		if  self.Miss then
			if  User.MapData.Level < self.Miss.Temp.lv then return end
		end
		if self.Miss.Status >= MStatus.ALLOW_SUBMIT then return end
	end
	if not self.Temp then return end
	local curSID = User.SceneId
	if curSID ~= self.Temp.screen and self.Tree and curSID ~= self.Tree.screen then 
		if curSID ~= self.Temp.screen then
			if SceneMgr.IsSpecial() == nil then
				--iTrace.eWarning("hs","执行流程树进入场景"..self.Temp.screen)
				if self.IsEndFlowChart == false then
					SceneMgr:ReqPreEnter(self.Temp.screen, true)
				end
			end
		end
		return false
	end
	local tree = self.Tree
	if not tree then return end
	if User.IsInitLoadScene then return end
	local name = FlowChartMgr.CurName
	if StrTool.IsNullOrEmpty(name) == false then
		--iTrace.eError("--------------->>>>   CurName ",name)
		return
	end
	if self.IsEndFlowChart == true then return end
	if not self.IsFCCallbackInit then
		self.IsFCCallbackInit = true
		--MissionFlowChart.StartCallback:Add(self.StartCallback, self)
		iTrace.eLog("hs","注册流程树结束事件")
		MissionFlowChart.EndCallback:Add(self.EndCallback, self) 
	end
	iTrace.eLog("hs","任务："..self.Temp.id)
	if not MissionFlowChart:Check(tree) then		
    	local pos = User:GetMapEntrancePos(self.Temp.screen)
    	if pos.x == 0 and pos.y == 0 and pos.z == 0 then return end
    	MissionNavPath:ScreenPathfinding(pos, self.Temp.screen, self.Execute)
	end
end

--流程树开始
function M:StartCallback()
	if self.Tree and self.Tree.screen ~= User.SceneId then return end
	MissionFlowChart.StartCallback:Remove(self.StartCallback, self)
	local isHg = Hangup:GetAutoHangup();
	if isHg == true then return end
	if not self.Temp then return end
	self:AutoExecuteAction()
end

function M:EndCallback(name, win)
	if self.Temp and  name ~= tostring(self.Tree.id) then return end
	MissionFlowChart.EndCallback:Remove(self.EndCallback, self)
	self.IsEndFlowChart = true
	self.IsFCCallbackInit = false
	Hangup:SetAutoSkill(false);
	local isHg = Hangup:GetAutoHangup();
	if isHg == true then 
		MissionMgr:Execute(false)
		return 
	end
	if not self.Temp then return end
	self:AutoExecuteAction()
end

function M:NavPath(pos, scene, dis, id, fly,isRtg)	
	local sTemp = SceneTemp[tostring(scene)]
	if not sTemp then iTrace.eError("hs",string.format( "场景【%s】数据不存在", scene)) end
	if SceneMgr:CheckSceneRes(sTemp) == false then
		if NetworkMgr.IsHadResource == true or self.Execute == MExecute.ClickItem then
			NetworkMgr.IsHadResource = false
			iTrace.eLog("XGY", "场景资源不存在:"..scene)
			UITip.Error("地图正在初始化准备当中，请稍后再试!")
			UIMgr.Open(UIDownload.Name)
		end
		return
	end
	EventMgr.Add("NavPathComplete", EventHandler(self.NPComplete, self))
	if self.Temp and self.Temp.type == MissionType.Escort then
		User:EscortNavPath(self.Temp.id, pos, scene, dis, 0)
		return
	end
	if not fly or fly == false then
		if isRtg == nil then
			isRtg = false;
		end
		User:MissStarNavPath(self.Temp.id, pos, scene, dis, id, isRtg)
	else
		local vip = VIPMgr.GetVIPLv() > 0
		local item = PropMgr.TypeIdByNum(31015) > 0
		local t = false
		if vip == true or item == true then
			t = true
		end
	
		if t == false then
			--MsgBox.ShowYes("小飞鞋使用条件不足（Vip等级不足或小飞鞋道具不足）");
			MapMgr:ShowFlyShoesMsg();
			return;
		end

		if vip == false then
			UITip.Log("消耗小飞鞋 x 1");
		end
		User:MissionFlyShoes(self.Temp.id, pos, scene, dis, id)
	end
end

function M:NPComplete(t, id)
	local temp = self.Temp
	if temp and temp.id ~= id then return end
	EventMgr.Remove("NavPathComplete", EventHandler(self.NPComplete, self))
	--User:StopNavPath()
	if t == PathRType.PRT_PATH_SUC then
		self:CustomNPComplete()
	else
	end
end

function M:CustomNPComplete()
	-- body
end

function M:ChangeEndEvent(isLoad)
	-- body
end

--任务描述
function M:TargetDes()
	return ""
end

function M:Distance(pos1, pos2)
	return Vector3.Distance(pos1, pos2)
end

function M:IsFlowChartScene()
	if self.Temp then
	 	local fcid = nil
	 	if self.Tree then
	 		fcid = self.Tree.screen
			 if fcid and fcid ~= User.SceneId and fcid == self.SID then
				 return true
			 end
	 	end 
	end
	return false
end

--释放或销毁
function M:Dispose(isDestory)
	EventMgr.Remove("NavPathComplete", EventHandler(self.NPComplete, self))
	self.Temp = nil
	self.T = nil			
	self.Value = nil		
	self.Num = nil			
	self.TID = nil 		
	self.SID = nil		
	self.LNum = nil 	
	self.STemp = nil    
end
--endregion
