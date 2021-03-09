require("UI/UIStore/StoreCell")
local AssetMgr=Loong.Game.AssetMgr

Panel=Super:New{Name="Panel"}
local My=Panel

function My:Ctor()
	self.storeDic={}
	self.curTp=1
	self.curCell = nil--当前选中的道具
end

function My:Init(go)
	self.trans=go.transform
	self.grid=ComTool.Get(UIGrid,self.trans,"Grid",self.Name,false)
	self.panel=go:GetComponent(typeof(UIScrollView))

	self:SortOutGrid()

	-- for k,v in pairs(StoreMgr.limitDic) do
	-- 	self:Buylimit(k,v)
	-- end

	self:AddE()

	--self.timer=ObjPool.Get(iTimer)
end

function My:AddE()
	StoreMgr.eLimit:Add(self.Buylimit,self)
	StoreCell.eClick:Add(self.ClickCell,self)
	RoleAssets.eUpAsset:Add(self.PropChg,self)
end

function My:RemoveE()
	StoreMgr.eLimit:Remove(self.Buylimit,self)
	StoreCell.eClick:Remove(self.ClickCell,self)
	RoleAssets.eUpAsset:Remove(self.PropChg,self);
end

--属性改变
function My:PropChg(ty)
  for k,v in pairs(self.storeDic) do
  	local store = StoreData[k]
  	v:SPrice(store)
  end
end

function My:ClickCell(id)
	self:DealLight(self.curTp,false)
	self.clickId=id
end

function My:DealLight(tp,state)
	local id=self.clickId
	if(id~=nil)then 
		local cell=self.storeDic[tostring(id)]
		cell:SBg(state) 
	end
end

function My:Buylimit(key,val)
	key=tostring(key)
	local storeCell = self.storeDic[key]
	if(storeCell==nil)then return end
	local store=StoreData[key]
	storeCell:SNum(store)
end

--排序
function My:SortOutGrid()
	self.grid.onCustomSort=function(a,b) return self:SortName(a,b)end
end

function My:SortName(a,b)
	local num1 = tonumber(a.name)
	local num2 = tonumber(b.name)
	if(num1<num2)then
		return -1
	elseif (num1>num2)then
		return 1
	else
		return 0
	end
end

function My:CreateC(tp)
	--if self.isbegin==false then return end
	--取消上一标签页高亮的
	self:DealLight(self.curTp,false)
	self:CleanStore()

	self.curTp=tp

	--TableTool.ClearDicToPool(self.storeDic)
	local tb=StoreMgr.storeDic[tostring(tp)]
	if(tb==nil)then return end
	local allcount = TableTool.GetDicCount(tb)
	for k,v in pairs(tb) do
		allcount=allcount-1
		local lv = v.lv
		local cate = User.instance.MapData.Category
		local isShow = (v.cate==0) or (cate==v.cate)
		if(lv==nil or User.instance.MapData.Level>=lv) and isShow then
			self:SCell(v,allcount)
		end
		if allcount==0 then
			self:Light()
		end
	end
	self.grid:Reposition()
	self.panel:ResetPosition()

	self:SelectCell()
	-- self.isbegin=false
	-- self.timer.seconds=0.1
	-- self.timer.complete:Add(self.Light,self)
	-- self.timer:Start()
end

function My:SCell(store,allcount)
	local del = ObjPool.Get(DelGbj)
	del:Adds(store,allcount)
	del:SetFunc(self.Handler,self)
	self.obj = obj
	AssetMgr.LoadPrefab("StoreCell",GbjHandler(del.Execute,del))
end

function My:Handler(go,store,allcount)
	go.transform.parent=self.grid.transform
	go.name=tostring(store.id)
	go:SetActive(false)
	go:SetActive(true)
	go.transform.localScale=Vector3.one
	go.transform.localPosition=Vector3.zero

	local item=ItemData[tostring(store.PropId)]
	if(item==nil)then iTrace.Error("xiaoyu","道具表为空 id:".. store.PropId) return end
	local cell=ObjPool.Get(StoreCell)
	cell:Init(go)
	cell:UpData(item,store)
	cell:ShowCan(store)
	cell:ClickBg()
	self.storeDic[tostring(store.id)]=cell
	if allcount==0 then self:Light() end
end

function My:Light()
	if LuaTool.IsNull(self.trans) then return end
	--显示当前应该高亮的
	local id=self.clickId
	if(id==nil)then
		local name = nil
		if StoreMgr.selectId then
			name = tostring(StoreMgr.selectId)
			-- StoreMgr.selectId = nil
		else
			name = self.grid:GetChild(0).name
		end
		if name == nil then
			iTrace.eError("GS","请检查商城标签页配置商品id")
			return
		end
		local cell = self.storeDic[name]
		cell:SBg(true)
		cell.eClick(tonumber(name))
		self.clickId=tonumber(name)

		if StoreMgr.selectId then
			self.curCell = cell.trans
			StoreMgr.selectId = nil
		end
	else
		local cell = self.storeDic[tostring(id)]
		cell.eClick(id)
		self:DealLight(self.curTp,true)
	end	
	--self.isbegin=true
end

--选中道具（如果在UIScrollView范围外会自适应）
function My:SelectCell()
	if self.curCell then
		local spr = ComTool.Get(UISprite, self.curCell, "Bg")
		soonTool.ChooseInScrollview(self.curCell, self.panel, spr)
		self.curCell = nil
	end
end

function My:Open()
	--self:Light()
end

function My:CleanStore()
	for k,v in pairs(self.storeDic) do
 		v:DestroyGo()
 		ObjPool.Add(v)
 		self.storeDic[k]=nil
	 end
	 self.clickId=nil
end

function My:Dispose()
	self.curTp=nil
	--if self.timer then self.timer:AutoToPool() self.timer=nil end
 	--TableTool.ClearDicToPool(self.storeDic)
 	self:CleanStore()	
	self:RemoveE()
	TableTool.ClearUserData(self)
end





