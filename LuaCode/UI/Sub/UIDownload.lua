--=============================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 12/30/2018, 10:56:09 PM
-- 详细后台下载进度
--=============================================================================


UIDownload = UIBase:New{Name = "UIDownload"}

local My = UIDownload

My.items = UIItems:New()

function My:InitCustom()
  local root, des = self.root, self.Name
  local CG, TF = ComTool.Get, TransTool.Find
  local bg = TF(root, "bg", des)

  --屏蔽下载UI
  --bg.gameObject:SetActive(false)
  --do return end

  --提示标签
  self.tipLbl = CG(UILabel, bg, "tip", des)
  --进度说明标签
  self.preLbl = CG(UILabel, bg, "proPre", des)
  --进度标签
  self.proLbl = CG(UILabel, bg, "proLbl", des)
  --进度精灵
  self.proSp = CG(UISprite, bg, "pro/val", des)

  self.preLbl.text = "正在更新资源文件"
  local itRoot = TF(bg, "good", des)
  self.items:Init(itRoot)
  local cfg = GlobalTemp["79"]
  self.items:Refresh(cfg.Value1, "id", "value")
  self:SetLsnr("Add")

  self:SetTotal(PackCtrl.size, PackCtrl.total)
  self:SetCount(PackCtrl.count)
  self:Downloaded()
  UITool.SetBtnClick(bg, "close", des, self.Close, self)
  UITool.SetBtnClick(bg, "minBtn", des, self.OnClickMin, self)
  self.minLbl = CG(UILabel, bg, "minBtn/lbl", des)
  self:SetMinLbl(PackCtrl.isGetRewarded)
end


function My:SetLsnr(fn)
  local PC = PackCtrl
  PC.eComplete[fn](PC.eComplete, self.Complete, self)
  PC.eSetTotal[fn](PC.eSetTotal, self.SetTotal, self)
  PC.eSetCount[fn](PC.eSetCount, self.SetCount, self)
  PC.eDownloaded[fn](PC.eDownloaded, self.Downloaded, self)
  PC.eGetReward[fn](PC.eGetReward, self.RespGetReward, self)
  PropMgr.eGetAdd[fn](PropMgr.eGetAdd, self.OnAdd, self)
end

function My:SetTip(val)

end

function My:SetTotal(size, total)
  local len = string.len(size) - 1
  local newStr = string.sub(size, 1, len)
  local num = tonumber(newStr)
  local fake = num * 0.8
  self.tipLbl.text = "需要下载资源拓展包\n将消耗" .. fake .. "M流量"
end

function My:SetCount(count)
  local total = PackCtrl.total
  if total < 1 then return end
  count = count + 1
  if count > total then count = total end
  local pro = (count) / (1.0 * total)
  self.proSp.fillAmount = pro
  local p = pro * 100
  p = math.floor(p)
  self.proLbl.text = tostring(count) .. "/" .. total .. ", 进度" .. p .. "%"
end

function My:SetMinLbl(isGetRewarded)
  local msg = nil
  if User.SubAssetIsOver == true then
    msg = ((isGetRewarded == true) and "已领取" or "领取")
  else
    msg = ((isGetRewarded == true) and "领取" or "最小化")
  end
  self.minLbl.text = msg
end

function My:Downloaded()
  if User.SubAssetIsOver == true then
    self.preLbl.text = "更新完成"
  elseif PackCtrl.isDownloaded == true then
    self.preLbl.text = "正在校验资源文件"
  end
end

function My:RespGetReward(isGetRewarded)
  if (User.SubAssetIsOver == true) and (isGetRewarded == true) then
    self:Close()
  else
    self:SetMinLbl(isGetRewarded)
  end
end

function My:OnAdd(action, dic)
  if action == 10353 then
    My.dic = dic
    UIMgr.Open(UIGetRewardPanel.Name, self.ShowReward, self)
  end
end

function My:ShowReward(name)
  local ui = UIMgr.Get(name)
  if ui then
    -- local cfg = GlobalTemp["79"]
    -- local data = {}
    -- for i, v in ipairs(cfg.Value1) do
    --   local it = {}
    --   it.k = v.id
    --   it.v = v.value
    --   table.insert(data, it)
    -- end
    ui:UpdateData(My.dic)
  else
    UITip.Error(name .. "不存在")
  end
end

function My:Complete(isGetRewarded)
  if User.SubAssetIsOver and isGetRewarded then
    self:Close()
  else
    self:SetMinLbl(isGetRewarded)
    self:Downloaded()
  end
end

function My:OnClickMin()
  if User.SubAssetIsOver == true then
    if not PackCtrl.isGetRewarded then
      PackCtrl.ReqGetReward()
    else
      self:Close()
    end
  else
    self:Close()
  end
end

function My:SetPro(val)

end

function My:Clear()

end

function My:CloseCustom()
  self:SetLsnr("Remove")
end

function My:DisposeCustom()
  self.items:Dispose()
  self:SetLsnr("Remove")
end

return My
