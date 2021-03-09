--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-06-20 22:00:30
--=========================================================================

ParticleUtil = {Name = "ParticleUtil"}


local My = ParticleUtil


--播放特效
--fx(GameObject),粒子
function My.Play(fx)
  if fx == nil then return end
  fx:SetActive(false)
  fx:SetActive(true)
end

--在指定位置播放特效
function My.PlayOnPos(fx, pos)
  My.Play(fx)
  fx.transform.position = pos
end

return My
