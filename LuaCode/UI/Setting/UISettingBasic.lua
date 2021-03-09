UISettingBasic = UISetParent:New{Name = "UISettingBasic"}
local My = UISettingBasic
local Prv = {}
My.curIdex=0
My.toIdex=0
--统一设置场景的name为场景key=id.."set"
function My:Init(root)
  --工具字段
  local des = self.Name
  local USBC = UITool.SetBtnClick
  local CG = ComTool.Get
  local TF = TransTool.Find
  local ED = EventDelegate
  local EC, ES = ED.Callback, ED.Set
  local UO = UIProgressBar.OnDragFinished
  local UT = UIToggle
  local setRoot = root
  self.sceneId=tostring(User.instance.SceneId)
  local id = self.sceneId
  if id==nil or SceneTemp[id]==nil or SceneTemp[id].maxNum==nil then
    iTrace.Error("soon","同屏人数没有设置 id="..id)
    return
  end
    self.MaxNum=SceneTemp[self.sceneId].maxNum
  --滑条
  local US = UISlider
  local slRoot = TF(setRoot,"slider",des)
  self.music = CG(US, slRoot, "music", des)
  self.audio = CG(US, slRoot, "audio", des)
  self.blockOther=CG(US,slRoot,"blockOther",des)
  self.OtherNum=CG(UILabel,slRoot,"blockOther/thump/lbl",des)
  self.SndLst={self.music,self.audio}
   --UIToggle的集合一个list一个Name查询的字典
  local bkRoot = TF(setRoot,"blockSt",des)
  self.UtList,self.NVDic = self:AddAllUt(bkRoot)
  local UC = UITool.SetLsnrClick;
  local ssname = SettingMgr.SQName
  for i=1,#ssname do
    UC(bkRoot,ssname[i] , des, self.Oncilk, self); 
  end
  --展示读取状态
  self:ShowInfo(self.UtList)
  Prv.ShowSd( self.music )
  Prv.ShowSd( self.audio )
  Prv.ShowOther( )
  --画质集合
  self.QList = Prv.setQlist()
  Prv.SetBegQt()  
  --监听事件
  USBC(root, "yesBtn", des, self.OnSave, self)
  USBC(root, "chgAccBtn", des, self.OnChgAccount, self)
  USBC(root, "backFirst", des, self.OnBackFirst, self)
  ES(self.music.onChange, EC(self.MusicCtrl, self))
  ES(self.audio.onChange, EC(self.AudioCtrl, self))
  ES(self.blockOther.onChange, EC(self.OtherCtrl, self))
end

function My:OnBackFirst( go )
  -- Mgr.ReqPreEnter(10101, tostring(0), false)
  info = CopyTemp[tostring( self.sceneId)];
  if info~=nil then
    if info.type==0 then
      UISetting:Close()
      UITip.Log("当前场景无法退出")
      return
    end
  end
  -- Hangup:ClearAutoInfo()
  UISetting:Close()
  SceneMgr:QuitScene();
  -- SceneMgr:ReqPreEnter(10101,false,true);
end

function My:Oncilk( go )
  if My.MaxNum==0 then
    return
  end
  local best,max =  QualityTool:GetSetUseQuality()
  local goname = tostring(go.name)
  self.GoName=goname
  local ssname = SettingMgr.SQName
  for i=1,#ssname do
    if ssname[i]==goname then
      My.toIdex=i
      if i>best then
        local desc = "选择当前设置可能会造成游戏体验不流畅"
        MsgBox.ShowYesNo(desc, self.YesChos,self, "确定", self.NoChos,self, "取消")
        return
      end
    end
  end
  self:ChangePeople(  )
end

function My:YesChos(  )
  self:ChangePeople(  )
end
function My:NoChos(  )
  My.QList[My.toIdex].value=false
  My.QList[My.curIdex].value=true
end

function My:ChangePeople(  )
  My.curIdex=My.toIdex
  local ssname = SettingMgr.SQName
  local sqPeople = SettingMgr.QuickPeople

       local num = sqPeople[ My.curIdex]
         num=num>My.MaxNum and My.MaxNum or num
         local  value = math.ceil(num*20/My.MaxNum)
         My.blockOther.value=value/20  
end

--展示场景人数
function Prv.ShowOther( )
  local num = My.SM.GetValueFast(My.sceneId.."set")  
  if num=="无此数据"  then
    num =SettingMgr.NilChooseNum( )
  end
  if My.MaxNum==0 then
    My.blockOther.value=0
  else
    local  value = math.ceil(num*20/My.MaxNum)
    My.blockOther.value=value/20
  end
end
--展示音效果
function Prv.ShowSd( obj )
 local num = My.SM.GetValueFast(obj.name)
 if num=="无此数据" then
  num = 1
end
  obj.value = num
end
function Prv.setQlist( )
  local qlst = {}
  local name = My.SM.SQName
  for i=1,#name do
    qlst[i]=My.NVDic[name[i]]
  end
  return qlst
end

--设置画质选项
function Prv.SetBegQt()   
  local best,max =  QualityTool:GetSetUseQuality()
  if max>4 then
    max=4
  end
  local b=true
  for i=1 ,#My.QList do
    if My.QList[i].value then
      b=false
      My.curIdex=i
    end
    if i>max then
      UITool.SetGray(My.QList[i].gameObject)
    end
  end
  if b then
    My.curIdex=best
    My.QList[best].value=true
  end
end
--音乐控制
function My:MusicCtrl()
  -- if UISetting.isFirst then  return end  
   local FN = self.music.value
   self.SM.MusicCtrl(FN)
  end
  --音效控制
  function My:AudioCtrl()
    -- if UISetting.isFirst then  return end    
    local FN = self.audio.value
    self.SM.AudioCtrl(FN)
end
--人数控制
function My:OtherCtrl()
  local num = math.floor(self.blockOther.value*self.MaxNum)
  self.OtherNum.text=num
  return num
end
  --切换账号
  function My:OnChgAccount()
    AccMgr:Logout(true, true)
  end

  return My
