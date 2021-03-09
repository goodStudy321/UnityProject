--[[
VIP信息
--]]
require("UI/UIVIP/RenewPanel")
VIPInfo=Super:New{Name="VIPInfo"}
local My=VIPInfo
My.btnState = 0 --1:升级 2：充值 3：续费

function My:Init(go)
    self.trans=go.transform
	local TF=TransTool.FindChild
    local CG=ComTool.Get
    
	self.Lv=CG(UILabel,self.trans,"Lv",self.Name,false)
	self.tip=CG(UILabel,self.trans,"tip",self.Name,false)
	self.Info=CG(UILabel,self.trans,"Info",self.Name,false)
	self.Slider=CG(UISlider,self.trans,"Slider",self.Name,false)
	self.vipVal=CG(UILabel,self.Slider.transform,"Val",self.Name,false)
	self.RechargeLab=CG(UILabel,self.trans,"RechargeBtn/Label",self.Name,false)
	self.red=TF(self.trans,"RechargeBtn/Red")
	UITool.SetBtnClick(self.trans,"RechargeBtn",self.Name,self.ReCharge,self)
	self.RenewGo=TF(self.trans,"needMoney")
	UITool.SetBtnClick(self.trans,"needMoney",self.Name,self.OnRenew,self)
	
    self:SetEvent("Add")

    self:UpSlider()
    self:UpTime()
end

function My:SetEvent(fn)
	VIPMgr.eVIPTime[fn](VIPMgr.eVIPTime,self.UpTime, self)
	VIPMgr.eVIPTime2[fn](VIPMgr.eVIPTime2,self.UpTip, self)
    VIPMgr.eExp[fn](VIPMgr.eExp,self.UpSlider,self)
	VIPMgr.eVIPLv[fn](VIPMgr.eVIPLv,self.UpVIP,self)
	PropMgr.eUpdate[fn](PropMgr.eUpdate,self.UpDateNum,self)
end

function My:UpSlider()
	local vip=VIPLv[VIPMgr.vipLv+2]
	local exp=VIPMgr.exp
	if(vip==nil)then 
		if VIPMgr.vipLv==#VIPLv-1 then  
			self.Slider.value=1
			self.vipVal.text=exp.."/MAX"
		else
			iTrace.Error(VIPMgr.GetVIPLv(),"xiaoyu VIP等级表为空")
		end
		return 
	end
	self.Slider.value=exp/vip.exp
	self.vipVal.text=exp.."/".. vip.exp

	self:UpTip()
end

function My:UpTip()
	if My.btnState==1 then
		self.RechargeLab.text="VIP 升级"
		self.tip.text="每消费100元宝+1点VIP经验"
	elseif My.btnState==2 then
		self.tip.text="特惠倒计时："..VIPMgr.timer2.remain
		self.RechargeLab.text="充值"
	elseif My.btnState==3 then 
		self.RechargeLab.text="续费"
		self.tip.text="每消费100元宝+1点VIP经验"
	end	
	self.red:SetActive((VIPMgr.GetVIPLv()==0 and TableTool.GetDicCount(VIPMgr.firstBuy)~=0)or (My.btnState==1 and #PropMgr.GetItemsByUseEff(91)>0))
end

function My:UpTime()
	local text=VIPMgr.timer.remain
	if(StrTool.IsNullOrEmpty(text))then text="尚未开通VIP功能" self.Info.text=text return end
	self.Info.text="剩余时间: "..text--.."(每天登陆获得5点成长值，每消耗100元宝获得1点成长值)"
end

function My:UpVIP()
	local vip = VIPMgr.vipLv
	self.Lv.text=tostring(vip)
	self:UpTip()
	self.RenewGo:SetActive(My.btnState==1)
end

function My:UpDateNum()
	if My.btnState~=1 then return end
	self.red:SetActive(#PropMgr.GetItemsByUseEff(91)>0)
end

--充值
function My:ReCharge()
	if My.btnState==1 then --升级
		self:OnRenew(1)
	elseif My.btnState==2 then --充值
		VIPMgr.OpenVIP(1)
	elseif My.btnState==3 then --续费
		self:OnRenew()
	end
end

function My:OnRenew(btnState)
	if not btnState then btnState=3 end
	if not self.renewPanel then 
		self.renewPanel=ObjPool.Get(RenewPanel) 
		self.renewPanel:Init(TransTool.FindChild(self.trans,"RenewPanel"))
	end
	self.renewPanel:Open()
	self.renewPanel:UpData(btnState)
end

function My:Open()
    self.trans.gameObject:SetActive(true)
end

function My:Close()
    self.trans.gameObject:SetActive(false)
end

function My:Dispose()
	My.btnState=0
	self:SetEvent("Remove")
	if self.renewPanel then ObjPool.Add(self.renewPanel) self.renewPanel=nil end
	TableTool.ClearUserData(self)
end