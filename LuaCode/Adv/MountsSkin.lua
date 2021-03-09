--[[
 	author 	    :Loong
 	date    	:2018-01-11 17:56:59
 	descrition 	:坐骑皮肤
--]]

local GetErr = ErrorCodeMgr.GetError
local MSI = require("Adv.MountsSkinInfo")
MountsSkin = Super:New{Name = "MountsSkin"}

local My = MountsSkin

--计算系统前5位因子
My.fact = 0.01

--皮肤信息字典
--k:模块ID前5位
--v:MountsSkinInfo
My.dic = {}

--当前选择皮肤的信息
My.info = nil

--响应进阶
My.eRespStep = Event()

--初始化
function My.Init()
  My.SetDic()
  My.AddLsnr()
end

--设置字典
function My.SetDic()
  local dic = My.dic
  local GetKey = My.GetKey
  local cfg = MountSkinCfg
  local id, k, info = nil, nil, nil
  for i, v in ipairs(cfg) do
    id = v.id
    k = GetKey(id)
    info = dic[k]
    if info == nil then
      info = ObjPool.Get(MSI)
      dic[k] = info
    end
    if info.cfg == nil then
      info.cfg = v
    end
    if info.uMod < 1 then
      info.uMod = v.uMod
    end
    if info.name == "" then
      info.name = v.name
    end
    info:AddSki(id, v.oSkiID)
  end
  My.SetFirstInfo()
end

--重新设置字典
function My.ResetDic()
  local id, cfg = 0
  for k, v in ipairs(My.dic) do
    id = tonumber(id) * 100 + 1
    cfg = BinTool.Find(MountSkinCfg, id)
    v:Clear()
    v.cfg = cfg
  end
  My.SetFirstInfo()
end

function My.SetFirstInfo()
  local k = My.GetKey(MountSkinCfg[1].id)
  My.info = My.dic[k]
end

--服务器返回所有皮肤信息
function My.Set(lst)
  if lst == nil then return end
  local dic, id, k = My.dic, nil, nil
  for i, v in ipairs(lst) do
    id = v.id
    k = My.GetKey(id)
    local info = dic[k]
    if info ~= nil then
      info.lock = false
      info.cfg = BinTool.Find(MountSkinCfg, id)
    end
  end
end

--判断技能是否锁定
--skiID:技能ID
function My.GetSkiLock(skiID)
  local info = My.info
  local k = tostring(skiID)
  local id = info.skiDic[k]
  if not id then return false end
  local lt = (info.cfg.id < id) and false or true
  return lt
end

--获取进阶模块的前5位
function My.GetKey(id)
  local v = id * My.fact
  v = math.floor(v)
  return tostring(v)
end

--获取当前配置
function My.GetCur()
  do return My.info.cfg end
end

--获取消耗道具ID
function My:GetConID()
  local id = My.info.cfg.conID
  do return id end
end

--请求升阶
function My.ReqStep()
  local msg = ProtoPool.GetByID(20279)
  msg.skin_id = My.info.cfg.id
  ProtoMgr.Send(msg)
  --iTrace.Log("Loong", "请求皮肤升阶:", msg)
end

--响应升阶
--msg:m_mount_skin_toc
function My.RespStep(msg)
  local err = msg.err_code
  local unlock, upstep = false, false
  if err > 0 then
    MsgBox.ShowYes(GetErr(err))
  else
    local kv = msg.skin
    local id = kv.id
    local k = My.GetKey(id)
    local info = My.dic[k]
    if info ~= nil then
      if info.lock then
        unlock = true
        info.lock = false
      elseif info.cfg.id ~= id then
        info.cfg = BinTool.Find(MountSkinCfg, id)
        upstep = true
      end
    end
  end
  My.eRespStep(err, id, unlock, upstep)
  --iTrace.Log("Loong", "响应皮肤升阶:", msg)
end

function My.Clear()
  My.ResetDic()
end


--添加监听
function My.AddLsnr()
  ProtoLsnr.Add(20280, My.RespStep)
end

--移除监听
function My.RmvLsnr()
  ProtoLsnr.Remove(20280, My.RespStep)
end

--释放
function My.Dispose()
  My.RmvLsnr()
end
