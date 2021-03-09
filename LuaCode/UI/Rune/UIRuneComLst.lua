--[[
 	author 	    :Loong
 	date    	:2018-01-25 14:49:03
 	descrition 	:UI符文合成列表
--]]

local URCLI = require("UI/Rune/UIRuneComLstItem")

local base = require("UI/Cmn/UITableList")
UIRuneComLst = base:New{Name = "UIRuneComLst"}

local My = UIRuneComLst

function My:Init(root, title, qt, mod)
    --第一个可合成条目
  self.firstIt = nil
  self.firstPass = nil
  base.Init(self, root, title, qt, mod)
  local CG, des = ComTool.Get, self.Name
  self.hlTitleLbl = CG(UILabel, root, "hlTitle", des)
  self.hlTitleGo = self.hlTitleLbl.gameObject
  self.hlTitleGo:SetActive(false)
  self.hlTitleLbl.text = title
  self.titleGo = self.titleLbl.gameObject
  self.kuangGo = TransTool.FindChild(root, "kuang", des)
  self.pointGo = TransTool.FindChild(root, "bg2", des)
  self.tween = ComTool.GetSelf(UIPlayTween, root, des)
  self.select = false

end

function My:SetSelect(at, play)
  if at == self.select then return end
  self.select = at
  self:SetOtherActive(at)
  self.foldSp.spriteName = (at and "ty_11" or "ty_13")
  self.hlSp.spriteName = (at and "ty_a15" or "ty_a4")
  if play then self.tween:Play(true) end
end

function My:Play(at)
  self.tween:Play(at)
end

function My:SetOtherActive(at)
  local nat = not at
  self.hlTitleGo:SetActive(at)
  self.titleGo:SetActive(nat)
  self.kuangGo:SetActive(nat)
  self.pointGo:SetActive(nat)
end

--设置列表
function My:SetItems(qt, mod)
  if mod == nil then return end
  local uiTbl = self.uiTbl
  local BF = BinTool.Find
  local TA = TransTool.AddChild
  local tblTran = uiTbl.transform
  local Inst = GameObject.Instantiate
  local lst = self.lst
  local cfg, it, go, tran, bid, k = nil
  local idx, cntr = 0, self.cntr
  local es ,GetCount= RuneMgr.essence,RuneMgr.GetCountByID
  for i, v in ipairs(RuneComCfg) do
    bid = v.id
    k = tostring(bid)
    cfg = RuneCfg[k]
    if cfg then
      if (cfg.qt == qt) then
        it = ObjPool.Get(URCLI)
        go = Inst(mod)
        go:SetActive(true)
        go.name = k
        tran = go.transform
        TA(tblTran, tran)
        it.cntr = self
        it.comCfg = v
        it.cfg = cfg
        it.idx = idx
        idx = idx + 1
        it:Init(tran)
        lst[#lst + 1] = it
        local tid = cfg.towerId
        local pass = CopyMgr:IsFinishCopy(tid)
        it.lockGo:SetActive(not pass)

        if pass then
          if self.firstIt == nil then
            local need = v.con
            if need <= es then
              local num1 = GetCount(v.cid1)
              local num2 = GetCount(v.cid2)
              if num1>0 and num2> 0 then
                self.firstIt = it
              end
            end
          end
          if self.firstPass == nil then
            self.firstPass = it
          end
        end
      end
    else
      local str = "符文合成的ID:" .. id .. " 未在 基础 表中配置"
      iTrace.Error("Loong", str)
    end
  end
  uiTbl:Reposition()
end


return My
