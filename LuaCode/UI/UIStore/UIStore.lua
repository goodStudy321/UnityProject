--[[
商城
--]]
require("UI/UIStore/StorePanel")

UIStore=UIBase:New{Name="UIStore"}
local My=UIStore

curTp=nil--每周限购
local tgDic = {} --Tog

function My:InitCustom()
	local trans=self.root
	local TF=TransTool.FindChild
	local CG=ComTool.Get	
	
	local grid = TF(trans,"Grid").transform
	local tool = UITool.SetLsnrSelf
	local list = {24,2,3,5,6,11,99}
	for i,v in ipairs(list) do
		local tg = CG(UIToggle,grid,"Tg".. v,self.Name,false)
		if i==3 then tg.gameObject:SetActive(false) end
		local key = tostring(v)
		tgDic[key] = tg
		tool(tg.gameObject,self.OnClick,self,self.Name)
	end

	self.storePanel=ObjPool.Get(StorePanel)
	self.storePanel:Init(TF(trans,"StorePanel"))

	UITool.SetLsnrClick(trans,"CloseBtn",self.Name,self.CloseBtn,self)
	euiopen:Add(self.OnOpenTrig,self)
end

function My:OpenCustom()
	for k,v in pairs(tgDic) do
		local tb = StoreMgr.storeDic[k]
		if not tb or TableTool.GetDicCount(tb)==0 then v.gameObject:SetActive(false) end
		if tonumber(k) == 99 then
			v.gameObject:SetActive(self:IsOpen() and FamilyMgr:JoinFamily())
		end
	end
end

--道绩商城是否开启
function My:IsOpen()
	local cfg = GlobalTemp["135"]
	if cfg == nil then return end
	if User.MapData.Level >= cfg.Value3 then
		return true
	end
	return false
end

--[[1 银两
	2 不绑定元宝
	3 绑定元宝(优先绑定)
	4.绑定元宝
	11荣誉
	23.活跃度
	99.道绩
--]]
function My.CanBuy(store,count)
	if not store then iTrace.eError("xiaoyu","UIStore.CanBuy store==nil")return end	
	if(count==nil)then count=1 end
	local ra = RoleAssets
	local color = "[ffe9bd]"
	local mType = store.priceTp
	local price = store.curPrice*count
	local has = RoleAssets.GetCostAsset(mType)
	if(has<price)then color="[DD4D22FF]" end
	return color
end

function My:OnClick(go)
	local tp = string.sub(go.name,3)
	self:SwatchTg(tp)
end

function My:SwatchTg(tp)
	if(curTp~=nil)then
		if(curTp==tp)then return end
		local tog = tgDic[curTp]
		if tog then tgDic[curTp].value=false end		
	end
	curTp=tostring(tp)
	local tg=tgDic[curTp]
	if not tg then iTrace.eError("xiaoyu","商城类型不存在为 curTp:"..curTp)return end
	tg.value=true	
	self.storePanel.panel:CreateC(curTp)
	self:CheckTop(tp)
end

function My:OnOpenTrig(uiName)
	if uiName~=UITop.Name then return end
	self:CheckTop(curTp)
end

--检查是否添加货币栏
function My:CheckTop(tp)
	local ui = UIMgr.Get(UITop.Name)
	if ui then 
		if not ui.root then return end
		ui:UpData(self.Name,tp)
	end
end

function My:CheckTopData( ... )
	-- body
  end

function My:GetSpecial(t1)
	StoreMgr.OpenStore(t1)
end

function My:OpenTabByIdx(t1,t2,t3,t4)
    self:SwatchTg(t1)
end

function My:CloseBtn()
	JumpMgr.eOpenJump()
	self:Close()
end

function My:CloseCustom()
	curTp=nil 
	TableTool.ClearDic(tgDic)
	if self.storePanel then ObjPool.Add(self.storePanel) self.storePanel=nil end
	My=nil
end

return My