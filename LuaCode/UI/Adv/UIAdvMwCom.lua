UIAdvMwCom = Super:New{Name = "UIAdvMwCom"}

local My = UIAdvMwCom

function My:Init(root)
  self.root = root
  self.go = root.gameObject
  local CG, des = ComTool.Get, self.Name
  local TF, UL = TransTool.Find, UILabel
  local FindC = TransTool.FindChild
  local SetB = UITool.SetBtnClick

  self.skillList = {}
  self.curId = 0

  self.ftLbl = CG(UL, root, "ft", des)
  self.nameLbl = CG(UL, root, "stepBg/nameBg/name", des)
  self.stepLbl = CG(UL,root,"stepBg/lab",des)
  self.alFlag = TF(root,"alFlag",des)
  self.skillItem = FindC(root, "skill/icon")
  self.tranBtn = FindC(root,"tranBtn",des)
  self.grid = CG(UIGrid, root, "skill/Grid")
  self.skillItem:SetActive(false)

  SetB(root, "tranBtn", des, self.OnBtn, self)
end

--更新显示
function My:UpShow(cfg, db, unlock)
    local lock = unlock
    local skinCfg = db.info.skinCfg
    local lv = (cfg.type==1) and cfg.lv or cfg.step
    local str = (lock==true) and "" or lv
    local list = (cfg.type==1) and self:GetSkillList(cfg, skinCfg) or cfg.skillTab
    self.curId = (lock==true) and 0 or cfg.id
    self:SetFight(cfg.fight, lock)
    self:SetSL(cfg.type, str, lock)
    self:SetName(cfg.id)
    self:UpSkill(list, lock, cfg)
    self:UpState()
    self.grid:Reposition()
end

--切换技能tips
function My:Switch(it)
	if not it then return end
	self.rCntr.skiTip:Show(it)
end

--更新技能
function My:UpSkill(list, lock, cfg)
  self:ClearSkills()
  local Add = TransTool.AddChild
  for i,v in ipairs(list) do
    local go = Instantiate(self.skillItem)
    local tran = go.transform
    go:SetActive(true)
    Add(self.grid.transform, tran)
    local it = ObjPool.Get(UISkillItem)
    it:Init(tran, v, self)
    if cfg.type == 1 then
      it:Lock(not (v==cfg.skillTab[i]), v)
    else
      it:Lock(lock, v)
    end
    table.insert(self.skillList, it)
  end
end

--获取技能列表
function My:GetSkillList(cfg, skinCfg)
    local list = {}
    local id = 0
    for i,v in ipairs(skinCfg) do
        local bid = math.floor(AdvMgr.GetBID(cfg.id) * 0.1)
        local baseId = math.floor(AdvMgr.GetBID(v.id) * 0.1)
        if bid == baseId then
            list = v.skillTab
            id = v.id
        end
    end
    return list
end

--清空技能
function My:ClearSkills()
  for i,v in ipairs(self.skillList) do
    local go = v.root.gameObject
    if go then
      go:SetActive(false)
      Destroy(go)
      v:Dispose()
    end
  end
  ListTool.Clear(self.skillList)
end

--设置战斗力值
function My:SetFight(ft, lock)
  self.ftLbl.gameObject:SetActive(not lock)
  self.ftLbl.text = ft
end

--设置名称
function My:SetName(id)
  local str = ""
  local bid = math.floor(AdvMgr.GetBID(id) * 0.1)
  for i,v in ipairs(MWCfg) do
    if v.id == bid then
        str = v.name
    end
end
  self.nameLbl.text = str
end

--设置等级
function My:SetSL(type, num, lock)
  local list = SignInfo.strList
  local str = (type==1) and num or (list[num] or "").."阶"
  str = (lock==true) and "" or str
  self.stepLbl.text = str
end

--点击幻化
function My:OnBtn()
  if self.curId == 0 then
    UITip.Log("请先激活该皮肤")
    return
  end
  AdvMgr:ReqMwChange(self.curId)
end

--更新幻化状态
function My:UpState()
  local curId = math.floor(AdvMgr.GetBID(self.curId) * 0.1)
  local temp = AdvMgr.GetBID(self.db.chgID)
  local chgId = (temp>99999) and math.floor(temp*0.1) or temp
  local state = not (curId==chgId) or self.db.chgID == 0
  self:SetBtnState(state)
end

--设置幻化状态
function My:SetBtnState(state)
  self.tranBtn:SetActive(state)
  self.alFlag.gameObject:SetActive(not state)
end

--打开
function My:Open()
  self.go:SetActive(true)
end

--关闭
function My:Close()
  self.go:SetActive(false)
end

-- --设置幻化显示
-- function My:SetShowFlag(showFlag)
--   self.tranBtn.gameObject:SetActive(not showFlag)
--   self.alFlag.gameObject:SetActive(showFlag)
-- end

function My:Dispose()
  self.curId = 0
  ListTool.ClearToPool(self.skillList)
  TableTool.ClearUserData(self)
end

return My