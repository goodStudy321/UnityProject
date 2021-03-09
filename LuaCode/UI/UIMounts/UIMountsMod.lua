--[[
 	authors 	:Loong
 	date    	:2017-08-21 01:27:16
 	descrition 	:坐骑模型模块
--]]

UIMountsMod = Super:New{Name = "UIMountsMod"}
local UMI = require("UI/Cmn/UIModItem")

local My = UIMountsMod
local Mm = MountsMgr

--模型字典 键:配置ID,值:UIModItem
My.dic = {}

function My:Init(root)
  --当前选择条目
  --My.cur = nil
  self.modRoot = root
  self:SetDic()
end

--设置模型条目字典
function My:SetDic()
  local dic, it, k = self.dic, nil, nil
  for i, v in ipairs(MountCfg) do
    local it = ObjPool.Get(UMI)
    k = tostring(v.id)
    it.cfg = v
    it.cntr = self
    dic[k] = it
    it:Init()
  end
  --local id = MountCfg[1].id
  --self.cur = dic[tostring(id)]
end

--选择上一个
function My:SelectLast()
  local cur = self.cur
  local kID = cur.cfg.id
  local lID = kID - 1
  if lID < MountCfg[1].id then
    UITip.Log("已是最低阶")
  else
    self:Switch(lID)
  end
end

--选择下一个
function My:SelectNext()
  local cur = self.cur
  local kID = cur.cfg.id
  local nID = kID + 1
  local nCfg = BinTool.Find(MountCfg, nID, "id")
  if nCfg == nil then
    UITip.Log("敬请期待")
  else
    self:Switch(nID)
  end
end

--切换
--it(UIModItem):条目
function My:Switch(id)
  local k = tostring(id)
  local it = self.dic[k]
  if it == nil then return end
  local cur = self.cur
  self.cur = it
  if cur then cur:SetActive(false) end
  it:SetActive(true)
  self.cntr:Switch(it.cfg)
end

--选择当前
function My:SelectCur()
  local id = MountsMgr.bid
  if id == 0 then id = MountCfg[1].id end
  self:Switch(id)
end

function My:Open()
  if self.cur then
    self.cur:SetActive(true)
  end
end

function My:Close()
  if self.cur then
    self.cur:SetActive(false)
  end
end

function My:Refresh()
  self.cntr:Switch(self.cur.cfg)
end

function My:Dispose()
  self.cur = nil
  -- AssetTool.Unload(self.root)
  TableTool.ClearDicToPool(self.dic)
end

return My
