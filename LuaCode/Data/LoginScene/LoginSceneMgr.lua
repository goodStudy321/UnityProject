--region LoginSceneMgr.lua
--Date
--此文件由[HS]创建生成

LoginSceneMgr = {Name="LoginSceneMgr"}
local M = LoginSceneMgr
local sMgr = SceneMgr

M.GOBJ = {}
M.GOBJ.Login = {}
M.GOBJ.Character = {}

M.Player = {}

function M:Init()
	iTrace.eLog("hs", "初始化LoginSceneMgr, 注册登入游戏结束事件")
	--self.ChangeEndEvent = EventHandler(self.OnChangeEndEvent, self)
	--self:SetEvent(EventMgr.Add)
end

function M:Remove()
	--self:SetEvent(EventMgr.Remove)
end

--// 添加监听
function M:AddEvent()
	local EMA = EventMgr.Add;
    local EH = EventHandler;
	EMA("HideAllCharNode", EH(self.HideAllCharNode, self));
	EMA("ShowFemaleNode", EH(self.ShowFemaleNode, self));
	EMA("ShowMaleNode", EH(self.ShowMaleNode, self));
end

--// 移除监听
function M:RemoveEvent()
	local EMR = EventMgr.Remove;
    local EH = EventHandler;
	EMR("HideAllCharNode", EH(self.HideAllCharNode, self));
	EMR("ShowFemaleNode", EH(self.ShowFemaleNode, self));
	EMR("ShowMaleNode", EH(self.ShowMaleNode, self));
end

function M:SetEvent(fn)
	--fn("OnEnterLogin", self.ChangeEndEvent)
	--sMgr.eChangeEndEvent[fn](sMgr.eChangeEndEvent, self.OnChangeEndEvent, self)
end

function M:OnChangeEndEvent()
	iTrace.eLog("hs", "登入游戏成功回调OnChangeEndEvent")
	self:GetSceneGOBJ()
	self:ShowLogin();
end

function M:GetSceneGOBJ()
	iTrace.eLog("hs", "获取场景角色对象。。。")
	if not self.GOBJ or not self.GOBJ.Login then return end
	local login = self.GOBJ.Login
	local character = self.GOBJ.Character
	local T = TransTool.FindChild

	local Character = GameObject.Find("Character").transform;
	login.FX = T(Character,"Character_Login");
	login.mpObj = T(Character,"Character_Login/MP");
	login.lpObj = T(Character,"Character_Login/LP");

	character.FX = T(Character,"Character_Create");
	character.mpObj = T(Character,"Character_Create/MP");
	character.lpObj = T(Character,"Character_Create/LP");
	character.hLightObj = T(Character,"Character_Create/Light_Creation");
	character.lLightObj = T(Character,"Character_Create/Light_Creation_low");


	local camRoot = GameObject.Find("Camera_Object")
	login.Camera = T(camRoot.transform, "Camera_Login")
	character.Camera = T(camRoot.transform, "Camera_Character")

	local locCam = login.Camera:GetComponent(typeof(Camera));
	locCam.allowMSAA = false;
	local chaCam = character.Camera:GetComponent(typeof(Camera));
	chaCam.allowMSAA = false;

	local player = self.Player
	local root = character.FX.transform
	
	player.maleH = T(root,"Test_Character/shushannan");
	player.femaleH = T(root,"Test_Character/shushannv");

	player.maleL = T(root,"Test_Character/shushannan_low");
	player.femaleL = T(root,"Test_Character/shushannv_low");

	player.malePot = T(root,"Test_Character/MaleStandPoint");
	player.femalePot = T(root,"Test_Character/FemaleStandPoint");

	--// 转换场景高低材质
	--QualityMgr.instance:ChangeSceneToCurQuality();

	local modelName = Device.Instance.Model;
	local curLv = 0;
	for k, v in pairs(MobileInfo) do
		if v.motype == modelName then
			curLv = v.quility;
			break;
		end
	end
	if curLv <= 0 then
		if App.platform == Platform.iOS or App.platform == Platform.PC then
			curLv = 3;
		else
			curLv = 1;
		end
	end
	M.curLv = curLv;
	QualityMgr.instance:ChangeQualityByIndex(curLv);

	--// 根据机型高低配置展示不同节点
	if player.maleH == nil or player.femaleH == nil then
		player.Male = player.maleL;
		player.Female = player.femaleL;
	elseif player.maleL == nil or player.femaleL == nil then
		player.Male = player.maleH;
		player.Female = player.femaleH;
	else
		player.maleH:SetActive(false);
		player.femaleH:SetActive(false);

		player.maleL:SetActive(false);
		player.femaleL:SetActive(false);

		if curLv > 0 then
			if curLv == 1 then
				player.Male = player.maleL;
				player.Female = player.femaleL;
			elseif curLv == 2 or curLv == 3 then
				player.Male = player.maleH;
				player.Female = player.femaleH;
			end
		else
			if App.platform == Platform.iOS or App.platform == Platform.PC then
				player.Male = player.maleH;
				player.Female = player.femaleH;
			else
				player.Male = player.maleL;
				player.Female = player.femaleL;
			end
		end
		-- if App.isEditor == true then
		-- 	player.Male = player.maleH;
		-- 	player.Female = player.femaleH;
		-- else
		-- 	if curLv > 0 then
		-- 		if curLv == 1 then
		-- 			player.Male = player.maleL;
		-- 			player.Female = player.femaleL;
		-- 		elseif curLv == 2 or curLv == 3 then
		-- 			player.Male = player.maleH;
		-- 			player.Female = player.femaleH;
		-- 		end
		-- 	else
		-- 		if App.platform == Platform.iOS or App.platform == Platform.PC then
		-- 			player.Male = player.maleH;
		-- 			player.Female = player.femaleH;
		-- 		else
		-- 			player.Male = player.maleL;
		-- 			player.Female = player.femaleL;
		-- 		end
		-- 	end
		-- end
	end

	self:ChangeNodeToQuality(curLv);
	MapHelper.instance:ChangeLoginCamQuality(login.Camera, curLv);
	MapHelper.instance:ChangeCharacterCamQuality(character.Camera, curLv);
	
	if player and player.Male then
		QualityMgr.instance:ChangeGoQuality(player.Male)
	else
		iTrace.eError("hs","Male模型获取为空")
	end
	if player and player.Female then
		QualityMgr.instance:ChangeGoQuality(player.Female)
	else
		iTrace.eError("hs","Female模型获取为空")
	end

	if character.FX ~= nil then
		player.sceneObj = T(character.FX.transform, "Scene_Object/HideNode");
	end
end

function M:ShowLogin()
	local login = self.GOBJ.Login
	local character = self.GOBJ.Character

	--login.FX:SetActive(true);
	--character.FX:SetActive(false);
	self:Change(login, character);

	self:ChangeNodeToQuality(M.curLv);
	MapHelper.instance:ChangeLoginCamQuality(login.Camera, M.curLv);
	MapHelper.instance:ChangeCharacterCamQuality(character.Camera, M.curLv);

	MapHelper.instance:SetCurRenderCamByObj(login.Camera, false);
end

function M:ShowCharacter()
	local login = self.GOBJ.Login
	local character = self.GOBJ.Character

	--login.FX:SetActive(false);
	--character.FX:SetActive(true);
	self:Change(character, login);

	self:ChangeNodeToQuality(M.curLv);
	MapHelper.instance:ChangeLoginCamQuality(login.Camera, M.curLv);
	MapHelper.instance:ChangeCharacterCamQuality(character.Camera, M.curLv);

	MapHelper.instance:SetCurRenderCamByObj(character.Camera, false);
end

--// 转换节点到当前质量等级
function M:ChangeNodeToQuality(curLv)

	local login = self.GOBJ.Login;
	local character = self.GOBJ.Character

	--// 最高质量
	if curLv >= 3 then
		if login.mpObj ~= nil then
			login.mpObj:SetActive(true);
		end
		if login.lpObj ~= nil then
			login.lpObj:SetActive(true);
		end

		if character.mpObj ~= nil then
			character.mpObj:SetActive(true);
		end
		if character.lpObj ~= nil then
			character.lpObj:SetActive(true);
		end
		if character.hLightObj ~= nil then
			character.hLightObj:SetActive(true);
		end
		if character.lLightObj ~= nil then
			character.lLightObj:SetActive(false);
		end
	--// 中质量
	elseif curLv == 2 then
		if login.mpObj ~= nil then
			login.mpObj:SetActive(false);
		end
		if login.lpObj ~= nil then
			login.lpObj:SetActive(true);
		end

		if character.mpObj ~= nil then
			character.mpObj:SetActive(false);
		end
		if character.lpObj ~= nil then
			character.lpObj:SetActive(true);
		end
		if character.hLightObj ~= nil then
			character.hLightObj:SetActive(true);
		end
		if character.lLightObj ~= nil then
			character.lLightObj:SetActive(false);
		end
	--// 最低质量
	else
		if login.mpObj ~= nil then
			login.mpObj:SetActive(false);
		end
		if login.lpObj ~= nil then
			login.lpObj:SetActive(true);
		end

		if character.mpObj ~= nil then
			character.mpObj:SetActive(false);
		end
		if character.lpObj ~= nil then
			character.lpObj:SetActive(false);
		end
		if character.hLightObj ~= nil then
			character.hLightObj:SetActive(false);
		end
		if character.lLightObj ~= nil then
			character.lLightObj:SetActive(true);
		end
	end
end

function M:Change(show, hide)
	if show then
		for k,v in pairs(show) do
			v:SetActive(true)
		end
	end
	if hide then
		for k,v in pairs(hide) do
			v:SetActive(false)
		end
	end
end

function M:SelectPlayer(sex)
	local player = self.Player
	local male = player.Male
	local female = player.Female
	--if male then male:SetActive(sex == 1) end
	--if female then female:SetActive(sex == 0) end
end

--// 隐藏所有角色节点
function M:HideAllCharNode()
	local player = self.Player
	if player ~= nil then
		if player.Male ~= nil then
			player.Male:SetActive(false);
		end
		if player.Female ~= nil then
			player.Female:SetActive(false);
		end
	end
	if player.sceneObj ~= nil then
		player.sceneObj:SetActive(false);
	end
end

--// 显示女性角色节点
function M:ShowFemaleNode()
	local player = self.Player
	if player ~= nil then
		if player.Male ~= nil then
			player.Male:SetActive(false);
		end
		if player.Female ~= nil then
			player.Female:SetActive(true);
		end
	end
	if player.sceneObj ~= nil then
		player.sceneObj:SetActive(true);
	end
end

--// 显示男性角色节点
function M:ShowMaleNode()
	local player = self.Player
	if player ~= nil then
		if player.Male ~= nil then
			player.Male:SetActive(true);
		end
		if player.Female ~= nil then
			player.Female:SetActive(false);
		end
	end
	if player.sceneObj ~= nil then
		player.sceneObj:SetActive(true);
	end
end

function M:ShowPlatform()
	local player = self.Player
	if player.sceneObj ~= nil then
		player.sceneObj:SetActive(true);
	end
end

--// 根据性别获取站立位置
function M:GetStandPos(sexIndex)
	local player = self.Player

	if sexIndex == 0 then
		if player ~= nil and player.malePot ~= nil then
			return player.malePot.transform.position;
		end
	elseif sexIndex == 1 then
		if player ~= nil and player.femalePot ~= nil then
			return player.femalePot.transform.position;
		end
	end

	iTrace.Error("LY", "Sex index error !!! ");
	return Vector3.new(0, 0, 0);
end

function M:Clear()
end

function M:Close()
	local player = self.Player
	local male = player.Male
	local female = player.Female
	if male then male:SetActive(false) end
	if female then female:SetActive(false) end
end

function M:Dispose()	
	self:Remove()
end

return M
