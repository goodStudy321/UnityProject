--[[
宝石合成
--]]
T1=Super:New{Name="T1"}
local My = T1
local list = nil --宝石合成表
local curType = 1; --1宝石 2.纹印
local redTDic = {}
local redTgDic = {}
local SealList = nil --纹印合成表
local SealText = {"碧玺印","","龙纹印"} --获取纹印文本
function My:Init(go,tt)
	self.tt=tt
	self.trans=go.transform

	self.Cell=ObjPool.Get(UIItemCell)
	self.Cell:InitLoadPool(self.trans)
	list=EquipMgr.gemList
	SealList = EquipMgr.sealList
	self.str=ObjPool.Get(StrBuffer)
	self.islong=true
end

--宝石合成返回
function My:OnCompose()
	local num=self.gem.num
	local id = self.gem.id
	local has = PropMgr.TypeIdByNum(id)
	local color = has>=num and "[F4DDBDFF]" or "[CC2500FF]"
	self.str:Dispose()
	self.str:Apd(color):Apd(has):Apd("/"):Apd(num)
	self.Cell:UpData(id,self.str:ToStr())
end

function My:UpData()
	local tId = self.tY
	self.gem = GemData[tId]
	if(self.gem==nil)then iTrace.eError("xiaoyu","宝石表为空 id: "..tId)return end
	self:OnCompose()
	
	self.tt:UpData(self.gem.canGem)
end
function My:UpSealData(tId)
	self.gem = tSealData[tId]
	if(self.gem==nil)then iTrace.eError("soon","纹印表为空 id: "..tId)return end
	self:OnCompose()
	self.tt:UpData(self.gem.canGem)
end

function My:CreateTb(jumpItem)
	local CG = ComTool.Get
	local U = UITool.SetLsnrSelf
	local TF = TransTool.FindChild
	for i,v in ipairs(list) do
		if(#v>0)then
			--标签
			local t = self:GetX(i)
			local go=self.tt:CreateT(t.."宝石",tostring(i))
			U(go,self.OnT,self,self.Name, false)

			local isFirst = false
			if(i==1)then isFirst=true end
			local tween = CG(TweenScale,go.transform,"Tween",self.Name,false)
			local table =CG(UITable,go.transform,"Tween/table",self.Name,false) 
			for i1,v1 in ipairs(v) do
				local gem = GemData[v1]
				local gg=self.tt:CreateTg(table.transform,gem.name,i,v1)			
				U(gg,self.OnTg,self,self.Name, false)	
				if jumpItem and jumpItem~=0 and gem.canGem then 
					if gem.id==jumpItem then
						self:OnT(go)
						self:OnTg(gg)
					end
				end
				if i1==1 and isFirst==true and (not jumpItem or jumpItem==0) then
			 		self:OnT(go)
					self:OnTg(gg)
				end
			end
			table.repositionNow=true
		end		
	end
	self:doSealT( jumpItem )
	self.tt.table.repositionNow=true
end


function My:doSealT(jumpItem  )
	local CG = ComTool.Get
	local U = UITool.SetLsnrSelf
	local TF = TransTool.FindChild
	for i,v in ipairs(SealList) do
		if(#v>0)then
			local go=self.tt:CreateT(SealText[i],tostring(3+i))
			go.name=tostring(3+i)
			U(go,self.OnT,self,self.Name, false)
			local isFirst = false
			if(i==1)then isFirst=true end
			local tween = CG(TweenScale,go.transform,"Tween",self.Name,false)
			local table =CG(UITable,go.transform,"Tween/table",self.Name,false) 
			for i1,v1 in ipairs(v) do
				local gem = tSealData[v1]
				local gg=self.tt:CreateTg(table.transform,gem.name,i,v1)		
				U(gg,self.OnSealTg,self,self.Name, false)	
				if jumpItem and gem.canGem then 
					if gem.id==jumpItem then
						self:OnT(go)
						self:OnSealTg(gg)
					end
				end
			end
			table.repositionNow=true
		end		
	end
end

function My:OnT(go)
	self.tX=tonumber(go.name)
end

function My:OnTg(go)
	if self.curBg then self.tt:TgState(self.curBg,false) end
	self.tY=go.name
	local bg = go:GetComponent(typeof(UISprite))
	self.tt:TgState(bg,true)
	curType = 1
	self:UpData()
	self.curBg=bg
end

function My:OnSealTg(go)
	if self.curBg then self.tt:TgState(self.curBg,false) end
	self.tY=go.name
	local bg = go:GetComponent(typeof(UISprite))
	self.tt:TgState(bg,true)
	curType = 2
	self:UpSealData(self.tY)
	self.curBg=bg
end

function My:OnCbtn()
	if curType==1 then
		EquipMgr.ReqSCompose(self.gem.id)
	elseif curType ==2 then
		EquipMgr.ReqSealCompose(self.gem.id)
	end
end

--获取宝石前缀文本
function My:GetX(k)
	local x =""
	if(k==1)then
		x="生命"
	elseif(k==2)then
		x="防御"
	elseif(k==3)then
		x="攻击"
	end
	return x
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
	if self.Cell then self.Cell:DestroyGo() ObjPool.Add(self.Cell) end
end