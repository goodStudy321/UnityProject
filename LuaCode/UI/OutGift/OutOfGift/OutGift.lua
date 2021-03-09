OutGift = Super:New{Name = "OutGift"}

local My = OutGift

local AssetMgr = Loong.Game.AssetMgr

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find
	local USBC = UITool.SetBtnClick
	local FindC = TransTool.FindChild

	self.go = root.gameObject
	self.Model = Find(root,"Model",des)
	self.btnItem = CG(UISprite, root, "btn", des)
	self.btnLab = CG(UILabel, root, "btn/lab", des)
	self.moneyLab = CG(UILabel, root, "labs/lab1", des)
	self.chargeLab = CG(UILabel, root, "labs/lab7", des)
	self.timerLab = CG(UILabel, root, "labs/lab8", des)
	self.nameLab = CG(UILabel, root, "desLab", des)
	self.warLab = CG(UILabel, root, "platformBg/lab", des)
	self.rewardGrid = CG(UIGrid,root,"ScrollView/Grid",des)
	self.red = FindC(root,"btn/red",des)
	self.red:SetActive(false)
	self.rewardTab = {}
	self.btnIndex = 0
	self:LoadModel()
	self:RefreshReward()
	self:Countdown()
	self:BtnState()
	self:SetLnsr("Add")
	UITool.SetLsnrSelf(self.btnItem.gameObject,self.PayFunc,self,des,false)
end

function My:SetLnsr(func)
    GiftMgr.eGiftInfo[func](GiftMgr.eGiftInfo, self.BtnState, self)
    GiftMgr.eGiftBtnInfo[func](GiftMgr.eGiftBtnInfo, self.BtnState, self)
end


function My:Countdown()
    local info = NewActivMgr:GetActivInfo(2006)
    if not info then return end
    local startTime = 0
    local endTime = 0
    local severTime = 0
    local seconds = 0
    startTime = info.startTime
    endTime = info.endTime
    severTime = TimeTool.GetServerTimeNow()*0.001
    seconds = info.endTime - severTime
    local isOpen = GiftMgr:IsOpen()
    if isOpen and seconds > 0 then
        if not self.timer then
            self.timer = ObjPool.Get(DateTimer)
            self.timer.fmtOp = 0
            self.timer.apdOp = 0
            self.timer.invlCb:Add(self.InvCountDown, self)
            self.timer.complete:Add(self.EndCountDown, self)
        end
        self.timer.seconds = seconds
        self.timer:Stop()
        self.timer:Start()
        self:InvCountDown()
    end
end

function My:InvCountDown()
	local time = self.timer:GetRestTime()
	time = DateTool.FmtSec(time,0,0,true)
    self.timerLab.text = time
    -- self.timerLab.text = self.timer.remain
end

function My:EndCountDown()
    self.timerLab.text = ""
    if self.timer then
        self.timer:Stop()
	end
	local active = UIMgr.GetActive(UIOutGift.Name)
	local ui = UIMgr.Get(UIOutGift.Name)
	if ui and active ~= -1 then ui:Close() end
end

--更新显示
function My:UpShow(state)
	local btnState = GiftMgr.btnState
	if state == true and btnState ~= 1 then
		OutGiftMgr:UpAction(1,false)
	end
	self.go:SetActive(state)
 end

function My:RefreshReward()
	local cfg = GlobalTemp["189"]
	local reward = cfg.Value1
	local war = cfg.Value2[1]
	local money = cfg.Value3
	self.warLab.text = war
	self.moneyLab.text = money .. "元"
	local data = reward
	local len = #data
	local itemTab = self.rewardTab
	local count = #itemTab
	local max = count >= len and count or len
	local min = count + len - max
	for i = 1,max do
		 if i <= min then
			  itemTab[i]:UpData(data[i].id,data[i].value)
			  itemTab[i]:SetActive(true)
		 elseif i <= count then
			  itemTab[i]:SetActive(false)
		 else
			  local item = ObjPool.Get(UIItemCell)
			  item:InitLoadPool(self.rewardGrid.transform)
			  item:UpData(data[i].id,data[i].value)
			  table.insert(self.rewardTab,item)
		 end
	end
	self.rewardGrid:Reposition()
end

function My:LoadModel()
	if self.model then
		return
	end
	local path = ItemModel["3019000"].model[1]
	AssetMgr.LoadPrefab(path,GbjHandler(self.LoadModelCb,self))
end

function My:LoadModelCb(go)
	go:SetActive(true)
	go.transform.parent=self.Model.transform
	go.transform.localPosition=Vector3.zero
	-- go.transform.localScale=Vector3.one*200
	local eff = go:GetComponent(typeof(UIEffBinding))
	if not eff then eff=go:AddComponent(typeof(UIEffBinding)) end
	eff.mNameLayer="ItemModel"
	LayerTool.Set(go,22)
	self.models=go.gameObject
end

function My:ClearModel()
	if not LuaTool.IsNull(self.models) then
		AssetMgr.Instance:Unload(self.models.name,".prefab",false)
		Destroy(self.models)
		self.models = nil
  	end
end


function My:BtnState()
	local spStr = ""
	local btnStr = ""
	local nameStr = ""
	local chargeStr = ""
	local btnIndex = 0
	local needCharge = 0
	local roleId = User.instance.MapData.UID
	roleId = tostring(roleId)
	local needGold = GlobalTemp["189"].Value3
	local haveGold = GiftMgr.roleCharge
	local btnState = GiftMgr.btnState
	local charRoleId = GiftMgr.roleId
	local roleName = GiftMgr.roleName
	charRoleId = tostring(charRoleId)
	local spTab = {"btn_figure_non_avtivity","btn_figure_down_avtivity"}
	local labTab = {"前往充值","立即领取","已领取","已结束"}
	if haveGold < needGold then --未到充值金额
		if roleId == charRoleId then
			spStr = spTab[1]
			btnStr = labTab[1]
			btnIndex = 1
			needCharge = needGold - haveGold
			chargeStr = string.format("我已经充值：%s元，还差%s元",haveGold,needCharge)
		end
	elseif haveGold >= needGold then --已到充值金额
		if roleId == charRoleId then
			if btnState == 1 then
				spStr = spTab[1]
				btnStr = labTab[2]
				btnIndex = 2
			elseif btnState == 2 or btnState == 3 then
				spStr = spTab[2]
				btnStr = labTab[3]
				btnIndex = 3
			end
		else
			spStr = spTab[2]
			btnStr = labTab[4]
			btnIndex = 4
		end
	end
	self.nameLab.gameObject:SetActive(haveGold >= needGold)
	if roleId == charRoleId then
		self.red:SetActive(btnState == 1)
	end
	roleName = string.format("[%s]",roleName)
	self.btnItem.spriteName = spStr
	self.btnLab.text = btnStr
	self.nameLab.text = roleName
	self.chargeLab.text = chargeStr
	self.btnIndex = btnIndex
end

--点击充值项
function My:PayFunc()
	local index = self.btnIndex --{"前往充值","立即领取","已领取","已结束"}
	if index == 1 then
		VIPMgr.OpenVIP(1)
	elseif index == 2 then
		GiftMgr:ReqGetR()
	elseif index == 3 then
		UITip.Error("当前奖励已领取")
	elseif index == 4 then
		UITip.Error("本次活动已有玩家完成")
	end
end


function My:Dispose()
	self:SetLnsr("Remove")
	if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
	end
	self.btnIndex = 0
	self:ClearModel()
	TableTool.ClearListToPool(self.rewardTab)
end

return My
