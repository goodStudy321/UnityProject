SkillInfo=Super:New{Name="SkillInfo"}
local My = SkillInfo

local SLT = SkillLvTemp
function My:setbase( skillid )
    local strid = tostring(skillid)
    local info = SLT[strid]
    self.isOpen=false
    self.skill_id=info.id
    self.seal_id=0
    self.seal_id_list=nil
    self.seal_upred_list={}
    for i=1,3 do
        local sealred = {}
        sealred.seal_unlmt=false
        sealred.seal_exp=false
        sealred.seal_up=false
        sealred.max=false
        self.seal_upred_list[i]=sealred
    end
    self.seal_base_list=info.sealLst
    self.baseid=info.baseid
    self.Seallim=info.SealLim
    self.tb=info.tb
    self.level=0
    local baseinfo = SkillBaseTemp[tostring(self.baseid)]
    if baseinfo==nil then
        iTrace.Error("soon","sheet2无此基础技能id"..self.baseid)
        return
    end
    self.limLv=baseinfo.limLv
    self.cost=nil
    self.next_skilid=self.skill_id
    self.undermax=self.limLv>self.level
    if self.undermax then
        local nextInfo =  SLT[tostring(self.next_skilid)]
        local num =  nextInfo.cost.v
        if num~=nil then
            self.cost=nextInfo.cost
            self.itemId = nextInfo.cost.k
            self.itemNum = nextInfo.cost.v
        end
    end
    self.red = false
    self.seal_Open = false
    self.curLvl=0
    self.maxLvl=0
    self.upred=false
    self.seal_up=false
    self.chosered=false
end

function My:UpdateInfo( pskill,info )
    self.isOpen=true
    self.skill_id=pskill.skill_id
    self.seal_id=pskill.seal_id
    self.seal_id_list=pskill.seal_id_list
    self.level=info.level
    self.undermax=self.limLv>self.level
    self.red = false
    self.seal_Open = false
    self.curLvl=0
    self.maxLvl=0
    self.upred=false
    self.chosered=false
    self.seal_up=false
    self.cost=nil
    self.itemId = nil
    self.itemNum = nil
    if self.undermax then
      self.next_skilid=self.skill_id+1
      local nextInfo =  SLT[tostring(self.next_skilid)]
      local num =  nextInfo.cost.v
      if num~=nil then
          self.cost=nextInfo.cost
          self.itemId = nextInfo.cost.k
          self.itemNum = nextInfo.cost.v
      end
    end
end

function My:Dispose()

end

return My;