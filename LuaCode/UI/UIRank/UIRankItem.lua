--region UIRankItem.lua
--排行榜基类
--此文件由[HS]创建生成
UIRankItem = Super:New{Name = "UIRankItem"}
local I = UIRankItem
UIRankItem.Items1 = {0, 3}
UIRankItem.Items2 = {0, 2}

local US = UITool.SetLsnrSelf

function I:Init(go)
	--变量
	self.gameObject = go
	--控件
	local trans = go.transform

	self.Values = {}

	self.IsUser = false

	self.PlayerID = nil
	local GN = self.gameObject.name
	local name = string.format("UIRankItem %s", GN)
	local C = ComTool.Get
	local T = TransTool.FindChild
	for i = 1, 4 do
		local label = C(UILabel, trans, string.format("Value%s",i), name, false)
		table.insert(self.Values, label)
	end
	self.BG = self.gameObject:GetComponent("UISprite")
	-- self.Menu = self.gameObject:GetComponent("UIMenuTip")
	self.Select = T(trans, "Select")
	-- self.SelectSpr = C(UISprite, trans, "Select", GN)
	self.Rank = C(UISprite, trans, "Rank", GN)
	self.RankBG = C(UISprite, trans, "RankBg", GN)
	self.vip = C(UISprite, trans, "vip", GN)
	self.confine = C(UISprite, trans, "confine", GN)

	US(trans,self.ClickSelf,self,nil, false)
end

function I:ClickSelf()
	if self.selCallBack ~= nil then
		self.selCallBack()
	end
end

function I:UpdateBg(index)
	if self.IsUser == true then return end
	if self.BG then
		local n = ""
		local x = index % 2
		if x == 0 then n = "nrk" end
		self.BG.spriteName = n
	end
end

function I:UpdateData(rank, key, data,selCB)
	self.PlayerID = data.roleId
	--self:UpdateMenuItems(data.roleId)
	self.selCallBack = selCB;
	self:UpdateRank(rank)
	if key == RankType.RP then
		self:UpdateDataRP(data)
	elseif key == RankType.RL then
		self:UpdateDataRL(data)
	elseif key == RankType.MP then
		self:UpdateDataMP(data)
	elseif key == RankType.PP then
		self:UpdateDataPP(data)
	elseif key == RankType.ZX then
		self:UpdateDataZX(data)
	elseif key == RankType.OFF then
		self:UpdateDataOFF(data)
	elseif key == RankType.GWP then
		self:UpdateDataGWP(data)
	elseif key == RankType.WP then
		self:UpdateDataWP(data)
	elseif key == RankType.MWP then
		self:UpdateDataMWP(data)
	end
	if not data then return end
end

-- 更新点击显示面板
-- function I:UpdateMenuItems(id)
-- 	local isFriend = FriendMgr:IsFriend(id)
-- 	if not self.Menu then return end
-- 	local custom = self.Menu.customIndex
-- 	custom:Clear()
-- 	local items = nil
-- 	if isFriend == true then
-- 		items = self.Items2
-- 	else
-- 		items = self.Items1
-- 	end
-- 	local len = #items
-- 	for i=1,len do
-- 		local index = items[i]
-- 		custom:Add(index)
-- 	end
-- end

function I:UpdateRank(index)
	if not index then return end
	if self.Rank then 
		if index <= 3 then
			self.Rank.spriteName = "rank_icon_"..tostring(index)
		else
			self.Rank.spriteName = ""
		end
		self.Rank.gameObject:SetActive(index <=3 and index >0)
	end
	if self.RankBG then
		if index == 1 then
			self.RankBG.spriteName = "rank_info_g"
		elseif index == 2 then
			self.RankBG.spriteName = "rank_info_z"
		elseif index == 3 then
			self.RankBG.spriteName = "rank_info_b"
		else
			self.RankBG.spriteName = ""
		end
		self.RankBG.gameObject:SetActive(index <=3 and index >0) 
	end
end

--战力
function I:UpdateDataRP(data)
	local kfn = data.params[RankPType.KFN]
	if StrTool.IsNullOrEmpty(kfn) then kfn = "无" end
	local kp = data.params[RankPType.KP]
	local rkp = RankMgr:GetFight(kp)
	self:SetVipSpr(data.vip, self:GetConfine(data.confine))
	self:UpdateLabel(data.rank, data.name, kfn, rkp)
end
--等级
function I:UpdateDataRL(data)
	local ct = UserMgr:GetCareerName(tonumber(data.cate))
	self:SetVipSpr(data.vip, self:GetConfine(data.confine))
	local lv = data.level
	local rl = 0
	local temp = UserMgr.RoleLv
	if temp then rl = temp.Value3 end
	if lv > rl then
		lv = string.format( "化神%s级",lv - rl)
	end
	self:UpdateLabel(data.rank, data.name, ct, lv)
end
--坐骑
function I:UpdateDataMP(data)
	local mID = data.params[RankPType.KMI]
	--local mpname = RankMgr:GetMountName(tonumber(mID))
	local bt = data.params[RankPType.KP]
	local st = RankMgr:GetMountStep(tonumber(mID))
	self:SetVipSpr(data.vip, self:GetConfine(data.confine))
	--self:UpdateLabel(data.rank, data.name, mpname, st)
	self:UpdateLabel(data.rank, data.name, bt, st)
end
--宠物
function I:UpdateDataPP(data)
	local id = data.params[RankPType.KPI]
	--local ppname = RankMgr:GetPetName(id)
	local bt = data.params[RankPType.KP]
	local st = RankMgr:GetPetStep(id)
	self:SetVipSpr(data.vip, self:GetConfine(data.confine))
	--self:UpdateLabel(data.rank, data.name, ppname, st)
	self:UpdateLabel(data.rank, data.name, bt, st)
end
--诛仙塔
function I:UpdateDataZX(data)
	local kp = data.params[RankPType.KP]
	local rkp = RankMgr:GetFight(kp)
	local num = data.params[RankPType.ZXC]
	self:SetVipSpr(data.vip, self:GetConfine(data.confine))
	self:UpdateLabel(data.rank, data.name, rkp, num)
end
--离线效率
function I:UpdateDataOFF(data)
	local kp = data.params[RankPType.KP]
	local rkp = RankMgr:GetFight(kp)
	local offl = data.params[RankPType.OFFL]
	local num = CustomInfo:ConvertNum(tonumber(offl))
	local hang = string.format("%s/分钟", num)
	self:SetVipSpr(data.vip, self:GetConfine(data.confine))
	self:UpdateLabel(data.rank, data.name, rkp, hang)
end
--神兵
function I:UpdateDataGWP(data)
	--local ct = UserMgr:GetCareerName(data.cate)
	local sb = data.params[RankPType.KGWL]
	local bt = data.params[RankPType.KP]
	local lv = string.format("%s级", sb)
	self:SetVipSpr(data.vip, self:GetConfine(data.confine))
	--self:UpdateLabel(data.rank, data.name, ct, lv)
	self:UpdateLabel(data.rank, data.name, bt, lv)
end
--翅膀
function I:UpdateDataWP(data)
	--local ct = UserMgr:GetCareerName(data.cate)
	local cb = data.params[RankPType.KWL]
	local bt = data.params[RankPType.KP]
	local lv = string.format("%s级", cb)
	self:SetVipSpr(data.vip, self:GetConfine(data.confine))
	--self:UpdateLabel(data.rank, data.name, ct, lv)
	self:UpdateLabel(data.rank, data.name, bt, lv)
end
--法宝
function I:UpdateDataMWP(data)
	--local ct = UserMgr:GetCareerName(data.cate)
	local fb = data.params[RankPType.KMWL]
	local bt = data.params[RankPType.KP]
	local lv = string.format("%s级", fb)
	self:SetVipSpr(data.vip, self:GetConfine(data.confine))
	--self:UpdateLabel(data.rank, data.name, ct, lv)
	self:UpdateLabel(data.rank, data.name, bt, lv)
end

function I:UpdateLabel(t1, t2, t3, t4)
	self.Values[1].text = t1
	self.Values[2].text = t2
	self.Values[3].text = t3
	self.Values[4].text = t4
end

function I:GetConfine(id)
	local confine = BinTool.Find(AmbitCfg,id,"id")
	if confine and not StrTool.IsNullOrEmpty(confine.path) then
		local conPathLen = string.len(confine.path)
		local path = QualityMgr.instance:GetQuaEffName(confine.path)
		local pathLen = string.len(path)
		if pathLen == (conPathLen - 4) then --高配特效
			path = StrTool.Concat(path,"_big")
		else								--低配特效
			path = string.gsub(path,"_low","")
			path = StrTool.Concat(path,"_big_low")
		end
		return path
	else
		return nil
	end
end

function I:SetVipSpr(viplv, confinePath)
	if viplv or tonumber(viplv)~=0 then
		self.vip.gameObject:SetActive(true)
		self.vip.spriteName = "vip"..viplv
	end	
	if self.confine then
		self.confine.gameObject:SetActive(confinePath ~= nil)
		if not LuaTool.IsNull(self.ConfineEff)  then
			if not StrTool.IsNullOrEmpty(self.confineName) and confinePath == self.confineName then
				return 
			end
		end
		self:UnloadMode()
		self.confineName = confinePath
		local del = ObjPool.Get(DelGbj)
		del:Add(self.PlayerID)
		del:SetFunc(self.LoadConfineCb,self)
		if(confinePath ~= nil) then
			Loong.Game.AssetMgr.LoadPrefab(confinePath, GbjHandler(del.Execute, del))
		end
	end
end

function I:LoadConfineCb(go, id)
	if id ~= self.PlayerID then return end
	self.ConfineEff = go
	local sp = self.confine
	if sp then
		local trans = go.transform
		local cs = go:AddComponent(typeof(UIEffectBinding))
		if cs then
			--cs.specifyWidget = sp
			--cs.mIsUsedMaterials = true
		end
		trans.parent = sp.transform
		trans.eulerAngles = Vector3.zero
		trans.localPosition = Vector3.zero
		trans.localScale = Vector3.one * 100
		LayerTool.Set(trans, 5)
		go:SetActive(true)
	else
		self:UnloadMode()
	end
end

function I:UnloadMode()
	if self.ConfineEff then
		Destroy(self.ConfineEff)
		if not StrTool.IsNullOrEmpty(self.confineName) then
			AssetMgr:Unload(self.confineName,".prefab", false)
		end
	end
	self.ConfineEff = nil
	self.confineName = nil
end

function I:EnabledEff()
	local eff = self.ConfineEff
	if LuaTool.IsNull(eff) == true  then return end
	eff:SetActive(false)
	eff:SetActive(true)
end

function I:Show(value)
	if value then
		self.Select:SetActive(true)
	else
		self.Select:SetActive(false)
	end
end

--销毁释放
function I:Dispose()
	self:UnloadMode()
	self.Values = nil
	if self.gameObject then
		self.gameObject.transform.parent = nil
	end
	GameObject.Destroy(self.gameObject)
	self.gameObject = nil
end
--endregion
