--[[
 	authors 	:Loong
 	date    	:2017-08-23 16:29:22
 	descrition 	:神兵精炼界面
--]]


UIAdvRefine = Super:New{Name = "UIAdvRefine"}
local My = UIAdvRefine

My.root = nil

--星级游戏对象列表
My.stars = {}

--星级最大数量
My.starMax = 5

--最大星级游戏对象
My.maxGbj = nil

--非最大级游戏对象
My.nrlObj = nil

function My:Init(root)
  self.root = root
  local CG = ComTool.Get
  local des = self.Name
  self.gbj = root.gameObject

  TFC = TransTool.FindChild
  self.maxGbj = TFC(root, "max", des)
  self.nrlObj = TFC(root, "nrl", des)
  self.maxGbj:SetActive(false)
  local nrlTran = self.nrlObj.transform

  local USBC = UITool.SetBtnClick
  USBC(nrlTran, "reBtn", des, self.OnRefine, self)
  self.reLbl = CG(UILabel, nrlTran, "reBtn/des", des)
  self.conLbl = CG(UILabel, nrlTran, "con", des)

  self.curLv = CG(UILabel, root, "curLv", des)

  self.btnRed = TFC(root, "nrl/reBtn/red", des)

  self.item = ObjPool.Get(UIItem)
  local itTran = TransTool.Find(nrlTran, "icon", des)
  self.item:Init(itTran)
  PropMgr.eUpdate:Add(self.item.Refresh, self.item)
  self:SetStars()
end

function My:SetBtnRed(ac)
  if LuaTool.IsNull(self.btnRed) then
    return
  end
  self.btnRed:SetActive(ac)
end

--设置星级游戏对象列表
function My:SetStars()
  local max = self.starMax
  local root = self.root
  for i = 1, max do
    local path = StrTool.Concat("star", i, "/hl")
    local go = root:Find(path).gameObject
    self.stars[i] = go
  end
end

--激活星级
function My:ActiveStars()
  local max = self.starMax
  local st = self.db.info.sCfg.st
  local starStr = nil
  if st == nil then
    return
  end
  if st >= max then
    self.maxGbj:SetActive(true)
    self.nrlObj:SetActive(false)
    starStr = self.starMax
    for i = 1, max do
      local go = self.stars[i]
      go:SetActive(true)
    end
  else
    self.maxGbj:SetActive(false)
    self.nrlObj:SetActive(true)
    starStr = st
    for i = 1, max do
      local go = self.stars[i]
      if st < i then
        go:SetActive(false)
      else
        go:SetActive(true)
      end
    end
  end
  -- if starStr > 0 then
  --   self.curLv.text = starStr.."星"
  -- else
  --   self.curLv.text = ""
  -- end
end

--设置进度
function My:SetPro()
  local info = self.db.info
  local exp = info.exp
  local total = info.sCfg.refNum * 1.0
  if total == 0 then total = 1 end
  local val = exp / total
  local str = string.format("%s/%s",exp,total)
  if info.sCfg.st >= self.starMax then
    str = ""
  end
  self.curLv.text = str
  self.cntr.cntr:SetPro(val)
end

function My:GetDes(lock)
  if lock == true then
    return "激活"
  else
    return "升级"
  end
end

--设置消耗
function My:SetCon()
  local info = self.db.info
  local sb = ObjPool.Get(StrBuffer)

  local id = info.sCfg.refid
  local idStr = tostring(id)
  local itCfg = ItemData[idStr]
  local name = itCfg and itCfg.name or (idStr)
  local own = ItemTool.GetNum(id)
  local need = info.sCfg.refNum
  -- local color = (own < need and "[e83030]" or "[67cc67]")
  local color = (own == 0 and "[e83030]" or "[67cc67]")
  local des = self:GetDes(info.lock)
  sb:Apd(des):Apd("消耗: ")

  sb:Apd(color):Apd("["):Apd(name):Apd("]"):Apd("[-]") --[[ [ ")
  sb:Apd(color):Apd(own):Apd("[-] / ")
  sb:Apd("[67cc67]"):Apd(need):Apd("[-] ]")--]] 

  -- sb:Apd(color):Apd("["):Apd(name):Apd("]"):Apd("[-] * ")
  -- sb:Apd(color):Apd(need):Apd("[-] (拥有")
  -- sb:Apd(color):Apd(own):Apd("[-])")
  if not LuaTool.IsNull(self.conLbl) then
    self.conLbl.text = sb:ToStr()
  end
  ObjPool.Add(sb)
  local isBtnRed = self:IsShowBtnRed()
  self:SetBtnRed(isBtnRed)
end

function My:IsShowBtnRed()
  local info = self.db.info
  local bCfg = info.bCfg
  local res = false
  if RebirthMsg.RbLev < bCfg.rLv then
    res = false
  else
    local sCfg = info.sCfg
    local itID = sCfg.refid
    local num = PropMgr.TypeIdByNum(itID)
    res = num > 0 and true or false
  end
  return res
end

--精炼条件
function My:RefineCond()
  local info = self.db.info
  local bCfg = info.bCfg
  local sysId = self.db.sysID
  local res = false
  if RebirthMsg.RbLev < bCfg.rLv then
    local sb = ObjPool.Get(StrBuffer)
    sb:Apd("人物达到"):Apd(bCfg.rLv):Apd("转解锁")
    local str = sb:ToStr()
    ObjPool.Add(sb)
    UITip.Error(str)
  else
    local sCfg = info.sCfg
    local itID = sCfg.refid
    res = ItemTool.NumCond(itID, 1,false)
    if res == false then
      GetWayFunc.AdvGetWay(UIAdv.Name,sysId,itID)
    end
  end
  return res
end

--精炼按钮事件
function My:OnRefine()
  self:ReqRefine()
end

--请求自动精炼
function My:ReqRefine()
  if not self:RefineCond() then return end--false end
  local id = self.db.info.sCfg.refid
  -- iTrace.eLog("Loong", "请求升级皮肤,道具ID:", id)
  self.rCntr:Lock(true)
  local uid = PropMgr.TypeIdById(id)
  PropMgr.ReqUse(uid, 1)
  -- return true
end


--响应精炼
function My:RespRefine(id, unlock)
  if unlock == true then self.reLbl.text = "升级" end
  local info = self.db.info
  self.item:RefreshByID(info.sCfg.refid)
  self:ActiveStars()
  self:SetPro()
  self:SetCon()
end

--更新数据
function My:Refresh()
  -- self:ClearIcon()
  local info = self.db.info
  if info == nil or self.db.sysId == 2 then
    return
  end
  self.reLbl.text = self:GetDes(info.lock)
  self.item:RefreshByID(info.sCfg.refid)
  self:ActiveStars()
  self:SetPro()
  self:SetCon()
end

--进阶/升星
function My:AdvStep()

end

--清除升级消耗texture
function My:ClearIcon()
  if self.item then
    self.item:ClearIcon()
  end
end

--将item放入对象池
function My:ItemToPool()
  local item = self.item
  if item then
    ObjPool.Add(item)
    self.item = nil
  end
end

function My:Open()
  self.gbj:SetActive(true)
  self.active = true
  self:SetPro()
  PropMgr.eUpdate:Add(self.SetCon, self)
end

function My:Close()
  self.gbj:SetActive(false)
  self.active = false
  PropMgr.eUpdate:Remove(self.SetCon, self)
  -- self:ClearIcon()
end

function My:Dispose()
  if self.item then
    PropMgr.eUpdate:Remove(self.item.Refresh, self.item)
  end
  -- self:ClearIcon()
  self:ItemToPool()
  -- TableTool.ClearListToPool(item)
  TableTool.ClearUserData(self)
end

return My
