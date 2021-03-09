--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-08-11 15:42:22
-- 根据道具ID列表返回flag
-- 需要道具ID列表
--=========================================================================
require("Flag/Flag")
PropsFlag = Flag:New{Name = "PropsFlag"}

local My = PropsFlag

--ids:道具ID列表
--qualIds:资质丹药ID列表
function My:Init(ids,qualIds,skltIds,sysId)
  self.ids = ids
  self.qualIds = qualIds
  self.skltIds = skltIds
  self.sysId = sysId
  self.getQualById = {}
  self.needExp = nil
  self.isFullStep = nil
  self.isFullQual = nil
  self.isFullQualTab = {}
  self.isFullSkin = nil
  Flag.Init(self)
  PropMgr.eUpdate:Add(self.Update, self)
  RebirthMsg.eRefresh:Add(self.Update,self)
end


--id:养成系统系统id: 1--->坐骑  2--->法宝  3--->宠物  4--->神兵  5--->翅膀
function My:Update()
  local ids = self.ids
  local qualIds = self.qualIds
  local skltIds = self.skltIds
  local sysId = self.sysId
  local needExp = self.needExp
  local isFullStep = self.isFullStep
  local isFullQual = self.isFullQual
  local isFullQualTab = self.isFullQualTab
  local isFullSkin = self.isFullSkin
  self.red = false
  if ids == nil then return end
  if qualIds == nil then return end
  local res, GetNum = nil, PropMgr.TypeIdByNum
  local qualRes = nil
  local skltRes = nil
  local totalExp = 0
  if sysId == 1 or sysId == 3 then
    for i,v in pairs(ids) do
      local num = GetNum(v)
      num = num or 0
      if num > 0 then
        local cfg = ItemData[tostring(v)]
        local exp = cfg.uFxArg[1] * num
        totalExp = totalExp + exp
      end
    end
  end
  local isCanLv = false
  if needExp and totalExp >= needExp then
    isCanLv = true
  end
  for i, v in pairs(ids) do
    res = GetNum(v)
    res = res or 0
    if res > 0 then
      if sysId == 1 or sysId == 3 then
        if (isFullStep == nil or isFullStep == false) and isCanLv == true then
          self.red = true
          break
        elseif isFullStep == true or isCanLv == false then
          self.red = false
        end
      else
        if isFullStep == nil or isFullStep == false then
          self.red = true
          break
        elseif isFullStep == true then
          self.red = false
        end
      end
    else
      self.red = false
    end
  end
  self.eChange(self.red,1) --进阶道具红点

  self.red = false
  for i,v in pairs(qualIds) do
    qualRes = PropMgr.TypeIdByNum(i)
    if self.getQualById[i] == nil then
      self.getQualById[i] = v
    end
    if self.isFullQualTab[i] == nil then
      self.isFullQualTab[i] = {}
      self.isFullQualTab[i].isFull = false
    end
    qualRes = qualRes or 0
    if qualRes > 0 then
      if isFullQualTab[i].isFull == false then
        self.red = true
        break
      -- elseif isFullQual == true then
      --   self.red = false
      end
    else
      self.red = false
    end 
  end
  self.eChange(self.red,2) --资质丹药道具红点

  -- local isFull = false
  -- if isFullStep == true and (isFullQual == nil or isFullQual == false) then
  --   self.red = false
  --   -- isFull = true
  -- elseif (isFullStep == nil or isFullStep == false) and isFullQual == true then
  --   self.red = false
  --   isFull = true
  -- elseif isFullStep == true and isFullQual == true then
  --   self.red = false
  --   isFull = true
  -- end
  -- if isFull == true then
  --     self.eChange(false, 1) -- 满阶或者最大等级时的红点判断
  --     -- self.eChange(false, 2) -- 满阶或者最大等级时的红点判断
  -- end


  if sysId == 2 then
    return
  end
  local rebirthLv = User.MapData.ReliveLV
  if skltIds then
    self.red = false
    for i,v in pairs(skltIds) do
      skltRes = PropMgr.TypeIdByNum(i)
      skltRes = skltRes or 0
      if skltRes > 0 and rebirthLv >= v.rLv then
        self.red = true
        break
      end 
    end
    if isFullSkin == true then
      self.red = false
    end
    -- if isFull == false and isFullSkin == true then
    --   self.red = false
    -- elseif isFull == true and isFullSkin == true  then
    --   self.red = false
    -- end
    self.eChange(self.red,3) --皮肤道具红点
  end
end


function My:Dispose()
  self.ids = nil
  self.isFullStep = nil
  self.isFullQual = nil
  self.isFullSkin = nil
  self.getQualById = {}
  Flag.Dispose(self)
  PropMgr.eUpdate:Remove(self.Update, self)
  RebirthMsg.eRefresh:Remove(self.Update,self)
end

return My
