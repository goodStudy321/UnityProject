--[[
 	authors 	:Loong
 	date    	:2017-08-24 23:54:39
 	descrition 	:道具工具
--]]

ItemTool = {}

local My = ItemTool

--k:使用效果参数
My.fxDic = {}

function My.Init()
  local dic, fxk = My.fxDic, nil
  for k, v in pairs(ItemData) do
    fxk = v.uFxArg
    if fxk then
      dic[tostring(fxk[1])] = v
    end
  end
end

--通过使用效果参数获取道具条目
--uFxArg(number):使用效果参数
function My.GetByuFxArg(uFxArg)
  local k = tostring(uFxArg)
  local v = My.fxDic[k]
  return v
end

--通过道具ID获取拥有数量
function My.GetNum(id)
  if type(id) ~= "number" then return 0 end
  return PropMgr.TypeIdByNum(id)
end

--通过道具ID获取UID
--itID:道具ID
--num:需要数量
--show:数量不足显示提示
--return:nil 无UID number:有UID
function My.GetUID(itID, num, show)
  if not My.NumCond(itID, num, show) then return end
  return PropMgr.TypeIdById(itID)
end

--设置道具配置
function My.GetCfg(id)
  local cfg = ItemData[tostring(id)]
  if cfg == nil then
    iTrace.Error("Loong", "无ID为:", id, "的道具配置")
  end
  return cfg
end

--判断拥有的道具数量是否达到某个值
--itID:道具ID
--num:需要数量
--show:数量不足显示提示
function My.NumCond(itID, num, show)
  local ownNum = My.GetNum(itID)
  if ownNum < num then
    if show == nil then show = true end
    if show == true then
      local dif = num - ownNum
      local k = tostring(itID)
      local data = ItemData[k]
      local name = data and data.name or ""
      local sb = ObjPool.Get(StrBuffer)
      sb:Apd(name):Apd(" 数量不足,还差"):Apd(dif):Apd("个")
      local msg = sb:ToStr()
      ObjPool.Add(sb)
      UITip.Error(msg)
    end
    return false
  end
  return true
end

--获取消耗道具提示字符
--itID:道具ID
--needNum:需要数量
function My.GetConsume (itID, needNum)
  local ownNum = ItemTool.GetNum(itID)
  local itData = ItemData[tostring(itID)]
  local itName = itData and itData.name or ("无道具信息:" .. itID)
  local sb = ObjPool.Get(StrBuffer)
  sb:Apd("消耗:"):Apd(itName):Apd(" ("):Apd(ownNum):Apd("/"):Apd(needNum):Apd(")")
  local msg = sb:ToStr()
  ObjPool.Add(sb)
  return msg
end

--获取道具消耗/拥有提示字符串
--拥有数量不足时显示红色
--id:道具ID
--need:消耗数量
function My.GetConsumeOwn(id, need)
  local own = My.GetNum(id)
  local color = (own < need) and "[CC2500FF]" or "[00FF00FF]"

  local sb = ObjPool.Get(StrBuffer)
  sb:Apd(color):Apd(own)
  sb:Apd("/"):Apd(need)
  local str = sb:ToStr()
  ObjPool.Add(sb)
  return str
end

--获取消耗道具提示字符仅包含数字
--itID:道具ID
--needNum:需要数量
function My.GetOnlyCon (itID, needNum)
  local ownNum = My.GetNum(itID)
  local itData = ItemData[tostring(itID)]
  if itData == nil then return ("无道具信息:" .. itID) end
  local sb = ObjPool.Get(StrBuffer)
  sb:Apd(ownNum):Apd("/"):Apd(needNum)
  local msg = sb:ToStr()
  ObjPool.Add(sb)
  return msg, itData
end

--判断拥有的道具数量是否达到某个值
--如果不足则判断是否有足够的元宝购买
function My.GoldCond(itID, num, show)
  local ownNum = My.GetNum(itID)
  if ownNum < num then
    show = show or true
    local dif = num - ownNum
    local it = ItemData[tostring(itID)]
    local sp = it.quickprice or 0
    if sp == 0 then
      if show then
        MsgBox.ShowYes(itID .. "道具配置价格为0")
      end
      return false
    end
    local total = sp * dif
    local ra = RoleAssets
    local gold = ra.Gold
    local bGold = ra.BindGold
    if gold >= total then return true end
    if bGold >= total then return true end
    MsgBox.ShowYes("元宝数量不足")
    return false
  end
  return true
end

--清理格子列表
--lst(UIItemCell)列表
--toPool:true:(默认)放入对象池,反之直接销毁
function My.Clear(lst, toPool)
  if lst == nil then return end
   toPool = toPool or true
   while #lst > 0 do
    local it = table.remove(lst)
    if toPool then
      it:DestroyGo()
    else
      it:Destroy()
    end
    ObjPool.Add(it)
  end
end
