IdentifyMgr = Super:New{Name = "IdentifyMgr"}

local M = IdentifyMgr

M.eUpdateIdentify = Event()

function M:Init()
  self.PassIndex = 0 --1： 未通过   2 通过
  self:Reset()
  self:SetLsnr(ProtoLsnr.Add)
  self:AddEvent()
end

function M:Reset()
  -- iTrace.Error("GS","000 Reset==")
  self.IsAuth = false -- 是否实名认证
  self.TouristIndex = 1 --1：能进行游客模式选择    2：正在进行游客模式直接要认证   3：游客模式结束直接要认证"
  self.CostMin = 0  --分钟
  self.AddState = 0  --"0:表示无要求 1:宽松版 2:严格版本"
  self.IsTourist = false  --"0:表示无要求 1:宽松版 2:严格版本"
  self.IsShowMain = false  --是否显示主界面认证按钮
  self.IsShowIndu = false  --是否显示防沉迷弹窗

  self.antiAddInfo = nil
end

function M:SetLsnr(func)
  func(22480, self.RespRoleAddictInfo, self)
  func(22482, self.RespRoleAddictRemain, self)
  func(22488, self.RespRoleAddictAuth, self)
  func(22490, self.RespNoticeBox, self)
end

function M:AddEvent()
  local Add = EventMgr.Add
  local EH = EventHandler
  -- Add("LogoutSuc", EH(self.LogoutSuccess, self))
  Add("RoleLogin", EH(self.RoleLogin, self))
  if Sdk then
    if App.platform == Platform.Android then
      Sdk.eAntiAddtictSuc:Add(self.AntiAddtictSuc, self)
      Sdk.eAntiAddtictFail:Add(self.AntiAddtictFail, self)
    end
  end
end

function M:RoleLogin()
  if Sdk then
    local isSupportAnti = Sdk:SupportAntiAddict() --判断是否支持防沉迷
    if not isSupportAnti then
      iTrace.eError("GS","不支持防沉迷    不能设置游戏计时")
      return
    end
    Sdk:SetAntiAddictBeg()
  end
end

--防成谜成功
function M:AntiAddtictSuc(info)
  self.antiAddInfo = info
  -- number 
  -- 0  未定义，不需要处理
  -- 1  弹提示
  -- 2  强制下线
  -- 3  打开网页窗口
  local type = info.type 
  -- string  弹窗标题   type=1 或 type=2 时有效
  local title = info.title
  -- string  弹窗内容   type=1 或 type=2 时有效
  local content = info.content
  -- string  打开网址   type=3 时有效
  local url = info.url
  --number 
  --0:表示允许关闭弹窗
  --1:表示关闭弹窗需要退出登录,调用accountSwitch接口
  local modal = info.modal
  -- string  命中防沉迷规则名称
  -- 值： xg_holiday_tip          说明： 节假日2小时提醒
  -- 值： xg_holiday_noplay       说明： 节假日3小时禁玩
  -- 值： xg_work_tip             说明： 工作日1小时提醒
  -- 值： xg_work_noplay          说明： 工作日1.5小时禁玩
  -- 值： xg_alltime_noplaytime   说明： 所有时间宵禁
  local ruleFamily = info.ruleFamily
  -- iTrace.Error("GS 防沉迷返回： ","type:",type," title:",title," content:",content," url:",url," modal:",modal," ruleFamily:",ruleFamily)
  if type == 0 then return end
  if type == 1 or type == 2 then
    MsgBox.ShowYes(content,self.YesCb,self)
  elseif type == 3 then
    UApp.OpenURL(url)
  end
end

function M:YesCb()
  local info = self.antiAddInfo
  local modal = info.modal
  local ruleFamily = info.ruleFamily
  -- iTrace.Error("GS","防沉迷 ClickYesBtn   modal:",modal,"   ruleFamily:",ruleFamily)
  if ruleFamily == "xg_holiday_tip" or ruleFamily == "xg_work_tip" then
    local ui = UIMgr.Dic[MsgBox.Name]
      if ui then 
        ui:Close()
      end
  elseif ruleFamily == "xg_holiday_noplay" or ruleFamily == "xg_work_noplay" or ruleFamily == "xg_alltime_noplaytime" then
      AccMgr:Logout(true, true)
  end
  -- if modal == 0 then
  --   local ui = UIMgr.Dic[MsgBox.Name]
  --   if ui then 
  --     ui:Close()
  --   end
  -- elseif modal == 1 then
  --   -- Sdk:SwitchAccount()
  --   AccMgr:Logout(true, true)
  -- end
end

--防沉迷失败   sdk未实名，唤起登陆界面
function M:AntiAddtictFail()
  -- Sdk:SwitchAccount()
  AccMgr:Logout(true, true)
end

function M:GetRealName(info)
  --1
  --[[表示渠道SDK有实名制且能够获取实名制结果，研发只需要通过data获取验证结果，
      然后实现防沉迷功能（注意！因为登录验证后拿到的实名认证信息可能是不准确的，
      所以当渠道“age”为0或为空的时候，独代默认返回“age”为18）
  --]]

  --2
  --[[表示渠道SDK有实名制但不能获取实名制结果，研发跟君海运营确认处理方案
  --]]

  --3
  --[[表示渠道SDK没有实名制功能，研发需要自行实现实名制功能，并实现防沉迷功能 
  --]]

  --4
  --[[表示渠道有实名制功能，且实现了防沉迷功能，研发收到该回调后应关闭游戏内实名认证与防沉迷功能
  --]]
  -- iTrace.Error("GS","Init  GetRealName self.PassIndex ==",self.PassIndex)
  if self.PassIndex > 0 then
    return
  end

  local sdk = Sdk
  if sdk and sdk.SupportRealName then
    local isSRealName = sdk:SupportRealName() --SupportRealName  判断是否支持实名制
    if isSRealName then
      local dingTuoAge = info.age  --  age:年龄
      local dingTuoRNameIndex = info.isRealName --isRealName：1已实名,0未实名
      local isMain = false
      if dingTuoAge <= 17 then
        isPass = 1
        isMain = true
      elseif dingTuoAge >= 18 then
        isPass = 2
        isMain = false
      end
      self.PassIndex = isPass
      self.IsShowMain = isMain
      self.IsShowIndu = false
    else
      self.IsShowMain = true
      self.IsShowIndu = true
      self.PassIndex = 0
    end
  end


  local state = info.state
  local data = info.data
  local age = data.age --"17", 玩家年龄
  
  --"false", 玩家是否成年，true表示成年，false表示未成年。如果获取不到数据就为空串。注意是字符串类型。
  local isAdult = data.is_adult 

  --"false", 玩家是否实名制，true表示完成了实名制，false表示没有完成实名制。如果获取不到数据就为空串。注意是字符串类型。
  local isIdentify = data.real_name_authentication 

  local mobile = data.mobile --"", 玩家手机号码。如果获取不到数据就为空串
  local realName = data.real_name --"", 玩家真实姓名。如果获取不到数据就为空串。
  local idCard = data.id_card --"" 玩家身份证号码。如果获取不到数据就为空串。

  local isPass = 0 --是否成年
  local strIsNull = StrTool.IsNullOrEmpty
  -- iTrace.Error("GS","state==",state,"   age===",age,"  isAdult==",isAdult,"  isIdentify==",isIdentify," realName==",realName,"  idCard==",idCard)
  if state == 1 then
    local isMain = false
    if age then
      age = tonumber(age)
      if age <= 17 then
        isPass = 1
        isMain = true
      elseif age >= 18 then
        isPass = 2
        isMain = false
      end
      self.PassIndex = isPass
    end
    self.IsShowMain = isMain
    self.IsShowIndu = false
    -- iTrace.Error("GS","111 state==",state,"   age===",age,"  self.PassIndex==",self.PassIndex)
  elseif state == 2 then
    self.IsShowMain = true
    self.IsShowIndu = true
    self.PassIndex = 0
  elseif state == 3 then
    self.IsShowMain = true
    self.IsShowIndu = true
    self.PassIndex = 0
  elseif state == 4 then
    self.IsShowMain = false
    self.IsShowIndu = false
    self.PassIndex = 2
  end
  -- iTrace.Error("GS","222 state==",state,"   age===",age,"  self.PassIndex==",self.PassIndex)
end

--==============================--


function M:RespRoleAddictInfo(msg)
  local isAuth = false
  local isPassed = false
  local costMin = 0
  local addState = msg.addict_state --"0:表示无要求 1:宽松版 2:严格版本"
  isAuth = msg.is_auth --是否进行过实名验证
  local touristIndex = msg.is_tourist -- " 1：能进行游客模式选择    2：直接要认证   3：游客模式结束直接要认证"
  isPassed = msg.is_passed --年龄是否达标
  costMin = msg.min
  self.AddState = addState
  if addState == 0 then
    self.IsAuth = true
  elseif addState == 2 then
    local isTourist = false
    if isAuth == true then
      isTourist = false
    elseif isAuth == false or isPassed == false then
      isTourist = true
    end
    if self.IsShowIndu then
      if isTourist == true then
        self.TouristIndex = touristIndex
        self.CostMin = costMin
        UIMgr.Open(UIIdentification.Name)
      end
    end

    self.IsTourist = isTourist
    self.IsAuth = isAuth
  else
    if isAuth then --进行过实名验证
      self.IsAuth = true
    else
      if Sdk then
        local info = Sdk.realNameInfo
        if not info or info.state == 3 then
          self.IsAuth = false
          SystemMgr:ShowActivity(ActivityMgr.SMRZ)
        else
          self.IsAuth = true
        end
      else
        self.IsAuth = false
        SystemMgr:ShowActivity(ActivityMgr.SMRZ)
      end
    end
  end
  -- iTrace.Error("GS","resp  addState=",addState,"  isAuth==",isAuth,"  touristIndex==",touristIndex,"  isPassed=",isPassed,"  IsShowMain=",self.IsShowMain,"  IsShowIndu=",self.IsShowIndu)
  self.eUpdateIdentify(self.IsShowMain)
end

function M:RespRoleAddictRemain(msg)
  if StrTool.IsNullOrEmpty(msg.benefit) then
    MsgBox.ShowYes(string.format("您的累计在线时长已达%d分钟，请合理安排游戏时间！", msg.online_time))
  else
    MsgBox.ShowYes(string.format("您的累计在线时长已达%d分钟，请合理安排游戏时间！(当前收益为%s%%)", msg.online_time, msg.benefit))
  end
end

function M:RespRoleAddictAuth(msg)
  if msg.err_code == 0 then
    self.IsAuth = true
    self.eUpdateIdentify(false)
    UIMgr.Close(UIIdentification.Name)
  else
    local err = ErrorCodeMgr.GetError(msg.err_code)
    UITip.Log(err)
  end
end

function M:RespNoticeBox(msg)
  local notice = msg.notice
  local type = msg.type
  if type == 1 then
    MsgBox.ShowYes(notice,self.ReturnMain,self)
    EventMgr.Trigger("AntiIndulge",1)
  else
    MsgBox.ShowYes(notice)
    EventMgr.Trigger("AntiIndulge",0)
  end
end

function M:ReturnMain()
  AccMgr:Logout(true, true)
end

function M:ReqRoleAddictAuth(id_card, real_name)
  local msg = ProtoPool.GetByID(22487)
  msg.id_card = id_card --身份证信息
  msg.real_name = real_name --姓名
  ProtoMgr.Send(msg)
end

--是否成年
function M:ReqRoleAddictNotice()
  local psIndex = self.PassIndex
  -- iTrace.Error("GS","psIndex=",psIndex)
  local isPass = false
  if psIndex == 0 then
    return
  end
  if psIndex == 1 then
    isPass = false
  elseif psIndex == 2 then
    isPass = true
  end
  -- iTrace.Error("GS","send  是否成年=",isPass)
  local msg = ProtoPool.GetByID(22489)
  msg.is_passed = isPass
  ProtoMgr.Send(msg)
end

-- function M:ReqChoseTourist(is_choose)
--   local msg = ProtoPool.GetByID(22491)
--   msg.is_choose = is_choose 
--   ProtoMgr.Send(msg)
-- end

function M:Clear()
  self:Reset()
end

function M:LogoutSuccess()
  -- iTrace.Error("GS","LogoutSuccess==")
  self.PassIndex = 0
end

return M
