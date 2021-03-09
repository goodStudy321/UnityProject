UIAdvMwLvShow = Super:New{Name = "UIAdvMwLvShow"}

local My = UIAdvMwLvShow

local BtnLabTab = {"激活","升级","进阶"}

function My:Init(root)
  self.root = root
  self.go = root.gameObject
  local CG, des = ComTool.Get, self.Name
  local TF, UL = TransTool.Find, UILabel
  local TFC = TransTool.FindChild
  local SetB = UITool.SetBtnClick

  self.cfg = nil
  self.skinCfg = nil
  self.lock = true
  self.itemId = 0
  self.lastSkillTab = nil
  self.curExp = 0
  self.clickCount = 1
  self.isUpDate = false
  self.itemCount = 0

  self.acSkilLab = CG(UL,root,"desLab",des)
  self.acDesLab = CG(UL,root,"tlab",des)
  self.sliderLab = CG(UL,root,"slidLab",des)
  self.sliderSp = CG(UISprite, root,"slidsp",des)

  self.cellP = TF(root,"cell",des)
  self.btn = TFC(root,"btn",des)
  self.btnLab = CG(UL,root,"btn/lab",des)

  self.spr1 = TFC(root, "sp", des)
  self.spr2 = TFC(root, "tlab1", des)
  self.des1 = CG(UL, root, "des1", des)
  self.des2 = CG(UL, root, "des2", des)

  --UIEvent.Get(self.btn).onPress = UIEventListener.BoolDelegate(self.OnPressCell, self)

  SetB(root, "btn", des, self.OnBtn, self)
end

--更新显示
function My:UpShow(cfg, db, unlock, curExp)
    self.lock = unlock
    self.cfg = cfg
    self.curExp = curExp or 0
    self.skinCfg = (db==nil) and self.skinCfg or db.info.skinCfg
    self.sysId = db.sysID
    local exp = curExp or db.info.exp
    self:InitLastSkill(cfg, self.skinCfg)
    self:UpCell(cfg, unlock)
    self:UpSlider(exp)
    self:UpSkillDes(cfg, self.skinCfg)
    self:UpMaxState(cfg, self.skinCfg)
    self:UpMenuShow()
end

--更新界面展示
function My:UpMenuShow(isUse)
  if self.lock == nil or self.lock == true then return end
  if self.cfg == nil then return end
  if self:IsMax() then return end
  local cfg = self.cfg
  local isUp = self.curExp >= cfg.lvExp
  local nextCfg, isEnd,isFull = AdvInfo:GetMwNextCfg(cfg, self.skinCfg)
  local curCfg = (isUp) and nextCfg or cfg
  local val = (isUp) and 0 or self.curExp + 10

  -- local clickCount = self.clickCount
  -- if isUp or clickCount >= 50 or isUse then
  --   self.itemCount = self.itemCount - clickCount
  --   iTrace.eError("GS","clickCount===",clickCount)
  --   self:ReqUse(clickCount)
  --   self.clickCount = 1
  -- end

  self:UpShow(curCfg, nil, false, val)
  self:UpCellNum()
end

--更新道具数量
function My:UpCellNum()
  if self.cell == nil then return end
  local num = self.itemCount - self.clickCount
  self.cell:UpLab(num)
end

--设置道具数量
function My:SetCellNum()
  if self.lock == true then return end
  local count = self:GetItemNum(self.itemId)
  self.itemCount = count
end

--是否达到使用上限
function My:IsMax()
  if self.itemId == nil then return end
  local count = self.itemCount
  local clickCount = self.clickCount
  if count < 1 then return true end
  if count <= clickCount then
    self.itemCount = count - clickCount
    self:ReqUse(count)
    self.clickCount = 1
    UITip.Log("道具不足")
    return true
  end
  return false
end

--更新进度
function My:UpSlider(exp)
  self.sliderLab.gameObject:SetActive(not self.lock)
  self.sliderSp.gameObject:SetActive(not self.lock)
  self.sliderSp.fillAmount = exp/self.cfg.lvExp
  self.sliderLab.text = exp.."/"..self.cfg.lvExp
end

--更新技能开启描述
function My:UpSkillDes(cfg, skinCfg)
    local sTab = self.lastSkillTab
    if sTab == nil then return end

    local skillId, lv, isEnd,isFull = self:GetOpenSkill(cfg, skinCfg)
    local sklCfg = nil
    local str = ""
    if skillId == nil or isFull==true then
      local lastId = sTab[#sTab]
      sklCfg = SkillLvTemp[tostring(lastId)]
      str = sklCfg.desc
    else
      sklCfg = SkillLvTemp[tostring(skillId)]
      str = string.format("[F4DDBDFF]等级%s激活技能[-][00FF00FF]%s[-]", lv, sklCfg.name)
    end
    self.acSkilLab.text = str
end

--更新满级状态
function My:UpMaxState(cfg, skinCfg)
  local nextCfg, isEnd,isFull = AdvInfo:GetMwNextCfg(cfg, skinCfg)
  self.des2.text = self.acSkilLab.text
  self:SetMaxState(isFull)
end

--设置满级后的状态
function My:SetMaxState(isMax)
  self.spr2:SetActive(isMax)
  self.des1.gameObject:SetActive(isMax)
  self.des2.gameObject:SetActive(isMax)
  self.acSkilLab.gameObject:SetActive(not isMax)
  self.cellP.gameObject:SetActive(not isMax)
  self.spr1:SetActive(not isMax)
  self.btn:SetActive(not isMax)
  local v3 = (isMax==true) and Vector3(368, -166, 0) or Vector3(368, -102, 0)
  self.acDesLab.transform.localPosition = v3
  if isMax then
    self.sliderLab.gameObject:SetActive(not isMax)
    self.sliderSp.gameObject:SetActive(not isMax)
  end
end

--获取下一个开启技能
function My:GetOpenSkill(cfg, skinCfg)
  for i,v in ipairs(skinCfg) do
    local nextCfg, isEnd,isFull = AdvInfo:GetMwNextCfg(cfg, skinCfg, i)
    if nextCfg then
        if nextCfg.oSkiID then
            return nextCfg.oSkiID, nextCfg.lv, isEnd,isFull
        end
    end
  end
  return nil
end

--初始化最后的开启技能
function My:InitLastSkill(cfg, skinCfg)
  if self.lastSkillTab then return end
  for i,v in ipairs(skinCfg) do
      local bid = math.floor(AdvMgr.GetBID(cfg.id) * 0.1)
      local baseId = math.floor(AdvMgr.GetBID(v.id) * 0.1)
      if bid == baseId then
        self.lastSkillTab = v.skillTab
      end
  end
end

--更新道具
function My:UpCell(cfg, lock)
  local itemId = (lock==true) and self:GetBaseCfg(cfg).acPropId or cfg.lvPropId
  self.itemId = itemId
    if self.cell == nil then
        self.cell = ObjPool.Get(UIItemCell)
        self.cell:InitLoadPool(self.cellP, 1)
    end
    self.cell:UpData(itemId, str)
    self:UpCellCount(lock)
end

--获取基础配置
function My:GetBaseCfg(cfg)
  local bid = math.floor(AdvMgr.GetBID(cfg.id) * 0.1)
  local id = bid * 1000
  local baseCfg = BinTool.Find(self.skinCfg, id)
  return baseCfg
end

--更新道具数量
function My:UpCellCount(lock)
  local count = self:GetItemNum(self.itemId)
  local str = string.format("%s", count)
  self:UpBtnLab(lock)
  if self.cell == nil then return end
  if self.isUpDate == false and lock == false then
    self.cell:UpData(self.itemId, str)
    self.isUpDate = true
  end
  self.cell:UpLab(str)
end

-- --检测点击
-- function My:OnPressCell(go, isPress)
--   if self.lock == true then return end
-- 	if not go then
-- 		return
-- 	end
--   if isPress == true then
--     -- self:SetCellNum()
--     self.IsAutoClick = Time.realtimeSinceStartup
--   else
--     self.IsAutoClick = nil
--     -- self:UpMenuShow(true)
-- 	end
-- end

--更新
function My:Update()
  -- if self.lock == true then return end
  -- local num = ItemTool.GetNum(self.itemId)
	-- if num < 1 then return end
  -- if self.IsAutoClick then
  --     if Time.realtimeSinceStartup - self.IsAutoClick > 0.05 then
  --       self.IsAutoClick = Time.realtimeSinceStartup
  --       -- self.clickCount = self.clickCount + 1
  --       -- self:UpMenuShow()
  --       self:ReqUse(1)
  --     end
	-- end
end

--请求使用
function My:ReqUse(count)
  AdvMgr:ReqSkinLv(self.cfg.id, count)
end

--点击按钮
function My:OnBtn()
  self:UseItem()
end

--使用道具
function My:UseItem()
  if self.cfg == nil then return end
  local mgr = PropMgr
  local count = self:GetItemNum(self.itemId)
  local sysId = self.sysId
  if count < 1 then
    if self.lock == true then
      if FirstPayMgr:IsPayState() and FirstPayMgr:IsGetFDay() then
        local count = ItemTool.GetNum(35212)
        if count > 0 then
          UIMgr.Open(FirstChangePack.Name,My.FirstChPackCb)
        end
      else
        UIFirstPay:OpenFirsyPay()
      end
    else
      UITip.Log("道具不足")
      UIMgr.Open(PropTip.Name,self.OpenCb,self)
    end
    return
  end
  if self.lock == true then
    mgr.ReqUse(self.itemId, 1, 1)
  else
    self:ReqUse(count)
  end
end

--装备tip界面回调
function My:OpenCb(name)
	local ui = UIMgr.Get(name)
  if(ui)then
    -- local btnList = {"GetWay"}
    ui:UpData(self.itemId)
    -- ui:ShowBtn(btnList)
    ui:ShowBtn()
	end
end

function My.FirstChPackCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then 
	   ui:UpData(35212)
	end
end

--获取道具数量
function My:GetItemNum(itemId)
  if itemId == 0 then return 0 end
  local count = ItemTool.GetNum(itemId)
  if count < 1 then return 0 end
  return count
end

function My:UpBtnLab(lock)
  local count = self:GetItemNum(self.itemId)
  local str = ""
  if lock==true then
    str = (count<1) and "前往获取" or "激活"
  else
    str = (count<1) and "前往获取" or "一键升级"
  end
  self.btnLab.text = str
end

function My:Open()
  self.go:SetActive(true)
end

function My:Close()
  self.go:SetActive(false)
end

function My:Dispose()
  self.IsAutoClick = nil
  self.cfg = nil
  self.skinCfg = nil
  self.lock = true
  self.itemId = 0
  self.curExp = 0
  self.lastSkillTab = nil
  self.clickCount = 1
  self.itemCount = 0
  self.isUpDate = false
  if self.cell then
    self.cell:DestroyGo()
    ObjPool.Add(self.cell)
    self.cell = nil
  end
  TableTool.ClearUserData(self)
end

return My
