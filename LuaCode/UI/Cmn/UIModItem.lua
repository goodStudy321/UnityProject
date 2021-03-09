UIModItem = Super:New{Name = "UIModItem"}

local My = UIModItem

function My:Init()

end

--index == nil 养成模型
--index == 1   宝座化形模型
--激活
function My:SetActive(at,index)
  -- iTrace.Error("GS","self.mod====",tostring(self.mod),"   at==",tostring(at))
  if (self.mod == nil) and (at == true) then
    self:LoadMod(index)
  elseif (self.mod==nil) then
    self:LoadMod(index)
  else
    self.mod:SetActive(at)
    self.rotTran.localEulerAngles = self.localEuler
    -- if index == nil then
      self.cntr.rCntr.loadLabR:SetActive(false)
    -- end
  end
end


--加载模型
function My:LoadMod(index)
  local name = AssetTool.GetSexModName(self.cfg)
  local scName = AssetTool.GetSexScModName(self.cfg)
  if name == nil then return end
  if scName == nil then return end
  local tran = self.cntr.modRoot:Find(name)
  if tran then
    self:SetEuler(tran)
    self.mod = tran.gameObject
    self.mod:SetActive(true)
  else
    self.cntr.rCntr:Lock(true)
    local isContinue = self:SetShowAssTip(name,scName)
    if isContinue == false then
      return
    end
    local GH = GbjHandler(self.LoadModCb, self)
    Loong.Game.AssetMgr.LoadPrefab(name, GH)
  end
end

--加载模型回调
function My:LoadModCb(go)
  -- iTrace.Error("GS","Load Mode")
  self.cntr.rCntr:Lock(false)
  local modRoot = self.cntr.modRoot
  if LuaTool.IsNull(modRoot) then
    Destroy(go)
  else
    self.mod = go
    local at = ((self.cntr.cur == self)) and true or false
    go:SetActive(at)
    local tran = go.transform
    tran.parent = modRoot
    self:SetEuler(tran)
    tran.localPosition = Vector3.zero
  end
end

--显示养成资源找回提示
function My:SetShowAssTip(name,scName)
  local isExist = AssetTool.IsExistAss(name)
  local isScExist = AssetTool.IsExistAss(scName)
  local isContinue = false
  if isExist == false or isScExist == false then
    self.cntr.rCntr:IsShowAssTip(true)
    isContinue = false
  elseif isExist == true and isScExist == true then
    self.cntr.rCntr:IsShowAssTip(false)
    isContinue = true
  end
  return isContinue
end

--设置初始角度
function My:SetEuler(tran)
  self.rotTran = tran:GetChild(0)
  self.localEuler = self.rotTran.localEulerAngles
end

function My:Dispose()
  self.cfg = nil
  self.cntr = nil
  TableTool.ClearUserData(self)
end

return My
