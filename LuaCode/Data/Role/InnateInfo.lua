InnateInfo=Super:New{Name="treeInfo"}
local My = InnateInfo

function My:SetInfo(skillId,lv,backPoint,nextId,lmt,exp,lmPoint,lmLv)
    self.skillId=skillId
    self.lv=lv
    self.backPoint=backPoint
    self.nextId=nextId
    self.lmt=lmt
    self.exp=exp
    self.lmPoint=lmPoint
    self.lmLv=lmLv
end

function My:setTNB( info )
    self.skillId=info.baseId
    self.baseId=info.baseId
    self.max=info.max
    self.line=info.line
    self.grp=info.grp
    self.nextId=info.baseId
    self.lv=0
    self.backPoint=0
    local sysInfo= tInnateSys[self.baseId]
    if sysInfo==nil then
        iTrace.eError("soon",string.format("天赋系统表没找到此id=%s",self.baseId))
        return
    end
    self.tree=sysInfo.tree
    self.lmt=sysInfo.lmt
    self.lmLv=sysInfo.lmLv
    self.lmPoint=sysInfo.lmPoint
    self.exp=sysInfo.exp
    self.rad=false
    self.Error="需要解锁此天赋"
    self.needErrorLst={false,false,false,false}
    self.changError=""
end


function My:Dispose()
    self.skillId=nil
    self.baseId=nil
    self.nextId=nil
    self.max=nil
    self.line=nil
    self.tree=nil
    self.grp=nil
    self.nextId=nil
    self.lmt=nil
    self.lmLv=nil
    self.lmPoint=nil
    self.exp=nil
    self.backPoint=nil
    self.rad=false
    self.Error="需要解锁此天赋"
    self.changError=""
end

return My;