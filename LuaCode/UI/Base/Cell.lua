--[[
格子  Quality  Icon  Lab
得自己手动销毁格子对象
--]]
local AssetMgr=Loong.Game.AssetMgr
Cell=Super:New{Name="Cell"}
local My=Cell
local CG=ComTool.Get
local TF=TransTool.FindChild

My.eMarketShow = Event()

function My:Ctor()
	self.starList={}
	self.texList = {}
	self.eClickCell = Event()
	self.btnList={}
	self.IsClick = true
end

--自己传递Go
function My:Init(go)
	if LuaTool.IsNull(go) then iTrace.eError("xiaoyu"," init go ==null") return end
	self.trans=go.transform
	self.Qua=self.trans:GetComponent(typeof(UISprite))
	self.Qua.color = Color.New(255, 255, 255, 255)/255.0
	self.Icon=CG(UITexture,self.trans,"Icon",self.Name,false)
	self.Lab=CG(UILabel,self.trans,"Lab",self.Name,false)
	self.lock = CG(UISprite,self.trans,"eff",self.Name,false)
	self.rank=CG(UILabel,self.trans,"rank",self.Name,false)
	local Ego = TF(self.trans,"EN")
	self.limit = TF(self.trans,"limit")
	if self.limit then
		self.limit:SetActive(false);
	end
	if Ego then
		self.EN = Ego.transform
	end
	if self.EN then
		self.work=TF(self.EN,"work")
		self.bind=TF(self.EN,"lock")

		for i=1,3 do
			self.starList[i]=TF(self.EN,"S".. i)
		end
	end
	UITool.SetLsnrSelf(go,self.OnClick,self,self.Name, false)
	self.width=self.Qua.width*self.trans.localScale.x

	self:InitCustom()
end

function My:InitCustom( ... )
	-- body

	self.delayResetCount = 0;
	self.effScale = Vector3.one;
end

function My:OnClick(go)
	if self.IsClick == false then return end
	self.eClickCell(go)
end

--从对象池加载出来的load方法 默认是"ItemCell"
function My:InitLoadPool(parent,scale,obj,path, func,pos)
	self.ispool=true
	if not scale then scale=1 end
	if not pos then pos=Vector3.zero end
	if not path then path="ItemCell" end
	local del = ObjPool.Get(DelGbj)
	del:Adds(parent,scale,pos,obj, func)
	del:SetFunc(self.LoadCb,self)
	AssetMgr.LoadPrefab(path,GbjHandler(del.Execute,del))
end

function My:LoadCb(go,parent,scale,pos,obj, func)
	local trans=go.transform
	trans:SetParent(parent)
	trans.localPosition=pos
	trans.localScale=Vector3.one*scale
	go:SetActive(false)
	go:SetActive(true)
	go.name="601"
	self:Init(go)
	if obj and obj.LoadCD then
		obj:LoadCD(go)
	end

	if func then
		func()
	end
end

--obj 为ItemData或者type_id都可以
function My:UpData(obj,num,isQua,scale, extraEff, delayShowEff)
	self:Clean()
	if obj==nil then iTrace.eError("xiaoyu","传入参数为空")return end
	if(type(obj)=="table") then
		self.type_id=tostring(obj.id)
		self.item=obj
	else
		if(type(obj)=="number")then
			self.tId=obj
			self.type_id=tostring(obj)
		else
			self.tId=tonumber(obj)
			self.type_id=obj
		end
		--判断是不是服务端生成的特殊道具
		self:FindCreate()
		if not self.item then 
			iTrace.eError("xiaoyu","道具表为空 id: "..tostring(self.type_id))
			return 
		end
	end

	if delayShowEff ~= nil then
		self.delayResetCount = delayShowEff;
	end

	self:UpIcon(self.item)
	self:UpQua(self.item, isQua, scale)
	self:UpLab(num) 
	self:UpWork()
	self:SetLimit()
	if(self.item.uFx==1)then
		self.equip =EquipBaseTemp[self.type_id] 
		if(self.equip==nil)then iTrace.sLog("xiaoyu","装备表为空 type_id: "..self.type_id)return end
		self:UpStar()		
	end
	self:UpRank()
end

--设置限标识
function My:SetLimit()
	local cfg =UIMisc.FindCreate(self.type_id);
	if cfg.uFx == 94 or cfg.uFx == 95 then
		if self.limit then
			self.limit:SetActive(true);
		end
	end
end

-- 是否为限时上架道具
function My:ShowLimit(endTime,tb)
	if not endTime then return end
	if tb then
		if tb.bind == true then return end
	end
	local price = self.item.startPrice
	if not price then return end
	-- local now = TimeTool.GetServerTimeNow()*0.001
	-- local time = endTime - now
	local now =  TimeTool.GetServerTimeNow()*0.001
	if now - endTime <= 0 then
		-- if self.tb then
		-- 	self.tb.bind = true
		-- end
		--if self.limit then
			--self.limit:SetActive(false)
		--end
	else
		-- if not self.time then
		-- 	self.time = ObjPool.Get(DateTimer)
		-- end
		-- self.time:Stop()
		-- self.time.complete:Add(self.CompleteCb, self)
		-- self.time.seconds = time
		-- self.time:Start()
		--if self.limit then
			--self.limit:SetActive(true)
		--end
	end
end

-- function My:CompleteCb()
-- 	if LuaTool.IsNull(self.limit)~=true then
-- 		--self.limit:SetActive(false)
-- 		self:UpBind(true)
-- 		local ui = UIMgr.Get(PropTip.Name)
-- 		if ui then
-- 			UIMgr.Close(PropTip.Name)
-- 		end
-- 		-- My.eMarketShow()
-- 	end
-- end


function My:SetActive(bool)
	if self.trans then
		self.trans.gameObject:SetActive(bool)
	end
end

function My:IsActive()
	return self.trans and self.trans.gameObject.activeSelf
end

function My:SetGray(bool, canClick)
	if self.trans then
		if bool then
			UITool.SetAllGray(self.trans, canClick)
			UITool.SetNormal(self.Lab)
			self.BLab=ComTool.Get(UILabel,self.trans,"BLab",self.Name,false)
			if self.BLab  then
				UITool.SetNormal(self.BLab)
			end
		else
			UITool.SetAllNormal(self.trans)
		end
	end
end
function My:FindCreate()
	if self.tId>70000 and self.tId<90000 then  --服务端生成的特殊道具
		local c = ItemCreate[self.type_id]
		if(c==nil)then self.item=ItemData[self.type_id] return end
		local cate = User.instance.MapData.Category
		if(cate==1)then
			self.type_id=tostring(c.w1)
		elseif(cate==2)then
			self.type_id=tostring(c.w2)
		end
		self.item=ItemData[self.type_id]
	else
		self.item=ItemData[self.type_id]
	end
end

--icon
function My:UpIcon(item,ignore)
	local icon = nil 
	if type(item)=="table" then
		icon=item.icon
	else
		icon=item 
	end
	if(ignore==nil and self.iconName and self.iconName ==icon)then return end
	self.iconName=icon
	AssetMgr.Instance:Load(icon,ObjHandler(self.LoadIcon,self))
end

function My:LoadIcon(obj)
	if LuaTool.IsNull(self.Icon)then return end
	self.Icon.mainTexture=obj
	table.insert(self.texList, obj.name)
end

--道具流光效果 isQua是否需要流光效果(默认需要)
--白兰紫橙红粉
local quaList = {"","","FX_Equip_purple","FX_Equip_gold","FX_Equip_red","FX_Equip_Feng"}
local specialQuaList = {"FX_Equip_White01","FX_Equip_Blue01","FX_Equip_Violet01","FX_Equip_Orange01","FX_Equip_Gules01","FX_Equip_Pink01"}
function My:UpQua(item,isQua,scale)
	if(scale==nil)then scale=1 end
	if(isQua==nil)then isQua=true end
	local qua= item.quality
	self.Qua.spriteName=UIMisc.GetQuaPath(qua)
	if(isQua==false)then return end
	local isSpecial = self:UpSpecialItem(item.id)
	local path = isSpecial and specialQuaList[qua] or quaList[qua]
	if(StrTool.IsNullOrEmpty(path)~=true)then
		self.isLoading=true
		local del = ObjPool.Get(DelGbj)
		del:Add(scale)
		del:SetFunc(self.LoadEff,self)
		AssetMgr.LoadPrefab(path, GbjHandler(del.Execute,del))
	end
end

--特殊手镯&戒指
function My:UpSpecialItem(type_id)
	local temp = SpecialItemData[tostring(type_id)]
	return temp
end

function My:UpExtraEff()
	AssetMgr.LoadPrefab("FX_Equipsj_red", GbjHandler(self.LoadExTraEff,self))
end

function My:LoadExTraEff(go)	
	if LuaTool.IsNull(go) then return end
	self.exEff = go
	local trans=go.transform
	trans:SetParent(self.lock.transform)
    go:SetActive(true)
    trans.localScale = Vector3.one
	trans.localPosition = Vector3.zero
	local effBind =  ComTool.GetSelf(UIEffectBinding, trans, "获取特效绑定");
	if effBind ~= nil then
		effBind.enabled = false;
		effBind.enabled = true;
	end
end

function My:UnloadExtraEff()
	if self.exEff then
		GbjPool:Add(self.exEff)
		self.exEff = nil
	end
end



function My:LoadEff(go,scale)
	--// LY add end
	if LuaTool.IsNull(go) then return end
	if LuaTool.IsNull(self.lock) then return end

	self.isLoading = false
	go:SetActive(false);
	self.eff = go

	--// LY add begin
	self.lock.color = Color.New(255, 255, 255, 2) / 255.0;

	self.effScale = Vector3.one * scale;
	if self.delayResetCount == nil or self.delayResetCount <= 0 then
		self:ShowEff();
	end

	-- go:SetActive(false);
	-- go.transform:SetParent(self.lock.transform)
    -- go.transform.localScale = Vector3.one*scale
	-- go.transform.localPosition = Vector3.New(0,0,0)
	-- go:SetActive(true)
	
	--// LY add begin
	-- local CF = ComTool.GetSelf;
	-- local effBind = CF(UIEffectBinding, go.transform, "获取特效绑定");
	-- if effBind ~= nil then
	-- 	effBind.enabled = false;
	-- 	effBind.enabled = true;
	-- end
	--// LY add end
end

function My:UpLab(num, isB)
	isB = isB or false
	if isB==true then
		if not self.BLab then
			self.BLab=ComTool.Get(UILabel,self.trans,"BLab",self.Name,false)
		end
		self.BLab.gameObject:SetActive(isB)
		self.BLab.text = num
	else
		self.Lab.text=UIMisc.ToString(num)

		if self.BLab then self.BLab.gameObject:SetActive(isB) end
	end
end

function My:UpRank()
	local uFx = self.item.uFx or 0
	if uFx==1 then 
		self.rank.text=tostring(self.equip.wearRank).."阶"
		self.rank.gameObject:SetActive(true)
	elseif uFx>=21 and uFx<=24 then --货币
		local arg = self.item.uFxArg
		if arg then 
			local text = UIMisc.ToString(arg[1])
			self.rank.text=text
			self.rank.gameObject:SetActive(true)
		end
	end
end

--装备星级
function My:UpStar()
	local star = self.equip.startLv or 0
	for i,v in ipairs(self.starList) do
		local state=true
		if i>star then state=false end
		v:SetActive(state)
	end
end

function My:SetStar(star)
	for i,v in ipairs(self.starList) do
		local state=true
		if i>star then state=false end
		v:SetActive(state)
	end
end

--职业
function My:UpWork(use,work)
	if use then 		
		self.work:SetActive(false)
		return
	end
	self.isUse=true
	local w = self.item.cateLim or 0
	if not work then work=User.instance.MapData.Category end
	if(work~=w and w~=0)then
		self.work:SetActive(true)
		self.isUse=false
	end
end

--绑定
function My:UpBind(isBind)
	if isBind==1 then isBind=true elseif isBind==0 then  isBind=false end
	if isBind==nil then isBind=false end
	self.bind:SetActive(isBind)
	self.isBind=isBind
end

--选中
function My:Select(active)
	if not self.select then self.select=TF(self.trans,"select") end
	self.select:SetActive(active)
end

--吞噬
function My:Devour(active)
	if not self.devour then self.devour=TF(self.trans,"devour") end
	self.devour:SetActive(active)
end

--首冲活动左上角的
function My:FirstPayLeft(path)	 
	if not self.left then self.left=CG(UISprite,self.trans,"left",self.Name,false) end
	self.left.gameObject:SetActive(true)
	self.left.spriteName=path
end

--锁定
function My:Lock(a)
	self.lock.alpha=a
end

--职业
function My:UpWork(use,work)
	if use then 		
		self.work:SetActive(false)
		return
	end
	self.isUse=true
	local w = self.item.cateLim or 0
	if not work then work=User.instance.MapData.Category end
	if(work~=w and w~=0)then
		self.work:SetActive(true)
		self.isUse=false
	end
end

function My:UpdateIconArr(status)
	self:IconUp(status)
	self:IconDown(not status)
end

--背包里面需要道具穿戴更好的效果
function My:IconUp(isActive)
	if(isActive==nil)then isActive=false end
	if(self.Up==nil)then 
		self.Up=TF(self.trans,"Up")
	end
	if(self.isUse==false)then isActive=false end
	self.Up:SetActive(isActive)
end

--更差的装备
function My:IconDown(isActive)
	if(isActive==nil)then isActive=false end
	if(self.Down==nil)then 
		self.Down=TF(self.trans,"Down")
	end
	if(self.isUse==false)then isActive=false end
	self.Down:SetActive(isActive)
end

function My:Clean()
	self:unloadEff()
	self:UnloadExtraEff()
	if LuaTool.IsNull(self.select)~=true then 
		self.select:SetActive(false) 
	end
	if LuaTool.IsNull(self.devour)~=true then
		self.devour:SetActive(false)
	end
	if LuaTool.IsNull(self.Up)~=true then
		self.Up:SetActive(false)		
	end
	if LuaTool.IsNull(self.Down)~=true then
		self.Down:SetActive(false)
	end
	if LuaTool.IsNull(self.limit)~=true then
		self.limit:SetActive(false)
	end
	if LuaTool.IsNull(self.EN)~=true then
		if LuaTool.IsNull(self.work)~=true then self.work:SetActive(false) end
		if LuaTool.IsNull(self.bind)~=true then self.bind:SetActive(false) end
	end
	for i,v in ipairs(self.starList) do
		if LuaTool.IsNull(v)~=true then v:SetActive(false)end
	end
	if LuaTool.IsNull(self.lock)~=true then
		self:Lock(0.001)
	end
	if LuaTool.IsNull(self.BLab)~=true then self.BLab.text = "" end
	self.equip=nil
	self.type_id=nil
	self.item=nil
	if LuaTool.IsNull(self.Lab)~=true then self.Lab.text="" end
	if LuaTool.IsNull(self.rank)~=true then self.rank.text="" end
	if LuaTool.IsNull(self.Icon)~=true then
		self.Icon.mainTexture=nil
		self.Icon.gameObject:SetActive(false)
		self.Icon.gameObject:SetActive(true)
		self.iconName = nil
	end
	if LuaTool.IsNull(self.Qua)~=true then 
		self.Qua.spriteName=UIMisc.GetQuaPath(1)
	end
	if LuaTool.IsNull(self.rank)~=true then self.rank.gameObject:SetActive(false) end
	--if LuaTool.IsNull(self.limit)~=true then
		--self.limit:SetActive(false)
	--end
	if LuaTool.IsNull(self.left)~=true then
		self.left.gameObject:SetActive(false)
	end
	if self.time then
        self.time:Stop()
        self.time:AutoToPool()
        self.time = nil
	end
	self.doubleClick=nil
	self.isdouble=nil
	if self.timer then self.timer:AutoToPool() self.timer=nil end
	if LuaTool.IsNull(self.trans)~=true then UIEventListener.Get(self.trans.gameObject).onDoubleClick=nil end
end



function My:Dispose()
	if not LuaTool.IsNull(self.trans) and not LuaTool.IsNull(self.trans.gameObject) then
		UITool.SetAllNormal(self.trans.gameObject)
	end
	self.eClickCell:Clear()
	self:Clean()
	self:ClearBtn()
	self:DisposeCus()
	self.trans.name="ItemCell"
	self.trans.localScale=Vector3.one
	self.ispool=nil
	ListTool.Clear(self.starList)
	AssetTool.UnloadTex(self.texList)
	ListTool.Clear(self.texList)
	ListTool.Clear(self.btnList)
	TableTool.ClearUserData(self)
end

function My:ClearBtn()	
	if LuaTool.IsNull(self.trans) then return end
	local scale = ComTool.Add(self.trans, UIButtonScale)
	if scale then
		Destroy(scale)
	end
end

function My:unloadEff()
	if LuaTool.IsNull(self.eff)~=true then
		self.eff:SetActive(false);
		self.eff.transform.parent = nil;
		GbjPool:Add(self.eff)
		self.eff=nil
	end
end

function My:SetEff(state)
	if LuaTool.IsNull(self.eff) then return end
	self.eff:SetActive(state)
end

function My:UnloadTex()
	if self.iconName then 
		AssetMgr.Instance:Unload(self.iconName,false)
		TableTool.Remove(self.texList, string.sub(self.iconName, 1, -5))
		self.iconName=nil
	end
end

--放进对象池
function My:DestroyGo()
	if self.ispool~=true then 
		iTrace.eError("xioayu","打死你啊不是从对象池拿的还放对象池里帮你销毁了")
		self:Destroy()
		return 
	end
	self:unloadEff()
	if LuaTool.IsNull(self.trans.gameObject)~=true then GbjPool:Add(self.trans.gameObject)end
end	

--直接销毁
function My:Destroy()
	if  LuaTool.IsNull(self.trans) or LuaTool.IsNull(self.trans.gameObject) then return end
	self:unloadEff()
	if LuaTool.IsNull(self.trans.gameObject)~=true then Destroy(self.trans.gameObject)end
end

function My:DisposeCus()
		
end

--- /// LY add begin

function My:ShowEff()
	if LuaTool.IsNull(self.eff) == true then
		return;
	end
	local trans=self.eff.transform
	trans:SetParent(self.lock.transform);
    trans.localScale = self.effScale;
	trans.localPosition = Vector3.New(0,0,0)
	self.eff:SetActive(true)
end

function My:FrameUpdate()
	if self.delayResetCount ~= nil and self.delayResetCount > 0 then
		self.delayResetCount = self.delayResetCount - 1;
		if self.delayResetCount <= 0 then
			self.delayResetCount = 0;
			
			self:ShowEff();
		end
	end
end

--- ///