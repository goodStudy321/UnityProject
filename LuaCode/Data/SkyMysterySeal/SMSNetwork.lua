--region 
--
--此文件由[HS]创建生成

SMSNetwork = {Name = "SMSNetwork"}
local M = SMSNetwork

local Send = ProtoMgr.Send
local CheckErr = ProtoMgr.CheckErr

function M:Init()
	self:AddProto()
end

function M:AddProto()
	self:ProtoHandler(ProtoLsnr.Add)
end

function M:RemoveProto()
	self:ProtoHandler(ProtoLsnr.Remove)
end

function M:ProtoHandler(Lsnr)
	Lsnr(26402, self.RespInfoToc, self)	
	Lsnr(26406, self.ResplaceOpenToc, self)	
	Lsnr(26408, self.RespPlaceOperateToc, self)	
	Lsnr(26410, self.RespPlaceRefineToc, self)	
	Lsnr(26412, self.RespGoodsRefineToc, self)	
	Lsnr(26414, self.RespOptToc, self)	
	Lsnr(26416, self.ResConsumeMoneyToc, self)	
end
--[[#############################################################]]--

--上线推送
function M:RespInfoToc(msg)
	SMSMgr:ClearInfo()
	SMSMgr.DecomposeQuality = msg.quality
	SMSMgr.DecomposeStar = msg.star
	SMSMgr.CostNum = msg.consume_money
	--天机印图鉴
	FiveElmtMgr.book_list = msg.book_list
	--/// LY add begin
	FiveElmtMgr.CanGoNext();
	--/// LY add end
	local list = msg.nature_place
	local len = #list
	if len > 0 then
		for i=1, len do
			local pro = list[i]
			if pro then
				SMSMgr:UpdateProto(pro.type, pro.aperture_id, pro.nature, pro.refine,true)
			end
		end
	end
	SMSMgr:CheckRed()
	SMSMgr:CheckStrengthRed()
end

--开孔数据返回
function M:ResplaceOpenToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	SMSMgr:UpdateHole(msg.type, msg.aperture_id)
end

--操作返回
function M:RespPlaceOperateToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	SMSMgr:UpdateSeal(msg.type, msg.aperture_id, msg.goods, msg.operate_type)
	SMSMgr:CheckStrengthRed()
end

--强化返回
function M:RespPlaceRefineToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	SMSMgr:UpdateStrengthLv(msg.type, msg.aperture_id, msg.refine)
	SMSMgr:CheckStrengthRed()
	UITip.Error("强化成功")
end

--分解
function M:RespGoodsRefineToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
end

--设置品质返回
function M:RespOptToc(msg)
	local err = msg.err_code
	if not CheckErr(err) then 
		UITip.Error(ErrorCodeMgr.GetError(err))
		return 
	end
	SMSMgr.DecomposeQuality = msg.quality
	SMSMgr.DecomposeStar = msg.star
end

--更新强化消耗数量
function M:ResConsumeMoneyToc(msg)
	SMSMgr.CostNum = msg.consume_money
	SMSMgr.eChangeConsume()
	SMSMgr:CheckStrengthRed()
end

--[[#############################################################]]--
--请求当前数据
function M:ReqInfoTos()
	local msg = ProtoPool.GetByID(26401)
	Send(msg)
end

--请求当前背包数据
function M:ReqBackpackInfoTos()
	local msg = ProtoPool.GetByID(26403)
	Send(msg)
end

--开孔
function M:ReqPlaceOpenTos(id,type)
	local msg = ProtoPool.GetByID(26405)
	msg.aperture_id = id
	msg.type = type
	Send(msg)
	-- body
end

--操作
--t:0:卸下,1:镶嵌,2:替换
function M:ReqPlaceOperateTos(type, id, itemid, t)
	local msg = ProtoPool.GetByID(26407)
	msg.aperture_id = id
	msg.type = type
	msg.goods_id = itemid
	msg.operate_type = t
	Send(msg)
end

--强化
function M:ReqPlaceRefineTos(type, id)
	local msg = ProtoPool.GetByID(26409)
	msg.aperture_id = id
	msg.type = type
	Send(msg)
end

--分解
function M:ReqGoodsRefineTos(ids)
	local msg = ProtoPool.GetByID(26411)
	for i,v in ipairs(ids) do
		msg.rune_ids:append(v)
	end
	Send(msg)
end

--设置分解品质
function M:ReqOptTos(quality, star)
	local msg = ProtoPool.GetByID(26413)
	msg.quality = quality
	msg.star = star
	Send(msg)
end

--[[#############################################################]]--
function M:Clear()
	self:RemoveProto()
end

return M