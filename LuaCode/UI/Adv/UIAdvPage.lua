--[[
 	authors 	:Loong
 	date    	:2017-08-23 16:27:56
 	descrition 	:神兵界面
--]]


UIAdvPage = Super:New{Name = "UIAdvPage"}

local My = UIAdvPage

local pre = "UI/Adv/UIAdv"


--升级模块
My.upg = require(pre .. "Upg")

--皮肤模块
My.skin = require(pre .. "Skin")

--法宝皮肤模块
My.mwSkin = require(pre .. "MwSkinPage")

function My:Init(root)
  self.root = root
  self.cur = self.upg
  self.prop = self.cntr.prop
  self.go = root.gameObject
  self.isCanShowPanel = nil
  local CG, des = ComTool.Get, self.Name
  local TF, UL = TransTool.Find, UILabel
  local FC = TransTool.FindChild
  local modRoot = self.rCntr.modRoot
  local SetB = UITool.SetBtnClick

  self.page = FC(root,"page",des)
  --战斗力标签
  self.ftLbl = CG(UL, root, "page/ft", des)
  self.ftBg = TF(root,"page/ftbg",des)
  --名称标签
  self.nameLbl = CG(UL, root, "page/nameBg/name", des)
  --进度标签
  self.proLbl = CG(UILabel, root, "page/proSp/lbl", des)
  -- 旧的 进度标签
  --self.proSp = CG(UISprite, root, "proSp", des)
  
  --法宝幻化按钮
  self.tranBtn = FC(root, "page/tranBtn", des)
  self.alFlag = FC(root, "page/alFlag", des)
  SetB(root, "page/tranBtn", des, self.OnTranBtn, self)

  -- 新的 进度标签
  self.proSp = CG(UISprite, root, "page/upgBg/s2", des)
  --特效进度标签
  self.proSpFx = CG(guiraffe.SubstanceOrb.OrbAnimator, root, "page/upgBg/s2/FX_SubstancePlane", des)
  self.proSpFx1 = TransTool.FindChild(root, "page/upgBg/s2/Fx_NengLiangQiu_UI02", des)

  self.modRoot = modRoot
  self.upg.modRoot = modRoot
  self.skin.modRoot = modRoot
  self.mwSkin.modRoot = modRoot
  local SetSub = UIMisc.SetSub
  SetSub(self, self.upg, "page/upg", true)
  SetSub(self, self.skin, "skin", true)
  SetSub(self,self.mwSkin,"mwSkin",true)
  self.skill = self.rCntr.skll
end

--点击幻化按钮
function My:OnTranBtn()
  local curId = math.floor(MWCfg[1].id * 1000)
  AdvMgr:ReqMwChange(curId)
end

--更新幻化按钮
function My:UpTranBtn()
  if self.db.sysID==2 then
    local curId = MWCfg[1].id
    local temp = AdvMgr.GetBID(self.db.chgID)
    local chgId = (temp>99999) and math.floor(temp*0.1) or temp
    local state = (curId==chgId) or (self.db.chgID==0)
    self:SetTranBtn(not state, state)
  else
    self:SetTranBtn(false, false)
  end
end

--设置幻化按钮
function My:SetTranBtn(state1, state2)
  self.tranBtn:SetActive(state1)
  self.alFlag:SetActive(state2)
end

--设置战斗力值
function My:SetFight(ft)
  self.ftLbl.text = ft
end

--pos1:字体显示位置
--pos2:战斗图标显示位置
function My:SetFitPos( pos1,pos2 )
  self.ftLbl.transform.localPosition = pos1
  self.ftBg.transform.localPosition = pos2
end

--设置名称
function My:SetName(name)
  self.nameLbl.text = name
end

function My:SetPro(val)
  local bval = math.floor(100 * val)
  --self.proLbl.text = tostring(bval) .. "%"
  self.proSp.fillAmount = val
  self.proSpFx.FillRate = val
end

 
--切换条目信息
function My:Switch(cur)
  if cur == nil then return end
  if cur == self.upg then self.isCanShowPanel = false else self.isCanShowPanel = true end
  if cur == self.cur then return end
  self.cur:Close()
  cur:Open()
  cur:Refresh()
  self.cur = cur
end


function My:Update()
  self.mwSkin:Update()
end

--设置数据
function My:SetDB(db)
  self.db = db
  UIMisc.SetDB(self, db)
  self:UpTranBtn()
end

function My:Open()
  self.SecondId = self.cntr.SecondId
  self.QPropId = self.cntr.QPropId
  local secId = self.SecondId
  self.go:SetActive(true)
  self:SetLsnr("Add")
  self:Reset()
  self.upg:Open()
  if secId >= 1 then
    self.upg:OpenSkin()
  end
  self.cntr.SecondId = 0
  self.cntr.QPropId = 0
  self.SecondId = 0
  self.QPropId = 0
end

function My:Close()
  self.go:SetActive(false)
  self:SetLsnr("Remove")
  self.cur:Close()
end

function My:RespUpg(err, lvChg)
  self.upg:RespUpg(err, lvChg)
end

function My:RespSoul()
  self.upg:RespSoul()
end

-- --进阶/升星
-- function My:AdvStep()
--   self.skin:AdvStep()
-- end

-- --响应精炼
-- function My:RespRefine(id, unlock)
--   self.skin:RespRefine(id, unlock)
-- end

--响应幻化
function My:RespChange(err)
  self.skin:RespChange(err)
  self:UpTranBtn()
end

function My:UpPageState(state)
  self.page:SetActive(state)
end

function My:SetLsnr(fn)
  local db = self.db
  -- db.eStep[fn](db.eStep, self.AdvStep, self)
  db.eRespUpg[fn](db.eRespUpg, self.RespUpg, self)
  db.eRespSoul[fn](db.eRespSoul, self.RespSoul, self)
  -- db.eRespRefine[fn](db.eRespRefine, self.RespRefine, self)
  db.eRespChange[fn](db.eRespChange, self.RespChange, self)
end


function My:Reset()
  local db = self.db
  if db.sysID == 2 then
    -- self.mwSkin:Reset()
  else
    self.skin:Reset()
  end
end

function My:Dispose()
  self.skill = nil
  -- AssetTool.Unload(self.modRoot)
  UIMisc.SetDB(self, nil)
  UIMisc.ClearSub(self)
  self.upg:Dispose()
  self.skin:Dispose()
  self.mwSkin:Dispose()
  TableTool.ClearUserData(self)
end
