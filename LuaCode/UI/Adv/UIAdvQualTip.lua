--[[
 	author 	    :Loong
 	date    	:2018-01-18 14:13:42
 	descrition 	:资质提示
--]]

UIAdvQualTip = Super:New{Name = "UIAdvQualTip"}

local My = UIAdvQualTip

--k:属性ID,v:UILabel
My.dic = {}

function My:Init(root)
  self.root = root
  self.gbj = root.gameObject
  local des = self.Name
  local CG = ComTool.Get

  self.icon = CG(UITexture, root, "icon", des)
  self.nameLbl = CG(UILabel, root, "name", des)
  self.desLbl = CG(UILabel, root, "des", des)
  self.useLbl = CG(UILabel, root, "use", des)
  self.qtSp = CG(UISprite, root, "qt", des)
  self.bgSp = CG(UISprite, root, "bg1", des)
  UITool.SetBtnClick(root, "close", des, self.Close, self)
  UserMgr.eLvEvent:Add(self.SetUse, self)
  self:Close()
end

--显示
--id:道具ID
--icon:道具图标
--qCfg:丹药配置
--use:使用数量
function My:Show(id, icon, qCfg, use)
  if icon == nil then
    return
  end
  local it = ItemData[tostring(id)]
  if it == nil then return end
  local qt = it.quality
  self.icon.mainTexture = icon
  self.iconName = icon.name
  local color = UIMisc.LabColor(qt)
  self.nameLbl.text = color .. it.name
  self.desLbl.text = it.des
  self.qtSp.spriteName = UIMisc.GetQuaPath(qt)
  self.bgSp.spriteName = "cell_a0"..qt
  self.qCfg = qCfg
  self.use = use
  self:SetUse()
  self.gbj:SetActive(true)
end

function My:SetUse()
  if self.qCfg == nil then return end
  local max = AdvMgr:GetUseMax(self.qCfg)
  local sb = ObjPool.Get(StrBuffer)
  sb:Apd("[67cc67]"):Apd(self.use)
  if self.use < max then sb:Apd("[-]") end
  sb:Apd("/"):Apd(max)
  self.useLbl.text = sb:ToStr()
  ObjPool.Add(sb)
end

--
function My:SetProps(props)
  if props == nil then return end
  local sb = ObjPool.Get(StrBuffer)
  for i, v in ipairs(props) do
    local it = BinTool.Find(PropName, v.k)
    if it then
      sb:Apd(it.name):Apd(": +")
      sb:Apd(v.v):Apd("\n")
    end
  end
  local str = sb:ToStr()
  sb:Dispose()
  ObjPool.Add(sb)
  self.desLbl.text = str
end

function My:ClearIcon()
  if self.iconName then
    -- iTrace.Error("GS","资质丹药提示释放===",self.iconName)
    AssetMgr:Unload(self.iconName,".png",false)
    self.iconName = nil
	end
end

function My:Close()
  self.gbj:SetActive(false)
  self.qCfg = nil
  self.use = nil
end

function My:Dispose()
  self:ClearIcon()
  TableTool.ClearDicToPool(self.dic)
  UserMgr.eLvEvent:Remove(self.SetUse, self)
end

return My
