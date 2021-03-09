--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-10-03 15:07:18
--=========================================================================

UIRune = UIBase:New{Name = "UIRune"}

local My = UIRune

local pre = "UI/Rune/UIRune"

My.bag = require(pre .. "Bag")
My.com = require(pre .. "Compose")
My.embed = require(pre .. "Embed")
My.decom = require(pre .. "Decompose")
My.exchg = require(pre .. "Exchange")

--选项按钮字典,k:"选项按钮名称",v:UIToggle
My.togDic = {}

function My:InitCustom()
  local root = self.root
  self.go = root.gameObject
  local SetSub = UIMisc.SetSub
  SetSub(self, self.com, "com")
  SetSub(self, self.bag, "bag")
  SetSub(self, self.embed, "embed")
  SetSub(self, self.decom, "decom")
  SetSub(self, self.exchg, "exchg")

  self.cur = self.embed
  self:SetTog()
  self:AddLsnr()

  UITool.SetBtnClick(root, "close", self.Name, self.CloseBtn, self)
  if My.tabName == nil then
    self:SwitchByName("embed")
  end
end

--设置互斥按钮点击事件
function My:SetTog()
  local des = self.Name
  local TF = TransTool.Find
  local UTS = UITool.SetLsnrClick
  local tog = TF(self.root, "tog", des)
  self:AddTog(tog, "com")
  self:AddTog(tog, "embed", true)
  self:AddTog(tog, "decom", true)
  self:AddTog(tog, "exchg")

  self:SetFlag("embed",RuneMgr.embedFlag)
  self:SetFlag("decom",RuneMgr.decomFlag)
  
  self:SetComOpen()
end

function My:SetComOpen()
  local at = OpenMgr:IsOpen(OpenMgr.FWHC)
  local comTog = self.togDic["com"]
  if comTog then comTog.gameObject:SetActive(at) end
  if not at then OpenMgr.eOpen:Add(self.RespOpen, self) end
end

function My:RespOpen(id)
  if(id~=OpenMgr.FWHC) then return end
  local comTog = self.togDic["com"]
  if comTog then comTog.gameObject:SetActive(true) end
  OpenMgr.eOpen:Remove(self.RespOpen, self)
end

function My:AddTog(togRoot, path)
  local des = self.Name
  local tog = ComTool.Get(UIToggle, togRoot, path, des)
  if tog == nil then return end
  local go = tog.gameObject
  UITool.SetLsnrSelf(go, self.Switch, self, des)
  self.togDic[path] = tog
end

function My:SetFlag(path,flag)
  local tog = self.togDic[path]
  if tog==nil then return end
  local flagGo = TransTool.FindChild(tog.transform,"flag",des)
  if flagGo==nil then return end
  local page = self[path]
  page.flagGo = flagGo
  page:SetFlagActive(flag.red)
end

--切换页面
function My:Switch(go)
  local name = go.name
  --print("点击切换界面:", name)
  local it = self[name]
  local cur = self.cur
  if cur == it then return end
  if cur then cur:Close() end
  self.cur = it
  it:Open()
  local at = true
end

--通过名称打开分页
function My:SwitchByName(name)
  local tog = self.togDic[name]
  if tog == nil then return end
  tog:Set(true, true, false)
  self:Switch(tog.gameObject)
  My.tabName = nil
end

function My:OpenTabByIdx(t1, t2, t3, t4)
  local tabName = nil
  if t1 == 1 then  
    tabName = "embed"
  elseif t1 == 2 then
    tabName = "decom"
  elseif t1 == 2 then
    tabName = "exchg"
  elseif t1 == 2 then
    tabName = "com"
  end
  self:SwitchByName(tabName)
end

--获取质量精灵
--return(string)
function My.GetQuaPath(qt)
  do return UIMisc.GetQuaPath(qt) end
end

--响应经验更新
function My:RespExp()
  self.embed:RespExp()
  self.decom:RespExp()
  --print("UI 响应经验更新")
end

--响应碎片更新
function My:RespPiece()
  self.exchg:RespPiece()
  --print("UI 响应碎片更新")
end

--响应精粹更新
function My:RespEssence()
  self.com:RespEssence()
  --print("UI 响应精粹更新")
end

--响应背包更新
function My:RespBag()
  self.bag:Refresh()
  self.com:RespBag()
  self.embed:RespBag()
  --print("UI 响应背包更新")
end

--响应镶嵌更新
function My:RespEmbed()
  self.embed:RespEmbed()
  --print("UI 响应镶嵌更新")
end

--响应符文升级
function My:RespUpg(err, k)
  self.embed:RespUpg(err, k)
  --print("UI 响应符文升级")
end

function My:RespCompose(err)
  self.com:RespCom(err)
  --print("UI 响应合成符文")
end

--响应分解符文
function My:RespDecompose(err)
  self.decom:RespDecom(err)
  --print("UI 响应分解符文")
end

--响应兑换符文
function My:RespExchange(err)
  self.exchg:RespExchg(err)
  --print("UI 响应兑换符文")
end

--响应装备符文
function My:RespEquip(err)
  self.embed:RespEquip(err)
  --print("UI 响应装备符文")
end

function My:CloseCustom()
  if self.cur then self.cur:Close() end
end

function My:Refresh()

end

--添加监听
function My:AddLsnr()
  self:SetLsnr("Add")
end

--移除监听
function My:RemoveLsnr()
  self:SetLsnr("Remove")
end

--设置监听
--fn(string):注册/注销名
function My:SetLsnr(fn)
  local Rm = RuneMgr
  Rm.eExp[fn](Rm.eExp, self.RespExp, self)
  Rm.eUpg[fn](Rm.eUpg, self.RespUpg, self)
  Rm.eEquip[fn](Rm.eEquip, self.RespEquip, self)
  Rm.ePiece[fn](Rm.ePiece, self.RespPiece, self)
  Rm.eEssence[fn](Rm.eEssence, self.RespEssence, self)
  Rm.eCompose[fn](Rm.eCompose, self.RespCompose, self)

  Rm.eUpdateBag[fn](Rm.eUpdateBag, self.RespBag, self)
  Rm.eExchange[fn](Rm.eExchange, self.RespExchange, self)
  Rm.eDecompose[fn](Rm.eDecompose, self.RespDecompose, self)
  Rm.eUpdateEmbed[fn](Rm.eUpdateEmbed, self.RespEmbed, self)

end

function My:CloseBtn()
  self:Close()
  JumpMgr.eOpenJump()
end

function My:DisposeCustom()
  self.cur = nil
  self:RemoveLsnr()
  self.bag:Dispose()
  self.com:Dispose()
  self.embed:Dispose()
  self.decom:Dispose()
  self.exchg:Dispose()
  My.tabName = nil
  OpenMgr.eOpen:Remove(self.RespOpen, self)
  TableTool.ClearDic(self.togDic)
end

return My
