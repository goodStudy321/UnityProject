UIThroneApp = UIBase:New {Name = "UIThroneApp"}
local My = UIThroneApp
require("UI/UIThroneApp/UIThroneAppProp")
--属性模块
My.prop = UIThroneAppProp:New()
--技能模块
My.skill = require("UI/UIThroneApp/UIThAppSkill")
--技能提示
My.skiTip = require("UI/UIThroneApp/UIThSkilTip")
local pre = "UI/UIThroneApp/UIThroneApp"
--模型模块
My.model = require(pre .. "Mod") 
--精炼模块
My.refine = require(pre .. "Refine")


function My:InitCustom()
    local root = self.root
    local des = self.Name
    local CG = ComTool.Get
    local TF = TransTool.Find
    local TFC = TransTool.FindChild
    local S = UITool.SetLsnrSelf

    self:SetDB(ThroneAppMgr)
    self.modCam = CG(Camera, root, "modCam", des)
    self.modBox = CG(BoxCollider, root, "rotate", des)
    self.modRoot = TF(root, "modRoot", des)
    self.actSp = TF(root,"actSp",des)
    self.nameLab = CG(UILabel,root,"throne/name",des)
    self.lvLab = CG(UILabel,root,"throne/lv",des)
    self.ftLab = CG(UILabel,root,"throne/ft",des)
    self.tranLbl = CG(UILabel,root,"throne/skin/tranBtn/lbl",des)
    self.equipBtn = TFC(root,"throne/skin/tranBtn",des)
    self.changBox = CG(BoxCollider, root, "throne/skin/tranBtn", des)
    self.showBox = CG(BoxCollider, root, "throne/skin/showBtn", des)
    self.alFlag = TFC(root,"throne/skin/alFlag",des)
    self.showBtn = TFC(root,"throne/skin/showBtn",des)
    self.showLab = CG(UILabel, root, "throne/skin/showBtn/lbl", des)
    self.isShowTog = CG(UIToggle, root,"throne/skin/isShowTog", des)
    self.model.modRoot = self.modRoot
    self.proSp = CG(UISprite, root, "throne/upgBg/s2", des)
    self.proSpFx = CG(guiraffe.SubstanceOrb.OrbAnimator, root, "throne/upgBg/s2/FX_SubstancePlane", des)

    self.loadLabR = TFC(root, "loadLab", des)
    self.loadLabR:SetActive(false)
    self.loadLabBox = CG(BoxCollider, root, "loadLab", des)
    UITool.SetLsnrSelf(self.loadLabBox, self.OnLoadClick, self)

    local SetSub = UIMisc.SetSub
    SetSub(self, self.skill, "skill")
    SetSub(self, self.skiTip, "skiTip")
    SetSub(self,self.model,"throne/skin/mods")
    SetSub(self,self.refine,"throne/skin/refine")
    self.prop.root = TF(root, "props", des)
    self.prop:Init()
    self:SetLsnr("Add")
    self.getSkillList = {}

    S(self.equipBtn,self.OnEquip,self)
    S(self.showBtn,self.OnShow,self)
    UITool.SetBtnClick(root, "closeBtn", name, self.CloseClick, self)

    local ED = EventDelegate
    local EC = ED.Callback
    local ES = ED.Set
    ES(self.isShowTog.onChange,EC(self.OnIsShow,self))
    self:RespStatus()
    self.isShowComb = false
end


function My:SetLsnr(fn)
    local db = self.db
    db.eRespActive[fn](db.eRespActive, self.RespRefine, self)
    db.eRespRefine[fn](db.eRespRefine, self.RespRefine, self)
    db.eRespChange[fn](db.eRespChange, self.RespChange, self)
    db.eRespStatus[fn](db.eRespStatus, self.RespStatus, self)
    db.eRespRed[fn](db.eRespRed, self.RespRed, self)
end

function My:OnLoadClick()
    self:Close()
    UIMgr.Open("UIDownload")
end

function My:OnIsShow()
    local isShow = self.isShowTog.value
    local index = isShow == false and 1 or 0
    self.db:ReqStatus(index)
end

--列表红点状态
function My:RespRed()
    local list = self.db.SkinRedTab
    self.model:SetReds(list)
    local isShowRed = self.db.isTransRed
    self.refine:SetBtnRed(isShowRed)
end

--响应激活
function My:RespActive(id,unlock)
    
end

--响应升级
function My:RespRefine(id,unlock)
    self:ResetProps()
    self:SetFightVal()
    self.refine:RespRefine(id, unlock)
    self.model:RespRefine(id, unlock)
    self:RefreshSkill()
    local info = self.db.info
    self:SetLockState(info.lock)
    if(unlock == true) then
        -- local id = AssetTool.GetSexModID(self.db.info.bCfg)
        -- UIShowGetCPM.OpenCPM(id)
    end
end

--响应幻化
function My:RespChange(err)
    self:SetTranLbl()
end

--响应设置状态
function My:RespStatus()
    local index = self.db.status
    local status = false
    if index == 1 then
        status = false
    else
        status = true
    end
    self.isShowTog.value = status
end

--设置幻化标签
function My:SetTranLbl()
    local isShow = self:IsChange()
    local str = ((isShow == true) and "已装备" or "幻化")
    self:IsShowAlFlag(isShow)
    self.tranLbl.text = str
end

function My:IsShowAlFlag(isShow)
    self.equipBtn.gameObject:SetActive(not isShow)
    self.alFlag.gameObject:SetActive(isShow)
end

function My:IsChange()
    local db = self.db
    local id = db.info.bCfg.id * 100 + 1
    if db.chgID == id then 
        UITip.Log("已幻化")
        return true 
    end
    return false
end

--设置解锁图片状态
function My:SetLockState(lock)
    self.actSp.gameObject:SetActive(lock)
end

--幻化按钮
function My:OnEquip()
    local info = self.db.info
    if info.lock then
      UITip.Error("未解锁")
    elseif self:IsChange() == true then
      return
    else
      self.db:ReqChange(self.curid)
    end
end

--预览按钮
function My:OnShow()
    local isShow = self.isShowComb
    local str = ""
    if isShow == false then
      self:TransCam(2)
      self:CanRotate(false)
      self.model:CombMod()
      isShow = true
      str = "还原"
    else
      self:TransCam(1)
      self:CanRotate(true)
      self.model:SingleMod()
      isShow = false
      str = "预览"
    end
    self.isShowComb = isShow
    self.showLab.text = str
end

function My:ResetMod(flag)
    self.isShowComb = flag
    self:OnShow()
end

--关闭
function My:CloseClick(go)
    self:Close()
    JumpMgr.eOpenJump()
end

function My:SetDB(db)
    self.db = db
    UIMisc.SetDB(self, db)
end

function My.Show()
    UIMgr.Open(UIThroneApp.Name)
end

function My:Switch(info)
    local db = self.db
    info = info or db.info
    db.info = info
    local bCfg = info.bCfg
    local sCfg = info.sCfg
    self.curid = bCfg.id * 100 + 1
    self:SetName(bCfg.name)
    self:SetStep(sCfg.step)
    self:SetLockState(info.lock)
    self:SetFightVal()
    self:SetTranLbl()
    self:ResetProps()
    self.refine:Refresh()
    self:RefreshSkill()
end

function My:SetName(name)
    self.nameLab.text = name
end

function My:SetStep(step)
    local str = UIMisc.ToNum(step)
    self.lvLab.text = string.format("%s 阶",str)
end

function My:SetFightVal()
    self.ftLab.text = self.db:GetFight()
end

function My:SetPro(val)
    self.proSp.fillAmount = val
    self.proSpFx.FillRate = val
end

function My:ResetProps()
    local prop = self.prop
    prop.srcObj = self
    prop.GetCfg = self.GetPropCfg
    prop:SetNames(self.db.skinPropNames)
    prop:Refresh()
end

function My:GetPropCfg()
    local info,cCfg,nCfg = self.db.info,nil,nil
    if info.lock then
        nCfg = info.sCfg
    else
        cCfg = info.sCfg
        nCfg = info:GetNextCfg()
    end
    return cCfg,nCfg
end

function My:RefreshSkill()
    local skillsList = self.db.info.sCfgSkill.hSkillIds
    local sCfg = self.db.info.sCfg
    if sCfg.hSkillIds then
        self.getSkillList = self:ReHaveSkill(sCfg.hSkillIds)
    end
    self.skill:Refresh(skillsList,self.GetLvSkiLock,self)
    self.skill:Open()
end

--判断技能是否解锁
--true :未解锁  false:解锁
function My:GetLvSkiLock(skillId)
    local lock = self.db.info.lock
    if lock then
        return true
    end
    if self.getSkillList[skillId] == nil then
        return true
    else
        return false
    end
    return true
end

--已经拥有的技能
function My:ReHaveSkill(skillList)
    local temp = {}
    for i = 1,#skillList do
        local skillId = skillList[i]
        if temp[skillId] == nil then
            temp[skillId] = skillId
        end
    end
    return temp
end

--设置幻化标签
function My:SetTranLbl()
    local isShow = self:IsChange()
    local str = ((isShow == true) and "已装备" or "幻化")
    self:IsShowAlFlag(isShow)
    self.tranLbl.text = str
end

function My:IsShowAlFlag(isShow)
    self.equipBtn:SetActive(not isShow)
    self.alFlag:SetActive(isShow)
end

function My:OpenCustom()
    self.model:Reset()
    self:RespRed()
end

function My:Refresh()
    self.model:Refresh()
end

--index：1 ---> 默认状态
--index：2 ---> 预览状态
function My:TransCam(index)
    local pos = nil
    local rotate = nil
    if index == 1 then
        pos = Vector3.New(-294,697,328)
        rotate = Vector3.New(35,0,0)
    elseif index == 2 then
        pos = Vector3.New(-209,363,-718)
        rotate = Vector3.New(0,0,0)
    end
    self.modCam.transform.localPosition = pos
    self.modCam.transform.localEulerAngles = rotate
end

function My:CanRotate(state)
    self.modBox.enabled = state
end

function My:IsShowAssTip(isShowTip)
    self:Lock(false)
    local box = self.changBox
    local showBox = self.showBox
    box.enabled = not isShowTip
    showBox.enabled = not isShowTip
    self.loadLabR:SetActive(isShowTip)
end

function My:CloseCustom()

end

function My:DisposeCustom()
    self.isShowComb = false
    self:SetLsnr("Remove")
    UIMisc.SetDB(self, nil)
    UIMisc.ClearSub(self)
    self.prop:Dispose()
    self.skill:Dispose()
    self.skiTip:Dispose()
    self.model:Dispose()
    self.refine:Dispose()
    TableTool.ClearDic(self.getSkillList)
    AssetTool.Unload(self.modRoot.transform)
end

return My
