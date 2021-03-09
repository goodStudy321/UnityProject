--[[
 	author 	    :Loong
 	date    	:2018-01-22 10:37:30
 	descrition 	:符文背包
--]]

local URI = require("UI/Rune/UIRuneBagItem")

UIRuneBag = Super:New{Name = "UIRuneBag"}

local My = UIRuneBag


--k:uid,v:UIRuneBagItem
My.dic = {}

--选择的条目
My.cur = nil

--锚点
My.anchor = nil

function My:Init(root)
  local des = self.Name
  self.root = root
  local CG = ComTool.Get
  self.active = false
  --true:需要重新排列
  self.neetRepos = true

  local uiGrid = CG(UIGrid, root, "Grid", des)
  --UI排列网格
  self.uiGrid = uiGrid
  --true:镶嵌
  self.isSlot = false
  --true:可以多选
  self.multiSelect = false

  --iTool.SetFunc(self, "Compare")
  uiGrid.onCustomSort = self.Compare
  --网格变换
  self.gridTran = self.uiGrid.transform
  --条目模板
  self.mod = TransTool.FindChild(root, "item", des)
  self:SetDic()
end

--设置字典
function My:SetDic()
  local dbDic = RuneMgr.bagDic
  local Add = self.Add
  for k, v in pairs(dbDic) do
    Add(self, v)
  end
end

--添加条目
--info(RuneInfo)
function My:Add(info)
  local k = tostring(info.uid)
  local Inst = GameObject.Instantiate
  local tran = self.root:Find("none")
  local go = nil
  if tran == nil then
    go = Inst(self.mod)
    tran = go.transform
    TransTool.AddChild(self.gridTran, tran)
  else
    go = tran.gameObject
  end
  go.name = k
  go:SetActive(true)
  local it = ObjPool.Get(URI)
  it.info = info
  it.cfg = info.cfg
  it.lvCfg = info.lvCfg
  it.cntr = self
  it:Init(tran)
  self.dic[k] = it
  if self.multiSelect then return end
  self:SetExpActive(it, false)
end

--移除条目
--k:UID的字符串
function My:Remove(k)
  local it = self.dic[k]
  if not it then return end
  it.go.name = "none"
  it:SetActive(false)
  self.dic[k] = nil
  ObjPool.Add(it)
  local cur = self.cur
  if cur == nil then return end
  if it ~= cur then return end
  cur:SetSelect(false)
  self.cur = nil
end

--选择条目
function My:Select(it)
  if self.multiSelect then
    it:SetSelect(not it.isSelect)
    self.cntr.decom:Switch(it)
  else
    if it == nil then return end
    --print("选择:", it.info.uid)
    local cur = self.cur
    if cur == it then return end
    if cur then cur:SetSelect(false) end
    it:SetSelect(true)
    self.cur = it
    self.cntr.decom:SetedExp()
  end
end

--设置所有经验符文/已有属性激活状态
function My:SetAllExpHasdActive(at, showIdx)
  local isExp,cfg,op = RuneMgr.IsExp
  local EmbedOp = RuneMgr.EmbedOp
  local EmbedOpOnly = RuneMgr.EmbedOpOnly
  local embed = My.cntr.embed
  local select = (My.cntr.cur == embed)
  local curSlot = embed.slot.cur
  local si = curSlot.info
  local selectCfg = si and si.cfg
  local sIdx = curSlot.idx
  local IsSameEmbedPos = RuneMgr.IsSameEmbedPos
  for k, v in pairs(self.dic) do
    cfg = v.info.cfg
    if showIdx then
      if sIdx then
        local isSame = IsSameEmbedPos(sIdx, cfg)
        v:SetActive(isSame)
      end
    else
      v:SetActive(true)
    end
    if isExp(cfg) == true then
      v:SetActive(at)
    end
    if select then
      if selectCfg then
        op = EmbedOpOnly(selectCfg, cfg)
        if op < 2 then
          op = EmbedOp(cfg)
          if op > 1 then op = 1 end
        end
      else
        op = EmbedOp(cfg)
        if op > 1 then op = 1 end
      end
    else
      op = EmbedOp(cfg)
    end
    v:SetHased(op)
  end
end

--设置经验符文条目激活状态
--it(UIRuneBagItem)
function My:SetExpActive(it, at)
  local isExp = RuneMgr.IsExp
  if isExp(it.info.cfg) == true then
    it:SetActive(at)
  end
end

--设置多选选项
function My:SetMultiSelect(val)
  self.multiSelect = val or false
end

function My:SetIsSlot(val)
  self.isSlot = val
  self.needRepos = true
end

--设置滚动视图位置和裁切面偏移
function My:SetScrollPanel(sPanel,posY,offsetY)
  if sPanel == nil then return end
  local tran = sPanel.transform 
  local localPos = tran.localPosition
  localPos.y = posY
  tran.localPosition = localPos
  local offset = sPanel.clipOffset
  offset.y = offsetY
  sPanel.clipOffset = offset
  local spring = tran.gameObject:GetComponent(typeof(SpringPanel))
  if(spring) then spring.target = localPos end
end

--重新排列
function My:Reposition()
  if self.active then
    self.uiGrid:Reposition()
    local pos = self.gridTran.position
    pos.x = self.anchor.position.x
    self.gridTran.position = pos
  else
    self.needRepos = true
  end
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

  local lhs = lt and lt.info or nil
  local rhs = rt and rt.info or nil

  if (not lhs) or (not rhs) then return 0 end
  local lCfg, rCfg = lhs.cfg, rhs.cfg
  if (not lCfg) or (not rCfg) then return 0 end
  local R = RuneMgr
  local lisExp = R.IsExp(lCfg)
  local risExp = R.IsExp(rCfg)
  local allExp = lisExp and risExp
  if (not allExp) then
    if lisExp == true then
      return 1
    elseif risExp == true then
      return (-1)
    end
  end
  local embed =  My.cntr.embed
  local select = (My.cntr.cur == embed)
  local si = embed.slot.cur.info
  local siCfg = si and si.cfg
  if select then
    if siCfg then
      local lem = R.EmbedOpOnly(siCfg, lCfg)
      local rem = R.EmbedOpOnly(siCfg, rCfg)
      if (lem > 1) or (rem > 1) then
        if (lem > 1) and (rem < 2) then 
          return (-1)
        elseif (rem > 1) and (lem < 2) then
          return (1)
        end
      else
        lem = R.EmbedOp(lCfg)
        rem = R.EmbedOp(rCfg)
        if (lem > 0) and (rem < 1) then 
          return (1)
        elseif (rem > 0) and (lem < 1) then
          return (-1)
        end
      end
    else
      local lem = R.EmbedOp(lCfg)
      local rem = R.EmbedOp(rCfg)
      if lem > 0 and rem < 1 then
        return 1
      elseif rem > 0 and lem < 1 then
        return (-1)
      end
    end
  else
    local lem = R.EmbedOp(lCfg)
    local rem = R.EmbedOp(rCfg)
    if (lem > 1) and (rem < 2) then 
      return (-1)
    elseif (rem > 1) and (lem < 2) then
      return 1
    end
    if(lem == 1) and (rem < 1) then
      return 1
    elseif (rem == 1) and (lem < 1) then
      return (-1)
    end
  end
  local res = R.Compare(lhs, rhs)
  return res
end

function My:Refresh()
  local itDic = self.dic
  local dbDic = RuneMgr.bagDic

  local Remove = self.Remove
  for k, v in pairs(itDic) do
    local info = dbDic[k]
    if not info then
      Remove(self, k)
    end
  end

  local Add = self.Add
  for k, v in pairs(dbDic) do
    local it = itDic[k]
    if not it then
      Add(self, v)
    end
  end
  self:Reposition()
  self.cur = nil
end

function My:Open()
  
  self.cur = nil
  self.active = true
  --if self.needRepos == true then
    self:Reposition()
  --end

end

function My:Close()
  self.active = false
  self.cur = nil
  self:SetAllSelect(false)
end

function My:SetAllSelect(at)
  for k, v in pairs(self.dic) do
    v:SetSelect(at)
  end
end

--设置排版
--anchor(Tranform):锚点
--col(number):列数
--cellWidth(number):元素宽度
function My:SetGrid(anchor, col, cellWidth)
  if anchor == nil then return end
  if anchor ~= self.anchor then
    self.needRepos = true
  end
  self.anchor = anchor
  local uiGrid = self.uiGrid
  uiGrid.maxPerLine = col or 2
  uiGrid.cellWidth = cellWidth or 369
  local tran = self.gridTran
  tran.parent = anchor.parent
  tran.localPosition = anchor.localPosition
end

function My:SetGridPos(pos)
  self.gridTran.position = pos
end

function My:Dispose()
  self.cur = nil
  self.anchor = nil
  self.active = false
  self.isSlot = false
  TableTool.ClearDicToPool(self.dic)
end

return My
