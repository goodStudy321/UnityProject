local UPI = require("UI/Adv/GWPropsItem")
UIAdvMwProp = Super:New{Name = "UIAdvMwProp"}

local My = UIAdvMwProp

function My:Init(root)
  local des = self.Name
  local root = root
  self.gbj = root.gameObject

  self.proItList = {}

  local CG = ComTool.Get
  local UL = UILabel
  local TFC = TransTool.FindChild
  local itWdg = CG(UIWidget, root, "item", des)
  self.itHt = itWdg.height
  self.item = itWdg.gameObject
  self.item:SetActive(false)
  local tblWdg = ComTool.GetSelf(UIWidget, root, des)
  self.tblHt = tblWdg.height
  self.uiTbl = CG(UITable, root, "Table", des)

  self.compare = TFC(root,"comp",des)
  self.curLbl = CG(UL, root, "comp/curLab", des)
  self.nextLbl = CG(UL, root, "comp/nextLab", des)
  self.totalLab = CG(UL, root, "lab", des)
end

--更新显示
function My:UpShow(cfg, db, unlock)
  local lock = unlock
  local skinCfg = db.info.skinCfg
  local nextCfg, lv,isFull = AdvInfo:GetMwNextCfg(cfg, skinCfg)
  if nextCfg == nil then return end
  self:SetLvLab(cfg, lock, nextCfg, lv)
  self:UpPro(cfg, nextCfg, lock, lv)
  self:SetMaxState(isFull)
end

--更新属性
function My:UpPro(cfg, nextCfg, lock, lv)
  local compareProps = PropTool.CompareAttr(cfg, nextCfg)
  for i,v in ipairs(compareProps) do
    local cfg = PropName[v.k]
    if cfg then
      local nameLab = cfg.name
      local curVal = (cfg.show==0) and v.curVal or (v.curVal/10000*100).."%"
      local nextVal = (cfg.show==0) and v.nextVal or (v.nextVal/10000*100).."%"
      local curPro = (lock==true) and 0 or curVal
      local nextPro = (lock==true) and curVal or nextVal
      local maxVal = (lv==0) and 0 or nextPro
      self:SetPro(compareProps, nameLab, curPro, maxVal, i)
      self.proItList[i]:SetMaxState(lv==0)
      self.proItList[i]:SetMaxLab(nameLab, nextPro)
    end
  end
end

--设置属性  加成
function My:SetPro(list, nameLab, curVal, nextVal, index)
    local Add = TransTool.AddChild
    local at = true
    if index % 2 == 0 then
      at = false
    end
    if #self.proItList < #list then
        local go = Instantiate(self.item)
        local tran = go.transform
        go:SetActive(true)
        Add(self.uiTbl.transform, tran)
        local it = ObjPool.Get(UPI)
        it:Init(tran)
        it:SetName(nameLab)
        it:SetCur(curVal)
        it:SetNext(nextVal)
        it:SetBgShow(at)
        table.insert(self.proItList, it)
    else
      self.proItList[index]:SetName(nameLab)
      self.proItList[index]:SetCur(curVal)
      self.proItList[index]:SetNext(nextVal)
      self.proItList[index]:SetBgShow(at)
    end
end

--设置等级/阶级文本
function My:SetLvLab(cfg, lock, nextCfg, lv)
  local list = SignInfo.strList
  local curLv = (cfg.type==1) and "等级"..cfg.lv or (list[cfg.step] or "?").."阶"
  local str = (lock==true) and "未激活" or "当前"..curLv
  self.curLbl.text = str
  local val = (cfg.type==1) and nextCfg.lv or nextCfg.step
  local nextLv = (lv==0) and val or lv
  local str1 = (cfg.type==1) and "等级"..nextLv or (list[nextLv] or "?").."阶"
  local str2 = (lock==true) and curLv or str1
  self.nextLbl.text = str2
end

--设置满级后的状态
function My:SetMaxState(isMax)
  self.totalLab.text = string.format("%s(已升满)", self.nextLbl.text)
  self.totalLab.gameObject:SetActive(isMax)
  self.compare:SetActive(not isMax)
end

--打开
function My:Open()
  self.gbj:SetActive(true)
end

--关闭
function My:Close()
  self.gbj:SetActive(false)
end

function My:Dispose()
  ListTool.ClearToPool(self.proItList)
  TableTool.ClearDicToPool(self.dic)
end

return My