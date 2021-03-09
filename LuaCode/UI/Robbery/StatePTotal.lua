StatePTotal = Super:New{Name = "StatePTotal"}
local My = StatePTotal

function My:Init(go)
    local root = go.transform
    self.Gbj = root
    local name = root.name
    local CG = ComTool.Get
    local US = UITool.SetLsnrSelf
    self.propTLab = CG(UILabel,root,"propLab",name)
    self.propPClose = CG(BoxCollider,root,"close")
    US(self.propPClose,self.OFFTotalProp,self) 
end

function My:OnTotalProp()
    self.Gbj.gameObject:SetActive(true)
end

function My:OFFTotalProp()
    self.Gbj.gameObject:SetActive(false)
end

function My:SetTotalP()
    local stateInfo = RobberyMgr.StateInfoTab
    local smallState = stateInfo.smallState
    local bigState = stateInfo.bigState
    if smallState == nil or bigState == nil then
        return
    end
    local maxAmId = AmbitCfg[#AmbitCfg].id
    local maxBigId = RobberyMgr:GetBigState(maxAmId)
    local maxSmallId = RobberyMgr:GetSmallState(maxAmId)

    local minAmId = AmbitCfg[1].id
    local minBigId = RobberyMgr:GetBigState(minAmId)
    local minSmallId = RobberyMgr:GetSmallState(minAmId)

    local preSmallState = smallState - 1
    local preBigState = bigState - 1
    local curInfo = RobberyMgr:GetCurCfg()
    local curMaxFloor = curInfo.floorMax
    local preInfo = RobberyMgr.AmbitInfo[bigState][preSmallState]
    if preInfo == nil and bigState > minBigId then
        preBigState = bigState - 1
        preSmallState = smallState
        curMaxFloor = RobberyMgr.AmbitInfo[preBigState][preSmallState].floorMax
        preInfo = RobberyMgr.AmbitInfo[preBigState][curMaxFloor]
    elseif preInfo == nil and bigState == minBigId then
        preInfo = {}
        preInfo.healthT = 0
        preInfo.attT = 0
        preInfo.defT = 0
        preInfo.armT = 0
        preInfo.aHurtT = 0
        preInfo.rHurtT = 0
    elseif bigState == maxBigId and smallState == maxSmallId then
        preInfo = RobberyMgr.AmbitInfo[maxBigId][maxSmallId]
    end
    local hpVal = preInfo.healthT
    local atkVal = preInfo.attT
    local defVal = preInfo.defT
    local armVal = preInfo.armT
    local ampdamVal = preInfo.aHurtT
    local damredVal = preInfo.rHurtT
    local labColor = "[F4DDBDFF]"
    local valColor = "[00FF00FF]"

    local sb = ObjPool.Get(StrBuffer)
    sb:Apd(labColor):Apd("生命"):Apd("[-]"):Apd(valColor):Apd(" +"):Apd(hpVal):Apd("\n")
    sb:Apd(labColor):Apd("攻击"):Apd("[-]"):Apd(valColor):Apd(" +"):Apd(atkVal):Apd("\n")
    sb:Apd(labColor):Apd("防御"):Apd("[-]"):Apd(valColor):Apd(" +"):Apd(defVal):Apd("\n")
    sb:Apd(labColor):Apd("破甲"):Apd("[-]"):Apd(valColor):Apd(" +"):Apd(armVal):Apd("\n")
    sb:Apd(labColor):Apd("伤害加深"):Apd("[-]"):Apd(valColor):Apd(" +"):Apd(ampdamVal):Apd("\n")
    sb:Apd(labColor):Apd("伤害减免"):Apd("[-]"):Apd(valColor):Apd(" +"):Apd(damredVal):Apd("\n")
    self.propTLab.text = sb:ToStr()
    ObjPool.Add(sb)
end

function My:Dispose()
    TableTool.ClearUserData(self)
end