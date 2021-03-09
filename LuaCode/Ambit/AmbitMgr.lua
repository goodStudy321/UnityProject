-- AmbitMgr = Super:New{Name = "Ambit"}

-- local M = AmbitMgr

-- M.eUpData = Event()
-- M.eUpdateRedPoint = Event()

-- function M:Init( ... )
--     self:SetLsnr(ProtoLsnr.Add)
--     self:SetEvent()
-- end

-- function M:SetLsnr(func)
--     func(20022, self.RespConfineUp, self)
-- end

-- function M:SetEvent()
--     local func = EventHandler(self.UpdateRedPoint,self)
--     EventMgr.Add("OnChangeFight",func)
--     EventMgr.Add("RoleLogin", func)
--     PropMgr.eUpdate:Add(self.UpdateRedPoint, self)
-- end

-- function M:ReqAdv()
--     local msg = ProtoPool.GetByID(20021)
--     ProtoMgr.Send(msg)
-- end

-- function M:RespConfineUp(msg)
--     if msg.error_code == 0 then
--         self.eUpData(msg.confine)
--     else
--         local err = ErrorCodeMgr.GetError(msg.error_code)
--         UITip.Log(err)
--     end
-- end

-- function M:UpdateRedPoint()
--     local confine = User.MapData.Confine
--     local power = User.MapData.AllFightValue
--     local cfg = AmbitCfg
--     local state = false
--     if User.MapData.Level>=SystemOpenTemp["46"].trigParam then
--         for i=1,#cfg do
--             if cfg[i].power <= power and cfg[i].id > confine then
--                 local items = cfg[i].itemDic
--                 local len = #items
--                 if len>0 then
--                     for j=1,len do
--                         local item = items[j]
--                         local num = PropMgr.TypeIdByNum(item.k)
--                         state = num>=item.v
--                         if not state then
--                             break
--                         end
--                     end 
--                 else
--                     state = true
--                 end
--                 break
--             end
--         end
--     end
--     self.eUpdateRedPoint(state)
-- end

-- function M:Clear()
-- end

-- return M