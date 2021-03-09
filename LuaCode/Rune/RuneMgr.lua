--==============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-01-19 16:08:52
-- 符文BID和LVID一定是8位,1:符文,2-3等级,4-5未知,6-8类型
--======================================================================
require("Rune/RuneInfo")

RuneMgr = {Name = "RuneMgr"}

local My = RuneMgr
local GetErr = ErrorCodeMgr.GetError

function My.Init()
  
  --镶嵌的符文字典,k:uid,v:RuneInfo
  My.embedDic = {}

  --对应槽位是否镶嵌,true:已镶嵌
  My.embedIdxs = {}

  --背包符文字典,k:uid,v:RuneInfo
  My.bagDic = {}

  --k:基础ID,v:数量
  My.countDic={}

  --更新经验事件
  My.eExp = Event()

  --更新碎片事件
  My.ePiece = Event()

  --更新精粹事件
  My.eEssence = Event()

  --背包新增事件
  My.eBagAdd = Event()

  --更新背包完成事件
  My.eUpdateBag = Event()

  --更新镶嵌事件
  My.eUpdateEmbed = Event()

  --响应分解事件
  My.eDecompose = Event()

  --响应兑换事件
  My.eExchange = Event()

  --响应合成事件
  My.eCompose = Event()

  --响应装备事件
  My.eEquip = Event()

  --镶嵌槽开放事件
  My.eSlot = Event()
  --true:有符文镶嵌
  My.hasEmbed = false

  --镶嵌类型列表
  My.embedTypes = {}
  --镶嵌类型字典,v:品质
  My.embedTypeDic = {}

  --选择的符文信息,仅用来进行排序
  My.selectInfo = nil


  --响应升级事件
  My.eUpg = Event()
  My.embedFlag = require("Rune/RuneEmbedFlag")
  My.decomFlag = require("Rune/RuneDecomFlag")
  My.embedFlag:Init()
  My.decomFlag:Init()
  My.Reset()
  My.AddLsnr()
  My.SetCfgProp()
  CopyMgr.eUpdateTower:Add(My.UpdateCopy)
  CopyMgr.eInitCopyInfo:Add(My.SetOpenIdx)
  if App.isEditor then
    My.CheckLvCfg(RuneExchgCfg, "兑换")
    My.CheckComCfg()
  end
end

  --最大可以根据爬塔开启进行设置的槽位
function My.GetMaxOpenIdx()
  do return 8 end
end

--符文槽位数量上限
function My.GetMaxIdx()
  do return 10 end
end

function My.SetEmbedIdxs()
  local idxs = My.embedIdxs
  local max = My.GetMaxIdx()
  for i=1,max do
    idxs[i] = false
  end
end

function My.SetEmbedIdxsByInfo(lst)
  local count = #lst
  local idxs = My.embedIdxs
  if count < 1 then return end
  for i, v in ipairs(lst) do
    idxs[v.index] = true
  end
end

function My.GetMaxLv(cfg)
  if cfg == nil then return 50 end
  local st = cfg.st or 0
  if st < 1 then return 50 end
  do return 1 end
end

--检查是否开启
function My.ChkOpen()
  My.isOpen = OpenMgr:IsOpen(OpenMgr.FWXB)
  if (My.isOpen) then 
    My.decomFlag:Update()
    My.embedFlag:Update()
  else
    OpenMgr.eOpen:Add(My.RespOpen)
  end
end

function My.RespOpen(id)
  if id~=OpenMgr.FWXB then return end
  OpenMgr.eOpen:Remove(My.RespOpen)
  My.isOpen = true
  My.decomFlag:Update()
  My.embedFlag:Update()
end

function My.SetOpenIdx()
  local maxIdx = My.GetMaxOpenIdx()
  for i, v in ipairs(RuneOpenCfg) do
    if i > maxIdx then break end
    local cID = v.cID or 40000
    local res = CopyMgr:IsFinishCopy(cID)
    if res then
      My.openIdx = i 
    end
  end
  My.SetCanEmbed()
  My.embedFlag:Update()
end

--id(number):爬塔副本ID
function My.UpdateCopy(id)
  local k = tostring(id)
  local v = nil
  local cfg = RuneOpenCfg
  for i = (#cfg - 2), 1, - 1 do
    v = cfg[i]
    if id >= v.cID then
      idx = i
      break
    end
  end
  if idx <= My.openIdx then return end
  local maxIdx = My.GetMaxOpenIdx()
  idx = ((idx>maxIdx) and 8 or idx)

  My.openIdx = idx
  My.eSlot(idx)
end

function My.Reset()
  --经验
  My.exp = 0
  --背包数量
  My.bagCnt = 0
  --背包最大数量
  My.bagMax = 200
  --上一次经验
  My.lastExp = 0
  --碎片
  My.piece = 0
  --精粹
  My.essence = 0
  --(1-8)可镶嵌
  My.CanEmbed = false
  --开启槽索引
  My.openIdx = 0
  --true:系统已开启
  My.isOpen = false

  My.SetEmbedIdxs()
end

--打开制定索引UI
function My.OpenBySysIndex(index)
  local tag = nil
  if index == 1 then
    tag = "embed"
  elseif index == 2 then
    tag = "decom"
  end
  UIRune.tabName = tag
  UIMgr.Open(UIRune.Name,My.RuneCb) 
end

function My.RuneCb(name)
	local ui = UIMgr.Get(name)
  if ui then 
    ui:SwitchByName(UIRune.tabName)
  end
end

--判断背包是否已满
function My.BagIsFull()
  do return My.bagCnt >= My.bagMax end
end

--检查配置
--cfg:配置文件
--name:配置名称
function My.CheckLvCfg(cfg, name)
  local it, err = nil
  local BF = BinTool.Find
  local SC = StrTool.Concat
  for i, v in ipairs(cfg) do
    it = BF(RuneLvCfg, v.id)
    if it == nil then
      err = SC("符文 ", name, " 表中ID:", v.id, " 未在 等级 表中配置")
      iTrace.Error("Loong", err)
    end
  end
end

function My.CheckComCfg()
  local it, id, err = nil
  for i, v in ipairs(RuneComCfg) do
    id = v.id
    it = RuneCfg[tostring(id)]
    if it == nil then
      err = SC("符文合成表中ID:", id, " 未在 基础 表中配置")
      iTrace.Error("Loong", err)
    end
  end
end

--获取背包中指定基础ID的符文的数量和UID
--bid(number):基础ID
function My.GetCountByID(bid)
  if bid == nil then return 0 end
  local k = tostring(bid)
  local cnt = My.countDic[k] or 0
  return cnt
end

function My.SetCountDic()
  local dic = My.countDic
  TableTool.ClearDic(dic)
  local id, ks = nil,nil
  for k,v in pairs(My.bagDic) do
    id = v.cfg.id
    ks = tostring(id)
    local cnt = dic[ks] or 0
    dic[ks] = cnt + 1
  end
end

--设置符文字典
--lst(p_rune):符文列表
function My.SetRuneDic(dic, lst)
  local count = #lst
  if count < 1 then return end
  local Add = My.Add
  for i, v in ipairs(lst) do
    Add(dic, v)
  end
end

--添加符文信息
--it(p_rune):符文信息
function My.Add(dic, it)
  local uid = it.rune_id
  local lvid = it.level_id
  local info = ObjPool.Get(RuneInfo)
  info.uid = uid
  info.sIdx = it.index
  local bid = My.GetBaseID(lvid)
  info:SetLvID(lvid, bid)
  k = tostring(uid)
  dic[k] = info
  --print("添加符文信息,uid:", k, "id:", id, "sIdx:", info.sIdx)
end

--删除符文信息
function My.Remove(dic, uid)
  local k = tostring(uid)
  local info = dic[k]
  if info then
    ObjPool.Add(info)
    dic[k] = nil
    --print("删除符文信息,uid:", k)
  else
    iTrace.Log("Loong", "删除符文信息,不包含UID:", k)
  end
end

--删除多个符文信息
--lst(Int):符文UID列表
function My.Removes(dic, lst)
  local Remove = My.Remove
  for i, v in ipairs(lst) do
    Remove(dic, v)
  end
end

--设置基础配置属性ID
function My.SetCfgProp()
  local SetCfgPropVal = My.SetCfgPropVal
  for i, v in ipairs(RuneLvCfg) do
    if v.p1 then
      SetCfgPropVal(v, "p1")
    end
    if v.p2 then
      SetCfgPropVal(v, "p2")
    end
  end
end

function My.SetCfgPropVal(v, pn)
  if v == nil then return end
  local bid = My.GetBaseID(v.id)
  local bCfg = RuneCfg[tostring(bid)]
  if bCfg then
    local val = v[pn]
    bCfg[pn] = val
  else
    iTrace.Error("Loong", v.id, "符文基础表中没有配置ID:", bid)
  end
end

--通过等级ID获取基础ID
function My.GetBaseID(lvid)
  local r = 100000
  local s = 10000000
  local num1 = lvid%r
  local num2 = math.floor(lvid / s)
  local lv = num2 * 100 + 1
  local bid = lv * r + num1
  return bid
end

--通过当前ID获取下一级ID
function My.GetNextLvID(lvid)
  local r = 100000
  local num1 = lvid%r
  local num2 = math.floor(lvid / r)
  local lv = num2 + 1
  local nid = lv * r + num1
  return nid
end

--通过基础ID获取等级为1的等级ID
--bid(number):基础ID
function My.GetLvID(bid)
  do return bid end
end

--判断两个类型列表是否具有相同的值
function My.TyIntersection(lhs, rhs)
  for li, lv in ipairs(lhs) do
    for ri, rv in ipairs(rhs) do
      if lv == rv then return true end
    end
  end
  do return false end
end

--设置选择的符文信息
--val(RuneInfo)
--select(bool)
function My.SetSelectInfo(val, select)
  My.selectInfo = val
  --用于判断是否选择
  My.select = select
end

--排序
--lhs(RuneInfo)
--rhs(RuneInfo)
function My.Compare(lhs, rhs)
  local lCfg, rCfg = lhs.cfg, rhs.cfg
  local lqt = lCfg.qt
  local rqt = rCfg.qt
  if lqt < rqt then
    return 1
  elseif lqt > rqt then
    return (-1)
  end

  local llv = lhs.lvCfg.lv
  local rlv = rhs.lvCfg.lv
  if llv < rlv then
    return 1
  elseif llv > rlv then
    return (-1)
  end
  if lCfg.id < rCfg.id then
    return (-1)
  elseif lCfg.id > rCfg.id then
    return (1)
  end
  return 0
end


--判断是否经验符文
--cfg(符文基础配置)
function My.IsExp(cfg)
  if cfg == nil then return false end
  local v = cfg.id
  if v == 101 then return true end
  if v == 80100001 then return true end
  if v == 80100002 then return true end
  if v == 80100003 then return true end
  if v == 80100004 then return true end
  if v == 80100005 then return true end
  if v == 80100006 then return true end
  do return false end
end

--是否是可镶嵌槽位
--idx(number)槽位索引
--cfg(table)基础配置条目
function My.IsSameEmbedPos(idx, cfg)
  if cfg == nil then return false end
  if idx > 8 then
    return (idx == cfg.st)
  else
    return cfg.st < 1
  end
end

--通过配置判断是否和镶嵌属于同一类型
--return(number):0:未镶嵌,1:包含相同类型,2:更高品质
function My.EmbedOp(cfg)
  if cfg == nil then return 0 end
  local ty , qt, eqt= nil, nil, nil
  for i,v in ipairs(cfg.ty) do
    ty = tostring(v)
    qt = cfg.qt
    eqt =  My.embedTypeDic[ty]
    if eqt then
      if eqt < qt then 
        return 2
      else 
        return 1
      end
    end
  end
  do return 0 end
end

--判断指定类型的配置和另外配置是否更好
--return(同EmbedOp)
function My.EmbedOpOnly(cfg, other)
  if other == nil then return 0 end
  for i,v1 in ipairs(cfg.ty) do
    for j,v2 in ipairs(other.ty) do
      if v1 == v2 then
        if other.qt > cfg.qt then
          return 2
        else
          return 1
        end
      end
    end
  end
  return 0
end

--判断是否包含指定槽位的符文
function My.ContainsEmbedIdx(idx)
  local st = nil
  for k,v in pairs(My.bagDic) do
    st = v.cfg.st
    if idx < 9 and (st == 0) then return true end
    if idx == st then return true end
  end
  do return false end
end

--return(bool):返回是否镶嵌
function My.IsEmbed(cfg)
  do return (My.EmbedOp(cfg) > 0) end
end


function My.SetCanEmbed()
  local types = My.embedTypes
  local typeDic = My.embedTypeDic
  ListTool.Clear(types)
  TableTool.ClearDic(typeDic)
  local cnt, cfg, maxIdx= 0, nil, My.GetMaxIdx()
  for k ,v in pairs(My.embedDic) do
    cnt = cnt + 1
    cfg = v.cfg
    for i,t in ipairs(cfg.ty) do
      tk = tostring(t) 
      if not typeDic[tk] then
          typeDic[tk] = cfg.qt
          types[#types+1]=t
      end
    end
  end

  local CanEmbed, HasBetter = false, false
  
  local IsExp ,EmbedOp, cfg= My.IsExp, My.EmbedOp
  local Insec, embedIdxs, st= My.TyIntersection, My.embedIdxs
  local maxOpenIdx , openIdx , notEmbedIn18= My.GetMaxOpenIdx(), My.openIdx

  for i=1, maxOpenIdx do
    if (not embedIdxs[i])  and (i <= openIdx)then
      notEmbedIn18 = true
      break
    end
  end

  for k,v in pairs(My.bagDic) do
    cfg = v.cfg
    if (not IsExp(cfg)) then
      local op = EmbedOp(cfg)
      if op == 0 then
        if not CanEmbed then
          if cnt < maxIdx then
            st = cfg.st
              if st > maxOpenIdx then
                if not embedIdxs[st] then
                  CanEmbed = true
                end
              else
                -- for i=1, maxOpenIdx do
                --   if not embedIdxs[i] then
                --     CanEmbed = true
                --     iTrace.Error("Loong", "X3 CanEmbed:", CanEmbed)
                --     break
                --   end
                -- end
                if notEmbedIn18 then
                  CanEmbed = true
                end
              end
          end
        end
      elseif op == 2 then
        if not HasBetter then
          HasBetter = true
        end
      end
    end
  end
  --可以镶嵌
  My.CanEmbed = CanEmbed
  --拥有更高品质
  My.HasBetter = HasBetter

end

--响应所有信息
--msg(m_rune_info_toc)
function My.RespInfo(msg)
  My.exp = msg.exp
  My.piece = msg.piece
  My.essence = msg.essence
  My.SetRuneDic(My.bagDic, msg.bag_runes)
  My.SetCountDic()
  local loads = msg.load_runes
  My.SetRuneDic(My.embedDic, loads)
  My.SetEmbedIdxsByInfo(loads)
  My.bagCnt = TableTool.GetDicCount(My.bagDic)
  if (loads and #loads > 0) then
    My.hasEmbed = true
  else
    My.hasEmbed = false
  end
  My.SetCanEmbed()
  My.ChkOpen()
  --My.decomFlag:Update()
end

--响应经验更新
--msg(m_rune_exp_update_toc)
function My.RespExp(msg)
  My.lastExp = My.exp
  My.exp = msg.exp
  My.eExp()
  --print("响应经验更新:", val)
end

--响应碎片更新
--msg(m_rune_piece_update_toc)
function My.RespPiece(msg)
  My.piece = msg.piece
  My.ePiece()
  --print("响应碎片更新:", val)
end

--响应精粹更新
--msg(m_rune_essence_update_toc)
function My.RespEssence(msg)
  My.essence = msg.essence
  My.eEssence()
  --print("响应精粹更新:", val)
end

--响应背包更新
--msg(m_rune_bag_update_toc)
function My.RespBag(msg)
  local adds = msg.update_runes
  local addLen = #adds
  local dic = My.bagDic
  My.Removes(dic, msg.del_runes)
  if addLen > 0 then
    local Add = My.Add
    for i, v in ipairs(adds) do
      Add(dic, v)
      My.eBagAdd(v)
    end
  end
  My.bagCnt = TableTool.GetDicCount(dic)
  My.SetCountDic()
  My.SetCanEmbed()
  My.eUpdateBag()
  --print("响应背包更新,新增:", #adds, "删除:", #msg.del_runes)
end

--响应镶嵌更新
--msg(m_rune_load_update_toc)
function My.RespEmbed(msg)
  local dic = My.embedDic
  My.Removes(dic, msg.del_runes)
  local uprune = msg.update_rune
  My.embedIdxs[uprune.index] = true
  My.Add(dic, uprune)
  My.SetCanEmbed()
  My.eUpdateEmbed()
  --print("响应镶嵌更新,新增:", msg.update_rune.rune_id, "删除:", #msg.del_runes)
end

--请求符文升级
--uid(number):符文唯一ID
function My.ReqUpg(uid)
  local msg = ProtoPool.GetByID(20321)
  msg.rune_id = uid
  ProtoMgr.Send(msg)
end

--响应符文升级
--msg(m_rune_level_up_toc)
function My.RespUpg(msg)
  local err = msg.err_code
  if err > 0 then
    MsgBox.ShowYes(GetErr(err))
  else
    local uid = msg.rune.rune_id
    local k = tostring(uid)
    local info = My.embedDic[k]
    info:SetLvID(msg.rune.level_id)
  end
  My.eUpg(err, k)
  --print("响应符文升级:", it.rune_id)
end

--请求分解
--ids(number):要分解的ID列表
function My.ReqDecompose(ids)
  if (ids == nil) or (#ids < 1) then return end
  local msg = ProtoPool.GetByID(20323)
  local rune_ids = msg.rune_ids
  --print("请求分解符文数量:", #ids, "消息内数量:", #rune_ids)
  for i, v in ipairs(ids) do
    rune_ids:append(v)
  end
  ProtoMgr.Send(msg)
end

--响应分解符文
--msg(m_rune_decompose_toc)
function My.RespDecompose(msg)
  local err = msg.err_code
  if err > 0 then
    MsgBox.ShowYes(GetErr(err))
  end
  My.eDecompose(err)
  --print("响应分解符文")
end

--请求兑换符文
--lvid(number):等级ID
function My.ReqExchange(lvid)
  local msg = ProtoPool.GetByID(20325)
  msg.level_id = lvid
  ProtoMgr.Send(msg)
end

--响应兑换符文
--msg(m_rune_exchange_toc)
function My.RespExchange(msg)
  local err = msg.err_code
  if err > 0 then
    MsgBox.ShowYes(GetErr(err))
  end
  My.eExchange(err)
  --print("响应兑换符文")
end

--请求合成符文
--typeid(number):符文类型ID
function My.ReqCompose(typeid)
  local msg = ProtoPool.GetByID(20327)
  msg.type_id = typeid
  ProtoMgr.Send(msg)
end

--响应合成符文
--msg(m_rune_compose_toc)
function My.RespCompose(msg)
  local err = msg.err_code
  if err > 0 then
    MsgBox.ShowYes(GetErr(err))
  end
  My.eCompose(err)
  --print("响应合成符文")
end

--请求装备符文
--uid(number):符文UID
--idx(number):槽位
function My.ReqEquip(uid, idx)
  local msg = ProtoPool.GetByID(20329)
  msg.rune_id = uid
  msg.index = idx
  ProtoMgr.Send(msg)
end

--响应装备符文
--msg(m_rune_load_toc)
function My.RespEquip(msg)
  local err = msg.err_code
  if err > 0 then
    MsgBox.ShowYes(GetErr(err))
  end
  My.eEquip(err)
  --print("响应装备符文")
end



function My.AddLsnr()
  local Add = ProtoLsnr.Add
  Add(20300, My.RespInfo)
  Add(20330, My.RespEquip)
  Add(20322, My.RespUpg)
  Add(20302, My.RespExp)
  Add(20308, My.RespBag)
  Add(20326, My.RespExchange)
  Add(20310, My.RespEmbed)
  Add(20304, My.RespPiece)
  Add(20328, My.RespCompose)
  Add(20324, My.RespDecompose)
  Add(20306, My.RespEssence)

end

function My.Clear()
  My.Reset()
  My.selectInfo = nil
  ListTool.Clear(My.embedTypes)
  TableTool.ClearDic(My.countDic)
  TableTool.ClearDic(My.embedTypeDic)
  TableTool.ClearDicToPool(My.bagDic)
  TableTool.ClearDicToPool(My.embedDic)
end


return My
