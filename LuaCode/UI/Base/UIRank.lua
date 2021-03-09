--region UICreatePanel.lua
--排行榜UI
--此文件由[HS]创建生成
require("UI/UIRank/UIRankItem")
-- require("UI/UIRank/UITopItem")
require("Data/Rank/RankMgr")

UIRank = UIBase:New{Name ="UIRank"}

local M = UIRank

local DN = UIScrollView.OnDragNotification

local rankState = {None="None", RankBig="RankBig", RankSmall="RankSmall"}

local nowstate = rankState.None

local Drag = false

local US = UITool.SetLsnrClick

local aMgr = Loong.Game.AssetMgr

local isDrag = false

local quNum = 0

--注册的事件回调函数

function M:InitCustom()
	local name = "LUA排行榜"
	local trans = self.root
	local C = ComTool.Get
	local T = TransTool.FindChild

	local widget = T(trans,"Container").transform
	self.btnTog = T(widget,"btnPanel/btnTog")
    self.BattleBtn = T(widget, "btnPanel/btnTog/Battle")
	self.LvBtn = T(widget, "btnPanel/btnTog/Lv")
	self.MountBtn = T(widget, "btnPanel/btnTog/Mount")
    self.PetBtn = T(widget, "btnPanel/btnTog/Pet")
    self.TowerBtn = T(widget, "btnPanel/btnTog/Tower")
    --self.OffBtn = T(widget, "btnPanel/btnTog/OffLine")
    self.MWBtn = T(widget, "btnPanel/btnTog/MagicWeapon")
    self.WingBtn = T(widget, "btnPanel/btnTog/Wing") 
	self.GWBtn = T(widget, "btnPanel/btnTog/GodWeapons")
	self.CloseBtn = T(trans, "Close")
	self.sv = T(trans,"sv")

	local arcSv = self.btnTog:AddComponent(typeof(ArcSV))
	arcSv.target = self.sv

	self.OpenKey = 1

	self.TitleLabel = {}
	for i=1, 4 do
		local label = C(UILabel, trans, string.format("Rank/Title%s",i), name, false)
		table.insert(self.TitleLabel, label)
	end
	
	self.User = ObjPool.Get(UIRankItem)
	self.User:Init(T(trans, "User"))
	self.User.IsUser = true
	self.User:UpdateBg(0)

	self.SV = C(UIScrollView,trans, "Rank/Scroll View")
	self.Grid = C(UIGrid, trans, "Rank/Scroll View/Grid")
	self.Prefab = T(trans, "Rank/Scroll View/Item")
	self.Items = {}
	self.rank = T(trans, "Rank").transform
	self.modRoot = T(trans,"modRoot")
	self.title = T(trans,"modRoot/model/title").transform
	self.model = T(trans,"modRoot/model")
	self.other = T(trans,"modRoot/other")
	self.name = C(UILabel,trans,"info/name")
	self.family = C(UILabel,trans,"info/family")
	self.lv = C(UILabel,trans,"info/lv")
	self.otherName = C(UILabel,trans,"info/otherName")
	self.vip = C(UISprite,trans,"info/vip")
	self.LvBG = C(UISprite,trans,"info/lv/Sprite")

	self.svTran = TransTool.Find(trans, "Rank/Scroll View", self.Name)
    self.yPos = self.svTran.localPosition.y

	self.modCamTrans = T(trans,"modRoot/modCam").transform

	self.btnsList = {}
	self.btnGrid = C(UIGrid,trans,"btnGrid")
	local Btns = {"friendBtn","chatBtn","infoBtn"}
	for i = 1,3 do
		local btn = T(trans,"btnGrid/"..Btns[i])
		US(trans,"btnGrid/"..Btns[i],"",self.ClickMes,self)
		self.btnsList[#self.btnsList + 1] = btn
	end
	
	self.grid = TransTool.Find(self.root, "Rank/Scroll View/Grid", self.Name)

	self.btnList = {self.BattleBtn,self.LvBtn,self.MountBtn,self.PetBtn,self.TowerBtn,self.MWBtn,self.WingBtn,self.GWBtn}
	local E = UITool.SetLsnrSelf
	for i=1,#self.btnList do
		E(self.btnList[i], self.OnClickToogleBtn, self)
		-- UIEventListener.Get(self.btnList[i]).onDrag = function(go,ispress) M:OnDrag(go,ispress) end
		-- UIEventListener.Get(self.btnList[i]).onPress = function(go,ispress) M:OnPress(go,ispress) end
	end
	if self.CloseBtn then	
		E(self.CloseBtn, self.Close, self)
	end
	self.gbjPool = ObjPool.Get(MyGbjPool)
	
	self:SetLnsr("Add")
	self:InitData()
	self:ScreenChange(ScreenMgr.orient,true)
end

function M:SetLnsr(func)
	RankNetMgr.eRankEnd[func](RankNetMgr.eRankEnd, self.RespUpdateRankEnd, self)
	UserMgr.eUpdateData[func](UserMgr.eUpdateData,self.UpdateChaData,self)
	--euiopen[func](euiopen,self.SetTopPos,self)
	ScreenMgr.eChange[func](ScreenMgr.eChange, self.ScreenChange, self)
end

function M:ScreenChange(orient,init)
	if ScreenMgr.orient == ScreenOrient.Right then
		UITool.SetLiuHaiAnchor(self.root, "Rank", self.Name, true,true)
		UITool.SetLiuHaiAnchor(self.root, "User", self.Name, true,true)
		UITool.SetLiuHaiAnchor(self.root, "btnGrid", self.Name, true,true)
		if not init then
			UITool.SetLiuHaiAnchor(self.root, "Container", self.Name, true,true)
		end
	elseif ScreenMgr.orient == ScreenOrient.Left then
		if not init then
			UITool.SetLiuHaiAnchor(self.root, "Rank", self.Name, true)
			UITool.SetLiuHaiAnchor(self.root, "User", self.Name, true)
			UITool.SetLiuHaiAnchor(self.root, "btnGrid", self.Name, true)
		end
		UITool.SetLiuHaiAnchor(self.root, "Container", self.Name, true)
    end
end

-- 切换按钮
function M:OnClickToogleBtn(go)
	self:HideItems()
	self.key = RankType.None
	if self.BattleBtn.name == go.name then
		self.key = RankType.RP
   	elseif self.LvBtn.name == go.name then
		self.key = RankType.RL
	elseif self.MountBtn.name == go.name then
		self.key = RankType.MP
	elseif self.PetBtn.name == go.name then
		self.key = RankType.PP
	elseif self.TowerBtn.name == go.name then
		self.key = RankType.ZX
	-- elseif self.OffBtn.name == go.name then
	-- 	self.key = RankType.OFF
	elseif self.MWBtn.name == go.name then
		self.key = RankType.GWP
	elseif self.WingBtn.name == go.name then
		self.key = RankType.WP
	elseif self.GWBtn.name == go.name then
		self.key = RankType.MWP
	end

	self.CurItem = nil
	self:SetTitle()
	nowstate = rankState.RankBig
	
end

-- function M:OnPress()
-- 	local togTrans = self.btnTog.transform
-- 	if isDrag == true then
-- 		isDrag = false
-- 	else
-- 		isDrag = true
-- 		self.mouPos = UnityEngine.Input.mousePosition
-- 	end
-- 	if togTrans.localRotation.eulerAngles.z < 360 and togTrans.localRotation.eulerAngles.z > 180 then
-- 		togTrans.localRotation = Quaternion.Euler(0,0,0)
-- 	elseif togTrans.localRotation.eulerAngles.z > 5 and togTrans.localRotation.eulerAngles.z < 21 then
-- 		togTrans.localRotation = Quaternion.Euler(0,0,20)
-- 	elseif togTrans.localRotation.eulerAngles.z >= 21 and togTrans.localRotation.eulerAngles.z < 41 then
-- 		togTrans.localRotation = Quaternion.Euler(0,0,40)
-- 	elseif togTrans.localRotation.eulerAngles.z >= 41 and togTrans.localRotation.eulerAngles.z < 60 then
-- 		togTrans.localRotation = Quaternion.Euler(0,0,60)
-- 	elseif togTrans.localRotation.eulerAngles.z >= 61 and togTrans.localRotation.eulerAngles.z < 80 then
-- 		togTrans.localRotation = Quaternion.Euler(0,0,80)
-- 	elseif  togTrans.localRotation.eulerAngles.z > 81 then
-- 		togTrans.localRotation = Quaternion.Euler(0,0,80)
-- 	end
-- 	quNum = togTrans.localRotation.eulerAngles.z
-- 	for i=1,9 do
-- 		self.btnList[i].transform.localRotation = Quaternion.Euler(0,0,-quNum)
-- 	end
-- end

-- function M:OnDrag()
-- 	local mouPos = UnityEngine.Input.mousePosition
-- 	local lerp = mouPos.y - self.mouPos.y
-- 	local togTrans = self.btnTog.transform
-- 	if isDrag then
-- 		if lerp < 0 then
-- 			quNum = quNum - 1
-- 			togTrans.localRotation = Quaternion.Euler(0,0,quNum)
-- 		else
-- 			quNum = quNum + 1
-- 			togTrans.localRotation = Quaternion.Euler(0,0,quNum)
-- 		end
-- 		for i=1,9 do
-- 			self.btnList[i].transform.localRotation = Quaternion.Euler(0,0,-quNum)
-- 		end
-- 	else
-- 		if togTrans.localRotation.eulerAngles.z < 360 and togTrans.localRotation.eulerAngles.z > 180 then
-- 			togTrans.localRotation = Quaternion.Euler(0,0,0)
-- 		elseif togTrans.localRotation.eulerAngles.z > 81 then
-- 			togTrans.localRotation = Quaternion.Euler(0,0,80)
-- 		end
-- 	end
-- end


-- 初始化数据
function M:InitData()
	self.Title = {}
	self.Title[tostring(RankType.None)] = {"","","",""}
	self.Title[tostring(RankType.RP)] = {"排名","角色名称","道庭","战斗力"}--战力
	self.Title[tostring(RankType.RL)] = {"排名","角色名称","职业","玩家等级"}--等级
	self.Title[tostring(RankType.MP)] = {"排名","角色名称","战斗力","外形等级"}--坐骑
	self.Title[tostring(RankType.PP)] = {"排名","角色名称","战斗力","外形等级"}--宠物
	self.Title[tostring(RankType.ZX)] = {"排名","角色名称","战斗力","通关层数"}--诛仙塔
	self.Title[tostring(RankType.OFF)] = {"排名","角色名称","战斗力","挂机效率"}--离线效率
	self.Title[tostring(RankType.GWP)] = {"排名","角色名称","战斗力","外形等级"}--神兵
	self.Title[tostring(RankType.WP)] = {"排名","角色名称","战斗力","外形等级"}--翅膀
	self.Title[tostring(RankType.MWP)] = {"排名","角色名称","战斗力","外形等级"}--法宝
	self.key = self:GetKey()

	self.CurItem = nil
	self:SetTitle()
end

--index==0 无
--index==1 战力排行
--index==2 等级排行
--index==3 坐骑战力排行
--index==4 法宝战力排行
--index==5 宠物战力排行
--index==6 神兵战力排行
--index==7 翅膀战力排行
--index==8 离线效率排行 --暂时未开放
--index==9 诛仙塔排行
function M:OpenRank(index)
	self.OpenKey = index
end

function M:GetKey()
	if self.OpenKey == 0 then
		return RankType.None
	elseif self.OpenKey == 1 then
		return RankType.RL
	elseif self.OpenKey == 2 then
		return RankType.RP
	elseif self.OpenKey == 3 then
		return RankType.MP
	elseif self.OpenKey == 4 then
		return RankType.PP
	elseif self.OpenKey == 5 then
		return RankType.GWP
	elseif self.OpenKey == 6 then
		return RankType.MWP
	elseif self.OpenKey == 7 then
		return RankType.WP
	elseif self.OpenKey == 8 then
		return RankType.ZX
	elseif self.OpenKey == 9 then
		return RankType.OFF
	end
end

-- 玩家信息、加好友、聊天按钮事件
function M:ClickMes(go)
	local str = go.name
	if self.CurItem == nil then
		return
	end
	local playerid = self.CurItem.PlayerID
	if StrTool.IsNullOrEmpty(playerid) then return end
	if str == "infoBtn" then
		-- self.modRoot:SetActive(false)
		UIMgr.Open(UIOtherInfoCPM.Name)
	elseif str == "chatBtn" then
		FriendMgr.TalkId = playerid
		if not playerid then return end
		UIMgr.Open(UIInteractPanel.Name, self.OpenUI, self)
		UIMgr.Close(UIRank.Name)
	elseif str == "friendBtn" then
		if User.MapData.UIDStr == playerid then
			MsgBox.ShowYes("不可以加自己为好友哦！")
			return
		end
		FriendMgr:ReqAddFriend(playerid)
		MsgBox.ShowYes("好友请求发送成功！")
	end
end

function M:OpenUI(name)
	local ui = UIMgr.Get(name)
	if ui then 
		ui:ShowChat()
	end
end

function M:AddItem(index)
	local key = tostring(index)
	if self.Items[key] == nil then
		local go = GameObject.Instantiate(self.Prefab)
		go.name = tostring(index)
		go.transform.parent = self.Grid.transform
		go.transform.localPosition = Vector3.zero
		go.transform.localScale = Vector3.one
		--UITool.SetLsnrSelf(go, self.OnClickItem, self, nil, false)
		-- go:SetActive(true)
		self.Items[key] = ObjPool.Get(UIRankItem)
		self.Items[key]:Init(go)
	end
	self.Items[key]:UpdateBg(index)
	self.Items[key].gameObject:SetActive(true)
end

function M:SetTitle()
	if self.key == RankType.None then
		return
	end
	local title = self.Title[tostring(self.key)]
	if not title then return end
	local len = #self.TitleLabel
	for i=1, len do
		self.TitleLabel[i].text = title[i]
	end
	RankMgr:Init()
	if RankMgr:IsUpdate(self.key) == true then		
		RankNetMgr:ReqRankInfo(self.key)		
	else
		self:UpdateRankEnd()
	end
end

function M:UpdateItems(len)
	if not self.key then return end
	self:HideItems()
	self.list = nil 
	if LuaTool.Length(RankMgr.Rank) ~= 0 then
		local rank = RankMgr.Rank[self.key]
		if rank then
			self.list = rank.Rank
		end
	end
	-- local len = 0
	-- if self.list then 
	-- 	len = LuaTool.Length(self.list)
	-- end
	local num = len
	if len<=1000 then
		num = len
	else
		num = 100
	end
	for i = 1 , num do
		self:AddItem(i)
		if self.list[i] then
			local index = i
			self:UpdateItemData(i, index, self.list[i])
		end
	end

	if num > 0 then
		if self.Items["1"] then
			self.Items["1"]:ClickSelf()
		end
	end

	self.Grid:Reposition()
	-- self.SV:ResetPosition()
	self:UpdateUser(self.list)
end

function M:UpdateItemData(i, index, data)
	local key = tostring(index)
	if not self.Items[key] then return end
	self.Items[key]:UpdateData(i, self.key, data,function() self:OnClickItem(i) end)
	if key == 1 then
		self.Items[key]:Show(true);
	else
		self.Items[key]:Show(false);
	end
end

function M:UpdateUser(list)
	if not self.User then return end

	local rank = nil
	local num = 0
	if list then
		rank = RankMgr:GetRank(nil, list)
		if rank~="未上榜" then
			num = tonumber(rank)
		else
			num = 0
		end
		self.User:UpdateRank(num)
	end
	local t1,t2,t3,t4 = nil
	local mapData = User.MapData
	t1 = rank
	local key = self.key
	if key == RankType.RP then
		t2 = UserMgr:GetName()
		t3 = UserMgr:GetFamililyName()
		t4 = UserMgr:GetFight(FightType.All)		
	elseif key == RankType.RL then
		t2 = UserMgr:GetName()
		t3 = UserMgr:GetCareerName()
		t4 = UserMgr:GetLv()
		t5 = UserMgr:GetFamililyName()
		t6 = UserMgr:GetFight(FightType.All)	
	elseif key == RankType.MP then
		t2 = UserMgr:GetName()
		--t3 = RankMgr:GetMountName()
		t3 = UserMgr:GetFight(FightType.MOUNT)
		t4 = RankMgr:GetMountStep()
	elseif key == RankType.PP then
		t2 = UserMgr:GetName()
		--t3 = RankMgr:GetPetName()
		t3 = UserMgr:GetFight(FightType.PET)
		t4 = RankMgr:GetPetStep()
	elseif key == RankType.ZX then
		t2 = UserMgr:GetName()
		t3 = UserMgr:GetFight(FightType.All)
		t4 = RankMgr:GetTowerLay()
	elseif key == RankType.OFF then
		t2 = UserMgr:GetName()
		t3 = UserMgr:GetFight(FightType.All)
		local exp = RankNetMgr.EXP
		local num = CustomInfo:ConvertNum(tonumber(exp))
		t4 = string.format("%s/分钟", num)
	elseif key == RankType.GWP then
		t2 = UserMgr:GetName()
		t3 = UserMgr:GetFight(FightType.GOD_WEAPON)
		--t3 = UserMgr:GetCareerName()
		t4 = RankMgr:GetGWLv()
	elseif key == RankType.WP then
		t2 = UserMgr:GetName()
		t3 = UserMgr:GetFight(FightType.WING)
		--t3 = UserMgr:GetCareerName()
		t4 = RankMgr:GetWingLv()
	elseif key == RankType.MWP then
		t2 = UserMgr:GetName()
		t3 = UserMgr:GetFight(FightType.MAGIC_WEAPON)
		--t3 = UserMgr:GetCareerName()
		t4 = RankMgr:GetMWLv()
	end
	local vip = RankMgr:GetVipLv()
	local confine = self.User:GetConfine(tonumber(mapData.Confine))
	self.User:UpdateLabel(t1, t2, t3, t4)
	self.User:SetVipSpr(vip, confine)
end

--实时更新
function M:Update()
	if self.svTran and tonumber(self.svTran.localPosition.y) ~= tonumber(self.yPos) then
		self:RespUpdateRankEnd(true)
		self.svTran = nil
	end
end

function M:RespUpdateRankEnd(isUpShow)
	if not self.key then return end
	if LuaTool.Length(RankMgr.Rank) ~= 0 then
		local rank = RankMgr.Rank[self.key]
		if rank then
			local len = LuaTool.Length(rank.Rank)
			local max = (len<10) and len or 10
			local num = (isUpShow==nil and self.svTran) and max or len
			self:UpdateItems(num)
			if self.svTran==nil then self.SV:ResetPosition() end
		end
	end
end

function M:UpdateRankEnd()
	if not self.key then return end
	if LuaTool.Length(RankMgr.Rank) ~= 0 then
		local rank = RankMgr.Rank[self.key]
		if rank then
			local len = LuaTool.Length(rank.Rank)
			self:UpdateItems(len)
			if self.svTran==nil then self.SV:ResetPosition() end
		end
	end
end

-- 更新称号
function M:UpdateTitle(id)
    local titleInfo = TitleCfg[tostring(id)]
	if StrTool.IsNullOrEmpty(titleInfo) then 
		if self.curTitle then
			self.gbjPool:Add(self.curTitle)
			self.curTitle = nil;
		end
		return 
	end
    local name = titleInfo.prefab1
    if self.curTitle and self.curTitle.name == name then return end
    local go = self.gbjPool:Get(name)
    if not go then
        if not AssetTool.IsExistAss(name) then 
            UITip.Log("该称号资源正在加载...")
            return 
        end
        aMgr.LoadPrefab(name, GbjHandler(self.SetChaTitle, self))
    else
        self:SetChaTitle(go)
    end
end

function M:SetChaTitle(go)  
    if not LuaTool.IsNull(self.title) then
        self.gbjPool:Add(self.curTitle)
        self.curTitle = go
        go.transform:SetParent(self.title)
        go.transform.localScale = Vector3.one
        go.transform.localPosition = Vector3.zero
    else
        self:Unload(go)
    end
end

function M:Unload(go)
    if LuaTool.IsNull(go) then return end
    AssetMgr:Unload(go.name,".prefab", false)
    GameObject.DestroyImmediate(go)
end

-- 创建其他模型
function M:CreatOtherMod()
	local key = self.key
	local otherInfo = UserMgr.OtherInfo
	local modName = ""
	local modId = 0
	local info = {}
	if key == RankType.MP then
		info = MountCfg
		modId = tonumber(string.sub(otherInfo.mount,0,5))
		self.modCamTrans.localPosition = Vector3.New(950,180,-3500)
	elseif key == RankType.MWP then
		info = MWCfg
		modId = tonumber(string.sub(otherInfo.magicw,0,5))
		self.modCamTrans.localPosition = Vector3.New(630,0,-2800)
	elseif key == RankType.PP then
		info = PetTemp
		modId = tonumber(string.sub(otherInfo.pet,0,5))
		self.modCamTrans.localPosition = Vector3.New(545,0,-2500)
	else
		info = GWCfg
		modId = tonumber(string.sub(otherInfo.godw,0,5))
		self.modCamTrans.localPosition = Vector3.New(525,5,-2300)
	end
	local otherName = ""
	for i,v in ipairs(info) do
		if v.id == modId then
			if info == GWCfg then
				local mod = {v.muMod,v.wuMod}
				modName = RoleBaseTemp[tostring(mod[otherInfo.sex+1])].path
				otherName = v.name
				break
			else
				modName = RoleBaseTemp[tostring(v.uMod)].path
				otherName = v.name
				break
			end
		end
	end
	aMgr.LoadPrefab(modName,GbjHandler(self.SetOtherModel,self))
	self:ShowOtherName(otherName)
end

function M:SetOtherModel(go)
    self:ClearOtherModel()
    AssetMgr:SetPersist(go.name, ".prefab",true)
    self.curDetailModel = go
	go.transform:SetParent(self.other.transform)
	go.transform.localPosition =  Vector3.zero
    go.transform.localScale = Vector3.one
end

function M:ClearOtherModel()
    if self.curDetailModel then
        AssetMgr:Unload(self.curDetailModel.name, ".prefab", false)
        Destroy(self.curDetailModel)
        self.curDetailModel = nil
    end
end

-- 每个条目自身点击按钮事件
function M:OnClickItem(i)
	local key = tostring(i)
	if self.CurItem then
		local name = self.CurItem.gameObject
		if name == i then 
			return
		else
			self.CurItem:Show(false)
		end
	end

	local item = self.Items[key]
	item:Show(true)
	self.CurItem = item
	local playerId = self.CurItem.PlayerID
	local isFriend = FriendMgr:IsFriend(playerId)
	for i=1,3 do
		self.btnsList[i]:SetActive(true)
	end
	if isFriend then
		self.btnsList[1]:SetActive(false)
	else
		self.btnsList[2]:SetActive(false)
	end
	UserMgr:ReqRoleObserve(tonumber(playerId))
	self.btnGrid:Reposition()
end

--是否显示vip以及道庭
function M:IsShowVipOrFam(value)
	self.vip.gameObject:SetActive(value)
	self.family.gameObject:SetActive(value)
	self.otherName.gameObject:SetActive(not value)
end


-- 显示当前信息
function M:UpdateChaData()
	local info = UserMgr.OtherInfo
	self:ShowModel()
	self:UpdateTitle(info.title)

	self.name.text = info.name

	if self.LvBG then
		local name = "ty_19"
		if UserMgr:IsGod(info.lv) then
			name = "ty_19A"
		end
		self.LvBG.spriteName = name
	end
	self.lv.text = UserMgr:GetChangeLv(info.lv, false)
end

-- 显示vip以及道庭信息
function M:ShowVipAndFamily(info)
	local Id = tonumber(info.familyId)
    local value = Id ~= 0
    if self.family then
       local name = "无"
        if value == true then
            name = info.familyName
        end
        self.family.text = "道庭:【"..name.."】"
	end

	local value = info.vip ~= 0
	if self.vip then
		self.vip.gameObject:SetActive(value)
		if value == true then
            self.vip.spriteName = "vip"..info.vip
        end
	end
end

-- 显示其他模型名字
function M:ShowOtherName(text)
	self.otherName.text = text
end

-- 显示模型
function M:ShowModel()
	local info = UserMgr.OtherInfo
	local key = self.key
	if key == RankType.MP or -- 坐骑
	key == RankType.MWP or -- 法宝
	key == RankType.PP or -- 宠物
	key == RankType.GWP then -- 神兵
		self:ClearModel()
		self:CreatOtherMod()
		self.model:SetActive(false)
		self:IsShowVipOrFam(false)
	else
		self.model:SetActive(true)
		self:ClearOtherModel()
		self:CreateMod()
		self.modCamTrans.localPosition = Vector3.New(304,316,-1547.3)
		self:IsShowVipOrFam(true)
		self:ShowVipAndFamily(info)
	end
end

-- 创建角色模型
function M:CreateMod()
	local info = UserMgr.OtherInfo
	local id = (info.cate * 10 + info.sex) * 1000 + info.lv
	if not self.skin then
		self.skin = ObjPool.Get(RoleSkin)
		self.skin.eLoadModelCB:Add(self.SetModel, self)
	end
	self.skin:Create(self.model, id, info.skins, info.sex)
end

function M:SetModel(go)
	if not LuaTool.IsNull(self.skin) then
		go.transform.localRotation = Quaternion.Euler(0,0,0)
	end
end

function M:ClearModel()
	if self.skin then
		self.skin.eLoadModelCB:Remove(self.SetModel, self)
		ObjPool.Add(self.skin)
		self.skin = nil
	end
end

function M:EnabledItems()
	local items = self.Items
	if not items then return end
	for k,v in pairs(items) do
		v:EnabledEff()
	end
end

function M:OpenCustom()
	local top = UIMgr.Get(self.cfg.cp)
	if top then 
		top:SetTitle("排行榜")
	end
end

-- function M:SetTopPos(name)
-- 	if name~=UITop.Name then return end
-- 	local ui = UIMgr.Get(UITop.Name)
-- 	if (ui) then
--         ui:SetPos(-200)
--     end
-- end

function M:HideItems()
	if self.grid.childCount > 0  then
		-- TransTool.ClearChildren(self.grid)
		TransTool.SetChildrenActive(self.grid, false)
	end
end

function M:DisposeCustom()
	self:SetLnsr("Remove")
	--self:RemoveEvent()

	if self.Items then
		local len = #self.Items
		while #self.Items > 0 do
			len = #self.Items
			self.Items[len]:Dispose()
			ObjPool.Add(self.Items[len])
			self.Items[len] = nil
			table.remove(self.Items, len)
		end
	end
	if self.User then
		ObjPool.Add(self.User)
	end
	ObjPool.Add(self.gbjPool)
    self.gbjPool = nil
    self:Unload(self.curTitle)
	self.curTitle = nil
	self:ClearOtherModel()
	self:ClearModel()

	self.LvBtn = nil
   	self.BattleBtn = nil
	self.MountBtn = nil
	self.PetBtn = nil
	self.TowerBtn = nil
	self.OffBtn = nil
   	self.MWBtn = nil
	self.WingBtn = nil
	self.GWBtn = nil
	isDrag = false
end

return M
