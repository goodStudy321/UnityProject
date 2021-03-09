
UISettingHangup = UISetParent:New{Name = "UISettingHangup"}
local My = UISettingHangup
local Prv = {}
function My:Init(root)
  --工具字段
  local des = self.Name
  local CG = ComTool.Get
  local TF = TransTool.Find
  self.timetxt = CG(UILabel,root,"offline/tmbg/tm",des)
  self.timetxt.text=OffRwdMgr.GetHaveOffLineTime()
  local USBC  = UITool.SetBtnClick
  --UIToggle的集合一个list一个Name查询的字典
  local utRoot=TF(root,"ut",des)  
  self.UtList,self.NVDic = self:AddAllUt(utRoot)
  --监听
  USBC(root, "offline/add", des, self.addTime, self)
  USBC(root, "yesBtn", des, self.OnSave, self)
  self.maxTime=CG(UILabel,root,"offline/max",des)
  self.maxTime.text=string.format("(最多可存储%s个小时)", self:GetMaxTime());
  self:AddLsnr()
  self:ShowInfo(self.UtList)
  if  self.NVDic[self.SM.SPName[1]].value==false  then 
    if  self.NVDic[self.SM.SPName[2]].value==false  then 
      self.NVDic[self.SM.SPName[1]].value=true 
    end
  end
  
end
--监听文本需要改变时候
function My:AddLsnr()
  PropMgr.eUse:Add(self.setText, self)
end
function My:RemoveLsnr()
  PropMgr.eUse:Remove(self.setText, self)
end
function My:setText( )
  self.timetxt.text=OffRwdMgr.GetHaveOffLineTime()
end
function My:addTime( )
  OffRwdMgr.Addtime() 
end
--获取最大离线时间
function My:GetMaxTime()
  local cfg = GlobalTemp["87"]
  if cfg == nil then return 0 end
  return cfg.Value3
end
--释放资源
function My:DisposeCustom()
  self:RemoveLsnr()
end

return My

