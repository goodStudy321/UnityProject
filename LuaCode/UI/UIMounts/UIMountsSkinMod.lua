--[[
 	authors 	:Loong
 	date    	:2017-08-21 01:27:16
 	descrition 	:坐骑模型预览模块
--]]
require("UI/UIMounts/UIMountsSkinModItem")

UIMountsSkinMod = Super:New{Name = "UIMountsSkinMod"}
local Mm = MountsSkin
local My = UIMountsSkinMod
local UMSI = UIMountsSkinModItem

My.root = nil

--条目模板
My.item = nil

--当前选择条目
My.cur = nil

--UI表
My.uiTbl = nil

--模型根结点
My.modRoot = nil

--条目列表 键:模块前5位,值:UIMountsSkinModItem
My.items = {}

function My:Init(root)
  self.active = false
  self.root = root
  local des = self.Name
  self.gbj = root.gameObject
  local CGS = ComTool.GetSelf

  local TF = TransTool.Find
  local tblTran = TF(root, "Table", des)
  self.uiTbl = CGS(UITable, tblTran, des)

  self.modRoot = TF(root.parent, "modRoot", des)
  self.item = TransTool.FindChild(tblTran, "item", des)
  self.item:SetActive(false)
  self:SetItems()
end

--设置条目
function My:SetItems()
  local item = self.item
  local Inst = GameObject.Instantiate
  for k, v in pairs(Mm.dic) do
    local go = Inst(item)
    self:AddItem(v, go)
  end
  local k = Mm.GetKey(Mm.info.cfg.id)
  self.cur = self.items[k]
  self.cur:TweenPlay(true)
  self.uiTbl:Reposition()
end


--添加条目
function My:AddItem(info, go)
  if go == nil then return end
  local k = Mm.GetKey(info.cfg.id)
  local it = ObjPool.Get(UMSI)
  go.name = k
  self.items[k] = it
  local tran = go.transform
  it.root = tran
  it.info = info
  it.cntr = self
  go:SetActive(true)
  it:Init()
  TransTool.AddChild(self.uiTbl.transform, tran)
end

--添加模型
function My:AddMod(it, mod)
  if mod == nil then return end
  if LuaTool.IsNull(self.modRoot) then
    Destroy(mod)
  end
  local tran = mod.transform
  tran.parent = self.modRoot
  tran.localPosition = Vector3.zero
end

--设置锁定
--id:模块ID
function My:SetLock(id)
  local k = Mm.GetKey(id)
  local it = self.items[k]
  if it then it:SetLock() end
end

function My:Open()
  self.gbj:SetActive(true)
  self.active = true
end

function My:Close()
  self.gbj:SetActive(false)
  self.active = false
end

function My:Refresh()
  self.cntr:Switch(self.cur.info)
end

function My:Dispose()
  TableTool.ClearUserData(self)
  TableTool.ClearDicToPool(self.items)
end

return My
