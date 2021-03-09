--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 1/2/2019, 2:32:43 AM
-- 主界面后台下载进度
--=============================================================================

UIMainmenuDl = {Name = "UIMainmenuDl"}

local My = UIMainmenuDl

function My:Init(go)
  --屏蔽下载UI
  --go:SetActive(false)
  --do return end
  if not App.IsSubAssets then go:SetActive(false) return end
  if (User.SubAssetIsOver) and (PackCtrl.isGetRewarded) then
    go:SetActive(false)
  else
    self.go = go
    go:SetActive(true)
    self:SetLsnr("Add")
    local des = self.Name
    local root = go.transform
    UITool.SetBtnSelf(go, self.OpenDetail, self, des)
    self.proSp = ComTool.Get(UISprite, root, "Load", des)
    self.completeFx = TransTool.FindChild(root, "EffRoot", des)
    self:SetCompleteFx(User.SubAssetIsOver)
    self:SetCount(PackCtrl.count)
  end
end

function My:SetLsnr(fn)
  local PC = PackCtrl
  PC.eComplete[fn](PC.eComplete, self.Complete, self)
  PC.eSetCount[fn](PC.eSetCount, self.SetCount, self)
  PC.eGetReward[fn](PC.eGetReward, self.RespGetReward, self)
end

function My:SetCount(count)
  local total = PackCtrl.total
  if total > 1 then
    local pro = count / (1.0 * total)
    self.proSp.fillAmount = pro
  end
end

function My:OpenDetail()
  UIMgr.Open("UIDownload")
end


function My:Complete(isGetRewarded)
  if isGetRewarded == true then
    self:GetReward()
  else
    self:SetCompleteFx(true)
  end
end

function My:RespGetReward(isGetRewarded)
  if isGetRewarded == true then
    self:GetReward()
  end
end

function My:GetReward()
  if not User.SubAssetIsOver then return end
  self:Close()
  self:Clear()
end

function My:SetCompleteFx(at)
  if at==nil then at = false end
  local go = self.completeFx
  if LuaTool.IsNull(go) then return end
  go:SetActive(at)
end

function My:Close()
  self.go:SetActive(false)
end

function My:Open()
  self.go:SetActive(true)
end

function My:Clear()
  self:SetLsnr("Remove")
end


return My
