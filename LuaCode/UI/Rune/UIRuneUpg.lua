--[[
 	author 	    :Loong
 	date    	:2018-01-22 16:45:56
 	descrition 	:符文升级
--]]

require("UI/Cmn/UIPropsItem")

UIRuneUpg = Super:New{Name = "UIRuneUpg"}

local My = UIRuneUpg

function My:Init(root)
  self.root = root
  self.go = root.gameObject
  local des = self.Name
  local USBC ,CG= UITool.SetBtnClick,ComTool.Get
  local TF,TFC= TransTool.Find, TransTool.FindChild
  --等级标签
  self.lvLbl = CG(UILabel, root, "lv", des)
  
  --名称标签
  self.nameLbl = CG(UILabel, root, "name", des)
--评分标签
  self.scoreLbl = CG(UILabel, root, "score", des)
  --图标贴图
  self.iconTex = CG(UITexture, root, "icon", des)

  self.desLbl = CG(UILabel, root, "des", des)
  --品质精灵
  self.qtSp = CG(UISprite, root, "qt", des)

  self.maxLvGo = TFC(root, "maxLv", des)

  local notTran = TF(root, "notMax", des)
  self.notMaxGo = notTran.gameObject

  --消耗标签
  self.conLbl = CG(UILabel, notTran, "con", des)
  --消耗提示标签
  self.conPreLbl = CG(UILabel, notTran, "conPre", des)

  self.repBtnTran = TF(root, "repBtn", des)
  USBC(root, "repBtn", des, self.OnClickRep, self)
  self.oriRepBtnPos = self.repBtnTran.localPosition
  self.midRepBtnPos = Vector3.New(0,self.oriRepBtnPos.y,0)

  USBC(notTran, "upgBtn", des, self.OnClickUpg, self)
  self.upgFlagGo = TFC(notTran, "upgBtn/flag",des)
  self.repFlagGo = TFC(root, "repBtn/flag",des)
  self.upgFlagGo:SetActive(false)
  self.repFlagGo:SetActive(false)

  self:AddProp("p1", "p1")
  self:AddProp("p2", "p2")
  self.active = true
  self:SetActive(false)

end


--添加属性条目
function My:AddProp(pn, rn)
  local it = ObjPool.Get(UIPropsItem)
  local tran = TransTool.Find(self.root, rn, self.Name)
  self[pn] = it
  it.root = tran
  it:Init()
  it:SetActive(false)
end

--设置属性
function My:SetProp(info, it, pn, vn)
  if info == nil then return end
  if it == nil then return end
  local cfg = info.cfg
  local pid = cfg[pn]
  if pid then
    local lvCfg = info.lvCfg
    local pCfg = BinTool.Find(PropName, pid)
    local name = pCfg and pCfg.name or "无"
    it:SetName(name)
    local GetVal = PropTool.GetVal
    local cur = lvCfg[vn]
    local curStr = GetVal(pCfg, cur)
    it:SetCur(curStr)
    local nlvid = RuneMgr.GetNextLvID(lvCfg.id)
    local nLvCfg = BinTool.Find(RuneLvCfg, nlvid)
    nLvCfg = nLvCfg or lvCfg
    local nv = nLvCfg and nLvCfg[vn] or 0
    nv = GetVal(pCfg, nv)
    it:SetNext(nv)
    it:SetActive(true)
  else
    it:SetActive(false)
  end
end

function My:SetProps()
  info = self.cntr.slot.cur.info
  local cfg = info.cfg
  if self:IsSpecital(cfg) then
    self.p1:SetActive(false)
    self.p2:SetActive(false)
    self.desLbl.text = cfg.des or ("基础符文:" .. cfg.id .. "未配置描述")
  else
    self.desLbl.text = ""
    self:SetProp(info, self.p1, "p1", "v1")
    self:SetProp(info, self.p2, "p2", "v2")
  end
end

function My:IsSpecital(cfg)
  if cfg == nil then return false end
  local st = cfg.st or 0
  do return st > 8 end
end

--切换信息
function My:Switch()
  local cur = self.cntr.slot.cur
  if cur == nil then return end
  local info = cur.info
  if info == nil then return end
  self:SetLv()
  self:SetProps()
  self:SetConsume()
  local cfg = info.cfg
  self.nameLbl.text = cfg.name
  self.scoreLbl.text = info.lvCfg.score
  self.qtSp.spriteName = UIRune.GetQuaPath(cfg.qt)
  --self.iconTex.mainTexture = cur.iconTex.mainTexture
  AssetMgr:Load(cfg.icon, ObjHandler(self.SetTex, self))
  if self.cfg then
    AssetMgr:Unload(self.cfg.icon, false)
  end
  self.cfg = cfg
  
  self:SetFlag()
  self:SetRepFlag(cfg)
end

function My:SetFlag()
  local cur = self.cntr.slot.cur
  local info = cur.info
  if info == nil then return end
  local lvCfg = info.lvCfg
  local at = false
  if (lvCfg.lv < RuneMgr.GetMaxLv(info.cfg)) then
    at = (lvCfg.upExp <= RuneMgr.exp)
  end
  self:SetFlagActive(at)
end

function My:SetRepFlag(cfg)
  local dic, at, tCfg = RuneMgr.bagDic, false
  local EmbedOpOnly, op = RuneMgr.EmbedOpOnly
  for k,v in pairs(dic) do
    tCfg = v.cfg
    op = EmbedOpOnly(cfg, tCfg)
    if op > 1 then
      at = true
      break
    end
  end
  self:SetRepFlagActive(at)
end

function My:SetTex(tex)
  self.iconTex.mainTexture = tex
end

--设置等级
function My:SetLv()
  local info = self.cntr.slot.cur.info
  if info == nil then return end
  local lv = info.lvCfg.lv
  self.lvLbl.text = "Lv." .. lv
end

--设置消耗
function My:SetConsume()
  local slot = self.cntr.slot
  local str = slot:GetConsumeStr(true)
  self.conLbl.text = str
  local info = slot.cur.info
  if info == nil then return end
  local lv = info.lvCfg.lv
  local notMax = (lv < RuneMgr.GetMaxLv(info.cfg))
  --self.conPreLbl.text = (notMax and "升级消耗:" or "已满级")
  self.notMaxGo:SetActive(notMax)
  self.maxLvGo:SetActive(not notMax)
  self.repBtnTran.localPosition = (notMax and self.oriRepBtnPos or self.midRepBtnPos)
end

function My:RespExp()
  self:SetConsume()
  self:SetFlag()
end

--响应升级
function My:RespUpg()
  self:SetLv()
  self:SetProps()
end

function My:SetFlagActive(at)
  if at == nil then at = false end
  self.upgFlagGo:SetActive(at)
end


function My:SetRepFlagActive(at)
  self.repFlagGo:SetActive(at)
end

--响应镶嵌
function My:RespEmbed()
  local it = self.cntr.slot.cur
  local embedded = it:IsEmbedded()
  self:SetActive(embedded)
  if embedded then self:Switch() end
end

--点击替换按钮事件
function My:OnClickRep()
  self.cntr.bag:Open()
end

--点击升级按钮事件
function My:OnClickUpg()
  local cur = self.cntr.slot.cur
  if cur == nil then return end
  local info = cur.info
  if info == nil then return end
  if info.lvCfg == nil then
    UITip.Error("发生未知错误,建议重启")
    return
  end
  if(info.lvCfg.lv < RuneMgr.GetMaxLv(info.cfg)) then
    if info.lvCfg.upExp > RuneMgr.exp then
      UITip.Error("经验不足")
    else
      --EventMgr.Trigger("ReqRuneUpg", info.uid)
      RuneMgr.ReqUpg(info.uid)
      self.rCntr:Lock(true)
    end
  else
    UITip.Log("该符文已经满级")
  end
end

function My:SetActive(at)
  if at == nil then at = false end
  if at == self.active then return end
  self.active = at
  self.go:SetActive(at)
  --iTrace.sLog("loong",self.Name, at)
end

function My:Dispose()
  self.active = true
  
  ObjPool.Add(self.p1)
  ObjPool.Add(self.p2)
  self.cfg = nil
  self.info = nil
  self.p1 = nil
  self.p2 = nil
end


return My
