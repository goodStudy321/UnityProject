UIAdvMwMods = Super:New{Name = "UIAdvMwMods"}
local UMSI = require("UI/Adv/UIListModItem")
local My = UIAdvMwMods
--条目字典 键:模块ID,值:UWItem
My.itDic = {}

function My:Init(root)
  self.root = root
  local des = self.Name
  self.gbj = root.gameObject
  local CGS, TF = ComTool.GetSelf, TransTool.Find
  local tblTran = TF(root, "Table", des)
  --UITable表
  self.uiTbl = CGS(UITable, tblTran, des)
  self.modRoot = self.cntr.modRoot
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
  self.redId = 0
  local itMod, db, it = self.item, self.db, nil
  local dic, p = db.dic, self.root
  local info, go, c = nil, nil, nil
  local uiTblTran = self.uiTbl.transform
  local itDic, name, k = self.itDic, nil, nil
  TransTool.RenameChildren(uiTblTran)
  self:ClearItDic()
  -- self.skinBtnRed = false
  -- self.isSkinFull = true
  -- self.rebirthLv = User.MapData.ReliveLV
  -- self.curRedId = 0
  local mwSysId = 2 --法宝系统id  优化处理逻辑
  local sysId = db.sysID
  local mwId = db.upgCfg.id
  local isInit = false
  local markIndex = 0

  table.sort(db.iCfg, function(a,b) return a.sort < b.sort end)
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
        self:UpAction(info.sCfg, info.lock, it)

          if go.activeSelf then
            local propId = self.rCntr.QPropId
            if propId and propId ~= 0 then
                local bid = AdvMgr.GetBID(propId)
                if tonumber(k) == bid then
                    markIndex = k
                end
                self.rCntr:SetIsClose(true)
            else
                if info.lock == false then
                  markIndex = k
                  isInit = true
                else
                  if not isInit then
                    markIndex = k
                    isInit = true
                  end
                end
            end
          end

      end
  end

  local redid = self.redId
  redid = tostring(redid)
  for k,v in pairs(itDic) do
    if k == redid then
      self:Switch(v)
      break
    elseif k == markIndex then
      self:Switch(v)
    end
  end
end

-- --更新皮肤红点
-- function My:UpSkinAction()
--   local isShow = false
--   for i,v in pairs(self.itDic) do
--     if v.actionGo.activeSelf then
--       isShow = true
--       break
--     end
--   end
--   MWeaponMgr.flag.eChange(isShow, 3)
-- end

--设置红点
function My:SetAction(cfg, lock)
  for k,v in pairs(self.itDic) do
    if v.hlGo.activeSelf then
      self:UpAction(cfg, lock, v)
    end
  end
end

--更新红点
function My:UpAction(cfg, lock, it)
  local isShow = false
  local itemId = 0
  local nextCfg, lv,isFull = AdvInfo:GetMwNextCfg(cfg, MWSkinCfg)
  if lock == true then
    itemId = (cfg.type==1) and cfg.acPropId or cfg.stPropId
  else
    itemId = (cfg.type==1) and nextCfg.lvPropId or nextCfg.stPropId
  end
  if isFull == true then--满级
    isShow = false
  else
    local count = ItemTool.GetNum(itemId)
    local num = (lock==true) and cfg.stNum or nextCfg.stNum
    local nextCount = (cfg.type==1) and 1 or num
    if (num == nil and count > 0) or (count >= nextCount) then
      isShow = true
    end
    -- isShow = (count >= nextCount)
  end
  if isShow == true then
    self.redId = math.floor(cfg.id * 0.001)
  end
  it:IsShowAction(isShow)
end

--响应激活
function My:RespRefine(id)
  local k = tostring(math.floor(self.db.GetKey(id) * 0.1))
  local it = self.itDic[k]
  if it == nil then return end
  it:SetLock()
end

-- function My:Refresh()
--   self.cntr:Switch(self.cur.info)
-- end

--切换item
function My:Switch(it)
  if it == nil then return end
  local cur = self.cur
  if cur == it then return end
  self.cur = it
  if cur then cur:SetActive(false) end
  it:SetActive(true)
  self.cntr:Switch(it.info, self.db)
end

--将item放入对象池
function My:ItemToPool()
  if self.itDic or #self.itDic > 0 then
    for k,v in pairs(self.itDic) do
      v.info = nil
      v.cntr = nil
      ObjPool.Add(v)
      self.itDic[k] = nil
    end
  end
end

function My:Open()
  self:Reset()
  -- self.cur:SetActive(true)
  self.uiTbl:Reposition()
end

function My:Close()
  if self.cur == nil then return end
  self.cur:SetActive(false)
  self.cur = nil
  self.redId = 0
end

function My:Dispose()
    self:ItemToPool()
    TableTool.ClearUserData(self)
end

return My