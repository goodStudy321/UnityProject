--[[
VIP界面
--]]
require("UI/UIVIP/VIP")
require("UI/UIVIP/NoVIP")
require("UI/UIVIP/VIPInfo")
require("UI/UIOpenService/UIAccuPay")
require("UI/UIRecharge/UIRecharge")
require("UI/UIInvest/UIInvest")
require("UI/UIVIPInvest/UIVIPInvest")
require("UI/UIMonthInvest/UIMonthInvest")
require("UI/UIInvest/UILvInvest")

UIVIP=UIBase:New{Name="UIVIP"}
local My=UIVIP

local novip=nil
local vip=nil
local AccuPay=nil
local togList = {}
local cDic={}

function My:InitCustom()
	local TF=TransTool.FindChild
	local CG=ComTool.Get
	local trans = self.root
	local des = self.Name
	local actionList = {}

	for i=1,8 do
		local tog = CG(UIToggle,TF(trans,"Grid").transform,"Tog".. i,des,false)
		togList[i] = tog
		UITool.SetLsnrClick(trans,"Grid/Tog".. i,des,self.OnClick,self)
		table.insert(actionList, TF(tog.transform, "Action"))   
	--	屏蔽充值
		-- togList[1].gameObject:SetActive(false)
		local isShield = VIPMgr:IsShieldBtn(i)
		togList[i].gameObject:SetActive(not isShield)
		--	屏蔽开服累充【开服累充功能移动到开服活动，vip界面不需要显示开服累充标签页】
		if i == 4 then
			togList[i].gameObject:SetActive(false)
		end
	end
	self:OpenInvest()
	self.actionList = actionList
	self.grid = CG(UIGrid, trans, "Grid", des)
	UITool.SetBtnClick(trans,"CloseBtn",des,self.CloseBtn,self)
	
	self.vip=TF(trans,"vip")
	self.noVip=TF(trans,"novip")
	self.vipInfo=TF(trans,"VIPInfo")
	self.accuPay = TF(trans, "AccuPay")
	self.recharge = TF(trans, "Recharge")
	self.invest = TF(trans, "Invest")
	self.vipInvest = TF(trans, "VIPInvest")
	self.monthInvest = TF(trans, "MonthInvest")
	self.lvInvest = TF(trans, "LvInvest")

	self:InitNorAction()
	self:UpAction()
	self:AddLsnr()
end

function My:AddLsnr()	
	VIPMgr.eVIPStart:Add(self.VIPStart, self)
	--VIPMgr.eVIPEnd:Add(self.VIPEnd, self)
	VIPMgr.eBuy:Add(self.VIPStart,self)
	VIPMgr.eUpAction:Add(self.UpAction, self)
	
	PropMgr.eGetAdd:Add(self.OnAdd,self)
end

function My:RmvLsnr()	
	VIPMgr.eVIPStart:Remove(self.VIPStart, self)
	--VIPMgr.eVIPEnd:Remove(self.VIPEnd, self)
	VIPMgr.eBuy:Remove(self.VIPStart,self)
	VIPMgr.eUpAction:Remove(self.UpAction, self)
	
	PropMgr.eGetAdd:Remove(self.OnAdd,self)
end

function My:OpenCustom()
	local now=TimeTool.GetServerTimeNow()*0.001
	local lerp=VIPMgr.time-now
	togList[5].gameObject:SetActive(lerp<=0 or VIPMgr.isExpire==true)
	togList[6].gameObject:SetActive(lerp>0 and VIPMgr.isExpire~=true)
	self.grid:Reposition()


	self:UpOpenTime()
end

--道具添加
function My:OnAdd(action,dic)
	if action==10006 or action==10022 or action==10023 then		
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

function My:OnClick(go)
	local tp = tonumber(string.sub( go.name, 4 ))
	self:SwitchTg(tp)
end

function My:SwitchTg(tp,isVIPCard)
	if not self.vip then return end
	if self.curTp==tp then return end
	if togList[self.curTp] then togList[self.curTp].value=false end
	self.curTp=tp
	togList[tp].value=true
	if self.curC then 
		self.curC:Close()
		if self.info then self.info:Close() end 
	end
	local c=cDic[tostring(tp)]
	if c then 
		self.curC=c 
	else
		if tp==1 then --充值
			self:ORecharge(c)
			self:DelNorAction(1)
			RechargeMgr:DelRedDot()
		elseif tp==2 then --超值月卡
			self:OMonthInvest(c)
			self:DelNorAction(2)
		elseif tp==3 then --投资理财
			self:OInvest(c)	
			self:DelNorAction(3)
			self:CloseAction()
		elseif tp==4 then --开服累充
			self:OAccuPay(c)
		elseif tp==5 then --VIP购买
			self:OVIPBuy(c)
		elseif tp==6 then --VIP
			self:OVIP(c)
		elseif tp==7 then --VIP投资
			self:OVIPInvest(c)
		elseif tp==8 then --化神投资
			self:OLvInvest(c)
			self:DelNorAction(8)
		end
	end	
	self.curC:Open()

	if tp==5 or tp==6 then
		self:OInfo(isVIPCard)
	end
end

--开服累充
function My:OAccuPay(c)
	if not c then
		c = ObjPool.Get(UIAccuPay)
		c:Init(self.accuPay)
		cDic["4"]=c
	end
	self.curC=c
end

--初始化是否显示标签4
function My:UpOpenTime()
	local info = LivenessInfo:IsOpen(1003)
	-- if not info then
	-- 	togList[4].gameObject:SetActive(false)
	-- else
	-- 	togList[4].gameObject:SetActive(true)
	-- end
	self.grid:Reposition()
end

--关闭返利红点
function My:CloseAction()
	-- local ui = UIMgr.Get(UIMainMenu.Name)
	-- if ui then ui:UpInvestBtn(false) end
end

--初始化默认的红点状态
function My:InitNorAction()
	local invest = InvestMgr.curInvest
	local mInvest = MonthInvestMgr.remainDay
	if invest ~= 0 then self:DelNorAction(3) end
	if mInvest ~= 0 then self:DelNorAction(2) end
	local dic = VIPMgr.norDic
	for k,v in pairs(dic) do
		local index = tonumber(k)
		if VIPMgr.stateDic[k] then
			self:DelNorAction(index)
		elseif v == true then
			self:UpRedDotStae(index, true)
		end
	end
end

--删除默认的红点状态
function My:DelNorAction(index)
	local dic = VIPMgr.norDic
	local key = tostring(index)
	if not dic[key] then return end
	dic[key] = false
	self:UpRedDotStae(index, false)
	VIPMgr.UpRedDot()
end

--更新红点
function My:UpAction()
	local dic = VIPMgr.norDic
	for k,v in pairs(VIPMgr.stateDic) do
		if not dic[k] then
			self:UpRedDotStae(k, v)
		end
	end
end

--更新红点状态
function My:UpRedDotStae(index, state)
	local list = self.actionList
	local go = list[tonumber(index)]
	if not go then
		iTrace.Error("SJ", "没有找到红点物体")
		return
	end
	go:SetActive(state)
end

--开启投资理财 or 化神投资
function My:OpenInvest()
	local isOpen = LvInvestMgr:IsOpen()
	togList[3].gameObject:SetActive(not isOpen)
	togList[8].gameObject:SetActive(isOpen)
	if isOpen then
		VIPMgr.norDic["3"] = not isOpen
	else
		VIPMgr.norDic["8"] = isOpen
	end
end

function My:OMonthInvest(c)
	if not c then
		c = ObjPool.Get(UIMonthInvest)
		c:Init(self.monthInvest)
		cDic["2"]=c
	end
	self.curC=c
end

function My:OInvest(c)
	if not c then
		c = ObjPool.Get(UIInvest)
		c:Init(self.invest)
		cDic["3"]=c
	end
	self.curC=c
end

--化神投资
function My:OLvInvest(c)
	if not c then
		c = ObjPool.Get(UILvInvest)
		c:Init(self.lvInvest)
		cDic["8"]=c
	end
	self.curC=c
end

--充值
function My:ORecharge(c)
	if not c then
		c = ObjPool.Get(UIRecharge)
		c:Init(self.recharge)
		cDic["1"]=c
	end
	self.curC=c
end

--VIP投资
function My:OVIPInvest(c)
	if not c then
		c = ObjPool.Get(UIVIPInvest)
		c:Init(self.vipInvest)
		cDic["7"]=c
	end
	self.curC=c
end

--VIP
function My:OVIP(c)	
	if not c then
		c = ObjPool.Get(VIP)
		c:Init(self.vip)
		cDic["6"]=c
	end
	self.curC=c
end

--VIP信息
function My:OInfo(isVIPCard)
	if not self.info then
		self.info=ObjPool.Get(VIPInfo)
		self.info:Init(self.vipInfo)
	end
	self.info:Open()

	--有VIP打开VIP界面，没有VIP打开购买界面
	local now=TimeTool.GetServerTimeNow()*0.001
	local lerp=VIPMgr.time-now
	if lerp>0 and VIPMgr.isExpire~=true then
		self:VIPStart()
		VIPInfo.btnState=1
	elseif VIPMgr.isExpire==true or lerp<=0 then 
		self:VIPEnd()
		local state = TableTool.GetDicCount(VIPMgr.firstBuy)>0 and 3 or 2
		VIPInfo.btnState=state
	end

	self.info:UpTip()
	self.info:UpVIP()
	if isVIPCard==true then self.info:ReCharge() end
	togList[5].gameObject:SetActive(lerp<=0 or VIPMgr.isExpire==true)
	togList[6].gameObject:SetActive(lerp>0 and VIPMgr.isExpire~=true)
	self.grid:Reposition()
end

--VIP购买
function My:OVIPBuy(c)	
	if not c then 
		c = ObjPool.Get(NoVIP)
		c:Init(self.noVip)
		cDic["5"]=c
	end
	self.curC=c
end

function My:VIPEnd()
	self:SwitchTg(5)
end

function My:VIPStart()
	self:SwitchTg(6)
end

function My:CloseBtn()
	self:Close()
	JumpMgr.eOpenJump()
end

function My:CloseCustom()
	self:RmvLsnr()
	self.curTp=nil
	if self.curC then self.curC:Close() self.curC=nil end
	if self.info then ObjPool.Add(self.info) self.info=nil end
	for k,v in pairs(cDic) do
		ObjPool.Add(v)
		cDic[k]=nil
	end
	TableTool.ClearDic(self.actionList)
end

return My