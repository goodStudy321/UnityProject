UIExitMap = UIBase:New{Name ="UIExitMap"}
local My = UIExitMap
My.EndCb = Event()
local base = UIBase
require("UI/UIBoss/bossTmdn");

function My:InitCustom()
	My.ext=false;
	local name = "离开地图进度条";
	local go = self.gbj;
	local CG = ComTool.Get;
	local TF = TransTool.FindChild;
	local trans = TF(go.transform,"bg",name).transform;
	self.SliderCom = CG(UISlider,trans,"Slider",name,false);
	self.Value = CG(UILabel,trans,"Value",name,false);
	self.SliderCom.value = 0;
	local mapId = User.instance.SceneId
	local bossPlace = SceneTemp[tostring(mapId)].mapchildtype;
	if bossPlace==1 then
		My:WorldInit();
	elseif  bossPlace==2  then
		My:HomeInit()
	elseif bossPlace==4 or bossPlace==17 then 
		My:wildInit();
	elseif bossPlace==16 then
		My:selfIslInit();
	end
	--释放与否控
	local EH = EventHandler;
	self.OnChange = EH(self.disChange, self);
	EventMgr.Add("BegChgScene",self.OnChange);
	EventMgr.Add("OnChangeScene",self.OnChangeScene);
	self.cfg.cleanOp=0;
	--刘海
	if ScreenMgr.orient==ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, "bg", name, true);
	end
	ScreenMgr.eChange:Add(self.ScreenChange, self);
	My.gbj:SetActive(true);
end
function My:OnChangeScene()
	local ui = UIMgr.Get(UICountDownTip.Name)
	if ui then 
		ui:EndDown()
		UIMgr.Close(UICountDownTip.Name) 
	end

	local mapId = User.instance.SceneId
	local bossPlace = SceneTemp[tostring(mapId)].mapchildtype;
	if bossPlace==1 then
		My:WorldInit();
	elseif  bossPlace==2  then
		My:HomeInit()
	elseif bossPlace==4 or bossPlace==17 then 
		My:wildInit();
	elseif bossPlace==16 then
		My:selfIslInit();
	end
	My.gbj:SetActive(true);
end
function My:OpenCustom( )
	My.gbj:SetActive(true);
end

function My:openOninfo(  )
	self:updataCaveShow( )
end
--刘海旋转
function My:ScreenChange(orient)
	if orient == ScreenOrient.Left then
		UITool.SetLiuHaiAnchor(self.root, "bg", nil, true)
	elseif orient == ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.root, "bg", nil, true, true)
	end
end

function My:disChange( )
	self.cfg.cleanOp=1;
	self.active = 1
	self:Close()
	self:DisposeCustom()
end
--世界加载
function My:WorldInit( )
	self.ValueCon="挑战次数：";
	self.maxTime=NetBoss.GetBossAllTime();
	self.nowTime=NetBoss.WorldTimes;
	self:WorldShow(self.nowTime,self.maxTime);
	self:lsnrkill();
end
--洞天加载
function My:HomeInit( )
	self.ValueCon="挑战次数：";
	self.maxTime=NetBoss.GetAllCaveTimes();
	self.nowTime=NetBoss.GetLessCaveTimes();
	self:WorldShow(self.nowTime,self.maxTime);
	NetBoss.eCaveTimes:Add(self.updataCaveShow,self);
	VIPMgr.eVIPLv:Add(self.openOninfo, self);
	VIPMgr.eUpInfo:Add(self.openOninfo, self);
end
--神兽岛加载
function My:selfIslInit( )
	self.ValueCon="挑战次数：";
	self.maxTime=NetBoss.GetAllIslTimes();
	self.nowTime=self.maxTime-NetBoss.islTimes;
	self:WorldShow(self.nowTime,self.maxTime);
	NetBoss.eUseAddIsl:Add(self.upIslShow,self);
	NetBoss.eIsland:Add(self.upIslShow,self);
end
--监听疲劳改变
function My:lsnrkill( )
	NetBoss.eUpTieTime:Add(self.updataShow,self);
end

function My:upIslShow( )
	self.maxTime=NetBoss.GetAllIslTimes();
	self.nowTime=self.maxTime-NetBoss.islTimes;
	self:WorldShow(self.nowTime,self.maxTime);
	if self.nowTime==0 then
		local desc = string.format("本日挑战次数已用完，将无法攻击\nboss"); 
		MsgBox.ShowYes(desc, self.YesCb,self, "确定")
	end
end

function My:BossYesCb(  )
	BossHelp.OpenBoss(2,1);
end

function My:NoCd(  )

end

function My:updataCaveShow( )
	self.maxTime=NetBoss.GetAllCaveTimes();
	self.nowTime=NetBoss.GetLessCaveTimes();
	if self.nowTime==0 then
		local desc = string.format("本日挑战次数已用完，将无法攻击\nboss"); 
		MsgBox.ShowYes(desc, self.YesCb,self, "确定")
	end
	self:WorldShow(self.nowTime,self.maxTime);
end

function My:updataShow( )
	self.maxTime=NetBoss.GetBossAllTime();
	self.nowTime=NetBoss.WorldTimes;
	self:WorldShow(self.nowTime,self.maxTime);
	-- if self.nowTime==0 then
	-- 	local homeLock=SceneTemp["90021"].unlocklv
	-- 	local lv = User.instance.MapData.Level
	-- 	if lv<homeLock then
	-- 		local desc = string.format("本日挑战次数已用完，将无法攻击\nboss"); 
	-- 		MsgBox.ShowYes(desc, self.YesCb,self, "确定")
	-- 	else
	-- 		local desc = string.format("本日挑战世界Boss次数已用完，\n是否前往洞天福地"); 
	-- 		MsgBox.ShowYesNo(desc, self.BossYesCb,self, "前往",self.NoCd,self,"取消")
	-- 	end
	-- end
end
function My:YesCb( )
	return;
end
--设置显示状态
function My:WorldShow(now,max)
	if self.SliderCom ~= nil then
		local pro = now/max;
		self.SliderCom.value = pro;
	end
	if self.Value ~= nil then
		self.Value.text = string.format("挑战次数：%d/%d",now,max);
	end
end

--蛮荒加载
function My:wildInit( )
	self:lsnrTime();
	bossTmdn:Init();
	self.endTime = false;
end

function My:lsnrTime( )
	NetBoss.eReChgTime:Add(self.ReChgTime,self);
	bossTmdn.eChange:Add(self.RefreshUI,self);
	bossTmdn.eEnd:Add(self.EndCountDown,self);
end
function My:lsnrTimeRv( )
	NetBoss.eReChgTime:Remove(self.ReChgTime,self);
	bossTmdn.eChange:Remove(self.RefreshUI,self);
	bossTmdn.eEnd:Remove(self.EndCountDown,self);
	UICountDownTip.EndCb:Remove(self.ExitC,self);
end
function My:ReChgTime()
	bossTmdn:reTime();
end

function My:RefreshUI(pro,min)
	local pro = 1-pro
	local min = 100-min
	min = min<0 and 0 or min
	if self.SliderCom ~= nil then
		self.SliderCom.value = pro;
	end
	if self.Value ~= nil then
		self.Value.text = string.format("怒气值：%d",min);
	end
end

function My:InvCountDown()
	self:UpdateSlider();
end

function My:EndCountDown()
	if My.ext then
		return
	end
	self.endTime = true;
	self:RefreshUI(1,100);
	UIMgr.Open(UICountDownTip.Name,self.OpenCB,self);
	self.EndCb();
end
local ExitMap = 0
function My:OpenCB(name)
	local ui = UIMgr.Get(name)
	if ui then ui:UpdateData(GlobalTemp["43"].Value3,"秒后退出地图") end
	ExitMap=User.instance.SceneId
	UICountDownTip.EndCb:Add(self.ExitC,self);
	My.ext=true;
end
--退出
function My:ExitC()
	My.ext=false;
	local mapId = User.instance.SceneId
	if ExitMap ~= mapId then
		return
	end
	SceneMgr:QuitScene();
end
function My:DisposeCustom()
	self:lsnrTimeRv();
	EventMgr.Remove("BegChgScene",self.disChange);
	EventMgr.Remove("OnChangeScene",self.OnChangeScene);
	NetBoss.eUpTieTime:Remove(self.updataShow,self);
	NetBoss.eUseAddIsl:Remove(self.upIslShow,self);
	NetBoss.eIsland:Remove(self.upIslShow,self);
	NetBoss.eCaveTimes:Remove(self.ReChgTime,self);
	VIPMgr.eVIPLv:Remove(self.openOninfo, self);
	VIPMgr.eUpInfo:Remove(self.openOninfo, self);
	ScreenMgr.eChange:Remove(self.ScreenChange, self);	
	self.EndCb:Clear();
	if LuaTool.IsNull(self.gbj) then
		return
	end
	self.SliderCom = nil;
	self.Value = nil;
	self.endTime = nil;
	Destroy(self.gbj)
	AssetMgr:Unload(self.Name..".prefab")
	UIMgr.Dic[self.Name]=nil
end


return My
