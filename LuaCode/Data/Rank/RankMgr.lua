--region FriendMgr.lua
--Date
--此文件由[HS]创建生成

RankMgr =Super:New{Name="RankMgr"}
local R = RankMgr
local iError = iTrace.Error

function R:Init()
	self.Rank = {}
	self:SetLnsr("Add")
end

function R:SetLnsr(func)
	RankNetMgr.eRankInfo[func](RankNetMgr.eRankInfo, self.RespRankInfo, self)
	RankNetMgr.eRankParams[func](RankNetMgr.eRankParams, self.RespRankParams, self)
end

function R:RespRankInfo(key, rank, roleid, rolename, lv, viplv, category, confine)
	if not self.Rank[key] then self.Rank[key] = {} end
	local rankT = self.Rank[key]
	if not rankT.Rank then rankT.Rank = {} end
	rankT.Time = System.DateTime.Now.Minute
	local rankList = self.Rank[key].Rank
	if not rankList[rank] then
		rankList[rank] = {}
	end
	local data = rankList[rank]
	data.rank = rank
	data.roleId = roleid
	data.name = rolename
	data.level = lv
	data.vip = viplv
	data.cate = category
	data.confine = confine
	data.params = {}
end

function R:RespRankParams(key, rank, id, value)
	if not self.Rank[key] then
		self.Rank[key] = {}
	end
	local rankT = self.Rank[key]
	if not rankT.Rank then rankT.Rank = {} end
	local rankList = self.Rank[key].Rank
	if not rankList[rank] then
		rankList[rank] = {}
	end
	if not rankList[rank].params then
		rankList[rank].params = {}
	end
	rankList[rank].params[tonumber(id)] = value
end

function R:IsUpdate(key)
	local rankT = self.Rank[key]
	if not rankT then
		return true
	else 
		local offset = System.DateTime.Now.Minute - rankT.Time
		if offset > 10 or offset < 0 then
			return true
		end
	end
	return false
end

--获得排行榜
function R:GetRank(rank, list)
	if not rank then
		if list then
			for k,v in pairs(list) do
				if v.roleId == User.MapData.UIDStr then
					rank = k
				end
			end
		end
	end
	if rank then return rank end
	return "未上榜"
end
--[[-------------------------------------------------------]]--
--获取坐骑名字
function R:GetMountName(id)
	local temp = nil
	if not id then
		if MountsMgr.id ~= 0 then
			id = MountsMgr.id
		else
			id = 0
		end
	end
	id = math.floor(id/100)
	temp = BinTool.Find(MountCfg,id)
	if temp then
		return temp.name
	end
	return "无"
end

--获取坐骑等阶
--state == false 不显示星级
function R:GetMountStep(id, state)
	if state == nil then state = true end
	local temp = nil
	local item = nil
	if not id then
		if MountsMgr.id ~= 0 then
			id = MountsMgr.id
		else
			id = 0
		end
	end
	local index = math.floor(id/100)
	temp = BinTool.Find(MountCfg, index)
	item = BinTool.Find(MountStepCfg, id)
	if temp and item then
		if state == true then
			return string.format("%s阶%s星", temp.st, item.st)
		else
			return string.format("%s阶", temp.st)
		end
	end
	return "无"
end

--获取宠物名字
function R:GetPetName(id)
	local temp = nil
	if not id then
		id = PetMgr.CurID
	end
	temp = PetMgr:GetPetTempOfStepID(id)
	if temp then
		return temp.name
	end
	return "无"
end

--获取宠物等阶
--state == false 不显示星级
function R:GetPetStep(id, state)
	if state == nil then state = true end
	local mgr = PetMgr
	if not id then
		id = mgr.StepID
	end
	local temp = mgr:GetPetStepTempOfStepID(id)
	if temp then
		if state == true then
			return string.format("%s阶%s星", temp.type, temp.step)
		else
			return string.format("%s阶",temp.type)
		end
	end
	return "无"
end

function R:GetAdvName(db,id)
	if not id then
		id = db.chgID
	end
	local cfg = db:GetBCfg(id)
	local name = cfg and cfg.name or "无"
	return name
end

--获取神兵名字
function R:GetGWName(id)
	return self:GetAdvName(GWeaponMgr,id)
end

--获取神兵等级
function R:GetGWLv(lv)
	if not lv then
		lv = GWeaponMgr.lv
	end
	return string.format("%s级", lv)
end


--获取法宝名字
function R:GetMWName(id)
	return self:GetAdvName(MWeaponMgr,id)
end


--获取法宝等级
function R:GetMWLv(lv)
	if not lv then
		lv = MWeaponMgr.lv
	end
	return string.format("%s级", lv)
end


--获取翅膀名字
function R:GetWingName(id)
	return self:GetAdvName(WingMgr, id)
end

--获取翅膀等级
function R:GetWingLv(lv)
	if not lv then
		lv = WingMgr.lv
	end
	return string.format("%s级", lv)
end

--获取战斗力显示
function R:GetFight(fight)
	if not StrTool.IsNullOrEmpty(fight) then
		local fight = tonumber(fight)
		if fight ~= 0 then
			return CustomInfo:ConvertNum(fight)
		end
	end
	return "-"
end

--获取通关层数
function R:GetTowerLay()
	local key = tostring(CopyType.Tower)
	local data = CopyMgr.Copy[key]
	local list = data.Dic
	if not list then return end
	local len = #list
	local indexOf = data.IndexOf
	if not data then
		iTrace.eError("gk","CopyMgr.Copy中没有找到爬塔副本的数据")
		return
	end
	local id = CopyMgr.LimitTower
	local index = nil
	if id ~= 0 then
		index = indexOf[tostring(id)]
		if not index then index = 0 end
	end
	if index and index~=0 then
		return index
	else
		return "无"
	end
	return ""
end

--获取Vip等级
function R:GetVipLv()
	lv = VIPMgr.GetVIPLv()
	return lv
end

--------------------------------------------------------------------------------


--------------------------------------------------------------------------------

-- function R:ClickMenuTip(str, playerid)
-- 	if StrTool.IsNullOrEmpty(playerid) then return end
-- 	--if str == "查看信息" then
-- 	if str == "infoBtn" then
-- 		UIMgr.Open(UIOtherInfoCPM.Name)
-- 		--UserMgr:ReqRoleObserve(tonumber(playerid))
-- 	--[[elseif str == "赠送鲜花" then
-- 		UIMgr.Close(UIRank.Name)--]]
-- 	--elseif str == "开始聊天" then
-- 	elseif str == "chatBtn" then
-- 		FriendMgr.TalkId = playerid
-- 		if not playerid then return end
-- 		UIMgr.Open(UIInteractPanel.Name, self.OpenUI, self)
-- 		UIMgr.Close(UIRank.Name)
-- 	--elseif str == "添加好友" then
-- 	elseif str == "friendBtn" then
-- 		if User.MapData.UIDStr == playerid then
-- 			--UITip.Log("不可以加自己为好友哦！")
-- 			MsgBox.ShowYes("不可以加自己为好友哦！")
-- 			return
-- 		end
-- 		FriendMgr:ReqAddFriend(playerid)
-- 		MsgBox.ShowYes("好友请求发送成功！")
-- 	end
-- end

function R:OpenUI(name)
	local ui = UIMgr.Dic[UIInteractPanel.Name]
	if ui then
		ui:ShowFirend()
	end
end

function R:Clear()
	TableTool.ClearDic(self.Rank)
end

function R:Dispose()
	-- body
	self:SetLnsr("Remove")
end

return R