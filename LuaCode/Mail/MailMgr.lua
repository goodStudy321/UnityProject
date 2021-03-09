--[[
 	authors 	:Loong
 	date    	:2017-10-11 10:18:15
 	descrition 	:邮件管理
--]]

require("Mail/MailInfo")
local GetError = nil

MailMgr = {Name = "MailMgr"}

local My = MailMgr

--邮件信息字典
--K:id字符 V:(MailInfo)邮件信息
My.dic = {}

--新邮件事件
My.eOwnNew = Event()

--添加邮件事件
My.eAdd = Event()

--结束接收邮件事件
My.eEndGet = Event()

--打开邮件事件
My.eOpen = Event()

--删除邮件事件
My.eRespDel = Event()

--获取物品事件
My.eRespGoods = Event()

function My.Init()
  My.Reset()
  My.AddLnsr()
  GetError = ErrorCodeMgr.GetError
end

function My.Reset()
  --拥有新邮件
  My.ownNew = false
  --第一次请求
  My.firstReq = true
end

function My.FirstReq()
  if My.firstReq then
    My.firstReq = false
    My.ReqGet()
  end
end

--返回MailInfo
--idStr(string):信件ID的字符串
function My.Get(idStr)
  return My.dic[idStr]
end

--返回true:有附件邮件
function My.HasGoods()
  for k, v in pairs(My.dic) do
    if v:HasGoods() then
      return true
    end
  end
  return false
end

--返回true:有已读无附件邮件
function My.ReadedNoGoods()
  for k, v in pairs(My.dic) do
    if not v:HasGoods() and v.st == 2 then
      return true
    end
  end
  return false
end

--请求已读邮件
--id(number):邮件UID
function My.ReqOpen(id)
  local msg = ProtoPool.GetByID(20203)
  msg.letter_id = id
  ProtoMgr.Send(msg)
end

--响应已读事件
--msg(m_letter_open_toc)
function My.RespOpen(msg)
  local err = msg.err_code
  local k = nil
  if err > 0 then
    MsgBox.ShowYes(GetError(err))
  else
    k = tostring(msg.letter_id)
    local info = My.dic[k]
    if info == nil then
      iTrace.Error("Loong", "no letter_id id:", k)
    else
      info:SetState(2)
    end
    --iTrace.sLog("Loong","set readed letter_id:", k)
  end
  My.eOpen(err, k)
end

--新邮件提醒事件
function My.OwnNew()
  My.ownNew = true
  My.firstReq = false
  My.eOwnNew()
  --iTrace.eLog("Loong", "有新邮件")
end

--请求获取邮件
function My.ReqGet()
  local msg = ProtoPool.GetByID(20201)
  ProtoMgr.Send(msg)
end

--响应获取邮件
--msg(m_letter_get_toc)
function My.RespGet(msg)
  local Add = My.Add
  local letters = msg.letters
  for i, v in ipairs(letters) do
    Add(v)
  end
  My.ownNew = false
  My.eEndGet(op)
end

--添加邮件内
--v(p_lua_letter)
function My.Add(v)
  local k = tostring(v.id)
  local it = My.dic[k]
  if it then
    iTrace.Error("Loong","repeat add letter_id:",k)
  else
    it = ObjPool.Get(MailInfo)
    it.id = v.id
    it.st = v.letter_state
    it.tm = v.send_time
    it.tmpID = v.template_id
    it:SetTitle(v.title_string)
    it:SetCont(v.text_string)
    My.AddGoods(it, v.goods_list)
    My.dic[k] = it
    My.eAdd(it)
    --iTrace.eLog("Loong","add letter_id:",k)
  end
end

--移除邮件
--id(number):邮件ID
function My.Remove(id)
  local k = tostring(id)
  local dic = My.dic
  local info = dic[k]
  ObjPool.Add(info)
  dic[k] = nil
  --iTrace.sLog("Loong", "delete letter_id:",k)
end

--移除多个邮件
--lst:ID列表
function My.Removes(lst)
  if lst == nil then return end
  local Remove = My.Remove
  local len = #lst
  for i = 1, len do
    Remove(lst[i])
  end
end

--添加物品
--info(MailInfo):邮件信息
function My.AddGoods(info, goods)
  if goods == nil then return end
  for i, v in ipairs(goods) do
    local db = PropMgr.ParseGood(v)
    info:AddGoods(db)
  end
end

--请求删除邮件
--op(number):删除类型 0:删除所有已读无附件信息 1:删除指定ID邮件信息
--id(number):邮件ID,值为1时存在
function My.ReqDel(op, id)
  local msg = ProtoPool.GetByID(20205)
  msg.op_type = op
  if (op > 0) then
    msg.id_list:append(id)
  end
  ProtoMgr.Send(msg)
end

--响应删除已读信件
--msg(m_letter_delete_toc)
function My.RespDel(msg)
  local err = msg.err_code
  local op = msg.op_type
  local lst = msg.id_list
  local id = nil
  if err > 0 then
    MsgBox.ShowYes(GetError(err))
  else
    My.Removes(lst)
  end
  --print("响应删除已读信件,op:", op, "id:", id)
  My.eRespDel(err, op)
end

--请求获取附件
--op(number):获取类型 0:获取所有附件信息 1:获取指定ID邮件附件
--id(number):获取类型为1时存在
function My.ReqGoods(op, id)
  local msg = ProtoPool.GetByID(20207)
  msg.op_type = op
  if op > 0 then
    msg.id_list:append(id)
  end
  ProtoMgr.Send(msg)
end

--响应获取物品/附件
--msg(m_letter_accept_goods_toc)
function My.RespGoods(msg)
  local err = msg.err_code
  local op = msg.op_type
  local lst = msg.id_list
  local id = nil
  if err > 0 then
    MsgBox.ShowYes(GetError(err))
  elseif op == 0 then
    for k, v in pairs(My.dic) do
      v:SetReadedNoGoods()
    end
  elseif (op == 1) and (#lst > 0)then
    id = lst[1]
    k = tostring(id)
    local info = My.dic[k]
    if info then info:SetReadedNoGoods() end
  end
  --iTrace.sLog("get letter goods,op:", op, "id:", id)
  My.eRespGoods(err, op, id)
end

--判断是否有附件未领取
function My.HasGoods()
  for k, v in pairs(My.dic) do
    if v:HasGoods() then return true end
  end
  do return false end
end

--排序:有附件无附件、未读已读、时间先后从上往下排
--lhs(MailInfo)
--rhs(MailInfo)
function My.Compare(lhs, rhs)
  if lhs == nil then return 0 end
  if rhs == nil then return 0 end
  local lhg = lhs:HasGoods()
  local rhg = rhs:HasGoods()
  ---[[
  if not (lhg and rhg)  then
    if lhg then return (-1) end
    if rhg then return (1) end
  end
  --]]
  if lhs.st < rhs.st then
    return (-1)
  elseif lhs.st > rhs.st then
    return (1)
  end
  ---[[
  if lhs.tm < rhs.tm then
    return (1)
  elseif lhs.tm > rhs.tm then
    return (-1)
  end

  if lhs.id < rhs.id then
    return (1)
  elseif lhs.id > rhs.id then
    return (-1)
  end
  --]]
  return 0
end

--添加事件
function My.AddLnsr()
  local Add = ProtoLsnr.Add
  Add(20200, My.OwnNew)
  Add(20202, My.RespGet)
  Add(20204, My.RespOpen)
  Add(20206, My.RespDel)
  Add(20208, My.RespGoods)
end

function My.Clear()
  My.Reset()
  TableTool.ClearDicToPool(My.dic)
end

return My
