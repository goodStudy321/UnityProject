--=========================================================================
--  刘路 
--=========================================================================

UISetting = UIBase:New{Name = "UISetting"}

local My = UISetting
local prv = {}
require("UI/Setting/UISetParent")
My.basic = require("UI/Setting/UISettingBasic")
My.hangup = require("UI/Setting/UISettingHangup")
My.push = require("UI/Setting/UISettingPush")
--My.actCode = require("UI/UIActiveCode/UIActiveCode")


require("UI/UIFeedback/UIFeedback")

local SM = SettingMgr
-- My.isFirst =not HasKey("jgxSet")

--UIToggle列表
My.togs = {}

function My:InitCustom()

  FeedbackMgr:SendId()

  local TF = TransTool.Find
  local T = TransTool.FindChild
  local S =  UITool.SetLsnrSelf
  local C = ComTool.Get

  local root, des = self.root, self.Name
  local bg = TF(root, "bg", des)
  local basicTran = TF(bg, "basic", des)
  self.tog=TF(bg,"tog",des)
  self.basic:Init(basicTran)
  local hangupTran = TF(bg, "hangup", des)
  self.hangup:Init(hangupTran)

  local pushTran = TF(bg, "push", des)
  self.push:Init(pushTran)
  --local actCodeTran = TF(bg, "activeCode", des)
  --self.actCode:Init(actCodeTran)

  local febackTran = TF(bg, "feedback/Feedback", des)
  self.feedback = ObjPool.Get(UIFeedback)
  self.feedback:Init(febackTran)


  UITool.SetBtnClick(bg, "close", des, self.CloseAndSave, self)
   -- 屏蔽意见反馈按钮
  self.feedBtn = TF(self.tog,"grid/feedback",des)

  local togs = self.togs
  local tog1 = C(UIToggle,root,"bg/tog/grid/base",tip,false)
  togs[1] = tog1
  S(tog1.transform,self.OnTog,self)

  local tog2 = C(UIToggle,root,"bg/tog/grid/hangup",tip,false)
  togs[2] = tog2
  S(tog2.transform,self.OnTog,self)

  local tog3 = C(UIToggle,root,"bg/tog/grid/push",tip)
  togs[3] = tog3
  --local tog2 = C(UIToggle,root,"bg/tog/grid/activecode",tip,false)
  local tog4 = C(UIToggle,root,"bg/tog/grid/feedback",tip,false)
  S(tog4.transform,self.OnTog,self)
  ShieldEntry.ShieldGbj( ShieldEnum.Feedback ,tog4.gameObject);


  self:SetLsnr("Add")

  self.isOpenFB = true
  self:SetFeedbackBtn()
end

-- 关闭意见反馈按钮
function My:SetFeedbackBtn()
  if FeedbackMgr.isOpen ~=  self.isOpenFB then
    self.feedBtn.gameObject:SetActive(false)
  else
    FeedbackMgr:SendStatus()
  end
end

function My:OnTog()
  --UIActiveCode:Clear()
end

function My:SetLsnr(key)
  FeedbackMgr.eClose[key](FeedbackMgr.eClose, self.SetFeedbackBtn, self)
end

--打开版面的方法int类型:1打开第一个以此类推
function My:ChooseOpen(index)
  if index==nil and type(index) ~="number" and index<1 and index>5 then
    index=1
  end
  for i,v in ipairs(self.togs) do
    local at = ((i == index) and true or false)
    v.value = at 
  end
end

function My:Save( )
  SDic={}
  prv.GetDic(My.basic.UtList,SDic)
  prv.GetDic(My.basic.SndLst,SDic)
  prv.GetDic(My.hangup.UtList,SDic)
  SDic[My.basic.sceneId.."set"]=My.basic:OtherCtrl()
  SM.SaveValue(SDic)
  return SDic
end

function prv.GetDic(list,SDic)
  for i=1 ,#list do
    SDic[list[i].name]=list[i].value
  end
end

function My:CloseAndSave( )
  -- CrossMgr:OpenCross11()
  self:Save()
  UITip.Log("保存设置成功")
  self:Close()
end

function My:DisposeCustom()
  self:SetLsnr("Remove")
  ObjPool.Add(self.feedback)
  ListTool.Clear(self.togs)
  self.push:Dispose()
  self.feedback = nil
  self.isOpenFB = true
  --UIActiveCode:Dispose()
end

return My
