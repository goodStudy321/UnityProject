--[[
 	authors 	:Liu
 	date    	:2018-7-9 16:33:00
 	descrition 	:符文Tip
--]]

UITreasRuneTip = UIBase:New{Name = "UITreasRuneTip"}

local My = UITreasRuneTip

function My:InitCustom()
    local des = self.Name
    local CG, TF = ComTool.Get,TransTool.Find
	self.bg = TF(self.root,"bg",des)
    local bg = self.bg
	self.qtaSp  = CG(UISprite, bg, "qta", des)
	self.qtSp  = CG(UISprite, bg, "qt", des)
	self.nameLbl  = CG(UILabel, bg, "name", des)
	self.lvLbl  = CG(UILabel, bg, "lv", des)
	self.getLbl = CG(UILabel, bg, "get", des)
	self.scoreLbl  = CG(UILabel, bg, "score", des)
    self.iconTex =  CG(UITexture, bg, "icon", des)
	self.des=CG(UILabel,bg,"des",des)
	self.getpre=CG(UILabel,bg,"getpre",des)
	
    self.str=ObjPool.Get(StrBuffer)
    UITool.SetLsnrClick(self.root, "box", des, self.Close, self)
end

function My:Refresh(cfg, type)
	if cfg == nil then return end
	if self.cfg == cfg then return end
	local lastCfg = self.cfg
	local UM = UIMisc
	self.cfg = cfg
	local qt = cfg.qt
	self.qtSp.spriteName = UM.GetQuaPath(qt)
	self.qtaSp.spriteName = UM.GetBgQuaPath(qt)
    self.nameLbl.text = UM.LabColor(qt) .. cfg.name
    local xPos = (type==1) and -210 or 210
    self.bg.localPosition = Vector3(xPos, self.bg.localPosition.y, 0)
	local lvCfg = BinTool.Find(RuneLvCfg, cfg.id)
	if lvCfg then 
		self.lvLbl = tostring(lvCfg.lv)
		self.scoreLbl.text = tostring(lvCfg.score)
	end
	local ly = cfg.towerId - 40000
	local str = "通关九九窥星塔" .. ly .. "层解锁" 
	self.getLbl.text = str
	AssetMgr:Load(cfg.icon, ObjHandler(self.SetIcon, self))
	if lastCfg then AssetMgr:Unload(lastCfg.icon, false) end

	--设置属性
	self:RuneGetAttDes(lvCfg)
	self:GetWayDes(self.cfg.id)
end

--获取途径描述
function My:GetWayDes(id)
	self.str:Dispose()
	local item=UIMisc.FindCreate(id)
	local way=item.getwayList
	if way then
		self.str:Apd("【获得途径】")
		self.str:Line()
		self.str:Apd("[67cc67]")
		for i,v in ipairs(way) do
			local data = GetWayData[tostring(v)]
			if not data then iTrace.eError("xiaoyu","获取表为空 id: "..v)return end
			local text = data.des
			self.str:Apd(text)
			if i~=#way then self.str:Apd("、") end
		end
		self.getpre.text=self.str:ToStr()
		return 
	end
	self.getpre.text=""
end

--符文描述
function My:RuneGetAttDes(temp)
	local p1 = temp.p1
	local v1 = temp.v1
	local p2 = temp.p2
	local v2 = temp.v2
	if not v1 and not v2 then 
		self.des.text=""
		return 
	end
	self.str:Dispose()
	self.str:Apd("【佩戴属性】")
	self.str:Line()
	local maxTemp = nil
	if temp.lv==1 then 
		maxTemp=BinTool.Find(RuneLvCfg,tonumber(temp.maxId))
	end
	if v1 then 
		self:GetAtt(p1,v1,temp,maxTemp)
	end
	if v2 then 
		self:GetAtt(p2,v2,temp,maxTemp)
	end
	self.des.text=self.str:ToStr()
end

function My:GetAtt(id,val,temp,maxTemp)
	self.str:Apd(PropTool.GetNameById(id)):Apd("  "):Apd(PropTool.GetValByID(id,val))
	if maxTemp and maxTemp.v1 and temp.lv==1 then self.str:Apd("(满级效果 "):Apd(PropTool.GetValByID(maxTemp.p1,maxTemp.v1)):Apd(")") end
	self.str:Line()
end

function My:SetIcon(tex)
	self.iconTex.mainTexture = tex
end

--清理缓存
function My:Clear()
    local cfg = self.cfg
	if cfg then 
		AssetMgr:Unload(cfg.icon, false)
    end
    self.cfg = nil
end
    
--重写释放资源
function My:DisposeCustom()
    self:Clear()
end

return My