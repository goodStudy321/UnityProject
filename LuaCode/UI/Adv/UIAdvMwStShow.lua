UIAdvMwStShow = Super:New{Name = "UIAdvMwStShow"}

local My = UIAdvMwStShow

function My:Init(root)
  self.root = root
  self.go = root.gameObject
  local CG, des = ComTool.Get, self.Name
  local TF, UL = TransTool.Find, UILabel
  local SetB = UITool.SetBtnClick

  self.cfg = nil
  self.skinCfg = nil
  self.lock = true
  self.itemId = 0

  self.des = CG(UL, root, "des")
  self.desGo = CG(UL, root, "des1")
  self.des1 = CG(UL, root, "comp/des1")
  self.des2 = CG(UL, root, "comp/des2")
  self.cellTran = TF(root, "cell", des)
  self.btnLab = CG(UL, root, "btn/lab")
  self.tlab2 = CG(UL, root, "tlab2")
  
  SetB(root, "btn", des, self.OnBtn, self)
end

--更新显示  当前法宝已满阶
function My:UpShow(cfg, db, unlock)
  -- if cfg.type==1 then self:Close() return else self:Open() end
    self.lock = unlock
    self.cfg = cfg
    self.skinCfg = db.info.skinCfg
    self.sysId = db.sysID
    self:SetDesState(self.lock)
    self:UpCell(cfg, self.lock)
    self:UpSkillDes(cfg, self.lock, self.skinCfg)
end

--更新道具
function My:UpCell(cfg, lock)
  local itemId = (lock==true) and cfg.acPropId or cfg.stPropId
  self.itemId = itemId
    if self.cell == nil then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.cellTran, 1)
    end
    self:UpCellCount(lock)
end

--更新技能描述
function My:UpSkillDes(cfg, lock, skinCfg)
  local skillId = tostring(cfg.skillTab[1])
  local skillCfg = SkillLvTemp[skillId]
  if skillCfg == nil then return end

  self:SetMaxState(false)
    if lock then
        self.des.text = skillCfg.desc
    else
        local nextCfg, lv,isFull = AdvInfo:GetMwNextCfg(cfg, skinCfg)
        if nextCfg == nil then return end
        if isFull == true then--满级
            self:SetDesState(true)
            self.des.text = skillCfg.desc
            self:SetMaxState(true)
        else
            self.des1.text = skillCfg.desc
            local sklId = tostring(nextCfg.skillTab[1])
            local sklCfg = SkillLvTemp[sklId]
            if sklCfg == nil then return end
            self.des2.text = sklCfg.desc
        end
    end
end

--设置描述文本状态
function My:SetDesState(state)
  local go1 = self.des.gameObject
  local go2 = self.des1.transform.parent.gameObject
  go1:SetActive(state)
  go2:SetActive(not state)
  local str = (state==true) and "激活" or "进阶"
  local str1 = (self.lock==true) and "解锁消耗" or "进阶消耗"
  self.btnLab.text = str
  self.tlab2.text = str1
end

--设置满级后的状态
function My:SetMaxState(isMax)
  self.desGo.gameObject:SetActive(isMax)
  self.cellTran.gameObject:SetActive(not isMax)
  self.btnLab.transform.parent.gameObject:SetActive(not isMax)
end

--点击激活/进阶
function My:OnBtn()
  self:UseItem()
end

--使用道具
function My:UseItem()
  if self.cfg == nil then return end
  local mgr = PropMgr
  local count = self:GetItemNum()
  local nextCfg, lv,isFull = AdvInfo:GetMwNextCfg(self.cfg, self.skinCfg)
  local num = (self.lock==true) and 1 or nextCfg.stNum
  local itID = self.itemId
  local sysId = self.sysId
  if count < num then
    -- UITip.Log("道具不足")
    GetWayFunc.AdvGetWay(UIAdv.Name,sysId,itID)
    return
  elseif isFull == true then
    UITip.Log("进阶等级已满")
    return
  end
  mgr.ReqUse(self.itemId, num, 1)
end

--获取道具数量
function My:GetItemNum()
  if self.itemId == 0 then return 0 end
  local count = ItemTool.GetNum(self.itemId)
  if count < 1 then return 0 end
  return count
end

--更新道具数量
function My:UpCellCount(lock)
  if self.cell == nil or self.cfg == nil then return end
  local nextCfg, lv,isFull = AdvInfo:GetMwNextCfg(self.cfg, self.skinCfg)
  if nextCfg == nil then return end
  local num = (not lock) and nextCfg.stNum or self.cfg.stNum
  local count = self:GetItemNum()
  local str = string.format("%s/%s", count, num)
  self.cell:UpData(self.itemId, str)
end

function My:Open()
  self.go:SetActive(true)
end

function My:Close()
  self.go:SetActive(false)
end

function My:Dispose()
  self.cfg = nil
  self.skinCfg = nil
  self.lock = true
  self.itemId = 0
  if self.cell then
    self.cell:DestroyGo()
    ObjPool.Add(self.cell)
    self.cell = nil
  end
  TableTool.ClearUserData(self)
end

return My