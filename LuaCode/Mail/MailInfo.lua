--[[
 	authors 	:Loong
 	date    	:2017-10-12 10:08:39
 	descrition 	:邮件信息
--]]

MailInfo = Super:New{Name = "MailInfo"}

local My = MailInfo

function My:Ctor()
  --物品/附件(PropTb)列表
  self.goods = {}
  self:Reset()
end

function My:Reset()
  self.id = 0
  --1:未读 2:已读
  self.st = 0
  --时间
  self.tm = 0
  --模板ID
  self.tmpID = 0
  --标题字符
  self.title = nil
  --内容字符
  self.cont = nil
end

--设置需要通过占位符转换的属性
--pn:字符属性名
--cn:配置属性名
--lst:C#列表
function My:SetStr(pn, cn, lst, color)
  local tmpID = self.tmpID
  if tmpID == 0 then self[pn] = color .. lst[1] return end
  local tstr = tostring(tmpID)
  local cfg = MailTmpCfg[tstr]
  local sb = ObjPool.Get(StrBuffer)
  sb:Apd(color)
  if cfg == nil then
    sb:Apd("无模板ID:"):Apd(tmpID)
  elseif #lst < 1 then
    local str = cfg[cn] and cfg[cn][1] or "无"
    sb:Apd(str)
  else
    local str = cfg[cn]
    local idx, len = 1, #str
    for i, v in ipairs(str) do
      if v == "#" then
        if idx > len then
          iTrace.Error("Loong", tstr .. "数量不匹配")
        else
          sb:Apd(lst[idx])
          idx = idx + 1
        end
      else
        sb:Apd(v)
      end
    end
  end
  self[pn] = sb:ToStr()
  ObjPool.Add(sb)
end

--设置信件状态
function My:SetState(st)
  self.st = st
end

--设置标题占位符列表
function My:SetTitle(lst)
  self:SetStr("title", "t", lst, "[f4ddbd]")
end

--设置内容占位符列表
function My:SetCont(lst)
  self:SetStr("cont", "c", lst, "[99886b]")
end

--添加物品
--it(类型后面会修改)
function My:AddGoods(it)
  if it == nil then return end
  self.goods = self.goods or {}
  local gs = self.goods
  gs[#gs + 1] = it
end

--判断是否有物品/附件
function My:HasGoods()
  if #self.goods > 0 then return true end
  return false
end

--判断是否已读无附件邮件
function My:ReadedNoGoods()
  if self.st == 1 then return false end
  if #self.goods > 0 then return false end
  return true
end

--设置已读并且清理附件
function My:SetReadedNoGoods()
  self:ClearGoods()
  self:SetState(2)
end

--清理附件列表
function My:ClearGoods()
  ListTool.Clear(self.goods)
end

function My:Dispose()
  self:Reset()
  ListTool.ClearToPool(self.goods)
end
