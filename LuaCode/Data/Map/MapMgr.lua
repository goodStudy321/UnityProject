--// 地图系统管理器

MapMgr = Super:New{Name = "MapMgr"}

local iLog = iTrace.eLog;
local iError = iTrace.Error;
local eWarming = iTrace.eWarning;
local ET = EventMgr.Trigger;

MapMgr.testSign = 0;
local mgrPre = {};

mgrPre.sceneIds = {};
mgrPre.sceneIds[1] = 10001;
mgrPre.sceneIds[2] = 10010;
mgrPre.sceneIds[3] = 10003;
mgrPre.sceneIds[4] = 10005;
mgrPre.sceneIds[5] = 10020;
mgrPre.sceneIds[6] = 10013;
mgrPre.sceneIds[7] = 10014;
mgrPre.sceneIds[8] = 10015;
mgrPre.sceneIds[9] = 10016;
mgrPre.sceneIds[10] = 10101;

--// 地图缩放等级
mgrPre.scaleLv = {};
-- mgrPre.scaleLv[1] = 650;
-- mgrPre.scaleLv[2] = 1024;
-- mgrPre.scaleLv[3] = 1536;
mgrPre.scaleLv[1] = 540;
mgrPre.scaleLv[2] = 782;
mgrPre.scaleLv[3] = 1024;

--// 初始化
function MapMgr:Init()

	if mgrPre.init ~= nil and mgrPre.init == true then
 		return;
	end
	
 	iLog("LY", " MapMgr create !!! ");
 	mgrPre.init = false;

	--// 当前场景Id
	mgrPre.curSceneId = 0;
	--// 当前场景地图跳转口信息
	mgrPre.portalInfos = nil;
	--// 当前场景Npc信息
	mgrPre.npcInfos = nil;
	--// 当前场景怪物信息
	mgrPre.evilInfos = nil;
	--// 当前所在分线Id
	mgrPre.curLineNum = 0;
	--// 分线列表
	mgrPre.lineList = {};


	SceneMgr.eChangeEndEvent:Add(self.ChangeSceneEnd, self)
	mgrPre.onWaitCS = EventHandler(self.WaitChangeScene, self);
	EventMgr.Add("WaitChangeScene", mgrPre.onWaitCS);
	mgrPre.onEndCS = EventHandler(self.EndChangeScene, self);
	EventMgr.Add("PreChangeScene", mgrPre.onEndCS);
	EventMgr.Add("BreakChangeScene", mgrPre.onEndCS);

	self:AddLsnr();

 	mgrPre.init = true;
end

--// 添加监听
function MapMgr:AddLsnr()

	--// 分线信息返回
	ProtoLsnr.AddByName("m_map_line_info_toc", self.RespLineInfo, self);
end

function MapMgr:Clear()

	mgrPre.curSceneId = 0;
	mgrPre.portalInfos = nil;
	mgrPre.npcInfos = nil;
	mgrPre.evilInfos = nil;

	mgrPre.init = false;
end

function MapMgr:Dispose()
	
end

---------------------------------- 向服务器请求 ----------------------------------

--// 根据Id转换场景
function MapMgr:ChangeScene(sceneId)
	if sceneId == nil or sceneId <=0 then
		iError("LY", "Scene id error !!! ");
		return;
	end

	--// 检测是否在副本中
	local curId = User.SceneId;
	local curSceneInfo = SceneTemp[tostring(curId)];
	if curSceneInfo == nil then
		iError("LY", "Can not get scene info : "..curId);
		return;
	end
	
	if SceneMgr:IsChangeScene() == false then
		return
	end
	if curSceneInfo.maptype ~= 1 or curSceneInfo.playId ~= 0 then
		MsgBox.ShowYes("副本中不能跳转场景");
		return;
	end

	--// 检测是否已经在此场景中
	if curId == sceneId then
		MsgBox.ShowYes("已经在此场景中");
		return;
	end

	if EscortMgr.FairyID > 1 then
		MsgBox.ShowYes("护送任务中不能转换场景");
		return;
	end

	-- if SceneMgr:IsChangeScene() == false then
	-- 	return
	-- end

	local nextSceneInfo = SceneTemp[tostring(sceneId)];
	if nextSceneInfo == nil then
		iError("LY", "Can not get scene info : "..sceneId);
		return;
	end

	local nextSceneResName = StrTool.Concat(nextSceneInfo.res, ".unity");
	if Loong.Game.AssetMgr.Instance:Exist(nextSceneResName) == false then
		--UITip.Log("场景资源尚未加载完成!");
		UIMgr.Open(UIDownload.Name)
		eWarming("LY", "Scene res is not exist : "..nextSceneResName);
		return;
	end

	local title = StrTool.Concat("进入", nextSceneInfo.name, "？");
	local yesCb=function()
		Hangup:ClearAutoInfo();
		--User:ClearPlayerNavState(4);
		
		--SceneMgr:ReqPreEnter(sceneId, true, true);
		MapHelper.instance:ChangeSceneCom(sceneId);
	end
	MsgBox.ShowYesNo(title,yesCb);
end

--// 请求分线信息
function MapMgr:ReqLineInfo(sceneId)
	local msg = ProtoPool.Get("m_map_line_info_tos");
	msg.map_id = sceneId;
	ProtoMgr.Send(msg);
end

-------------------------------------------------------------------------------

---------------------------------- 服务器推送返回 ----------------------------------

--// 分线信息返回
function MapMgr:RespLineInfo(msg)
	if msg == nil then
		return;
	end

	mgrPre.curLineNum = FamilyMgr.ChangeInt64Num(msg.cur_extra_id);

	mgrPre.lineList = {};
	if msg.extra_id_list ~= nil then
		for i = 1, #msg.extra_id_list do
			mgrPre.lineList[#mgrPre.lineList + 1] = msg.extra_id_list[i];
		end
	end

	table.sort(mgrPre.lineList, function(a, b)
		return a < b;
	end)

	ET("NewLineList");
end

-------------------------------------------------------------------------------

---------------------------------- 监听函数部分 ----------------------------------

function MapMgr:ChangeSceneEnd(isLoad)
	UIMgr.Close(UIMapWnd.Name);

	mgrPre.curSceneId = User.SceneId;
	--iLog("LY", "Need load map : "..mgrPre.curSceneId);

	--// 检测是否有场景信息
	local sceneInfo = SceneTemp[tostring(mgrPre.curSceneId)];
	if sceneInfo == nil then
		iError("LY", "Can not find scene info : "..mgrPre.curSceneId);
		return;
	end

	if sceneInfo.maptype == 3 then
		iLog("LY", "No map data scene !!! ");
		return;
	end

	--// 填充跳转口信息
	mgrPre.portalInfos = {};
	local infoList = MapHelper.instance:GetChangeMapPor();
	if infoList ~= nil then
		for i = 0, infoList.Count - 1 do
			mgrPre.portalInfos[#mgrPre.portalInfos + 1] = self:ChangePortalInfo(infoList[i]);
		end
	end

	--// 获取Npc信息
	mgrPre.npcInfos = {};
	if sceneInfo.npcList ~= nil and #sceneInfo.npcList > 0 then
		for i = 1, #sceneInfo.npcList do
			local npcCfg = NPCTemp[tostring(sceneInfo.npcList[i])]
			if npcCfg ~= nil and npcCfg.inMap ~= nil and npcCfg.inMap == 1 then
				local npcInfo = {};

				npcInfo.evilAreaId = "";
				npcInfo.id = npcCfg.id;
				npcInfo.name = npcCfg.name;
				npcInfo.info = "";
				npcInfo.pos = Vector3.New(0, 0, 0);
				npcInfo.pos.x = npcCfg.pos.x / 100;
				npcInfo.pos.y = npcCfg.pos.y / 100;
				npcInfo.pos.z = npcCfg.pos.z / 100;
				npcInfo.mapPos = Vector3.New(0, 0, 0);
				npcInfo.unlock = true;
				npcInfo.unlockLv = 0;
				npcInfo.unlockMissId = 0;
				npcInfo.isSpec = false;

				mgrPre.npcInfos[#mgrPre.npcInfos + 1] = npcInfo;
			end
		end
	end

	--// 获取刷怪区域
	mgrPre.evilInfos = {};
	if sceneInfo.update ~= nil and #sceneInfo.update > 0 then
		for i = 1, #sceneInfo.update do
			local evilArea = WildMapTemp[tostring(sceneInfo.update[i])];
			if evilArea ~= nil and evilArea.mID > 0 and (evilArea.showInMap == nil or evilArea.showInMap == 1) then
				local evilCfg = MonsterTemp[tostring(evilArea.mID)];

				local evilInfo = {};
				evilInfo.evilAreaId = tostring(sceneInfo.update[i]);
				evilInfo.pos = Vector3.New((evilArea.lbPos.x + evilArea.rtPos.x) / 200, 0, (evilArea.lbPos.y + evilArea.rtPos.y) / 200);
				evilInfo.mapPos = Vector3.New(0, 0, 0);
				evilInfo.unlock = true;
				evilInfo.unlockLv = 0;
				evilInfo.unlockMissId = 0;
				if evilCfg == nil then
					iError("LY", "刷怪区域："..tostring(sceneInfo.update[i]).."  找不到怪物Id ： "..evilArea.mID);
					evilInfo.id = 0;
					evilInfo.name = "未知";
					evilInfo.info = "";
					evilInfo.isSpec = false;
					evilInfo.lv = 0;
				else
					evilInfo.id = evilCfg.id;
					evilInfo.name = evilCfg.name;
					evilInfo.info = "Lv."..tostring(evilCfg.level);
					evilInfo.lv = evilCfg.level
					if evilCfg.type > 2 then
						evilInfo.isSpec = true;
					else
						evilInfo.isSpec = false;
					end
				end

				mgrPre.evilInfos[#mgrPre.evilInfos + 1] = evilInfo;
			end
		end
	end

	table.sort(mgrPre.evilInfos, function(a, b)
		return a.lv < b.lv;
	end)

end

--// 转换跳转口信息结构
function MapMgr:ChangePortalInfo(ptLuaInfo)
	local retData = {};

	retData.evilAreaId = "";
	retData.id = ptLuaInfo.id;
	retData.name = "地图传送口";
	retData.info = "";
	retData.pos = ptLuaInfo.pos;
	retData.mapPos = Vector3.New(0, 0, 0);
	retData.unlock = ptLuaInfo.unlock;
	retData.unlockLv = ptLuaInfo.unlockLv;
	retData.unlockMissId = ptLuaInfo.unlockMissId;
	retData.isSpec = false;

	return retData;
end

--// 打开等待面板
function MapMgr:WaitChangeScene(waitSec)
	UIMgr.Open(UIMapTipWnd.Name, function ()
		UIMapTipWnd:SetWaitSec(waitSec);
	end);
end

--// 关闭等待面板
function MapMgr:EndChangeScene()
	UIMgr.Close(UIMapTipWnd.Name);
end

--// 使用小飞鞋功能
function MapMgr:UseLittleFlyShoes(sceneId, pos, desDis, cb)

	if MissionMgr.Escort ~= nil then
		UITip.Log("护送任务中不能使用小飞鞋");
		return;
	end

	local vip = VIPMgr.GetVIPLv() > 0
	local item = PropMgr.TypeIdByNum(31015) > 0
	local t = false
	if vip == true or item == true then
		t = true
	end

	if t == false then
		--MsgBox.ShowYes("飞鞋使用条件不足（Vip等级不足或小飞鞋道具不足）");
		self:ShowFlyShoesMsg();
		return;
	end

	UIMgr.Close(UIMapWnd.Name);

	--// 计算小飞鞋距离
	local tDis = Vector3.Distance(MapHelper.instance:GetOwnerPos(), pos);
	if tDis <= 15 then
		MapHelper.instance:TryMoveToNewPos2(pos, desDis)
		return;
	end

	if vip == false then
		UITip.Log("消耗小飞鞋 x 1");
	end
	MapHelper.instance:LittleFlyShoes(sceneId, pos, desDis, cb);
end

--// 
function MapMgr:ShowFlyShoesMsg()
	MsgBox.ShowYesNo("飞鞋使用条件不足（Vip等级不足或小飞鞋道具不足）", self.OpenVipWnd, self, "购买VIP", self.OpenShopWnd, self, "购买飞鞋")
end

--// 打开VIP界面
function MapMgr:OpenVipWnd()	
	VIPMgr.OpenVIP()
end
--
function MapMgr:OpenShopWnd()
	StoreMgr.OpenStore(5)
end

-------------------------------------------------------------------------------

---------------------------------- 处理数据部分 ----------------------------------



-------------------------------------------------------------------------------

---------------------------------- 获取数据部分 ----------------------------------

--// 获取场景名称列表
function MapMgr:GetSceneNameList()
	local retList = {};
	for i = 1, #mgrPre.sceneIds do
		local sceneInfo = SceneTemp[tostring(mgrPre.sceneIds[i])];
		if sceneInfo == nil then
			retList[#retList + 1] = "未知";
		else
			retList[#retList + 1] = sceneInfo.name;
		end
	end

	return retList;
end

--// 获取场景解锁列表
function MapMgr:GetSceneUnlockList()
	local retList = {};
	for i = 1, #mgrPre.sceneIds do
		local tempInfo = {};
		local sceneInfo = SceneTemp[tostring(mgrPre.sceneIds[i])];
		if sceneInfo == nil then
			tempInfo.unLockLv = 999;
			tempInfo.unLock = false;
		else
			tempInfo.unLockLv = sceneInfo.unlocklv;
			if User.MapData.Level >= sceneInfo.unlocklv then
				tempInfo.unLock = true;
			else
				tempInfo.unLock = false;
			end
		end

		retList[#retList + 1] = tempInfo;
	end

	return retList;
end

--// 获取缩放等级数量
function MapMgr:GetScaleLvNum()
	return #mgrPre.scaleLv;
end

--// 根据索引获取缩放等级
function MapMgr:GetSizeLvByIndex(index)
	if mgrPre.scaleLv == nil then
		iError("LY", "mgrPre.scaleLv is null !!! ");
		return 700;
	end

	local tInd = index;
	if tInd < 1 then
		tInd = 1;
	elseif index > #mgrPre.scaleLv then
		tInd = #mgrPre.scaleLv;
	end

	return mgrPre.scaleLv[tInd];
end

--// 获取当前场景Id
function MapMgr:GetCurSceneId()
	return mgrPre.curSceneId;
end

--// 获取跳转口信息
function MapMgr:GetPortalInfo()
	return mgrPre.portalInfos;
end

--// 获取Npc信息
function MapMgr:GetNpcInfo()
	return mgrPre.npcInfos;
end

--// 获取刷怪点信息
function MapMgr:GetEvilInfo()
	return mgrPre.evilInfos;
end

--// 转换小地图坐标到场景坐标
function MapMgr:ChangeMiniMapPosToScenePos(minimapPos)
	
end

--// 按地图Id获取按钮索引
function MapMgr:GetMapIdToBtnIndex(mapId)
	for i = 1, #mgrPre.sceneIds do
		if mgrPre.sceneIds[i] == mapId then
			return i;
		end
	end

	return 0;
end

--// 获取当前所在分线Id
function MapMgr:GetCurLineId()
	return mgrPre.curLineNum;
end

--// 获取分线列表
function MapMgr:GetLineList()
	return mgrPre.lineList;
end

-------------------------------------------------------------------------------

--// 根据按钮Id转换场景
function MapMgr:CallChangeScene(btnIndex)
	if btnIndex == nil or btnIndex <= 0 or btnIndex > #mgrPre.sceneIds then
		iError("LY", "Button index error : "..btnIndex);
		return;
	end

	MapMgr:ChangeScene(mgrPre.sceneIds[btnIndex]);
end

--// 
function MapMgr:TryToGetLineInfo()
	if SceneMgr:IsChangeScene() == false then
		mgrPre.lineList = {};
		return false;
	end

	self:ReqLineInfo(mgrPre.curSceneId);
	return true;
end

return MapMgr