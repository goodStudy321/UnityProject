UIRobberyInfo = UICopyInfoBase:New{Name = "UIRobberyInfo"}

local M = UIRobberyInfo

function M:InitSelf()
    local G = ComTool.Get
    local trans = self.left
    self.lblName = G(UILabel, trans, "Name")
    self.lblTarge = G(UILabel, trans, "Target")
    self.rewardName = G(UILabel, trans, "Lab_2")
    self.icon = G(UITexture,trans,"Icon")
end

function M:InitData()  
    local temp = self.Temp
    self.lblName.text = temp.name
    self:UpdateCur()
end

function M:UpdateCur()
    local temp = self.Temp
    local info = CopyMgr.CopyInfo
    local mt = MonsterTemp[tostring(temp.eParam[1])]  
    local name = mt and mt.name or "怪物"
    if temp.eType ~= CopyEType.GUARD then
        self.lblTarge.text = string.format("击败[00FF00FF]%s[-] %d/%d", name, info.Cur or 0, info.totalWave)
    else
        self.lblTarge.text = string.format("守护[00FF00FF]%s[-]", name)
    end
    self:ShowReword()
end

function M:ShowReword()
    local curState = RobberyMgr.curState
    if curState == nil or curState == 0 then
        return
    end
    local nextAmbCfg = RobberyMgr:GetNextCfg()
    local roleCate = User.MapData.Sex
    local curReward = nil
    local skills = nextAmbCfg.getSkill
    local skillBooks = nextAmbCfg.getBook
    local curF = nextAmbCfg.floorName
    curReward = #skills > 0 and skills or skillBooks
    if curReward == nil or #curReward < 2 then
        iTrace.eError("GS","检查 境界配置表  " .. curF .. "  奖励配置")
        return
    end
    local rewardId = roleCate == curReward[1].k and curReward[1].v or curReward[2].v
    rewardId = tostring(rewardId)
    local rewardCfg = SkillLvTemp[rewardId] ~= nil and SkillLvTemp[rewardId] or ItemData[rewardId]
    if rewardCfg == nil then
        iTrace.eError("GS","检查 境界配置表  " .. curF .. "  奖励配置")
        return
    end
    local baseSkillId = nil
    if rewardCfg.baseid then
        baseSkillId = rewardCfg.baseid
    elseif rewardCfg.skillBaseId then
        baseSkillId = rewardCfg.skillBaseId[1]
    elseif rewardCfg.id then
        baseSkillId = rewardCfg.id
    end
    baseSkillId = tostring(baseSkillId)
    local baseSkillCfg = SkillBaseTemp[baseSkillId]
    if baseSkillCfg == nil then
        -- iTrace.eError("GS","检查 境界配置表  " .. curF .. "  奖励配置")
        -- return
        baseSkillCfg = ItemData[baseSkillId]
    end
    local name = baseSkillCfg.name
    local str = ""
    if rewardCfg.baseid then
        str = "解锁技能:"
    elseif rewardCfg.type == 6 then
        str = "获得技能书:"
    elseif rewardCfg.type == 3 then
        str = "获得天赋书:"
    end
    local iconPath = rewardCfg.icon
    self:SetCurR(iconPath)
    self.rewardName.text = string.format( "%s%s",str,name)
end

--设置当前奖励
function M:SetCurR(iconName)
    AssetMgr:Load(iconName, ObjHandler(self.LoadIconFin,self))
end

--// 读取图标完成
function M:LoadIconFin(obj)
    self.icon.mainTexture = obj
    self.iconName = self.icon.mainTexture.name
end

function M:UnLoadIcon()
    if self.iconName == nil then
        return
    end
    AssetTool.UnloadTex(self.iconName)
    self.iconName = nil
end


function M:DisposeSelf()
    self:UnLoadIcon()
end

return M