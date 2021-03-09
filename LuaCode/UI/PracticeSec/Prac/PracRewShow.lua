PracRewShow = Super:New{Name = "PracRewShow"}
local My = PracRewShow

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local TF = TransTool.Find
	local US = UITool.SetLsnrSelf
	local TFC = TransTool.FindChild

	self.go = root.gameObject
	self.closeBtn = TFC(root,"CloseBtn",des)
	self.buyBtn = TFC(root,"buyBtn",des)
	self.buyLab = CG(UILabel,root,"buyBtn/lb",des)
	self.grid = CG(UIGrid,root,"scrollV/grid",des)

	self.rewardTab = {}
	self:SetLnsr("Add")
	US(self.buyBtn,self.ClickBuy,self,des,false)
	US(self.closeBtn,self.ClickClose,self,des,false)
	self:RefreshReward()
	self:ShowCost()
end

function My:SetLnsr(func)
    RechargeMgr.eRecharge[func](RechargeMgr.eRecharge, self.RespRecharge, self)
end

--响应充值
function My:RespRecharge(orderId, url, proID,msg)
    RechargeMgr:StartRecharge(orderId, url, proID, msg)
end

function My:ClickClose()
	self:SetActive(false)
end

function My:ShowCost()
	local money = RechargeCfg[37].gold
	self.payId = RechargeCfg[37].id
	self.buyLab.text = money .. "元"
end

function My:ClickBuy()
	RechargeMgr:BuyGold("Func1", "Func2", "Func3", "Func4", self)
end

--编辑器
function My:Func1()
    
end

--Android
function My:Func2()
    local payId = self.payId
    RechargeMgr:ReqRecharge(payId)
end

--IOS
function My:Func3()
    local payId = self.payId
    RechargeMgr:ReqRecharge(payId)
end

--其他
function My:Func4()
    
end

function My:SetActive(ac)
	self.go:SetActive(ac)
end

function My:RefreshReward()
	local data = PracSecMgr:GetShowRew()
	for k,v in pairs(data) do
		local item = ObjPool.Get(UIItemCell)
		item:InitLoadPool(self.grid.transform)
		item:UpData(v.id,v.num)
		-- item:UpBind(1)
		table.insert(self.rewardTab,item)
	end
    self.grid:Reposition()
end

function My:Dispose()
	self:SetLnsr("Remove")
	TableTool.ClearListToPool(self.rewardTab)
	TableTool.ClearUserData(self)
end

return My
