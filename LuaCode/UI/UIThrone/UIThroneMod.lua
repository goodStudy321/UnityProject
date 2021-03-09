UIThroneMod = Super:New{Name = "UIThroneMod"}
local UMI = require("UI/Cmn/UIModItem")

local My = UIThroneMod
local Mm = ThroneMgr

--模型字典 键:配置ID,值:UIModItem
My.dic = {}

function My:Init(root)
  --当前选择条目
  --My.cur = nil
  self.modRoot = root
  self:SetDic()
end

--设置模型条目字典
function My:SetDic()
  local dic, it, k = self.dic, nil, nil
  for i, v in ipairs(ThroneCfg) do
    local it = ObjPool.Get(UMI)
    k = tostring(v.id)
    it.cfg = v
    it.cntr = self
    dic[k] = it
    it:Init()
  end
end

--选择上一个
function My:SelectLast()
  self.cntr:ResetMod(true)
  local cur = self.cur
  local kID = cur.cfg.id
  local lID = kID - 1
  if lID < ThroneCfg[1].id then
    UITip.Log("已是最低阶")
  else
    self:Switch(lID)
  end
end

--选择下一个
function My:SelectNext()
  self.cntr:ResetMod(true)
  local cur = self.cur
  local kID = cur.cfg.id
  local nID = kID + 1
  local maxId = ThroneCfg[#ThroneCfg].id 
  local k = tostring(nID)
  local it = self.dic[k]
  if it == nil then
    UITip.Log("敬请期待")
  else
    self:Switch(nID)
  end
end

--切换
--it(UIModItem):条目
function My:Switch(id)
  local k = tostring(id)
  local it = self.dic[k]
  if it == nil then return end
  local cur = self.cur
  self.cur = it
  if cur then cur:SetActive(false) end
  it:SetActive(true)
  self.cntr:Switch(it.cfg)
end

--选择当前
function My:SelectCur()
  local id = ThroneMgr.bid
  if id == 0 then id = ThroneCfg[1].id end
  self:Switch(id)
end

function My:CombMod()
  self:PetMod()
  local mod = self.cur.mod
  if mod == nil then return end
  mod.transform.localPosition = Vector3.New(0.35,-1,0)
end

function My:SingleMod()
  self:CleanModel()
  if self.cur == nil then
    return
  end
  local mod = self.cur.mod
  if mod == nil then return end
  mod.transform.localPosition = Vector3.New(0,0,0)
end

function My:PetMod()
  self:CleanModel()
  local curPedIndex = PetMgr:GetChangeIndex()
  local curPetCfg = PetTemp[curPedIndex]
  local name = AssetTool.GetSexModName(curPetCfg)
  if name == nil then return end
  local GH = GbjHandler(self.LoadModCb, self)
  Loong.Game.AssetMgr.LoadPrefab(name, GH)
end

--加载模型回调
function My:LoadModCb(go)
  local modRoot = self.modRoot
  if LuaTool.IsNull(modRoot) then
    Destroy(go)
  else
    go:SetActive(true)
    self.Model = go
    local tran = go.transform
    tran.parent = modRoot
    tran.localPosition = Vector3.New(-0.1,0,0.85)
    -- self:SetEuler(tran)
  end
end

--设置初始角度
function My:SetEuler(tran)
  local rotTran = tran:GetChild(0)
  rotTran.localPosition.z = 0
  -- self.localEuler = self.rotTran.localEulerAngles
end

function My:CleanModel()
	if self.Model then 
		GameObject.Destroy(self.Model)
		self.Model = nil
	end
end

function My:Open()
  if self.cur then
    self.cur:SetActive(true)
  end
end

function My:Close()
  if self.cur then
    self.cur:SetActive(false)
  end
end

function My:Refresh()
  self.cntr:Switch(self.cur.cfg)
end

function My:Dispose()
  self.cur = nil
  self:CleanModel()
  TableTool.ClearDicToPool(self.dic)
end

return My
