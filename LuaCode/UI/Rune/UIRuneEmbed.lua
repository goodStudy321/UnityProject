--[[
 	author 	    :Loong
 	date    	:2018-01-18 19:22:01
 	descrition 	:符文镶嵌面板
--]]
require("UI/Cmn/UIProp")
require("Data/Prop/KV")

UIRuneEmbed = Super:New{Name = "UIRuneEmbed"}

local My = UIRuneEmbed

local pre = "UI/Rune/UIRune"

My.upg = require(pre .. "Upg")
My.bag = require(pre .. "EmbedBag")
My.slot = require(pre .. "Slot")
My.prop = UIProp:New()

--k:id字符,v:索引
My.propDic = {}

--条目:{id,v}
My.props = {}

function My:Init(root)
  self.root = root
  local TF = TransTool.FindChild

  local SetSub = UIMisc.SetSub
  SetSub(self, self.upg, "upg")
  SetSub(self, self.bag, "bag")
  self.bag.realBag = self.cntr.bag
  
  SetSub(self, self.slot, "slot")
  SetSub(self, self.prop, "prop")
  local des = self.Name
  local prop = self.prop
  prop:Close()
  UITool.SetLsnrClick(root, "totalPropBtn", des, self.SetProp, self)
  RuneMgr.embedFlag.eChange:Add(self.SetFlagActive,self)
end

function My:SetFlagActive(at)
  --iTrace.Error("Loong",self.Name,",SetFlagActive ",at)
  self.flagGo:SetActive(at)
end


--设置属性
function My:SetProp()
  local lst = self.slot.lst
  local count = #lst
  if count < 1 then
    self.prop:SetActive(false)
    return
  end
  local dic, props = self.propDic, self.props
  TableTool.ClearDic(dic)
  ListTool.ClearToPool(props)
  local p1, p2, v1, v2, k1, k2 = nil
  local info = nil
  for i, v in pairs(lst) do
    info = v.info
    if info then 
      local lvCfg = info.lvCfg
      p1 = lvCfg.p1
      p2 = lvCfg.p2
      v1 = lvCfg.v1 or 0
      v2 = lvCfg.v2 or 0
      if p1 then
        k1 = tostring(p1)
        local idx = dic[k1]
        if idx then
          props[idx].v = props[idx].v + v2
        else
          idx = #props + 1
          dic[k1] = idx
          props[idx] = KV:New{k = k1, v = v1}
        end
      end
      if p2 then
        k2 = tostring(p2)
        local idx = dic[k2]
        if idx then
          props[idx].v = props[idx].v + v2
        else
          idx = #props + 1
          dic[k2] = idx
          props[idx] = KV:New{k = k2, v = v2}
        end
      end
    end
  end
  self.prop:SetActive(true)
  self.prop:RefreshByList(props)
end

--响应经验更新
function My:RespExp()
  self.upg:RespExp()
  self.slot:RespExp()
end

function My:RespUpg(err, k)
  self.rCntr:Lock(false)
  if err > 1 then return end
  self.upg:RespUpg()
  self.slot:RespUpg()
  --self:SetProp()
end

--响应背包更新
function My:RespBag()
  self.bag:RespBag()
  self.slot:RespBag()
end

--响应镶嵌更新
function My:RespEmbed()
  self.slot:RespEmbed()
  self.upg:RespEmbed()
 
  --self:SetProp()
end

--响应装备更新
function My:RespEquip(err)
  self.rCntr:Lock(false)
  if err > 1 then return end
  local tip = "镶嵌成功"
  UITip.Log(tip)
  --MsgBox.ShowYes("镶嵌成功")
  self.bag:Close()
end

function My:Open()

end

function My:Close()

end

function My:Dispose()
  self.bag:Dispose()
  self.upg:Dispose()
  self.prop:Dispose()
  self.slot:Dispose()
  TableTool.ClearDic(self.propDic)
  TableTool.ClearUserData(self)
  RuneMgr.embedFlag.eChange:Remove(self.SetFlagActive,self)
end

return My
