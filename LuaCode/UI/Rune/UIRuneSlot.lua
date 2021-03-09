--[[
 	author 	    :Loong
 	date    	:2018-01-22 16:48:01
 	descrition 	:符文镶嵌槽
--]]

local URSI = require("UI/Rune/UIRuneSlotItem")

UIRuneSlot = Super:New{Name = "UIRuneSlot"}

local My = UIRuneSlot

My.none = require("UI/Rune/UIRuneSlotNone")

--镶嵌槽字典 k:符文UID v:(UIRuneSlotItem)
My.dic = {}

--镶嵌槽列表,项类型(UIRuneSlotItem)
My.lst = {}

--当前选择槽
My.cur = nil

--已镶嵌符文的类型字典
My.typeDic = {}

function My:Init(root)
  self.root = root
  local des = self.Name
  local CG = ComTool.Get
  self.tipLbl = CG(UILabel, root, "tip/tip", des)
  self.itMod = TransTool.FindChild(root, "it", des)
  self.itMod:SetActive(false)
  local nTran = TransTool.Find(root,"none", des)
  self.none:Init(nTran)
  self:SetLst()
  self:SetOpen()
  self:Add()
  self:SetFlag(true)
  self:AddLsnr()
  self:SetTotalScore()
  self:SetAdd()
  --self:SetOpenTip()
end

function My:SetAdd()
  local lst = self.lst
  local it = nil
  for i = 1, RuneMgr.openIdx do
    it = lst[i]
    it:SetAddActive(not it:IsEmbedded())
  end

  for i=9,#RuneOpenCfg do
    it = lst[i]
    it:SetAddActive(not it:IsEmbedded())
  end
end

--设置槽开启
function My:SetOpen()
  local lst = self.lst
  for i = 1, RuneMgr.openIdx do
    local it = lst[i]
    it:SetLockActive(false)
    --iTrace.Error("符文开启槽位:",i ," ",RuneMgr.openIdx)
  end
  for i=9,#RuneOpenCfg do
    lst[i]:SetLockActive(false)
  end
end

--设置列表
function My:SetLst()
  local TF = TransTool.Find
  local root = self.root
  local cp,mod = "",self.itMod
  local child,v = nil,nil
  local des = self.Name
  local cID, ly = nil, nil
  local lst, sb = self.lst, ObjPool.Get(StrBuffer)
  local one, maxOpenIdx = Vector3.one, RuneMgr.GetMaxOpenIdx()
  for i=1, maxOpenIdx do
    cp = tostring(i)
    v = RuneOpenCfg[i]
    local anchor = TF(root, cp, des)
    local go = Instantiate(mod)
    child = go.transform
    child.parent = root
    child.localPosition = anchor.localPosition
    child.localScale = one
    go:SetActive(true)
    go.name = tostring(i)
    local it = ObjPool.Get(URSI)
    it:Init(child)
    it.idx = i
    it.cntr = self
    lst[#lst + 1] = it
    cID = v.cID
    ly = cID - 40000
    sb:Apd("[f39800]"):Apd(ly):Apd("层\n")
    sb:Apd("[-][99886b]开启")
    it:SeyLockLbl(sb:ToStr())
    sb:Dispose()
  end
  ObjPool.Add(sb)
  self:AddSpecial(9)
  self:AddSpecial(10)
end

--添加特殊槽位
function My:AddSpecial(idx)
  local child = TransTool.Find(self.root, tostring(idx),self.des)
  local it = ObjPool.Get(URSI)
  it:Init(child)
  it.idx = idx
  it.cntr = self
  self.lst[#self.lst + 1] = it
end

function My:SetFlag(first)
  local at = true
  local exp = RuneMgr.exp
  local openIdx = RuneMgr.openIdx
  local cur, info ,maxIdx= nil,nil,RuneMgr.GetMaxOpenIdx()
  for i, v in ipairs(self.lst) do
    info = v.info
    if v:IsEmbedded() then
      if (info.lvCfg.lv < RuneMgr.GetMaxLv(info.cfg)) then
        at = (info.lvCfg.upExp <= exp)
      else
        at = false
      end
    else
      if i > maxIdx then
        at = RuneMgr.ContainsEmbedIdx(i)
      elseif i > openIdx then
        at = false
      else
        at = RuneMgr.ContainsEmbedIdx(i)
        if ((cur == nil) and (at==true)) then cur = v end
      end
    end
    v:SetFlagActive(at)
  end
  if not first then return end
  if cur == nil then cur = self.lst[1] end
  self:Switch(cur, false)
end

function My:RespExp()
  self:SetFlag()
end

function My:RespUpg()
  self:SetTotalScore()
  local cur = self.cur
  if cur == nil then return end
  cur:SetLv(cur.info)
end

function My:RespEmbed()
  self:Refresh()
  self.none:RespEmbed()
  if self.cur then self.cur:SetAddActive(false) end
end

--添加
function My:Add()
  local dic = self.dic
  local lst = self.lst
  local dbDic = RuneMgr.embedDic
  for k, v in pairs(dbDic) do
    local it = dic[k]
    if it == nil then
      it = lst[v.sIdx]
      dic[k] = it
      it:RefreshByInfo(v)
    end
  end
end

--删除
function My:Remove()
  local dic = self.dic
  local dbDic = RuneMgr.embedDic
  for k, v in pairs(dic) do
    local info = dbDic[k]
    if info == nil then
      dic[k] = nil
      v:Clear()
    end
  end
end

--设置开启提示
function My:SetOpenTip()
  local oIdx = RuneMgr.openIdx
  if oIdx < #RuneOpenCfg then
    local oCfg = RuneOpenCfg[oIdx + 1]
    if oCfg == nil then return end
    local cID = oCfg.cID
    local sb = ObjPool.Get(StrBuffer)
    sb:Apd(ColorCode.darkGray):Apd("通关")
    sb:Apd(ColorCode.red):Apd("【")
    local cCfg = CopyTemp[tostring(cID)]
    local name = cCfg and cCfg.name or ("无配置")
    sb:Apd(name):Apd("】[-] 开启下个镶嵌槽")
    local str = sb:ToStr()
    self.tipLbl.text = str
    ObjPool.Add(sb)
  else
    self.tipLbl.text = "[99886b]已解锁全部镶嵌槽"
  end
end

--获取消耗经验字符串
function My:GetConsumeStr(showPre)
  local cur = self.cur
  if cur == nil then return end
  local info = cur.info
  if info == nil then return end
  if showPre == nil then showPre = true end
  local sb = ObjPool.Get(StrBuffer)
  local exp = RuneMgr.exp
  local need = info.lvCfg.upExp
  sb:Apd("[f4ddbd]")
  local color = (exp < need) and "[e83030]" or "[67cc67]"
  if showPre then sb:Apd("【经验】") end
  sb:Apd(color):Apd(exp)
  sb:Apd("[-]/"):Apd(need)
  local str = sb:ToStr()
  ObjPool.Add(sb)
  return str
end

--装备之前检查其它部位是否有相同类型符文
function My:HasSame(idx, ty)
  local TyIntersection = RuneMgr.TyIntersection
  for i, v in ipairs(self.lst) do
    if v:IsEmbedded() then
      if idx ~= i then
        --if v.info.cfg.ty == ty then
        if(TyIntersection(v.info.cfg.ty, ty)) then
          return true
        end
      end
    end
  end
  return false
end


--切换符文信息
function My:Switch(it, openBag)
  if it == nil then return end
  if it.lock then return end
  local cur = self.cur

  if cur ~= it then
    if cur then cur:SetSelect(false) end
    it:SetSelect(true)
  end
  self.cur = it
  if openBag==nil then openBag = true end
  local cntr = self.cntr
  local embedded = it:IsEmbedded()
  cntr.upg:SetActive(embedded)
  self.none:SetActive(not embedded)
  if embedded then
    cntr.upg:Switch()
  else
    cntr.bag.realBag:SetIsSlot(true)
    self:SetTypeDic()
    local maxIdx = RuneMgr.GetMaxOpenIdx()
    if it.idx > maxIdx then
      if RuneMgr.ContainsEmbedIdx(it.idx) then
        if openBag == true then cntr.bag:Open() end
      else
        JumpMgr:InitJump("UIRune", 1)
        UITreasure:OpenTab(2)
      end
    else
      if openBag == true then cntr.bag:Open() end
    end
  end
end

function My:SetTypeDic()
  local dic = self.typeDic
  TableTool.ClearDic(dic)
  local cur = self.cur
  for i, v in ipairs(self.lst) do
    if v ~= cur then
      if v:IsEmbedded() then
        for ti, tv in ipairs(v.info.cfg.ty) do
          dic[tostring(tv)] = true
        end
      end
    end
  end
end

--设置总评分
function My:SetTotalScore()
  local total = 0
  for k,v in pairs(RuneMgr.embedDic) do
    local lvCfg = v.lvCfg
    total = total + (lvCfg and lvCfg.score or 0)
  end
  self.tipLbl.text = tostring(total)
end

function My:ContainsType(ty)
  local dic = self.typeDic
  for i, v in ipairs(ty) do
    if dic[tostring(v)] then return true end
  end
  do return false end
end

--爬塔副本ID
function My:UpdateCopy(idx)
  local beg = idx
  beg = (beg < 1 and 1 or beg)
  for i = beg, idx do
    local it = self.lst[i]
    it:SetLockActive(false)
  end
  --self:SetOpenTip()
end

function My:RespBag()
  self:SetFlag()
end

--刷新
function My:Refresh()
  self:Remove()
  self:Add()
  self:SetFlag()
  self:SetTotalScore()
end

function My:AddLsnr()
  RuneMgr.eSlot:Add(self.UpdateCopy, self)
end

function My:RemoveLsnr()
  RuneMgr.eSlot:Remove(self.UpdateCopy, self)
end

function My:Dispose()
  self.cur = nil
  self:RemoveLsnr()
  TableTool.ClearDic(self.dic)
  TableTool.ClearDic(self.typeDic)
  TableTool.ClearUserData(self)
  ListTool.ClearToPool(self.lst)
end


return My