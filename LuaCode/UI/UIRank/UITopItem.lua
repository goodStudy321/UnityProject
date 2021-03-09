
UITopItem = Super:New{Name="UITopItem"}
local My = UITopItem

local trans = nil

function My:Init(go)
    trans = go.transform
    local des = self.Name
    local TF = TransTool.FindChild
    local CG = ComTool.Get

    self.Frame_b = CG(UISprite, trans, "r_frame_b")
    self.NameLab_b = CG(UILabel, trans, "nameLab_b")
    self.Frame_s = CG(UISprite, trans, "r_frame_s")
    self.NameLab_s = CG(UILabel, trans, "nameLab_s")
end

function My:UpBState(key, data)
    self:SetActiveState(true)
    self.NameLab_b.text = data.name.."\n"..self:GetDes(key, data)
    self.Frame_b.spriteName = "TX_0"..tostring(data.cate)
end

function My:UpSState( data)
    self:SetActiveState(false)
    self.NameLab_s.text = data.name
    self.Frame_s.spriteName = "TX_0"..tostring(data.cate)
end

function My:GetDes(key, data)  
	if key == RankType.RP then
        local kp = data.params[RankPType.KP]
		return string.format("战力:%s",RankMgr:GetFight(kp)) 
    elseif key == RankType.RL then
        local lv = data.level
        local rl = 0
        local temp = UserMgr.RoleLv
        if temp then rl = temp.Value3 end
        if lv > rl then
            return string.format( "化神%s级",lv - rl)
        else
            return string.format("等级:%s", lv) 
        end
	elseif key == RankType.MP then
        local id = tonumber(data.params[RankPType.KMI])
		return RankMgr:GetMountStep(id)
	elseif key == RankType.PP then
        local id = data.params[RankPType.KPI]
		return RankMgr:GetPetStep(id)
	elseif key == RankType.ZX then
        local num = data.params[RankPType.ZXC]
		return string.format("层数:%s", num)
	elseif key == RankType.OFF then
        local offl = data.params[RankPType.OFFL]
        local num = CustomInfo:ConvertNum(tonumber(offl))
		return string.format("%s/分钟", num)
	elseif key == RankType.GWP then		
        --local id = tonumber(data.params[RankPType.KGWI])
        local lv = tonumber(data.params[RankPType.KGWL])
		--return string.format("%s(%s)",RankMgr:GetGWName(id), RankMgr:GetGWLv(lv)) 
		return string.format("等级:%s", RankMgr:GetGWLv(lv)) 
	elseif key == RankType.WP then
        --local id = tonumber(data.params[RankPType.KWI])
        local lv = tonumber(data.params[RankPType.KWL])
		--return string.format("%s(%s)",RankMgr:GetWingName(id), RankMgr:GetWingLv(lv)) 
		return string.format("等级:%s", RankMgr:GetWingLv(lv)) 
	elseif key == RankType.MWP then
        local lv = tonumber(data.params[RankPType.KMWL])
		--return string.format("%s(%s)",RankMgr:GetMWName(lv), RankMgr:GetMWLv(lv)) 
		return string.format("等级:%s", RankMgr:GetMWLv(lv)) 
	end
    return ""
end

function My:SetActiveState(isActive)
    local Fb = self.Frame_b.gameObject
    local Nb = self.NameLab_b.gameObject
    local Fs = self.Frame_s.gameObject
    local Ns = self.NameLab_s.gameObject
    if isActive then
        Fb:SetActive(true)
        Nb:SetActive(true)
        Fs:SetActive(false)
        Ns:SetActive(false)
    else
        Fb:SetActive(false)
        Nb:SetActive(false)
        Fs:SetActive(true)
        Ns:SetActive(true)
    end
end

function My:CleanData()
    self.Frame_b = nil
    self.NameLab_b = nil
    self.Frame_s = nil
    self.NameLab_s = nil
end

function My:Dispose()
    self:CleanData()
end

return My