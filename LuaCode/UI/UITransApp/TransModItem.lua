TransModItem = Super:New{Name = "TransModItem"}

local My = TransModItem

function My:Init()

end

--激活
function My:SetActive(at)
  if (self.mod == nil) and (at == true) then
    self:LoadMod()
  elseif (self.mod==nil) then
    self:LoadMod()
  else
    self.mod:SetActive(at)
    self.rotTran.localEulerAngles = self.localEuler
    UITransApp.loadLabR:SetActive(false)
  end
end

--加载模型
function My:LoadMod()
  local name = AssetTool.GetSexModName(self.cfg)
  local scName = AssetTool.GetSexScModName(self.cfg)
  if name == nil then return end
  if scName == nil then return end
  local tran = UITransApp.modRoot:Find(name)
  if tran then
    self:SetEuler(tran)
    self.mod = tran.gameObject
    self.mod:SetActive(true)
  else
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
  local modRoot = UITransApp.modRoot
  if LuaTool.IsNull(modRoot) then
    Destroy(go)
  else
    self.mod = go
    local at = ((UITransApp.cur == self)) and true or false
    go:SetActive(at)
    local tran = go.transform
    tran.parent = modRoot
    self:SetEuler(tran)
    tran.localPosition = Vector3.zero
    -- tran.localScale = Vector3.New(200,200,200)
  end
end

--设置初始角度
function My:SetEuler(tran)
  self.rotTran = tran:GetChild(0)
  self.localEuler = self.rotTran.localEulerAngles
end


--资源找回提示
function My:SetShowAssTip(name,scName)
  local isExist = AssetTool.IsExistAss(name)
  local isScExist = AssetTool.IsExistAss(scName)
  local isContinue = false
  if isExist == false or isScExist == false then
    UITransApp:IsShowAssTip(true)
    isContinue = false
  elseif isExist == true and isScExist == true then
    UITransApp:IsShowAssTip(false)
    isContinue = true
  end
  return isContinue
end

function My:Dispose()
  self.cfg = nil
  self.cntr = nil
  TableTool.ClearUserData(self)
end

return My
