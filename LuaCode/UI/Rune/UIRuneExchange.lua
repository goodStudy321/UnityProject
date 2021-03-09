--[[
 	author 	    :Loong
 	date    	:2018-01-18 19:24:14
 	descrition 	:符文兑换面板
--]]
local UREI = require("UI/Rune/UIRuneExchgItem")

UIRuneExchange = Super:New{Name = "UIRuneExchange"}

local My = UIRuneExchange

--k:等级ID,v:UIRuneExchgItem列表
My.dic = {}

function My:Init(root)
  local des = self.Name
  self.root = root
  local CG = ComTool.Get
  local USBC = UITool.SetBtnClick
  USBC(root, "exchgBtn", des, self.OnClickExchg, self)

  --碎片标签
  self.pieceLbl = CG(UILabel, root, "piece", des)

  self:SetPiece()
  self:SetGrid()
end


function My:SetGrid()
  local dic = self.dic
  local root = self.root
  local mod = TransTool.FindChild(root, "Scroll/item", des)
  mod:SetActive(false)
  local uiGrid = ComTool.Get(UIGrid, root, "Scroll/Grid", des)
  uiGrid.onCustomSort = self.Compare
  local gridTran = uiGrid.transform
  local it, go, tran, k, lvCfg, id = nil, nil, nil, nil, nil, nil
  local TA = TransTool.AddChild
  local Inst = GameObject.Instantiate
  local BF = BinTool.Find
  for i, v in ipairs(RuneExchgCfg) do
    id = v.id
    lvCfg = BF(RuneLvCfg, id)
    if lvCfg then
      k = tostring(id)
      go = Inst(mod)
      go.name = k
      go:SetActive(true)
      tran = go.transform
      TA(gridTran, tran)
      it = ObjPool.Get(UREI)
      it.lvCfg = lvCfg
      it.exchgCfg = v
      it.cntr = self
      it:Init(tran)
      dic[k] = it
    else
      local str = "符文兑换的ID:" .. id .. " 在等级表中未配置"
      iTrace.Error("Loong", str)
    end
  end
  uiGrid:Reposition()
end

--排序方法
--lhs(Transform)
--rhs(Transform)
function My.Compare(lhs, rhs)
  if lhs == nil or rhs == nil then return 0 end
  local dic = My.dic
  local ln = lhs.name
  local rn = rhs.name

  local lt = dic[ln]
  local rt = dic[rn]

  local exlCfg = lt.exchgCfg
  local exrCfg = rt.exchgCfg
  if exlCfg.sID < exrCfg.sID then
    return (-1)
  elseif exlCfg.sID > exrCfg.sID then
      return 1
  end
  
  -- local lcon = lt.exchgCfg.con
  -- local rcon = rt.exchgCfg.con

  -- if lcon < rcon then
  --   return (-1)
  -- elseif lcon > rcon then
  --   return (1)
  -- end
  -- local lqt = lt.cfg.qt
  -- local rqt = rt.cfg.qt

  -- if lqt < rqt then
  --   return 1
  -- elseif lqt > rqt then
  --   return (-1)
  -- end
  -- local llv = lt.lvCfg.lv
  -- local rlv = rt.lvCfg.lv
  -- if llv < rlv then
  --   return 1
  -- elseif llv > rlv then
  --   return (-1)
  -- end

  return 0
end

function My:SetPiece()
  self.pieceLbl.text = tostring(RuneMgr.piece)
  for k, v in pairs(self.dic) do
    v:Refresh()
  end
end

--点击兑换事件
function My:OnClickExchg()
  local cur = self.cur
  if cur then
    if RuneMgr.BagIsFull() then
      do UITip.Error("已超出背包上限:" .. RuneMgr.bagMax) end
      return
    end
    local own = RuneMgr.piece
    local need = cur.exchgCfg.con
    if own < need then
      local dif = need - own
      local tip = "符文碎片不足,还差" ..dif .."个"
      UITip.Log(tip)
      --MsgBox.ShowYes(tip)
    else
      self.rCntr:Lock(true)
      local lvid = cur.lvCfg.id
      --EventMgr.Trigger("ReqRuneExchange", lvid)
      RuneMgr.ReqExchange(lvid)
      --print("请求兑换:", lvid)
    end
  else
    UITip.Error("没有选择要兑换的符文")
  end
end

--it(UIRuneExchgItem)
function My:Select(it)
  if it == nil then return end
  --print("选择:", it.lvCfg.id)
  local cur = self.cur
  if cur == it then return end
  if cur then cur:SetSelect(false) end
  it:SetSelect(true)
  self.cur = it
end

function My:RespPiece()
  self:SetPiece()
end

function My:RespExchg(err)
  self.rCntr:Lock(false)
  if err > 0 then return end
  local tip = "成功兑换"
  local cfg = self.cur.cfg
  if cfg then
    tip = tip .. cfg.name .. "符文"
  end
  UITip.Log(tip)
  --MsgBox.ShowYes(tip)
end

function My:Open()

end

function My:Close()

end

function My:Dispose()
  self.cur = nil
  TableTool.ClearUserData(self)
  TableTool.ClearDicToPool(self.dic)
end

return My
