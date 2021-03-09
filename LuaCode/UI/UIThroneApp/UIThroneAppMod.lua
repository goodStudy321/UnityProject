local UMSI = require("UI/UIThroneApp/UIThAppListModIt")
UIThroneAppMod = Super:New{Name = "UIThroneAppMod"}
local My = UIThroneAppMod

--条目字典 键:模块ID,值:UWItem
My.itDic = {}

function My:Init(root)
  self.root = root
  self.active = false
  local des = self.Name
  self.gbj = root.gameObject
  local CGS, TF = ComTool.GetSelf, TransTool.Find
  local tblTran = TF(root, "Table", des)
  --UITable表
  self.uiTbl = CGS(UITable, tblTran, des)
  --条目模板
  self.item = TransTool.FindChild(tblTran, "item", des)
  self.item:SetActive(false)
end

--清理条目字典
function My:ClearItDic()
  local itDic, root = self.itDic, self.root
  local OA, tran = ObjPool.Add, nil
  for k, v in pairs(itDic) do
    tran = v.root.transform
    tran.name = "none"
    tran.parent = root
    tran.gameObject:SetActive(false)
    itDic[k] = nil
    OA(v)
  end
end

--重设条目字典
function My:Reset()
  local itMod, db, it = self.item, self.cntr.db, nil
  local dic, p = db.dic, self.root
  local info, go, c = nil, nil, nil
  local uiTblTran = self.uiTbl.transform
  local itDic, name, k = self.itDic, nil, nil
  TransTool.RenameChildren(uiTblTran)
  self:ClearItDic()
  for i, v in ipairs(ThroneChangeCfg) do
    name = v.name
    k = v.id
    info = dic[k]
    if info then
      c = p:Find("none")
      if c then
        go = c.gameObject
      else
        go = Instantiate(itMod)
        c = go.transform
      end
      go.name = tostring(k)
      it = ObjPool.Get(UMSI)
      it.info = dic[k]
      it.cntr = self
      itDic[k] = it
      go:SetActive(true)
      it:Init(c)
      TransTool.AddChild(uiTblTran, c)
      local bId = v.id
      local propId = AdvMgr.GetPIdByBId(bId)
      local propNum = PropMgr.TypeIdByNum(propId)
    end
  end
  local ck = ThroneChangeCfg[1].id
  self:Switch(self.itDic[ck])
end

--响应激活
function My:RespRefine(id, unlock)
  local db = self.cntr.db
  if not unlock then return end
  local k = db.GetKey(id)
  local it = self.itDic[k]
  it:SetLock()
end

--设置红点
function My:SetReds(list)
	local itDic = self.itDic
	for k,v in pairs(itDic) do
		if list[k] ~= nil then
			v:IsShowAction(true)
		else
			v:IsShowAction(false)
		end
	end
end

function My:Refresh()
  self.cntr:Switch(self.cur.info)
end

--it:UIListModItem
function My:Switch(it)
  if it == nil then return end
  local cur = self.cur
  if cur == it then return end
  self.cur = it
  if cur then cur:SetActive(false) end
  self.cntr:ResetMod(true)
  it:SetActive(true)
  self.cntr:Switch(it.info)
end

function My:CombMod()
  self:PetMod()
  local mod = self.cur.mod
  if mod == nil then return end
  -- mod.transform.localPosition = Vector3.New(0,-1,0)
end

function My:SingleMod()
  self:CleanModel()
  local mod = self.cur.mod
  if mod == nil then return end
  -- mod.transform.localPosition = Vector3.New(0,0,0)
end

function My:PetMod()
  self:CleanModel()
  local curPedIndex = PetMgr:GetCurIndex()
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
    -- self:SetEuler(tran)
    tran.localPosition = Vector3.New(-0.54,1,0.76)
  end
end

--设置初始角度
function My:SetEuler(tran)
  self.rotTran = tran:GetChild(0)
  self.localEuler = self.rotTran.localEulerAngles
end

function My:CleanModel()
	if self.Model then 
		GameObject.Destroy(self.Model)
		self.Model = nil
	end
end

--将item放入对象池
function My:ItemToPool()
  if self.itDic or #self.itDic > 0 then
    for k,v in pairs(self.itDic) do
      v.info = nil
      v.cntr = nil
      ObjPool.Add(v)
      self.itDic[k] = nil
    end
  end
end

function My:Dispose()
  self.skinBtnRed = nil
  self.isSkinFull = nil
  self.cur = nil
  self:CleanModel()
  self:ClearItDic()
  TableTool.ClearUserData(self)
end

return My
