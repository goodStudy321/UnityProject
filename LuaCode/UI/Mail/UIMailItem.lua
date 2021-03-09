--[[
 	authors 	:Loong
 	date    	:2017-10-14 10:13:31
 	descrition 	:邮件条目
--]]

UIMailItem = Super:New{Name = "UIMailItem"}

local My = UIMailItem

--数据(MailInfo)
My.info = nil

--容器
My.cntr = nil

--时间字符
My.tmStr = nil


function My:Init(root)
  self.go = root.gameObject
  local des = self.Name
  local CG = ComTool.Get
  root.name = tostring(self.info.id)
  --图标精灵/用于表示已读/未读/有附件/无附件
  self.icon = CG(UISprite, root, "icon", des)
  --时间标签
  self.tmLbl = CG(UILabel, root, "tm", des)
  --标题标签
  self.titleLbl = CG(UILabel, root, "title", des)

  self.hlSp = ComTool.GetSelf(UISprite, root, des)

  self.goodGbj = TransTool.FindChild(root, "good", des)
  self.kuangGo = TransTool.FindChild(root, "kuang", des)
  self:SetTm()
  self:SetState()
  UITool.SetLsnrSelf(root, self.OnClick, self, des, false)
end

--点击事件
function My:OnClick(go)
  if self.info == nil then
    DestroyImmediate(self.go)
    ObjPool.Add(this)
  elseif self.info.st == 1 then
    self:ReqOpen()
  end
  local cntr = self.cntr
  if cntr then
    cntr:Switch(self)
  end

end

--请求打开
function My:ReqOpen()
  if self.info.st == 2 then return end
  self.cntr:Lock(true)
  MailMgr.ReqOpen(self.info.id)
end

--设置时间
function My:SetTm()
  local sc = self.info.tm
  local val = DateTool.GetDate(sc)
  self.tmStr = val:ToString("yyyy-MM-dd HH:mm:ss")
  self.tmLbl.text = self.tmStr
end

--设置状态图标
function My:SetState()
  local sn = nil
  local info = self.info
  local at = info:HasGoods()
  local st = info.st
  self.goodGbj:SetActive(at)
  if st == 1 then
    sn = "tx_05"
  else
    sn = "tx_03"
  end
  self.titleLbl.text = info.title or info.tmpID
  self.icon.spriteName = sn
end


function My:SetSelect(at)
  local sp = at and "ty_a15" or "ty_a4"
  self.hlSp.spriteName = sp
  self.kuangGo:SetActive(not at)
  --UIMisc.SetListItemSp(self, at)
end

function My:SetActive(at)
  if at == nil then at = false end
  self.go:SetActive(false)
end

function My:Dispose()
  self.idx = 0
  self.info = nil
  self.cntr = nil
  self.tmStr = nil
  TableTool.ClearUserData(self)
end

return My
