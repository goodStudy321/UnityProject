--[[

]]
StoreNetwork={Name="StoreNetwork"}
local My = StoreNetwork
local GetError = ErrorCodeMgr.GetError

--添加事件
function My.AddLnsr()
	local Add = ProtoLsnr.Add
	Add(22450, My.RespBuyLimit)
	Add(22452, My.RespBuyGoods)
end

--个人购买限购返回
function My.RespBuyLimit(msgs)
    TableTool.ClearDic(StoreMgr.limitDic)
	local list = msgs.buy_limit
	if list then
		for i,v in ipairs(list) do			
			StoreMgr.limitDic[v.id]=v.val
			StoreMgr.eLimit(v.id,v.val)
		end
	end
end

--==============================--
--desc:
-- local zgz=math.ceil(num/item.overlayNum)
-- local can = PropMgr.GetRemainCell()
-- if can==0 then
--     UITip.Log("背包已满")
--     return 
-- end
-- if zgz> can then
--     UITip.Log("背包格子不足，最多可购买"..can*item.overlayNum.."个")
--     return
-- end
--time:2019-09-20 07:43:13
--@shopId:
--@num:
--@return 
--==============================--
--请求购买商品
function My.ReqBugGoods(shopId,num)
	local msg = ProtoPool.GetByID(22451)
	msg.shop_id=shopId
	msg.num=num
	local shop = StoreData[tostring(shopId)]
	msg.type_id=tonumber(shop.PropId)
	ProtoMgr.Send(msg)
end

--购买商品返回
function My.RespBuyGoods(msgs)
	local err = msgs.err_code
	if(err==0)then
		UITip.Log("购买商品成功!");
	else
		UITip.Log(GetError(err))
	end
	StoreMgr.eBuyResp(msgs.type_id)
end


return My