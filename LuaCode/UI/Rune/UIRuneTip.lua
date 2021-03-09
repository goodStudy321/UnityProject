--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2019-04-29 16:19:08
--=========================================================================

UIRuneTip = Super:New{ Name = UIRuneTip }

local My = UIRuneTip


function My:Init(root)
	local des = self.Name
	local CG, TF = ComTool.Get,TransTool.Find
	local bg = TF(root,"bg",des)
	self.go = root.gameObject
	self.qtaSp  = CG(UISprite, bg, "qta", des)
	self.qtSp  = CG(UISprite, bg, "qt", des)
	self.nameLbl  = CG(UILabel, bg, "name", des)
	self.lvLbl  = CG(UILabel, bg, "lv", des)
	self.getLbl = CG(UILabel, bg, "get", des)
	self.scoreLbl  = CG(UILabel, bg, "score", des)
	self.iconTex =  CG(UITexture, bg, "icon", des)
	self:InitProp("p1", bg, des)
	self:InitProp("p2", bg, des)
	UITool.SetLsnrSelf(root, self.Close, self, des, false)
end

function My:InitProp(pn, root, des)
	local p = ObjPool.Get(UIPropItem)
	local path = "p/" .. pn
	local tran = TransTool.Find(root, path, des)
	p:Init(tran)
	self[pn] = p
end

function My:Refresh(cfg)
	if cfg == nil then return end
	if self.cfg == cfg then return end
	local lastCfg = self.cfg
	local UM = UIMisc
	self.cfg = cfg
	local qt = cfg.qt
	self.qtSp.spriteName = UM.GetQuaPath(qt)
	self.qtaSp.spriteName = UM.GetBgQuaPath(qt)
	self.nameLbl.text = UM.LabColor(qt) .. cfg.name
	local lvCfg = BinTool.Find(RuneLvCfg, cfg.id)
	if lvCfg then 
		self.lvLbl = tostring(lvCfg.lv)
		self.scoreLbl.text = tostring(lvCfg.score)
	end
	local ly = cfg.towerId - 40000
	local st = cfg.st or 0
	local str = ((st<1) and ("通关九九窥星塔" .. ly .. "层解锁") or "符文寻宝")
	self.getLbl.text = str
	AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))
	if lastCfg then AssetMgr:Unload(lastCfg.icon, false) end

	--设置属性
	if cfg.p1 then self.p1:SetByCfg(cfg.p1, lvCfg.v1) end
	if cfg.p2 then 
		self.p2:SetByCfg(cfg.p2, lvCfg.v2) 
		self.p2:SetActive(true)
	else 
		self.p2:SetActive(false)
	end

end

function My:SetIcon(tex)
	self.iconTex.mainTexture = tex
end

function My:Close()
	self:SetActive(false)
end

function My:Open()
	self:SetActive(true)
end

function My:SetActive(at)
	self.go:SetActive(at)
end


function My:Dispose()
	self:UnloadIcon()
	self.cfg = nil
	TableTool.ClearUserData(self)
end

function My:UnloadIcon()
	local cfg = self.cfg
	if cfg then 
		AssetMgr:Unload(cfg.icon, false)
	end
end


return My