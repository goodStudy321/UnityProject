UIThroneStep = Super:New{Name = "UIThroneStep"}
local My = UIThroneStep
local ThMgr = ThroneMgr

function My:Init(root)
  self.root = root
  self.gbj = root.gameObject
  local des, CG = self.Name, ComTool.Get
  local TF, TFC = TransTool.Find, TransTool.FindChild
  --进阶按钮
  self.advBtn = CG(UISprite, root, "advBtn", des)
  local advLab = CG(UILabel, root, "advBtn/lbl", des)
  advLab.text = "一键升级"
  --一键进阶标签
  self.aKeyLbl = CG(UILabel, root, "aKeyBtn/lbl", des)
  --当前拥有精华
  self.num = CG(UILabel,root,"num",des)
  local iconSp = CG(UISprite,root,"icon",des)
  iconSp.spriteName = "cell_3"
  self.icon = CG(UITexture,root,"icon/Icon",des)
  self.numLab = CG(UILabel,root,"icon/Lab",des)
  self.iconBox = CG(BoxCollider,root,"icon",des)

  self.btnRed = TFC(root,"advBtn/red",des)
  self.composeRed = TFC(root,"aKeyBtn/red",des)

  local USS = UITool.SetLsnrSelf
  local USC = UITool.SetLsnrClick
  USS(self.advBtn.gameObject, self.AdvClick, self, des)
  UIEvent.Get(self.advBtn.gameObject).onPress= UIEventListener.BoolDelegate(self.OnPressCell, self)
  USC(root,"aKeyBtn", des, self.AKeyClick, self,false)
  USS(self.iconBox.gameObject,self.ClickProp,self,des)

  --true 一键升阶中
  My.aKeying = false
  --一键进阶按钮计时器
  My.aKeyCnt = 0
  self:UpIcon()
end

function My:ClickProp()
  UIMgr.Open(PropTip.Name,self.OpenCb,self)
end

function My:OpenCb(name)
  local ui = UIMgr.Get(name)
  if(ui)then 
    ui:UpData(ItemData["20"].id)
  end
end

--icon
function My:UpIcon()
	self.iconName = ItemData["20"].icon
	AssetMgr:Load(self.iconName,ObjHandler(self.LoadIcon,self))
end

function My:LoadIcon(obj)
	self.icon.mainTexture = obj
end

function My:UnloadTex()
	if self.iconName then 
		AssetMgr:Unload(self.iconName,".png",false)
	end
	self.iconName=nil
end

function My:OnPressCell(go, isPress)
	if not go then
		return
	end
  if isPress== true then
		self.IsAutoClick = Time.realtimeSinceStartup
  else
		self.IsAutoClick = nil
	end
end

--更新
function My:Update()
  if self.IsAutoClick then
    if Time.realtimeSinceStartup - self.IsAutoClick > 0.05 then
			self.IsAutoClick = Time.realtimeSinceStartup
			self:AdvClick()
		end
	end
end

--点击进阶事件
function My:AdvClick(go)
  local need = ThMgr.curCfg.con
  local own = ThMgr.essence
  if self.isFull == true then
    UITip.Error("已满级")
    return
  end
  if own <= 0 then
    --UITip.Error("请获取精华！")
    self:JumpOpen()
    return
  end
  ThMgr.ReqStep()
end

function My:JumpOpen()
  local itID = ItemData["20"].id
  local isSkin = false
  local sysId = 6
  GetWayFunc.AdvGetWay(UIAdv.Name,sysId,itID,isSkin)
end

--点击分解事件
function My:AKeyClick(go)
    self.IsAutoClick = nil
    local compose = self.cntr.compose
    compose:Open()
end

--设置拥有精华
function My:SetEssence(essence)
  self.numLab.text = essence
end

--响应分解
--设置进度
function My:SetPro()
  local tExp = ThMgr.curCfg.con * 1.0
  local totalE = ThMgr.essence -- 当前拥有 精华
  local consumeE = ThMgr.accumEssence -- 当前消耗 精华
  self.isFull = false
  if tExp == 0 then
    self.isFull = true
    tExp = consumeE
  end
  self:SetEssence(totalE)
  self.rCntr.ThrStep:SetSlider(consumeE, tExp)
end

--响应解锁下阶模型
function My:UpStep()
  local bid = ThMgr.bid
  local cfg = BinTool.Find(ThroneCfg, bid)
  if cfg == nil then
    iTrace.eError("GS", "无ID为:", bid, "宝座基础配置")
  else
    -- UIShowGetCPM.OpenCPM(cfg.uMod)
  end
end

--设置激活状态
function My:SetActive(at)
  at = at or false
  if at == self.active then return end
  if at then
    self:Open()
  else
    self:Close()
  end
end

--升级按钮红点状态
function My:SetBtnFlag(red)
	self.btnRed:SetActive(red)
end

--分解按钮红点状态
function My:SetComposeFlag(red)
  self.composeRed:SetActive(red)
end

function My:Open()
  self.gbj:SetActive(true)
  self.rCntr.ThrStep:Open()
  self.active = true
  self:SetPro()
end

function My:Close()
  self.IsAutoClick = nil
  self.gbj:SetActive(false)
  self:SetEssence("")
  self.rCntr.ThrStep:Close()
  self.active = false
end

function My:Dispose()
  self:UnloadTex()
  self.IsAutoClick = nil
end

return My