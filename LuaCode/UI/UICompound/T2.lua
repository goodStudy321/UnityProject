--[[
道具合成
--]]
T2=Super:New{Name="T2"}
local My = T2
local Dic = nil --道具合成表
local cellList={}

function My:Init(go,tt)
	self.tt=tt
	self.trans=go.transform
	local CG = ComTool.Get

	self.Grid=CG(UIGrid,self.trans,"Grid",self.Name,false)
	for i=1,2 do
		local cell=ObjPool.Get(UIItemCell)
		cell:InitLoadPool(self.Grid.transform)
		cellList[i]=cell
	end
	self.Grid:Reposition()
	self.tog=CG(UIToggle,self.trans,"tog",self.Name,false)
	self.tog.value=EquipMgr.noshowRed
	UITool.SetBtnSelf(self.tog.gameObject,self.OnTog,self,self.Name)
	
	Dic=EquipMgr.goodDic
	self.str=ObjPool.Get(StrBuffer)

	self.islong=true
end

function My:OnTog()
	local val = self.tog.value
	EquipMgr.noshowRed=val
	EquipMgr.SetRed32()
end

--道具合成返回
function My:OnCompose()
	for i=1,2 do
		local cell = cellList[i]
		local need = self.info.needItems[i]
		if not need then cell:Clean() cell:Lock(1) break end
		local num=need.val
		local id = need.id
		local has = PropMgr.TypeIdByNum(id)
		local color = has>=num and "[F4DDBDFF]" or "[CC2500FF]"
		self.str:Dispose()
		self.str:Apd(color):Apd(has):Apd("/"):Apd(num)
		cell:UpData(id,self.str:ToStr())
	end
end

function My:UpData()
	for i,v in ipairs(cellList) do
		v:Clean()
	end
	local tId = tonumber(self.tY)
	self.info = SynInfo[tId]
	self:OnCompose()
	local id = self.info.items[1]
	self.tt:UpData(id)
end

function My:CreateTb(jumpItem)
	local TF = TransTool.FindChild
	local CG=ComTool.Get
	local U = UITool.SetLsnrSelf
	local isFirst = true
	for i,v in pairs(Dic) do
		if(#v>0)then
			--标签
			local ISSHOW=true
			if i=="8" then
				ISSHOW=self:IsShowSuit(v)
			end
			if ISSHOW==true then 
				local sync = SynInfo[v[1]]
				local go=self.tt:CreateT(sync.title,i)
				U(go,self.OnT,self,self.Name, false)
				local table =CG(UITable,go.transform,"Tween/table",self.Name,false) 
				for i1,v1 in ipairs(v) do
					local info=SynInfo[v1]
					local isShow=true
					if i=="8" then
						isShow=self:CheckSuit(info)
					end
					if isShow==true then 
						local r = info.des
						local gg = self.tt:CreateTg(table.transform,r,i,tostring(v1))
						U(gg,self.OnTg,self,self.Name)
						if jumpItem and jumpItem~=0 then
							local needItems = info.needItems
							local items = info.items
							local isjump = false
							if items[1]==jumpItem then
								isjump=true
							else
								for i2,v2 in ipairs(needItems) do
									if v2.id==jumpItem then
										isjump=true
									end
								end
							end
							if isjump==true then 
								self:OnT(go) 
								self:OnTg(gg) 
								isFirst=false
							end
						else
							if(i1==1 and isFirst==true)then 
								self:OnT(go) 
								self:OnTg(gg) 
							end
						end
					end
				end	
			end			
		end
		isFirst=false
		table.repositionNow=true	
	end
	self.tt.table.repositionNow=true
end

function My:IsShowSuit(v)
	for i1,v1 in ipairs(v) do
		local info=SynInfo[v1]
		local isShow=self:CheckSuit(info)
		if isShow==true then return true end
	end
	return false
end

--合成表
function My:CheckSuit(cfg)
	local suitInfo=SuitMgr.suitInfo
	local items=cfg.needItems[1].id
	local nextItems = cfg.items[1]
	for i1, suitList in ipairs(suitInfo) do
		for i2, suitid in ipairs(suitList) do
			local suitCfg=SuitStarData[tostring(suitid)]
			local suitAttCfg=SuitAttData[tostring(suitCfg.suitId)]
			local rank=suitAttCfg.rank
			local needid=suitCfg.needList[1]
			if (needid==items or needid==nextItems) and rank>=10 then
				return true
			end
		end
	end
	-- for index, value in ipairs(items) do
	-- 	local id=value.id
	-- 	for i1, suitList in ipairs(suitInfo) do
	-- 		for i2, suitid in ipairs(suitList) do
	-- 			local suitCfg=SuitStarData[tostring(suitid)]
	-- 			local suitAttCfg=SuitAttData[tostring(suitCfg.suitId)]
	-- 			local rank=suitAttCfg.rank
	-- 			local needid=suitCfg.needList[1]
	-- 			if needid==id or  and rank>=10 then
	-- 				iTrace.eError("GS","suitCfg.id: ",suitCfg.id,"  needId:",needid,"   id: ",id,"  rank: ",rank)
	-- 				return true
	-- 			end
	-- 		end
	-- 	end
	-- end
	return false
end

function My:OnT(go)
	self.tX=tonumber(go.name)
end

function My:OnTg(go)
	if self.curBg then self.tt:TgState(self.curBg,false) end
	self.tY=go.name
	local bg = go:GetComponent(typeof(UISprite))
	self.tt:TgState(bg,true)
	self:UpData()
	self.curBg=bg
end

function My:OnCbtn()
	EquipMgr.ReqGCompose(self.info.id,0)
end

function My:Open()
	self.trans.gameObject:SetActive(true)
end

function My:Close()
	self.trans.gameObject:SetActive(false)
	self.tt:CleanData()
end

function My:Dispose()
	if self.str then ObjPool.Add(self.str) self.str=nil end
	while #cellList>0 do
		local cell = cellList[#cellList]
		cell:DestroyGo()
		ObjPool.Add(cell)
		cellList[#cellList]=nil
	end
end