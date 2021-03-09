--[[
	authors 	:Loong
 	date    	:2017-08-20 20:24:16
 	descrition 	:养成资质提升
--]]
--需要外部通过Refresh传入以下参数
--self.qualCfg 资质丹药配置
--self.qualDic 资质弹药使用数量字典
--在资质更新的地方 调用RespUpg
--
UIAdvQual = Super:New {Name = "UIAdvQual"}
local AssetMgr = Loong.Game.AssetMgr
local My = UIAdvQual


local UII = require("UI/Adv/UIAdvQualItem")

--丹药配置
My.qualCfg = nil

--k:道具ID,v:使用数量
My.qualDic = nil

--道具字典,k:id,--v:UIItem
My.itDic = {}

function My:Init(root)
	self.root = root
	self.go = root.gameObject
	local name = self.Name
	local CG = ComTool.Get
	local USBC = UITool.SetBtnClick
	local TFC = TransTool.FindChild

	--It 排列表
	self.itTbl = CG(UITable, root, "Table", name)
	--Icon 模板
	self.itMod = TFC(root, "icon", name)
	self.itMod:SetActive(false)

	self:AddLsnr()
end

--cfg:丹药/资质配置
--dic:使用字典
function My:Refresh(cfg, dic)
	if cfg == nil then return end
	if dic == nil then return end
	if cfg == self.qualCfg then return end
	self.qualCfg = cfg
	self.qualDic = dic
	self:SetItDic()
end

--设置图标字典
function My:SetItDic()
	local uiTbl = self.itTbl
	local uiTblTran = uiTbl.transform
	local mod = self.itMod
	local itDic = self.itDic
	TableTool.ClearDicToPool(itDic)
	TransTool.RenameChildren(uiTblTran)
	local qualCfg = self.qualCfg
	local Inst = GameObject.Instantiate
	local TA, GetCfg = TransTool.AddChild, ItemTool.GetCfg
	local Get, BF = ObjPool.Get, BinTool.Find
	for i, v in ipairs(qualCfg) do
		local id = v.id
		local k = tostring(v.id)
		local tran = uiTblTran:Find("none")
		local it = nil
		if tran == nil then
			it = Inst(mod)
			tran = it.transform
		else
			it = tran.gameObject
		end
		it.name = k
		it:SetActive(true)
		TA(uiTblTran, tran)
		local it = Get(UII)
		it.cntr = self
		it.cfg = GetCfg(id)
		it.qualDic = self.qualDic
		it.qualMaxNum = AdvMgr:GetUseMax(v)
		it:Init(tran)
		it.qCfg = v
		it:LoadIcon()
		itDic[k] = it
	end
	uiTbl:Reposition()
end


--设置道具/比响应升级慢
function My:SetNums()
	local isFullQual = true
	for k, v in pairs(self.itDic) do
		v:Refresh()
		local idStr = tostring(v.qCfg.id)
		local qualUsed = self.qualDic[idStr]
		local qualMax = AdvMgr:GetUseMax(v.qCfg)
		if qualUsed ~= nil and qualUsed > 0 and qualUsed < qualMax then
			isFullQual = false
		end
	end
end

--响应升级
function My:RespUpg()

end

function My:Switch(it)
	local id = it.cfg.id
	local k = tostring(id)
	local cfg = it.qCfg
	local max = AdvMgr:GetUseMax(cfg)--cfg.useMax
	local used = self.qualDic[k] or 0
	local canShow = false
	local own = ItemTool.GetNum(id)
	if used >= max then
		UITip.Error("已达使用上限,无法再使用")
		canShow = true
	elseif own < 1 then
		canShow = true
	else
		self.rCntr.qualTip:Close()
		local uid = PropMgr.TypeIdById(id)
		PropMgr.ReqUse(uid, 1)
	end
	if canShow == true then
		local tex = it.iconTex.mainTexture
		self.rCntr.qualTip:Show(id, tex, cfg, used)
		self.rCntr.skiTip:Close()
	end
end

function My:AddLsnr()
	PropMgr.eUpdate:Add(self.SetNums, self)
end

function My:RmvLsnr()
	PropMgr.eUpdate:Remove(self.SetNums, self)
end

function My:Open()
	self.go:SetActive(true)
end

function My:Close()
	self.go:SetActive(false)
end


function My:Dispose()
	self:RmvLsnr()
	self.qualDic = nil
	self.qualCfg = nil
	TableTool.ClearDicToPool(self.itDic)
end

return My
