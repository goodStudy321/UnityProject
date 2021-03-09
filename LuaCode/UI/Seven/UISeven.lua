--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-05-21 19:48:02
-- 七日登陆UI
--=========================================================================

require("UI.Cmn.UIItems")
local USI = require("UI.Seven.UISevenItem")

UISeven = Super:New{Name = "UISeven"}

local My = UISeven

local AssetMgr = Loong.Game.AssetMgr

--七日列表,元素:UISevenItem
My.items = {}

--奖励列表
-- My.awards = UIItems:New()

function My:Init(root)
  local des = self.Name
  local CG = ComTool.Get
  local Find = TransTool.Find
  local USBC = UITool.SetBtnClick
  local FindC = TransTool.FindChild

  self.cur = nil
  self.awards = {}
  self.modelList = {}
  self.isRotate = false
  self.go = root.gameObject

  self.lab = CG(UILabel, root, "labs/lab1", des)
  self.getLbl = CG(UILabel, root, "btn/lab", des)
  self.grid = CG(UIGrid, root, "itemBg/Grid", des)
  self.spr = CG(UISprite, root, "sprs/spr1")
  self.day = FindC(root, "topBg/Grid/item", des)
  self.item = FindC(root, "itemBg/Grid/itMod", des)
  self.btnEff = FindC(root, "btn/FX_UI_Button", des)
  self.modelTran = Find(root, "bossModel", des)

  USBC(root, "btn", des, self.OnClickGet, self)

  self:InitItems()
  self:InitDays()
  self:InitLab()
  self:SetItems(root)
  self:InitStae()
  self:SetLsnr("Add")
end

--初始化文本
function My:InitLab()
  self.lab.text = SevenMgr.curDay
end

--初始道具
function My:InitItems()
  local AddC = TransTool.AddChild
  for i=1, 5 do
    local go = Instantiate(self.item)
    local tran = go.transform
    AddC(self.grid.transform, tran)
    local it = UIItems:New()
    it:Init(tran)
    table.insert(self.awards, it)
  end
  self.item:SetActive(false)
end

--初始化天数
function My:InitDays()
  local AddC = TransTool.AddChild
  local parent = self.day.transform.parent
  for i=1, SevenMgr.count do
    local go = Instantiate(self.day)
    local tran = go.transform
    go.name = i
    AddC(parent, tran)
  end
  self.day:SetActive(false)
end

function My:SetItems(root)
  local TF, des = TransTool.Find, self.Name
  local dr = TF(root, "topBg/Grid", des)
  local items, c, it = self.items, nil, nil
  for i = 1, SevenMgr.count do
    c = TF(dr, tostring(i), des)
    it = ObjPool.Get(USI)
    it.cfg = SevenCfg[i]
    it:Init(c)
    it.cntr = self
    items[i] = it
  end
  local index = self:SelectState()
  self:Switch(items[index])
end

--更新贴图
function My:UpSpr(index)
  if index > 7 then return end
  local str = "title_"..index
  self.spr.spriteName = str
end

--it:UISevenItem
function My:Switch(it)
  if it == nil then return end
  if self.cur == it then return end
  it:MarkState(true)
  if self.cur then
    self.cur:MarkState(false)
  end
  self.cur = it
  local day = it.cfg.id
  self:UpModel(day)
  self:SetGetLbl(it)
  Audio:PlayByID(119)
  --显示物品
  for i,v in ipairs(self.awards) do
    local list = {}
    local go = v.root.gameObject
    list[1] = it.cfg.awards[i]
    if list[1] then
      go:SetActive(true)
      v:Refresh(list)
    else
      go:SetActive(false)
    end
  end

  self:UpSpr(day)
  self.grid:Reposition()
  self.btnEff:SetActive(SevenMgr.gets[day]==2)
end

--设置获取标签
--it(UISevenItem)
function My:SetGetLbl(it)
  if it == nil then return end
  local day = it.cfg.id
  local state = SevenMgr:GetState(day)
  local str = nil
  if state == 1 then
    local dif = day - SevenMgr.curDay
    str = dif .. "天后可领取"
  elseif state == 2 then
    str = "领取"
  elseif state == 3 then
    str = "已领取"
  end
  self.getLbl.text = str
end

--点击请求获取奖励
function My:OnClickGet()
  local id = self.cur.cfg.id
  local state = SevenMgr:GetState(id)
  if state == 1 then
    UITip.Error("不能领取")
  elseif state == 3 then
    UITip.Log("已领取")
  else
    SevenMgr:ReqGet(id)
    -- self:Lock(true)
  end
end

--响应获取奖励
function My:RespGet(err, list)
  -- self:Lock(false)
  if list == nil then return end
  if err > 0 then return end
  local items = self.items
  for i, v in ipairs(list) do
    items[v.id]:Refresh(v.val)
  end
  self:SetGetLbl(self.cur)
  self.btnEff:SetActive(false)

  local index = self:SelectState()
  self:Switch(items[index])
end

--初始化七日登陆项状态
function My:InitStae()
  local items = self.items
  for i,v in ipairs(SevenMgr.gets) do
    if v == 3 then
      items[i]:YetGet()
    elseif v == 2 then
      items[i]:ShowAction()
    end
  end
end

--设置七日登陆的状态
function My:SelectState()
  local index = 0
  for i,v in ipairs(SevenMgr.gets) do
    if v == 2 then
      index = i
    end
  end
  index = (index~=0) and index or 1
  return index
end

function My:SetLsnr(fn)
  local SM = SevenMgr
  SM.eGet[fn](SM.eGet, self.RespGet, self)
  PropMgr.eGetAdd[fn](PropMgr.eGetAdd, self.OnAdd, self)
end

--道具添加
function My:OnAdd(action,dic)
	if action==10310 then		
		self.dic=dic
		UIMgr.Open(UIGetRewardPanel.Name,self.RewardCb,self)
	end
end

--显示奖励的回调方法
function My:RewardCb(name)
	local ui = UIMgr.Get(name)
	if(ui)then
		ui:UpdateData(self.dic)
	end
end

--更新显示
function My:UpShow(state)
  self.go:SetActive(state)
end

--初始化模型
function My:UpModel(index)
  self.index = index
  local cfg = SevenCfg[index]
  if cfg == nil then return end
  local isNull = StrTool.IsNullOrEmpty(cfg.path)
  self.modelTran.gameObject:SetActive(not isNull)
  local isExist, index = self:IsExist(cfg.path)
  if isExist then
    self:SwitchModel(index)
  else
    if not isNull then
      AssetMgr.LoadPrefab(cfg.path, GbjHandler(self.LoadcloModCb, self))
    end
  end
  -- if not self.isRotate then
  --   self.modelTran.gameObject:AddComponent(typeof(UIRotateMod))
  --   self.isRotate = true
  -- end
end

--加载模型
function My:LoadcloModCb(go)
  local cfg = SevenCfg[self.index]
  local xPos = cfg.pros[1]
  local yPos = cfg.pros[2]
  local zPos = cfg.pros[3]
  local scale = cfg.pros[4]
  local rotateX = cfg.pros[5]
  local rotateY = cfg.pros[6]
  local rotateZ = cfg.pros[7]
  go.transform.parent = self.modelTran
  go.transform.localPosition = Vector3(xPos, yPos, zPos)
  go.transform.localRotation = Quaternion.Euler(rotateX, rotateY, rotateZ)
  go.transform.localScale = Vector3.one * scale
  table.insert(self.modelList, go)
  self:SwitchModel(#self.modelList)
end

--判断模型是否已存在
function My:IsExist(modelName)
  for i,v in ipairs(self.modelList) do
    if v.name == modelName then
      return true, i
    end
  end 
  return false, 1
end

--切换模型
function My:SwitchModel(index)
  for i,v in ipairs(self.modelList) do
    if index == i then
      v:SetActive(true)
    else
      v:SetActive(false)
    end
  end
end

--卸载模型
function My:UnloadModel()
  for i,v in ipairs(self.modelList) do
    AssetMgr.Instance:Unload(v.name, ".prefab", false)
    Destroy(v)
  end
  TableTool.ClearDic(self.modelList)
end

function My:Dispose()
  self.dic = nil
  self:SetLsnr("Remove")
  self:UnloadModel()
  for i,v in ipairs(self.awards) do
    v:Dispose()
  end
  ListTool.ClearToPool(self.items)
end


return My
