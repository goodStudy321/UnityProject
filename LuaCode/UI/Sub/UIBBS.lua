--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-22 15:41:24
-- 电子公告牌
--=========================================================================

UIBBS = UIBase:New{Name = "UIBBS"}


local My = UIBBS

function My:InitCustom()
  local root, des = self.root, self.Name
  local bg = TransTool.Find(root, "bg", des)
  self.bgGo = bg.gameObject
  UITool.SetLsnrClick(bg, "yesBtn", des, self.Close, self)
  UITool.SetLsnrClick(bg, "close", des, self.Close, self)
  local textLbl = ComTool.Get(UILabel, bg, "area/text", des)
  UITool.SetLsnrSelf(textLbl.gameObject, self.OnClickText, self, des, false)
  self.textLbl = textLbl
  UIMgr.Open("UIRefresh", self.OpenRefreshCb, self)
end

function My:GetPath()
  local path = App.BSUrl .. "index/index/announcement?"
  local channel_id = User.ChannelID
  local game_channel_id = User.GameChannelId
  if (StrTool.IsNullOrEmpty(channel_id)) then
    channel_id = 1
  end
  if (StrTool.IsNullOrEmpty(game_channel_id)) then
    game_channel_id = 1
  end
  local sb = ObjPool.Get(StrBuffer)
  sb:Apd(path):Apd("channel_id="):Apd(channel_id):Apd("&")
  sb:Apd("channel_game_id="):Apd(game_channel_id)
  local full = sb:ToStr()
  ObjPool.Add(sb)
  do return full end
end

function My:OpenRefreshCb(name)
  local ui = UIMgr.Get(name)
  ui:SetCircleActive(true)
  UIRefresh.manual = true
  local path = self:GetPath()
  WWWTool.LoadText(path, self.SetText, self)
end

--设置内容
function My:SetText(text, err)
  self:Lock(false)
  if err then
    self:Close()
  elseif StrTool.IsNullOrEmpty(text) then
    self:Close()
  else
    self.bgGo:SetActive(true)
    text = string.gsub(text, "%[color=#", "%[")
    text = string.gsub(text, "%[/color%]", "%[-%]")
    self.textLbl.text = tostring(text)
  end
  local ui = UIMgr.Get("UIRefresh")
  ui:SetCircleActive(false)
  UIRefresh.manual = false
  ui:Close()
end

function My:OpenCustom()
  self:Lock(true)
end

--点击文本
function My:OnClickText()
  local url = self.textLbl:GetUrlAtPosition(UICamera.lastHit.point);
  if StrTool.IsNullOrEmpty(url) then return end
  UApp.OpenURL(url)
end

return My
