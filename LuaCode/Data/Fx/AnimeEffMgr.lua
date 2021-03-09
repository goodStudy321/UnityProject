--// 过场动画特效管理器 

AnimeEffMgr = Super:New{Name = "AnimeEffMgr"}

local mgrPre = {};
local iLog = iTrace.eLog;
local iError = iTrace.Error;
local eError = iTrace.eError;
local ET = EventMgr.Trigger;


--// 初始化
function AnimeEffMgr:Init()
	if mgrPre.init ~= nil and mgrPre.init == true then
 		return;
	end
	 
	--// 帮派等级配置
	mgrPre.lvCfg = FamilyLvCfg;

 	--iLog("LY", " AnimeEffMgr create !!! ");
 	mgrPre.init = false;
	
	self:AddLsnr();

 	mgrPre.init = true;
end

--// 添加监听
function AnimeEffMgr:AddLsnr()
	mgrPre.openFxWndHandler = EventHandler(self.OpenFxWnd, self);
	EventMgr.Add("PlayAnimeEff", mgrPre.openFxWndHandler);

	mgrPre.stopFxWndHandler = EventHandler(self.StopFxWnd, self);
	EventMgr.Add("StopAnimeEff", mgrPre.stopFxWndHandler);
end

function AnimeEffMgr:Clear()
	mgrPre.init = false;
end

function AnimeEffMgr:Dispose()
	EventMgr.Remove("PlayAnimeEff", mgrPre.openFxWndHandler);
	EventMgr.Remove("StopAnimeEff", mgrPre.stopFxWndHandler);
end

function AnimeEffMgr:OpenFxWnd(fxIndex)
	UIMgr.Open(AnimeFxWnd.Name, function()
		AnimeFxWnd:PlayFx(fxIndex)
	end)
end

function AnimeEffMgr:StopFxWnd(fxIndex)
	UIMgr.Close(AnimeFxWnd.Name);
end

return AnimeEffMgr

