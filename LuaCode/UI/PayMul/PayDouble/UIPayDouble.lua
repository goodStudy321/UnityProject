require("UI/PayMul/PayDouble/DoublePayBtn")
UIPayDouble = Super:New{Name = "UIPayDouble"}

local My = UIPayDouble

local AssetMgr = Loong.Game.AssetMgr

function My:Init(root)
	local des = self.Name
	local CG = ComTool.Get
	local Find = TransTool.Find
	local USBC = UITool.SetBtnClick
	local FindC = TransTool.FindChild

	self.go = root.gameObject
	self.Model = Find(root,"Model",des)
	self.btnGrid = CG(UIGrid, root, "btnGrid", des)
	self.btnItem = FindC(root, "btnGrid/btn", des)
	self.btnItem:SetActive(false)
	self.bgTexture = CG(UITexture,root,"bgT",des)
	self.lab1 = CG(UILabel, root, "labs/lab1", des)
	self.getMoneyLab = CG(UILabel, root, "labs/lab3", des)
	self.warLab = CG(UILabel, root, "labs/lab6", des)
	self.desLab = CG(UILabel, root, "labs/lab7", des)
	self.timerLab = CG(UILabel, root, "labs/lab8", des)
	self.rewardGrid = CG(UIGrid,root,"rewardBg/grid",des)
	self.rewardTab = {}
	self.btnTab = {}
	self:LoadModel()
	self:SetPayBtn()
	self:InitLab()
	self:RefreshReward()
	self:Countdown()
	self:SetLnsr("Add")
end

function My:SetLnsr(func)
    RechargeMgr.eRecharge[func](RechargeMgr.eRecharge, self.RespRecharge, self)
end

--响应充值
function My:RespRecharge(orderId, url, proID,msg)
	local cfg = GlobalTemp["179"]
	local double = cfg.Value2[4] --倍数
	RechargeMgr:StartRecharge(orderId, url, proID, msg,double)
	self:CloseUIPayMul()
end

function My:Countdown()
    local info = NewActivMgr:GetActivInfo(2000)
    if not info then return end
    local startTime = 0
    local endTime = 0
    local severTime = 0
    local seconds = 0
    startTime = info.startTime
    endTime = info.endTime
    severTime = TimeTool.GetServerTimeNow()*0.001
    seconds = info.endTime - severTime
    local isOpen = PayDoubleMgr:IsOpen()
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
	self:CloseUIPayMul()
end

function My:CloseUIPayMul()
	local active = UIMgr.GetActive(UIPayMul.Name)
	local ui = UIMgr.Get(UIPayMul.Name)
	if ui and active ~= -1 then ui:Close() end
end

--更新显示
function My:UpShow(state)
	if state == true then
		PayMulMgr:UpAction(1,false)
	end
	self.go:SetActive(state)
 end

function My:InitLab()
	local cfg = GlobalTemp["179"]
	local getGold = cfg.Value2[1]
	local war = cfg.Value2[2]
	local double = cfg.Value2[4]
	self.lab1.text = ""
	self.getMoneyLab.text = string.format("%s元充值大礼包",getGold)
	self.warLab.text = war
	self.desLab.text = string.format("机会只有一次！！！以下仅可选择一个获得%s倍元宝",double)
end

function My:RefreshReward()
	local reward = GlobalTemp["179"].Value1
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
	local id = GlobalTemp["179"].Value2[3]
	local path = ItemModel[tostring(id)].model[1]
	AssetMgr.LoadPrefab(path,GbjHandler(self.LoadModelCb,self))
end

function My:LoadModelCb(go)
	go:SetActive(true)
	go.transform.parent=self.Model.transform
	go.transform.localPosition=Vector3.zero
	go.transform.localScale=Vector3.one*200
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

function My:SetPayBtn()
	local btntemp = PayDoubleMgr:GetPayIds()
	local len = #btntemp
    local btnT = self.btnTab
    local count = #btnT
    local max = count >= len and count or len
    local min = count + len - max
    for i = 1,max do
        if i <= min then
            btnT[i]:UpdateData(btntemp[i])
            btnT[i]:BtnAct(true)
        elseif i <= count then
            btnT[i]:BtnAct(false)
        else
            local go = Instantiate(self.btnItem)
            TransTool.AddChild(self.btnGrid.transform,go.transform)
            local item = ObjPool.Get(DoublePayBtn)
            item:Init(go)
            UITool.SetLsnrSelf(go,self.PayFunc,self,"btn",false)
            item:BtnAct(true)
            item:UpdateData(btntemp[i])
            table.insert(self.btnTab, item)
        end
    end
    self.btnGrid:Reposition()
end

--点击充值项
function My:PayFunc(obj)
	self.payId = tonumber(obj.name)
  	RechargeMgr:BuyGold("Func1", "Func2", "Func3", "Func4", self)
end

--编辑器
function My:Func1()
	-- local payId = self.payId
	-- if payId == nil then
	-- 	iTrace.eError("GS","首充倍送充值id为空")
	-- 	return
	-- end
	-- RechargeMgr:ReqRecharge(payId)
end

--Android
function My:Func2()
	local payId = self.payId
	if payId == nil then
		iTrace.eError("GS","首充倍送充值id为空")
		return
	end
	RechargeMgr:ReqRecharge(payId)
end

--IOS
function My:Func3()
	local payId = self.payId
	if payId == nil then
		iTrace.eError("GS","首充倍送充值id为空")
		return
	end
	RechargeMgr:ReqRecharge(payId)
end

--其他
function My:Func4()
  
end


function My:Dispose()
	self:SetLnsr("Remove")
	if self.timer then
        self.timer:AutoToPool()
        self.timer = nil
    end
	self:ClearModel()
	TableTool.ClearListToPool(self.rewardTab)
end

return My
