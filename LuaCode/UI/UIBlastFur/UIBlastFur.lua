--[[
    authors 	:YueN
 	date    	:2019-4-19 11:00:00
 	descrition 	:炼丹炉
]]
--[[
    nextAuthors 	:soon
 	date    	:2019-7-11 20:00:00
 	descrition 	:炼丹炉
]]
UIBlastFur = UIBase:New{Name = "UIBlastFur"}
local M = UIBlastFur

local aMgr = Loong.Game.AssetMgr

local C = ComTool.Get
local T = TransTool.FindChild
local US = UITool.SetBtnClick
local USS = UITool.SetLsnrSelf
local isAKey = false
local status = false
local showAward = false
local blastCnt = 0 -- 自动炼丹计时
local luckyNum = 0 -- 记录幸运值
local lerp = 0.3

function M:InitCustom()
	local root = self.root
	local des = self.Name
	self.sv = C(UIScrollView,root,"sv")
	self.grid = C(UIGrid,root,"sv/grid")
	self.time = C(UILabel,root,"time")
	self.bigName = C(UILabel,root,"big/name")
	self.gold = C(UILabel,root,"mon")
	self.num = C(UILabel,root,"num")
	--self.tolNum = C(UILabel,root,"num2")
	self.btnLb1 = C(UILabel,root,"buyBtn/Lb1")
	self.picDes = C(UILabel,root,"say")
	self.mon = C(UILabel,root,"spend/price")
	self.sel = C(UIToggle,root,"sel")
	self.fightLb = C(UILabel,root,"fightLb")
	self.tipLb =C(UILabel,root,"desTip/Lb")
	self.btnSp = C(UISprite,root,"buyBtn")
	self.boxCollider = C(BoxCollider,root,"buyBtn" )

	self.txSlider = C(guiraffe.SubstanceOrb.OrbAnimator, root, "Tx/Group_jd/FX_SubstancePlane")

	self.yb = T(root, "spend/yb",des)
	self.by = T(root,"spend/by",des)
	self.yl = T(root,"spend/yl",des)
	self.model = T(root,"model",des)
	self.tip = T(root,"desTip",des)
	self.LbObj = T(root,"buyBtn/Lb2",des)
	self.isBtx = T(root,"Tx/Grou_dj",des)

	US(root, "closeBtn", des, self.Close, self)
	US(root, "buyBtn", des, self.ClickToBuy, self)
	US(root, "desBtn", des, self.ClickToDes, self)
	US(root, "desTip", des, self.CloseTip, self)
	USS(self.sel.transform,self.OnTog,self)
	self.items = {}
	self.allDic = {}
	self.dic = {}

	self:InitActData()
	
	self:SetLnsr("Add")

	if not self.quickList then self.quickList={} end
end

-- 打开面板
function M:OpenCustom()
	self:ShowData()
	self:UpGoldLab()
	self:InitPrice()
	self:InitComAward()
	self:ShowActTime()
	self:ShowModel()
end

function M:OpenTabByIdx(t1, t2, t3, t4)
	-- body
end

-- 关闭活动说明
function M:CloseTip()
	self.tip:SetActive(false)
end

-- 设置监听
function M:SetLnsr(func)
	RoleAssets.eUpAsset[func](RoleAssets.eUpAsset, self.UpGoldLab, self)
	FestivalActMgr.eUpdateModel[func](FestivalActMgr.eUpdateModel, self.ShowModel, self)
	FestivalActMgr.eUpdateBlastInfo[func](FestivalActMgr.eUpdateBlastInfo, self.ShowData, self)
	FestivalActMgr.eUdBlaetBtn[func](FestivalActMgr.eUdBlaetBtn, self.SetBtnLb, self)
	PropMgr.eGetAdd[func](PropMgr.eGetAdd, self.OnAdd, self)
	UIGetRewardPanel.eDoublePop[func](UIGetRewardPanel.eDoublePop,self.CloseRewardPanel,self)
	QuickUsePro.eDispose[func](QuickUsePro.eDispose,self.CloseRewardPanel,self)
end

-- 先播放特效再打开奖励面板
function M:ShowTx()
	self.isBtx:SetActive(false)
	self.isBtx:SetActive(true)
	if not self.dTimer then
		self.dTimer = ObjPool.Get(iTimer)
	end
	self.boxCollider.enabled = false
	self.dTimer:Start(0.2)
    self.dTimer.complete:Add(self.OpenGetReward,self)
end

function M:OpenGetReward()
	UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	self.boxCollider.enabled = true
end

--道具添加
function M:OnAdd(action,dic)
	local modId = self.data.award2.type_id
	if action == 10378 then
		if status then
			for i,v in ipairs(dic) do
				local data = ItemData[tostring(v.k)]
				local name = data.name
				local qua = UIMisc.LabColor(data.quality)
				local tip = string.format("恭喜获得%s%s[-]",qua,name)
				UITip.Log(tip)
				local kv = ObjPool.Get(KV)
				kv:Init(v.k,v.v)
				if v.k ~= modId then
					self.allDic[#self.allDic + 1] = kv
				else
					table.insert( self.allDic, 1, kv )
				end
				self.quickList[#self.quickList+1]=kv.k
			end
		else
			for i,v in ipairs(dic) do
				if not self.KV then
					self.KV = ObjPool.Get(KV)
				end
				self.KV:Init(v.k,v.v)
			end
			self.dic [#self.dic + 1]  = self.KV
			self.quickList[#self.quickList+1]=self.KV.k
			self:ShowTx()
		end
	end
end

--关闭奖励面板然后显示快速使用界面
function M:CloseRewardPanel()
	local count = #self.quickList
	if count==0 then return end
	local type_id = self.quickList[1]
	local num = PropMgr.TypeIdByNum(type_id)
	table.remove(self.quickList,1)
	local item = UIMisc.FindCreate(type_id)
	if not item then return end
	local canquick = item.canQuick or 0
	local canuse=QuickUseMgr.CanUse(item)
	if QuickUseMgr.isBegin==false then return end
	if canquick==1 and canuse==true and num>0 then 
		QuickUseMgr.OpenQuickUse(type_id,num)
	else
		self:CloseRewardPanel()
	end
end

--手动炼丹显示奖励的回调方法
function M:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
		local tip = "获得幸运值:1"
		ui:SetLuckyLb(tip)
		TableTool.ClearDic(self.dic)
	end
end

-- 自动炼丹显示奖励得回调方法
function M:AllRewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.allDic)
		local tip = "获得幸运值:"..luckyNum
		ui:SetLuckyLb(tip)
		self:ClearAwardDic()
		luckyNum = 0
	end
end

function M:ClearAwardDic()
	TableTool.ClearDicToPool(self.allDic)
	--self.allDic = nil
end

--初始化活动数据
function M:InitActData()
    self.actData = FestivalActMgr:GetActInfo(FestivalActMgr.LDL)
end

--初始化数据
function M:ShowData()
	self.data = FestivalActInfo.blastData
	if not self.data then return end
	local data = self.data
	local luc = data.lucky
	local tolluc = data.tollucky
	self.num.text = string.format("(%s/%s)",luc,tolluc)
	--self.tolNum.text = tolluc
	if self.txSlider then
		if luc == 0 then
			self.txSlider.FillRate = 0
		else
			self.txSlider.FillRate = luc/tolluc
		end
	end
end

-- 初始化炼丹价格及货币类型
function M:InitPrice()
	local data = self.data
	self:ShowMon(data.money)
	self.mon.text = data.price
	local txt = string.gsub(data.des,',','\n')
	self.btnLb1.text = txt
	self.picDes.text = data.picDes
end

-- 货币类型图标显示
function M:ShowMon(type)
	self.yl:SetActive(false)
	self.yb:SetActive(false)
	self.by:SetActive(false)
	if type == 1 then
		self.yl:SetActive(true)
	elseif type == 2 then
		self.yb:SetActive(true)
	elseif type == 3 then
		self.by:SetActive(true)
	end
end

-- 初始化显示普通奖品显示
function M:InitComAward()
	local data = self.data.award1
	local Add = TransTool.AddChild
	local trans = self.grid.transform
	for i,v in ipairs(data) do
		local item = ObjPool.Get(UIItemCell)
		item:InitLoadPool(trans,0.9)
		item:UpData(v.id, v.num,false)
		self.items[#self.items + 1] = item
	end
end

-- 显示大奖模型
function M:ShowModel()
	self:ClearModel()
	local modId = self.data.award2.type_id
	self.modInfo = ItemModel[tostring(modId)]
	local info = self.modInfo
	if not info then return end
	local name = info.name
	self.bigName.text = name
	local model = info.model
	local mm = nil
	if #model==1 then 
		mm=model[1] 
	else 
		mm=model[User.instance.MapData.Sex+1]
	end
	if not mm then return end	
	local isExit = aMgr.Instance:Exist(mm..".prefab")
	if isExit~=true then return end
	aMgr.LoadPrefab(mm,GbjHandler(self.LoadModel,self))
	self.fightLb.text = info.fight
end

function M:LoadModel(go)
	go:SetActive(true)
	go.transform.parent = self.model.transform
	go.transform.localPosition = self.modInfo.BlaPos
	go.transform.localScale = Vector3.one*345

	local eff = go:GetComponent(typeof(UIEffBinding))
	if not eff then eff=go:AddComponent(typeof(UIEffBinding)) end
	eff.mNameLayer="UIModel"
	LayerTool.Set(go,22)
	self.Model = go
end

function M:ClearModel()
    if self.Model then
        AssetMgr:Unload(self.Model.name, ".prefab", false)
        Destroy(self.Model)
        self.Model = nil
    end
end

-- 显示倒计时
function M:ShowActTime()
	local data = self.actData
	local eDate = 0
	if data.eTime == 0 then
		eDate = data.eDate
	else
		eDate = data.eTime
	end
	local seconds = eDate - TimeTool.GetServerTimeNow()*0.001
	if not self.timer then
		self.timer = ObjPool.Get(DateTimer)
	end
	local timer = self.timer
	timer:Stop()
	if seconds <= 0 then
		self:CompleteCb()
	else
		timer.invlCb:Add(self.InvlCb, self)
    	timer.complete:Add(self.CompleteCb, self)
		timer.seconds = seconds
		timer.fmtOp = 0
        timer:Start()
        self:InvlCb()
	end
end

-- 间隔倒计时
function M:InvlCb()
	if self.time then
		self.time.text = self.timer.remain
	end
end

--结束倒计时
function M:CompleteCb()
	self.timeLab.text = "活动结束"
	FestivalActMgr.BlastState = false
	FestivalActMgr.eUpState(false)
end

function M:OnTog()
	if self.sel.value == true then
		status = true
	else
		status = false
		self:SetBtnLb(true)
	end
end

function M:yesCb()
	UIRole:SelectOpen(4)
	JumpMgr:InitJump(UIBlastFur.Name)
end

-- 炼丹按钮
function M:ClickToBuy()
	local type = self:GetStatus()
	--self.btnLb1.text = self.data.des
	if type == 0 then
		MsgBox.ShowYesNo("背包空间不足，是否前往清理背包?",M.yesCb)
		return
	elseif type == 1 then
		StoreMgr.JumpRechange()
		return
	end
	if status then
		if isAKey == false then
			self:SetBtnLb(false)
		else
			self:SetBtnLb(true)
			return
		end
	else
		FestivalActMgr:ReqsBlast()
	end
end

-- 设置炼丹按钮状态
function M:SetBtnLb(status)
	if status == false then
		self.LbObj:SetActive(true)
		self.btnLb1.gameObject:SetActive(false)
		self.btnSp.spriteName = "btn_cultivate2"
		isAKey = true
	else
		local txt = string.gsub(self.data.des,',','\n')
		self.btnLb1.text = txt
		self.btnLb1.gameObject:SetActive(true)
		self.LbObj:SetActive(false)
		self.btnSp.spriteName = "btn_task_none"
		isAKey = false
		blastCnt = 0
		if #self.allDic ~= 0 then
			UIMgr.Open(UIGetRewardPanel.Name,self.AllRewardCb,self)
		end
	end
end

-- 得到炼丹状态 0 为背包空间不足 1为钱不足
function M:GetStatus()
	local bagNum = PropMgr.GetRemainCell()
	if bagNum <= 0 then
		return 0
	end
	if self.data.money == 2 then
		if RoleAssets.Gold < self.data.price then
			return 1
		end
	elseif self.data.money == 3 then
		if RoleAssets.BindGold < self.data.price then
			return 1
		end
	else

	end
end

-- 自动炼丹
function M:Update()
	if isAKey and status then
		local type = self:GetStatus()
		if type == 0 or type == 1  then
			self:SetBtnLb(true)
			local isActive = UIMgr.GetActive(UIGetRewardPanel.Name)
			if type == 0 then
				if isActive == -1 then
					MsgBox.ShowYesNo("背包空间不足，是否前往清理背包?",M.yesCb)
				end
			elseif type == 1 then
				if isActive == -1 then
					StoreMgr.JumpRechange()
				end
			end
		end
		blastCnt = blastCnt + Time.unscaledDeltaTime
		if blastCnt > lerp then
			blastCnt = 0
			FestivalActMgr:ReqsBlast()
			self.isBtx:SetActive(false)
			self.isBtx:SetActive(true)
			luckyNum = luckyNum + 1
		end
	end
end

-- 活动说明按钮
function M:ClickToDes()
	self.tip:SetActive(true)
	self.tipLb.text = self.actData.explain
end

-- 更新元宝数量
function M:UpGoldLab()
	self.gold.text = RoleAssets.Gold
end

-- 清除缓存
function M:Clear()
end

function M:DisposeCustom()
	if self.quickList then ListTool.Clear(self.quickList) end
	isAKey = false
	status = false
	luckyNum = 0
	if self.timer then
        self.timer:Stop()
        self.timer:AutoToPool()
        self.timer = nil
	end
	while #self.items > 0 do
        local item = self.items[#self.items]
        item:DestroyGo()
        ObjPool.Add(item)
        self.items[#self.items] = nil
	end
	if self.dTimer then
        self.dTimer:AutoToPool()
        self.dTimer = nil
    end
	self:ClearModel()
	self:ClearAwardDic()
	self.allDic = nil
	--TableTool.ClearDicToPool(self.KV)
	TableTool.ClearDic(self.dic)
	self.KV = nil
	self:SetLnsr("Remove")
end

return M