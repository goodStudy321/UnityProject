local AssetMgr = Loong.Game.AssetMgr
QuickUseMgr = {Name = "QuickUseMgr"}
local My = QuickUseMgr

local root = nil
local attNAME = {"hp","atk","def","arm"}

local openList = {} --存唯一id
My.openList2 = {} --存道具id
local curId = nil
local curNum = 1
local curTb = nil
local otherQuickUse=nil
My.isBegin = true
-- My.timer=ObjPool.Get(iTimer)

My.type_id=nil
My.num=nil
My.id=nil
My.time=nil
My.text=nil
My.des=nil
My.isDirUse=nil
local isFirst = true
My.eEndSprite=Event()
My.eJump=Event()
isWaitCheck=false
local isfirstcheck = true

My.cooltime = 0--沙之丹冷却时间

function My.Init()
	root = GameObject.Find("UI Root/Camera")
	PropMgr.eAdd:Add(My.OnQuickUse)
	PropMgr.eAddNum:Add(My.AddNum)
	QuickUsePro.eDispose:Add(My.DealItem)

	-- My.timer=ObjPool.Get(iTimer)
	-- My.timer.complete:Add(My.DealItem)

	--SceneMgr.eChangeEndEvent:Add(My.OffLine)
	EventMgr.Add("AllAnimFinish",My.AllAnimFinish)
	FindBackMgr.eStartBacK:Add(My.OnStartBacK)
	RobberyMgr.eUpInfo:Add(My.OnUpInfo)
	SceneMgr.eChangeEndEvent:Add(My.ChangeEnd)
	My:CreateTimer()
end

function My.OnUpInfo()
	if isfirstcheck==true then
		My.OnInfo()
		EventMgr.Add("OnChangeLv",EventHandler(My.OnChangeLv))
	end
end

function My.OnChangeLv()
	My.OnInfo()
end

function My.OnInfo()
	if User.instance.MapData.Level<90 then return end
	for k,v in pairs(PropMgr.tbDic) do
		local data = UIMisc.FindCreate(v.type_id)
		local isuse = My.CanUse(data)
		if data.canQuick==1 and data.uFx==1 and v.isUp==true and isuse==true then 
			table.insert(openList,tonumber(k))
		end
	end
	if My.isBegin==false then 
		if isfirstcheck==false then isWaitCheck=true end
		return 
	end
	isWaitCheck=false
	isfirstcheck=false
	if #openList==0 then return end
	My.DealItem()
end

function My.AllAnimFinish()
	local dic = openList
	if My.isBegin==false then return end
	My.DealItem()
end

function My.ChangeEnd()
	local dic = openList
	if My.isBegin==false then return end
	My.DealItem()
end

function My.OnStartBacK(state)
	if state==false and My.isBegin==true then
		My.DealItem()
	end
end

--离线挂机卡
-- function My.OffLine()
-- 	if My.isBegin==true then 
-- 		My.DealItem()
-- 	end

-- 	local lv = GlobalTemp["93"].Value3
-- 	if User.instance.MapData.Level<lv then return end
-- 	if SceneMgr.IsInitEnterScene==true then 
-- 		local time=OffRwdMgr.GetOffTime()	
-- 		if time<12 then
-- 			My.openList2[#My.openList2+1]=31010
-- 			if My.isBegin==false then return end
-- 			table.remove(My.openList2, 1)

-- 			local des="剩余不足十二小时"	
-- 			QuickUseMgr.OpenQuickUse(31010,1,nil,nil,"购买","离线挂机卡",des,false)
-- 		end
-- 	end	
-- end

function My.OnQuickUse(tb,action,tp)
	if tp~=1 then return end
	local item=ItemData[tostring(tb.type_id)]
	if(tb.isUp==false and item.uFx==1)then 
		return 
	end
	My.AddNum(tb.type_id,tb.num,action,tb.id)
end

function My.AddNum(type_id,num,action,id)
	if(action==10101)then return end
	if (action==10378) then return end --炼丹炉抽奖
	-- if (action==10385) then return end --渡劫成功
	local type_id = tostring(type_id)
	local item = UIMisc.FindCreate(type_id)
	local use = My.CanUse(item)
	if(item.canQuick==1 and use==true)then
		for i,v in ipairs(openList) do
			local tb = PropMgr.tbDic[tostring(v)]
			if tb and tostring(tb.type_id)==type_id then return end
		end
		openList[#openList + 1] = id
	end
	if My.isBegin==false then return end
	My.DealItem()
end

function My.DealItem()
	if #My.openList2>0 then
		local id = My.openList2[1]
		table.remove( My.openList2, 1)
		if id==31010  then 
			--My.OffLine()
		elseif id==100 then
			My.OpenFindBack(true)
		else
			local item=ItemData[tostring(id)]
			if not item then iTrace.eError("xiaoyu","道具表为空 id: "..tostring(id))return end
			local tipName=item.name.."已过期"
			local des="剩余0小时"    
			QuickUseMgr.OpenQuickUse(id,1,nil,30,"查看",tipName,des,false) 
		end
		return
	end
	if isFirst==true and GuardMgr.isendSprite==true then
		isFirst=false
		My.eEndSprite()
		return 
	end
	if #openList==0 then 
		if isWaitCheck==true then My.OnInfo() end return 
	end
	if CutscenePlayMgr.instance.IsPlaying == true then return end
	local isactive = My.CheckActive()
	if isactive==true then return end
	local index = #openList
	local id = openList[index]
	local tb = PropMgr.tbDic[tostring(id)]
	table.remove( openList,index) 
	if tb==nil then 
		My.DealItem()
		return 
	end
	local type_id = tb.type_id
	local num = PropMgr.TypeIdByNum(type_id)
	if num==0 then return end
	local item = UIMisc.FindCreate(type_id)
	local isup = true
	if item.uFx==1 then 
		num=1 
		isup=tb.isUp or false
	end
	if isup==false then
		My.DealItem()
		return 
	end
	curId=id
	curNum=num
	if My:IsCooltime(tb.type_id) then 
		My.DealItem()
		return 
	end
	UIMgr.Open(QuickUsePro.Name,My.QuickCb)
end

--检测结算面板是否打开
function My.CheckActive()
	local ui1=UIMgr.Get(UIEndPanelT.Name)
	if ui1 and ui1.active==1 then return true end
	local ui2=UIMgr.Get(UIEndPanel.Name)
	if ui2 and ui2.active==1 then return true end
end

function My.QuickCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		local type_id = PropMgr.tbDic[tostring(curId)].type_id
		ui:UpData(type_id,curNum,curId)
	end
end

-- function My.DealItem()
-- 	My.timer:Stop()
-- 	My.timer.seconds=0.1
-- 	My.timer:Start()
-- end

function My.CanUse(item)
	local lv = item.useLevel or 0
	local gg = item.gilgulLv or 0
	local cate = item.cateLim or 0
	local vip=item.useVIP or 0
	local realm = item.realm or 0 --境界
	if(cate~=0 and User.instance.MapData.Category~=cate)then
		return false
	end
	if(gg~=0 and RebirthMsg.RbLev<gg)then
		return false
	end
	if(lv~=0 and User.instance.MapData.Level<lv)then
		return false
	end
	if(vip~=0 and VIPMgr.GetVIPLv()<vip)then
		return false
	end
	local robcfg = RobberyMgr:GetCurCfg()
	if(realm~=0 and (not robcfg or robcfg.id)<realm)then
		return false
	end
	return true
end

function My.CompareFight(tb)
	local item = ItemData[tostring(tb.type_id)]
	if item.uFx==28 then
		if GuardMgr.guard==0 then return true 
		elseif GuardMgr.guard==40002 then return false 
		elseif GuardMgr.guard==40001 and tb.type_id==40002 then return true 
		else return false end		
	elseif item.uFx==1 then 
		local part = PropTool.FindPart(tostring(tb.type_id))
		local wear=EquipMgr.hasEquipDic[part]
		if(wear==nil)then return true 
		else
			local wearF = wear.fight
			local fight = PropMgr.fightDic[tostring(tb.id)]
			if(fight>wearF)then return true
			else return false end
		end
	else
		return true
	end
end

function My.OpenUse()
	UIMgr.Open(QuickUsePro.Name,My.UseCb)
end

function My.UseCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpData(openList[1])
	end
end

--限时道具跳转
function My:LimJump(item,id)
	if not item.time then return end
	self.item = item
	self.tb = PropMgr.tbDic[tostring(id)]
	if not self.tb then return end
	if self.tb.bind  == true then return end
	local now =  TimeTool.GetServerTimeNow()*0.001
	local endTime = now - self.tb.market_end_time;
	if self.item.startPrice and endTime and self.item.AucSecId then
		if self.tb.market_end_time ~= 0 then
			UIMgr.Open(ShelfTip.Name,self.ShelfTipCB,self)
			return true
		end
	end
end

function My:ShelfTipCB(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpData(self.tb)
	end
end

--道具使用  -- value 限时道具专用
function My.PropUse(item,id,num,value)	
	if(item.canUse~=1)then UITip.Log("不能使用") return end
	local useLv = item.useLevel or 1
	if User.MapData.Level < useLv then UITip.Log("等级不足") return end
	if not value then
		local isLimJump = My:LimJump(item,id)
		if isLimJump==true then return isLimJump end
	end
	My.PropNotLimitUse(item,id,num)
end

function My.PropNotLimitUse(item,id,num)
	My.item=item
	My.id=id
	My.num=num or 1
	local isjump=My.JumpOther(item)
	if isjump==true then return isjump end
	if item.uFx==45 then 
		My.UFx45()
	elseif item.uFx==43 then 
		My.UFx43()
	elseif item.uFx==42 then		
		My.UFx42()
	elseif item.uFx==33 then
		My.UFx33()
	elseif item.uFx==75 then
		My.UFx75()
	-- elseif item.uFx == 26 then
	-- 	My.UFx26()
	elseif(item.overlayNum>1 and My.num>1)then
		My.BatchUse()
	else			
		My.DirectUse()
	end
end

--跳转其他界面
function My.JumpOther(item)
	local jump = item.jump
	if jump then 
		local name = jump[1]
		local tp = jump[2]
		local mas = jump[3]
		My.Jump(name,tp,mas,item.id)
		return true
	end
	return false
end

function My.Jump(name,tp,mas,id,isEvent)
	if tp then tp=tonumber(tp) end
	if mas then mas=tonumber(mas) end
	if tp==nil and mas==nil then 
		if name=="UIFamilyBossIt" and not CustomInfo:IsJoinFamily() then My.GoToJoin() return end
		if name=="GiveRedPacket" then FamilyMgr:GiveRedPByItem(id)  end
		if name=="UIFamilyMainWnd" and not CustomInfo:IsJoinFamily() then
			My.GoToJoin()
			return
		end
		if name == "UIEscort" then EscortMgr:NavEscort()  end
		if name=="FirstChangePack" then My.FirstChangePack()  end
		if name=="UIPicCollect" then PicCollectMgr:OpenForId(id)  end
		if name == UICloudBuy.Name then CloudBuyMgr.OpenCloudy() end
		if name == UIRankActiv.Name then UIRankActiv:OpenTab(7)  end
		if name == UIWish.Name then
			if FestivalActMgr:IsOpen(FestivalActMgr.XYC) or LivenessInfo:IsOpen(1028) then
				UIMgr.Open(name)
			else
				UITip.Log("活动未开启")
				return
			end
		end
		if name == "UIFamilyMission" then
			if CustomInfo:IsJoinFamily() == false then My.GoToJoin()  return end
			if OpenMgr:IsOpen(33) == false then  UITip.Log("系统未开启")  return end
		end
		if name==UIFamilyEscort.Name then
			if CustomInfo:IsJoinFamily() == false then 
				My.GoToJoin() 
				return
			elseif not FamilyEscortMgr:GetOpenStatus() then
				UITip.Log("活动未开启")
				return
			end
		end
		if name == UIRushBuy.Name then
			local isOpen = My.IsActiveOpen(134)
			if isOpen == false then UITip.Log("活动未开启")  return end
		end
		UIMgr.Open(name)
	elseif name=="UIEquip" then
		EquipMgr.OpenEquip(tp,mas,id)
	elseif name=="UIAdv" then
		if mas == 0 then
			AdvMgr:OpenBySysID(tp,1,3021100)
		else
			AdvMgr:OpenBySysID(tp,mas,id)
		end
	elseif name=="UITreasure" then
		UITreasure:OpenTab(tp)
	elseif name=="UIFashionPanel" then
		UIFashionPanel:Show(tp, id)
	elseif name=="UIFamilyBossIt" then
		CustomInfo:IsJoinFamily()
	elseif name=="UIMarry" then
		UIMarry:OpenTab(tp)
	elseif name=="UIRobbery" then
		if tp == 4 then 
			UIRobbery:OpenRobbery(tp,mas)
		else
			UIRobbery:OpenRobbery(tp)
		end
	elseif name=="UIFlowers" then
		FlowersMgr:OpenUI(tp)
	elseif name == "UITransApp" then
		UITransApp.OpenTransApp(tp,id)
	-- elseif name=="UIPicCollect" then
	-- 	PicCollectMgr:OpenUI(tp)
	elseif name == "UILvAward" then
		UILvAward:OpenTab(tp)
	elseif name == "UICopy" then
		local isOpen,copyType = My.OpenCopy(tp,mas)
		if isOpen == false then
			return
		end
		UICopy:Show(copyType)
	elseif name == "UIRebirth" then
		UIRebirth.OpenRbLvTab(tp)
	elseif name == "UIBoss" then
		My.OBoss(tp)
	elseif name=="UIStore" then
		if tp==98 then
			if not CustomInfo:IsJoinFamily() then
				My.GoToJoin()
				return
			end			
		end
		StoreMgr.OpenSelectId(id,tp)
	elseif name=="UIVIP" then
		VIPMgr.OpenVIP(tp)
	elseif name == UIPicCollect.Name then
		PicCollectMgr:OpenUI(tp)
	elseif name=="UISuit" then
		SuitMgr.OpenSuit(tp)
	elseif name == "UIBenefit" then
		UIBenefit:Show(tp)
	elseif name==UICompound.Name then
		UICompound:SwitchTg(tp,mas,id)
	elseif name == "UIPetDevourPack" then
		UIPetDevourPack.OpenPetDevPack()
	elseif name == "UIArena" then
		local isOpen = UITabMgr.IsOpen(ActivityMgr.JJD)
		if isOpen == false then
			UITip.Log("系统未开启")
			return
		end
		UIArena.OpenArena(tp)
	elseif name==UIFamilyEscort.Name then
		if not CustomInfo:IsJoinFamily() then
			My.GoToJoin()
			return
		elseif not FamilyEscortMgr:GetOpenStatus() then
			UITip.Log("活动未开启")
			return
		end
		UIMgr.Open(UIFamilyEscort.Name)
	elseif name==UILimitActiv.Name then
		UILimitActiv:OpenTab(tp)
	elseif name == "UIRole" and tp == 5 then--丹药
		UIElixir.selectId = id
		UIRole:SelectOpen(5)
	elseif name==UIRole.Name then 
		UIRole:SelectOpen(tp)
	elseif name==UIHeavenLove.Name then
		HeavenLoveMgr.OpenUI(tp)
	else
		if name == "UIAlchemy" then
			local info = FestivalActMgr:GetActInfo(tp)
			if not info then UITip.Log("活动未开启")  return end
		elseif name == "UIFamilyDepotWnd" then
			if CustomInfo:IsJoinFamily() == false then My.GoToJoin()  return end
		end
		UITabMgr.OpenByIdx(name, tp, mas, id)
	end
	if isEvent==true then My.eJump() end
end

--判断活动是否开启
function My.IsActiveOpen(activityId)
	local isopen=true
	local key = tostring(activityId)
	local cfg = ActivityTemp[key]
	isopen = UITabMgr.IsOpen(cfg.type)
	return isopen
end

function My.GoToJoin()
	UITip.Log("你还没有道庭！")
	UIMgr.Open(UIFamilyListWnd.Name)
end

function My.FirstChPackCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then 
	   ui:UpData(35212)
	end
end

function My.FirstChangePack()
	UIMgr.Open(FirstChangePack.Name,My.FirstChangePackCb)
end

function My.FirstChangePackCb(name)
	local ui = UIMgr.Get(name)
	 if(ui)then 
		ui:UpData(My.item.id)
 	end
end


function My.OBoss(tp)
	BossHelp.curType = tp
	UIMgr.Open(UIBoss.Name)
end

function My.OpenCopy(tp,mas)
	local copyType = tp
	-- if tp == 1 then
	-- 	if mas == 1 then
	-- 		copyType = CopyType.Exp
	-- 	elseif mas == 2 then
	-- 		copyType = CopyType.SingleTD
	-- 	elseif mas == 3 then
	-- 		copyType = CopyType.Glod
	-- 	elseif mas == 4 then
	-- 		copyType = CopyType.ZLT
	-- 	end
	-- elseif tp == 2 then
	-- 	copyType = CopyType.Equip
	-- end
	local x,y,z,w = CopyMgr:GetCurCopy(copyType)
	if y==false then 
		UITip.Error("等级不足系统暂未开启")
		return false,copyType
	end
	return true,copyType
	-- UICopy:Show(copyType)
end

--自选防具道具
function My.UFx45()
	UIMgr.Open(SelectGift.Name,My.SelectGiftCb)
end

function My.SelectGiftCb(name)
	local ui = UIMgr.Get(name)
	 if(ui)then 
		ui:UpData(My.id)
 	end
end

--道庭改名卡
function My.UFx43()
	local isjoin = FamilyMgr:JoinFamily()
	local data = FamilyMgr:GetFamilyOwnerData()
	local owner = FamilyMgr.ChangeInt64Num(User.instance.MapData.UID)
	if isjoin==false then 
		UITip.Log("你仍未加入道庭，无法使用") 
	elseif not data or data.roleId~=owner then
		UITip.Log("只有盟主才可以更换道庭名字")
	else
		UIMgr.Open(UIChangeName.Name,My.ChangeNameCb)
	end
end

--角色改名卡
function My.UFx42()
	UIMgr.Open(UIChangeName.Name,My.ChangeNameCb)
end

function My.ChangeNameCb(name)
	local ui=UIMgr.Get(name)
	if ui then
		ui:UpData(My.item.id)
	end
end

--增加背包格子
function My.UFx33()
	UIMgr.Open(AddCellPanel.Name,My.AddCellPanel)
end

--藏宝图
function My.UFx75()
	local mgr = TreasureMapMgr
	local isTreasure = mgr.isTreasureUse
	local isTreasureT = mgr.isTreasureTeam
	if isTreasure == true and isTreasureT then
		UITip.Log("已有开启的藏宝图")
		return
	end
	local str = "藏宝洞异常凶险,需组队前往。\n队长可开启。"
	MsgBox.ShowYesNo(str,My.YesCb, My, "组队前往" , My.NoCb, My, "暂不前往")
end



function My.OKCb()
	PropMgr.ReqUse(My.item.id,1,1)
end

--teamState:
-- 1---> 为小队队长
-- 2---> 不是小队队长
-- 3---> 没有队伍
function My.YesCb()
	local propId = My.item.id
	local mgr = TreasureMapMgr
	mgr.usePropId = propId
	mgr.isTreasureUse = false
	mgr.isTreasureTeam = true
	local treasureInfo = mgr:GetTreasureInfo(propId)
	local x = treasureInfo.x/100
	local y = treasureInfo.y/100
	local z = treasureInfo.z/100
	local vecPos = Vector3.New(x,y,z)
	local sceneId = treasureInfo.sceneId
	User:StartNavPath(vecPos, sceneId, -1, 0)
end

function My.NoCb()
    
end

function My.AddCellPanel(name)
	local ui=UIMgr.Get(name)
	if ui then
		ui:UpData(1)
	end
end

function My.UFx26()
	local buffId = User:GetBuffIdBySrID(204)
	if buffId ~=0 and buffId ~= My.item.uFxArg[1] then
		MsgBox.ShowYesNo(string.format("已有经验药效果，是否使用%s替换？（替换后经验加成时间将重新计算）", My.item.name), My.OKCb, My, "确定")
	else
		My.OKCb()
	end
end

--批量使用
function My.BatchUse()
	UIMgr.Open(BatchUse.Name,My.BatchUseCb)
end

function My.BatchUseCb(name)
	local ui=UIMgr.Get(name)
	if ui then
		ui:UpData(My.item)
	end
end

--直接使用
function My.DirectUse()
	local id = My.item.id
	if My.item.uFx==27 then
		OffRwdMgr.UseOffItem(id)
	elseif My.item.uFx==26 then
		My.UFx26()
	else
		if id==35212 then  --首充特惠礼包
			local title = "是否花费"..My.item.uFxArg[1].."元宝开启该礼包？"
			MsgBox.ShowYesNo(title,My.UseCb)
		else
			My.UseCb()
		end		
	end
end

function My.UseCb()
	if My.id then
		PropMgr.ReqUse(My.id,My.num)
	else
		PropMgr.ReqUse(My.item.id,curNum,1)
	end
	
end

function My.OpenQuick(type_id,num,id,time,btnName,text,des,isDirUse)
	if My.isBegin==true then

	else

	end
end

--快速使用界面
function My.OpenQuickUse(type_id,num,id,time,btnName,text,des,isDirUse)
	if not time then time=10 end
	if not num then num=1 end
	My.type_id=type_id
	My.num=num
	My.id=id
	My.time=time
	My.btnName=btnName
	My.text=text
	My.des=des
	My.isDirUse=isDirUse
	UIMgr.Open(QuickUsePro.Name,My.QuickUseCb)
end

function My.QuickUseCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:UpData(My.type_id,My.num,My.id,My.time,My.btnName,My.text,My.des,My.isDirUse)
	end
end

function My.OpenFindBack(state)
	if state==true then UIMgr.Open(QuickUsePro.Name,My.doOtherMsgBack) return end
	if My.isBegin==false then My.openList2[#My.openList2+1]=100 return end	
end

function My.doOtherMsgBack( name )
    local ui = UIMgr.Get(name)
	if ui then
        QuickUsePro:UpdateFindBack(100,1,"资源找回","前往",My.openFindUI,My)
    end
end

function My:openFindUI( )
    UILiveness:OpenTab(3)
end

--判断是否处于冷却时间中
function My:IsCooltime(id)
	if id ~= 30403 then return false end
	if AdvMgr:IsLock(30211) == false then
		local isShow = AdvMgr:UpMwAction()
		return not isShow
	end
	if My.cooltime < 1 then
		self:UpTimer(1800)
		return false
	end
	return true
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
	My.cooltime = self.timer:GetRestTime()
end

--结束倒计时
function My:EndCountDown()
	My.cooltime = 0
end


function My.Clear()
	My.cooltime = 0
	EventMgr.Remove("OnChangeLv",EventHandler(My.OnChangeLv))
	My.des=nil
	isfirstcheck=false
	ListTool.Clear(openList)
	if(closeUse~=nil)then
		closeUse:Dispose()
		closeUse=nil
	end
	My.isBegin=true
end

return My
