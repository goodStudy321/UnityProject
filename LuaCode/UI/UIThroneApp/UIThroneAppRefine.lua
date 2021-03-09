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
  local cellBox = CG(BoxCollider,nrlTran,"icon",des)
  self.item:Init(itTran)
  UITool.SetLsnrSelf(cellBox.gameObject,self.ClickProp,self,des)
  PropMgr.eUpdate:Add(self.item.Refresh, self.item)
  self:SetStars()
end

function My:ClickProp()
  UIMgr.Open(PropTip.Name,self.OpenCb,self)
end

function My:OpenCb(name)
  local info = self.cntr.db.info
  local id = info.sCfg.propId
  local ui = UIMgr.Get(name)
  if(ui)then 
    ui:UpData(id)
  end
end

function My:SetBtnRed(ac)
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
  local st = self.cntr.db.info.sCfg.stars
  local starStr = nil
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
end

--设置进度
function My:SetPro()
  local info = self.cntr.db.info
  local exp = info.exp
  local total = info.sCfg.propNum * 1.0
  if total == 0 then total = 1 end
  local val = exp / total
  local str = string.format("%s/%s",exp,total)
  if info.sCfg.stars >= self.starMax then
    str = ""
  end
  self.curLv.text = str
  self.cntr:SetPro(val)
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
  local info = self.cntr.db.info
  local sb = ObjPool.Get(StrBuffer)

  local id = info.sCfg.propId
  local idStr = tostring(id)
  local itCfg = ItemData[idStr]
  local name = itCfg and itCfg.name or (idStr)
  local own = ItemTool.GetNum(id)
  local need = info.sCfg.propNum
  local color = (own == 0 and "[e83030]" or "[67cc67]")
  sb:Apd("消耗: ")
  sb:Apd(color):Apd(name):Apd("[-]")
  self.conLbl.text = sb:ToStr()
  ObjPool.Add(sb)
end

--精炼条件
function My:RefineCond()
  local info = self.cntr.db.info
  local res = false
  local sCfg = info.sCfg
  local itID = sCfg.propId
  local need = sCfg.propNum
  res = self:NumCond(itID,need)
  return res
end

function My:NumCond(itID,need)
  local own = PropMgr.TypeIdByNum(itID)
  if own <= 0 then
    -- UITip.Error("请获取道具")
    self:JumpOpen()
    return false
  end
  return true
end

function My:JumpOpen()
  local itID = self.cntr.db.info.sCfg.propId
  GetWayFunc.AdvGetWay(UIThroneApp.Name,0,itID,true)
end

--精炼按钮事件
function My:OnRefine()
  self:ReqRefine()
end

--请求自动精炼
function My:ReqRefine()
  if not self:RefineCond() then 
    return 
  end
  local db = self.cntr.db
  local info = db.info
  local lock = info.lock
  local id = info.sCfg.id
  if lock == true then
    db:ReqAcive(id)
  else
    db:ReqStep(id)
  end
end



--响应精炼
function My:RespRefine(id, unlock)
  if unlock == true then self.reLbl.text = "升级" end
  local info = self.cntr.db.info
  self.item:RefreshByID(info.sCfg.propId)
  self:ActiveStars()
  self:SetPro()
  self:SetCon()
end

--更新数据
function My:Refresh()
  -- self:ClearIcon()
  local info = self.cntr.db.info
  if info == nil then
    return
  end
  self.reLbl.text = self:GetDes(info.lock)
  self.item:RefreshByID(info.sCfg.propId)
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
end

function My:Dispose()
  PropMgr.eUpdate:Remove(self.item.Refresh, self.item)
  self:ItemToPool()
  TableTool.ClearUserData(self)
end

return My
