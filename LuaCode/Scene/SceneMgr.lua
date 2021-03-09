--region SceneMgr.lua
--Date	
--此文件由[HS]创建生成

SceneMgr = {Name="SceneMgr"}

local M = SceneMgr

M.Last = nil 		--上一场景ID
M.IsInitEnterScene = true
M.IsManual = nil
M.eOpenScene = Event()
M.ePreload = Event()

function M.Init()
	M.eChangeEndEvent = Event()
	--print("==============================================================>  SceneMgr:Init")
end

--打开场景时准备
function M.OpenScene(sceneId)
	M.Last = User.SceneId
	M.nextSceneId = sceneId
	M.eOpenScene(sceneId)
	-- print("==============================================================>  SceneMgr:LastScene "..tostring(M.Last))
	-- print("==============================================================>  SceneMgr:OpenScene "..tostring(sceneId))
end

--进入场景需要打开的UI
function M.GetUIConfig()
	--print("==============================================================>  SceneMgr:GetUIConfig")
	return nil
end

--预加载资源之前加载资源,有些资源的预加载必须在其它资源加载完才能获取
function M.BeforePreload()
	--print("==============================================================>  SceneMgr:BeforePreload")
end

--预加载资源
function M.Preload()
	M.ePreload()
	--print("==============================================================>  SceneMgr:Preload")
end

--预加载完成
function M.PreloadFinish()
	--print("==============================================================>  SceneMgr:PreloadFinish")
end

function M.LoadSceneFinish()
	--print("==============================================================>  SceneMgr:LoadSceneFinish")
end

function M.OnChangeScene(isLoad)
	M.eChangeEndEvent(isLoad)
	if M.IsInitEnterScene == true then M.IsInitEnterScene = false end
	M.CheckFeederMiss()
end

function M.CheckFeederMiss()
	local copy = CopyTemp[tostring(M.Last)]
	if not copy then return end
	local type = copy.type
	if type == CopyType.HYC or type == CopyType.YML or type == CopyType.MLGK or type == CopyType.GWD then
		local curType = MissionMgr.CurExecuteType
		if curType == MissionType.Turn or curType == MissionType.Family then
			--MissionMgr:AutoExecuteAction()
			Hangup:SetAutoHangup(true)
		end
	end
end


--切换场景释放当前场景数据
function M.ChangeDispose()
	-- body
end

function M.IsMissionScene()
	local id = User.SceneId
	local temp = CopyTemp[tostring(id)]
	if temp and temp.type == CopyType.Mission then
		return true 
	end
	return false
end

function M:IsCopy(id)
	if id == nil then id = User.SceneId end
	local key = tostring(id)
	local scene = SceneTemp[key]
	if scene and scene.maptype ~= SceneType.Copy then
		if scene.mapchildtype then
			return true
		end
	end
	local copy = CopyTemp[key]
	if copy and copy.type ~= CopyType.Mission then
		return true
	end
	return false
end

function M:IsOpenUISkill()
	local key = tostring(User.SceneId)
	local scene = SceneTemp[key]
	if scene and scene.maptype ~= SceneType.Copy then
		local t = scene.mapchildtype
		if t == SceneSubType.AnswerMap then
			return true
		end
	end
end

function M.IsSpecial()
	local id = User.SceneId
	local lastid = M.Last
	local key = tostring(id)
	local lastkey = tostring(lastid)
	local scene = SceneTemp[key]
	local lastscene = SceneTemp[lastkey]
	if scene and scene.mapchildtype then
		return true
	end
	local temp = CopyTemp[key]
	if temp and temp.type ~= CopyType.Mission then
		return true 
	else
		local lasttemp = CopyTemp[lastkey]
		if (not lasttemp or lasttemp.type == CopyType.Mission) and lastscene and lastscene.maptype == SceneType.Wild and not lastscene.mapchildtype then
			return false
		end
	end
	return false
end

--判断能否切场景
function M:IsChangeScene(tip)
	if tip == nil then tip = true end
	local k = tostring(User.SceneId)
	local sTemp = SceneTemp[k]
	if sTemp then
		if sTemp.maptype == 1 then
			if sTemp.mapchildtype ~= nil then 
				if tip == true then UITip.Error("特殊场景，不能进入其他场景") end
				iTrace.eError("hs","特殊场景，不能进入其他场景 1")
				return false
			end
		elseif sTemp.maptype == 2 then
			local copy = CopyTemp[k]
			if copy ~= nil then 
				if tip == true then UITip.Error("特殊场景，不能进入其他场景") end
				iTrace.eError("hs","特殊场景，不能进入其他场景 2")
				return false
			 end
		end
	end
	local mission = MissionMgr.Main
	if mission and mission:IsFlowChart() then
		if tip == true then UITip.Error("特殊场景，不能进入其他场景") end
		iTrace.eError("hs","特殊场景，不能进入其他场景 3")
		return false 
		--[[
		if User.MapData.Level >= mission.Temp.lv then
			if mission.Temp.tree ~= nil or mission.Temp.tarType ==  MTType.FlowChart then
				UITip.Error("特殊场景，不能进入其他场景")
				return false 
			end
		end
		]]--
	end
	return true
end

--请求进入场景
--iscleck 是否检查场景是不是副本
--ismanual 任务挂机用的
function M:ReqPreEnter(id, isCleck, isManual ,extraid)
	extraid = extraid or 0

	if self:IsMarryScene(id) then
		UITip.Error("特殊场景，不能进入其他场景")
		iTrace.eError("hs","特殊场景，不能进入其他场景 4")
		return
	end

	local nextSceneInfo = SceneTemp[tostring(id)];
	if nextSceneInfo == nil then
		iTrace.eError("LY", "Can not get scene info : "..id);
		return;
	end
	if self:CheckSceneRes(nextSceneInfo) == false  then 
		if User.IsInitLoadScene == true then
			Mgr.ReqPreEnter(0, tostring(extraid), isCleck)
			return
		end
		if NetworkMgr.IsHadResource == true or self.Execute == MExecute.ClickItem then
			NetworkMgr.IsHadResource = false
			UITip.Error("地图正在初始化准备当中，请稍后再试!")
			UIMgr.Open(UIDownload.Name)
		end
		return 
	end
	--[[
	local nextSceneResName = StrTool.Concat(nextSceneInfo.res, ".unity");
	if Loong.Game.AssetMgr.Instance:Exist(nextSceneResName) == false then
		--UITip.Log("场景资源尚未加载完成!");
		UIMgr.Open(UIDownload.Name)
		iTrace.eError("LY", "Scene res is not exist : "..nextSceneResName);
		return;
	end
	]]--
	Mgr.ReqPreEnter(id, tostring(extraid), isCleck)
	self.IsManual = isManual
end

--判断是否在结婚场景
function M:IsMarryScene(id)
	if id == 30020 then return false end
	if User.SceneId == MarryInfo.copyId then
		return true
	end
	return false
end

function M:QuitScene()
	iTrace.eLog("hs", "lua退出当前场景------------>>  "..User.SceneId)
	Mgr.QuitScene() 
	if not self.IsManual or self.IsManual == true then
		Hangup:ClearAutoInfo()
	else
		MissionMgr:Execute(true)
		Hangup:SetAutoHangup(true);
	end
end

function M:CheckSceneRes(temp)	
	local nextSceneResName = StrTool.Concat(temp.res, ".unity");
	if Loong.Game.AssetMgr.Instance:Exist(nextSceneResName) == false then
		--UITip.Log("场景资源尚未加载完成!");
		--UIMgr.Open(UIDownload.Name)
		--iTrace.eError("LY", "Scene res is not exist : "..nextSceneResName);
		return false
	end
	return true
end

function M:Clear()
end

function M:Dispose()
	-- body
end

return M