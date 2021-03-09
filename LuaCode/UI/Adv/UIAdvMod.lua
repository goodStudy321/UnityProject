--[[
 	authors 	:Loong
 	date    	:2017-08-24 11:58:46
 	descrition 	:神兵模型模块
--]]


local UMSI = require("UI/Adv/UIListModItem")
UIAdvMod = Super:New{Name = "UIAdvMod"}
local My = UIAdvMod

--条目字典 键:模块ID,值:UWItem
My.itDic = {}

function My:Init(root)
  self.root = root
  self.active = false
  local des = self.Name
  self.gbj = root.gameObject
  local CGS, TF = ComTool.GetSelf, TransTool.Find
  local tblTran = TF(root, "Table", des)
  --UITable表
  self.uiTbl = CGS(UIGrid, tblTran, des)
  --条目模板
  self.item = TransTool.FindChild(tblTran, "item", des)
  self.item:SetActive(false)
end

--清理条目字典
function My:ClearItDic()
  local itDic, root = self.itDic, self.root
  local OA, tran = ObjPool.Add, nil
  for k, v in pairs(itDic) do
    tran = v.root.transform
    tran.name = "none"
    tran.parent = root
    tran.gameObject:SetActive(false)
    itDic[k] = nil
    OA(v)
  end
end

--重设条目字典
function My:Reset()
  local itMod, db, it = self.item, self.db, nil
  local dic, p = db.dic, self.root
  local info, go, c = nil, nil, nil
  local uiTblTran = self.uiTbl.transform
  local itDic, name, k = self.itDic, nil, nil
  TransTool.RenameChildren(uiTblTran)
  self:ClearItDic()
  self.skinBtnRed = false
  self.isSkinFull = true
  self.rebirthLv = User.MapData.ReliveLV
  self.curRedId = 0
  local mwSysId = 2 --法宝系统id  优化处理逻辑
  local sysId = db.sysID
  local mwId = db.upgCfg.id
  for i, v in pairs(db.iCfg) do
    name = v.name
    k = tostring(v.id)
    info = dic[k]
    if info then
      c = p:Find("none")
      if c then
        go = c.gameObject
      else
        go = Instantiate(itMod)
        c = go.transform
      end
      go.name = k
      it = ObjPool.Get(UMSI)
      it.info = info
      it.cntr = self
      itDic[k] = it
      if mwSysId == sysId and mwId == v.id then
        go:SetActive(false)
      else
        go:SetActive(true)
      end
      it:Init(c)
      TransTool.AddChild(uiTblTran, c)
      local bId = v.id
      local propId = AdvMgr.GetPIdByBId(bId)
      local propNum = PropMgr.TypeIdByNum(propId)
      -- iTrace.Error("sysId = "..db.sysID)
      if db.sysID == 2 then return end
      self:SetInitAction(v,it,info,propNum)
    end
  end
  self.uiTbl:Reposition()
  self.db.eSkinRedS(self.skinBtnRed)
  local ck = self.db.iCfg[1].id
  if mwSysId == sysId then
    ck = self.db.iCfg[2].id
  end
  local secId = self.rCntr.SecondId
  local porpId = self.rCntr.QPropId
  if porpId > 0 then
    ck = porpId/100
  elseif self.curRedId > 0 then
    ck = self.curRedId
  end
  ck = tostring(ck)
  self.cur = self.itDic[ck]
  if self.cur == nil then
    return
  end
  if secId == 2 then
    self.cur:IsShowAction(false)
  elseif secId == 1 then
    self.cur:IsShowAction(porpId > 0 or self.curRedId > 0)
  end
  self.cur:TweenPlay(true)
end

--初始红点设置
function My:SetInitAction(icfg,it,info,propNum)
  local bId = icfg.id
  local isShowAc = false
  local rbLv = icfg.rLv
  local propNum = propNum
  local curSt = info.sCfg.st or 0
  local curExp = info.exp
  -- iTrace.Error("curSt = "..tostring(curSt).." curExp = "..tostring(curExp).." propNum = "..tostring(propNum))
  if curSt >= 5 and curExp == 0 and propNum >= 0 then
    isShowAc = false
  elseif propNum <= 0 then
    isShowAc = false
  elseif curSt < 5 and curExp >= 0 and propNum > 0 and self.rebirthLv >= rbLv then
    isShowAc = true
    if self.curRedId == 0 then
      self.curRedId = bId
    end
    self.skinBtnRed = true
    self.isSkinFull = false
  end
  it:IsShowAction(isShowAc)
end

--响应激活
function My:RespRefine(id, unlock)
  if not unlock then return end
  local k = self.db.GetKey(id)
  local it = self.itDic[k]
  it:SetLock()
end

function My:Refresh()
  if self.cur == nil then
    return
  end
  self.cntr:Switch(self.cur.info)
end

--it:UIListModItem
function My:Switch(it)
  local dic = self.db.dic
  -- iTrace.Error("lv = "..self.db.lv)
  if it == nil then return end
  local cur = self.cur
  if cur == it then return end
  self.cur = it
  if cur then cur:SetActive(false) end
  it:SetActive(true)
  self.cntr:Switch(it.info)
end

function My:Open()
  if self.cur == nil then return end
  self.cur:SetActive(true)
  self.gbj:SetActive(true)
  self.active = true
  self.uiTbl.repositionNow = true
end

function My:Close()
  if self.cur == nil then
    return
  end
  self.cur:SetActive(false)
  self.gbj:SetActive(false)
  self.active = false
end

function My:Dispose()
  self.skinBtnRed = nil
  self.isSkinFull = nil
  self.cur = nil
  self:ClearItDic()
  TableTool.ClearUserData(self)
end

return My
