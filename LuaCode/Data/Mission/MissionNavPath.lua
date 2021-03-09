--region MissionFlowChart.lua
--Date
--此文件由[HS]创建生成
MissionNavPath = {}
local MM = MissionNavPath
MM.Callback = nil


local NavPathType = {}
NavPathType.Screen = 1
NavPathType.NPC = 1


function MM:NPCPathfinding(missid, npcid, dis, fly, t, execute)
	NPCMgr.instance:CheckLoad(npcid)
	self.MissID = missid
	--User:StopNavPath()
	local temp = NPCTemp[tostring(npcid)]
	if not temp then
   		Error("hs", string.format("任务寻路未没有在npc配置表中找到配置的NPCID:",npcid))
		return
	end
	local sTemp = SceneTemp[tostring(temp.sceen)]
	if not sTemp then iTrace.eError("hs",string.format( "场景【%s】数据不存在", temp.sceen)) end
	if SceneMgr:CheckSceneRes(sTemp) == false then
		if NetworkMgr.IsHadResource == true or execute == MExecute.ClickItem then
			NetworkMgr.IsHadResource = false
            iTrace.eLog("XGY", "场景资源不存在:"..temp.sceen);
            UITip.Error("地图正在初始化准备当中，请稍后再试!");
			UIMgr.Open(UIDownload.Name)
		end
		return
	end
	local pos = temp.pos
	local tPos = Vector3.New(pos.x * 0.01, 0, pos.z * 0.01)
	local p = User.Pos
	local uPos = Vector3.New(p.x, 0, p.z)
	self.NPType = NavPathType.NPC
	local dis1 = Vector3.Distance(uPos, tPos)
	if dis1 <= 3.0 then
		self:NPComplete(PathRType.PRT_PATH_SUC, missid)
		return
	end
	EventMgr.Add("NavPathComplete",EventHandler(self.NPComplete, self))
	if t == MissionType.Escort then
		User:EscortNavPath(missid, tPos, temp.sceen, dis, 0)
		return
	end
	if not fly or fly == false then
		--// LY add begin
		-- if fly ~= nil and fly == false then
		-- 	--MsgBox.ShowYes("小飞鞋使用条件不足（Vip等级不足或小飞鞋道具不足）");
		-- 	MapMgr:ShowFlyShoesMsg();
		-- end
		--// LY add end
		--iTrace.sLog("hs","----------------> ".. tostring(tPos).."/"..tostring(p))
		User:MissStarNavPath(missid, tPos, temp.sceen, dis, 0)
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
		User:MissionFlyShoes(missid, tPos, temp.sceen, dis, 0)
	end
end

function MM:ScreenPathfinding(id, pos, screne, execute)
	local sTemp = SceneTemp[tostring(screne)]
	if not sTemp then iTrace.eError("hs",string.format( "场景【%s】数据不存在", screne)) end
	if SceneMgr:CheckSceneRes(sTemp) == false then
		if NetworkMgr.IsHadResource == true or execute == MExecute.ClickItem then
			NetworkMgr.IsHadResource = false
            iTrace.eLog("XGY", "场景资源不存在:"..screne);
            UITip.Error("地图正在初始化准备当中，请稍后再试!");
			UIMgr.Open(UIDownload.Name)
		end
		return
	end
	self.MissID = id
	self.NPType = NavPathType.Screen
	User:MissStarNavPath(missid, pos, screne, -1, 0)
end

--领取提交寻路完成
function MM:NPComplete(t, missid)
	if missid ~= self.MissID then return end
	self.MissID = 0
	EventMgr.Remove("NavPathComplete",EventHandler(self.NPComplete, self))
	if t == PathRType.PRT_PATH_SUC then
		if self.Callback then
			self.Callback()
			self.Callback = nil
		end
	end
	self.NPType = nil
end

function MM.CollectionPosNavPath( cid, sid, cdis, execute)
	local sTemp = SceneTemp[tostring(sid)]
	if not sTemp then iTrace.eError("hs",string.format( "场景【%s】数据不存在", sid)) end
	if SceneMgr:CheckSceneRes(sTemp) == false then
		if NetworkMgr.IsHadResource == true or execute == MExecute.ClickItem then
			NetworkMgr.IsHadResource = false
            iTrace.eLog("XGY", "场景资源不存在:"..sid);
            UITip.Error("地图正在初始化准备当中，请稍后再试!");
			UIMgr.Open(UIDownload.Name)
		end
		return
	end
	coroutine.wait(0.4)
	User:PathfindingToCollectionPos(cid, sid, cdis)
end

function MM:Dispose()
	self.Callback = nil
end