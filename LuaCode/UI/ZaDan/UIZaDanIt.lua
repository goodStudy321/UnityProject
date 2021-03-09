--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-09-10 15:40:06
--=========================================================================

UIZaDanIt = Super:New{ Name = "UIZaDanIt" }

local My = UIZaDanIt

--蛋未开的精灵列表,索引对应类型;已开后+b
My.spNames = {"luckagg_02", "luckagg_01", "luckagg_03"}

--砸蛋时的特效列表,索引对应类型;砸开后+_flow
My.fxNames = {"UI_zadan_jindan", "UI_zadan_caidan", "UI_zadan_longdan"}

----BEG PUBLIC

--info(ZaDanInfo)
function My:Init(root, info, rCntr)
	self.root = root
	self.info = info
	self.rCntr = rCntr
	self.pool = rCntr.pool
	local des,CG = self.Name, ComTool.Get
	UITool.SetBtnSelf(root, self.OnClick, self, des)
	self.sp = ComTool.GetSelf(UISprite, root, des)
	--特效
	self.fxGo = nil
	--奖励格子
	self.cell = nil
	--计时器
	self.timer = ObjPool.Get(iTimer)
	self.timer.complete:Add(self.Complete, self)
	self:Refresh()
end

--刷新表现
function My:Refresh()
	local info = self.info
	local ty = info.type
	local itID = info.itID
	--设置精灵
	local spName = self.spNames[ty]
	
	if (itID > 0) then spName = spName .. "b" end
	self.sp.spriteName = spName
	self.sp:MakePixelPerfect()

	--设置特效
	self:ClearFxToPool()
	if (itID > 0) then
		local fxName = self.fxNames[ty] .. "_glow"
		self:LoadFx(fxName)
	end

	--设置道具
	self:ClearCellToPool()
	if (itID > 0) then
		local cell = ObjPool.Get(UIItemCell)
		local pos = Vector3.up * 100 
		cell:InitLoadPool(self.root, 0.62, nil, nil, nil, pos)
		cell:UpData(itID, info.itNum)
		cell:UpBind(info.itBind)
		self.cell = cell
	end
end

--ty:道具ID,非0代表已打开
function My:LoadFx(fxName)
	local go = self.pool:Get(fxName)
	if go then
		self:SetFxGo(go)
	else
		LoadPrefab(fxName, GbjHandler(self.SetFxGo, self))
	end
end

function My:SetFxGo(go)
	self.fxGo = go
	local fxBind =  ComTool.Add(go, UIEffectBinding)
	local tran = go.transform
	tran.parent = self.root
	tran.localScale = Vector3.one
	tran.localPosition = Vector3.zero
	go:SetActive(true)
end

function My:BegZaFx()
	local info = self.info
	local ty = info.type
	local fxName = self.fxNames[ty]
	self:LoadFx(fxName)
end

----END PUBLIC

function My:OnClick()
	local info = self.info
	local itID = info.itID or 0
	if itID > 0 then
		UITip.Log("已打开")
	else
		self.rCntr:Lock(true)
		local ty = info.type
		local fxName = self.fxNames[ty]
		self:LoadFx(fxName)
		self.timer.seconds = UIZaDan.zaFxTm
		self.timer:Start()
	end
end

function My:Complete()
	if( not ZaDanMgr:ReqZaDan(self.info.id) ) then
		self.rCntr:Lock(false)
	end
end

--将格子返回对象池
function My:ClearCellToPool()
	if self.cell then
		self.cell:DestroyGo()
		ObjPool.Add(self.cell)
	end
	self.cell = nil
end

--将特效返回对象池
function My:ClearFxToPool()
	if not LuaTool.IsNull(self.fxGo)  then
		self.pool:Add(self.fxGo)
	end
	self.fxGo = nil
end

function My:EndTimer()
	if self.timer then
		self.timer:AutoToPool()
	end
	self.timer = nil
end

function My:Dispose()
	if not LuaTool.IsNull(self.fxGo) then
		AssetMgr:Unload(self.fxGo.name, ".prefab", false)
	end
	self:ClearCellToPool()
	self:EndTimer()
	TableTool.ClearUserData(self)
end


return My