--[[
商城管理类
--]]
require("Data/Store/StoreNetwork")

StoreMgr = {Name = "StoreMgr"}
local My = StoreMgr
My.network = StoreNetwork
My.eLimit=Event()
My.eBuyResp=Event()

My.limitDic={}--限购列表 KEY:shop_id VAL:num
My.storeDic={} --KEY:storeTp商店类型 VAL:key shop_id val:storeData

local idDic={} --key: propid_货币类型 value:id
local shop_id = nil
local shop_num = nil
local lerp_Money = nil


function My.Init()
	My.network.AddLnsr()

	My.SetStoreTb()
end

--表数据
--把表按商店类型分类
function My.SetStoreTb()
	for k,v in pairs(StoreData) do
		local storeTp=v.storeTp
		local tb=My.storeDic[tostring(storeTp)]
		if(tb==nil)then
			tb={}
			My.storeDic[tostring(storeTp)]=tb
		end
		tb[k]=v

		local key = tostring(v.PropId).."_".. v.priceTp
		idDic[key]=k
	end
end

--是否可购买
function My.CanBuy1(type_id,num)
	local id = tostring(type_id)
	for i=5,0,-1 do
		local tb=My.storeDic[tostring(i)]
		if tb then
			for k,v in pairs(tb) do
				if v.PropId==id then
					return My.IsBuy(v.id,num)					
				end
			end
		end
	end
	return false
end

--是否可购买
function My.CanBuy2(shopid,num,isLog)
	local temp = StoreData[tostring(shopid)]
	if not temp then
		if isLog~=false then
			local msg = "商城无此物品，无法购买";
            UITip.Log(msg);
		end
		return false
	end
	return My.IsBuy(shopid,num,isLog)			
end

--是否可购买
function My.CanBuy3(tp,type_id,num)
	local id = tostring(type_id)
	local dic = My.storeDic[tostring(tp)]
	if not dic then return false end
	for k,v in pairs(dic) do
		if v.PropId==id then
			return My.IsBuy(v.id,num)	
		end
	end
	return false
end

--购买的条件
function My.IsBuy(shopid,num,isLog)
	if not num then num=1 end
	local temp = StoreData[tostring(shopid)]
	if not temp then return false end
	shop_id=shopid
	shop_num=num
	--价格
	local isEnough=RoleAssets.IsEnoughAsset(temp.priceTp, temp.curPrice*num)
	if isEnough==false then
		if temp.priceTp==2 then 
			My.JumpRechange()
		end
		if isLog~=false then
			local des = RoleAssets:GetTypeName(temp.priceTp);
			local msg = string.format("%s不足",des);
            UITip.Log(msg);
		end
		return false 
	end
	--数量
	local islimit,canNum = My.IsLimit(shopid)
	if islimit==true then
		if isLog~=false then
			local msg="物品已售完!"
			if canNum>0 then msg= string.format("最多可购买%s个"..self.num)end
            UITip.Log(msg);
		end
		return false
	end
	--购买等级
	local lv = temp.lv or 0
	if lv>User.instance.MapData.Level then
		if isLog~=false then
			local msg = "角色等级不足";
            UITip.Log(msg);
		end
		return false
	end
	--限购VIP等级
	local vipLv = temp.vipLv or 0
	if vipLv>VIPMgr.GetVIPLv() then
		if isLog~=false then
			if IPMgr.GetVIPLv()<4 then
				self:UpVIPLv()
			else
				UITip.Log("达到Vip".. vip.."才可以购买")
			end
		end
		return false
	end
	--道庭等级限制
	local familyLv = temp.lvAstrict
	if familyLv~=0 then
		local isJoin = FamilyMgr:JoinFamily()
		if isJoin==false then
			if isLog~=false then
				local msg = "请先加入道庭再购买";
				UITip.Log(msg);
			end
			return false
		end
		if familyLv>FamilyMgr:GetFamilyData().Lv then
			if isLog~=false then
				local msg = "道庭等级不足";
				UITip.Log(msg);
			end
			return false
		end
	end
	--职业限制
	local cate = temp.cate
	if cate~=0 and cate~=User.instance.MapData.Category then
		if isLog~=false then
			local msg = "职业不符，无法购买";
            UITip.Log(msg);
		end
		return false
	end
	return true
end

function My:UpVIPLv()
	local msg = "当前VIP等级不足,是否前往升级VIP?"
	MsgBox.ShowYesNo(msg,self.UpVIPCb,self,"升级VIP")
end

function My:UpVIPCb()
	UIMgr.Open(UIV4Panel.Name)
end

--限购判断
function My.IsLimit(shopid)
	local id = tostring(shopid)
	local temp = StoreData[id]
	if not temp then iTrace.eError("xiaoyu","商城表为空 id: "..id)return false end
	local canPNum = temp.canPNum
	if not canPNum then return false end
	local limitNum = My.limitDic[id] or 0
	return limitNum==canPNum,canPNum-limitNum
end



--==============================--
--desc:道具id购买
--time:2019-09-20 05:49:04
--@type_id:道具id
--@num:数量（默认1）
--@isTip:询问是否购买
--@return 
--==============================--
function My.TypeIdBuy(type_id,num,isTip)
	local id = tostring(type_id)
	if id=="40003" then id="40001" end
	if not num then num=1 end
	local iscan = My.CanBuy1(id,num)
	if iscan==false then return false end
	if isTip==false then
		My.BuyCb()
	else
		My.BuyTip()
	end
end

--==============================--
--desc:商城id购买
--time:2019-09-20 05:49:54
--@shopid:商城id
--@num:数量（默认1）
--@isTip:询问是否购买
--@return 
--==============================--
function My.QuickBuy(shopid,num,isTip)
	local iscan = My.CanBuy2(shopid,num)
	if iscan==false then return false end
	if isTip==false then
		My.BuyCb()
	else
		My.BuyTip()
	end
	return true
end

--通过商店类型获取对应item的总价格
function My.GetTotalPriceByShopType(tp, type_id, num)
	local total = 0
	if not tp then return total end
	if not num then num = 1 end
	local shopid = My.GetStoreId(tp,type_id)
	local temp = StoreData[tostring(shopid)]
	total=temp.curPrice*num
	return total
end

--通过商店Id获取对应item的总价格
function My.GetTotalPriceByShopId(shopId, num)
	local total = 0
	if not tp then return total end
	if not num then num = 1 end
	local temp = StoreData[tostring(shopId)]
	total=temp.curPrice*num
	return total
end

function My.GetStoreId(tp,type_id)
	type_id=tostring(type_id)
	local tb=My.storeDic[tostring(tp)]
	if tb then
		for k,v in pairs(tb) do
			if v.PropId==type_id then
				return v.id
			end
		end
	end
	iTrace.eError("GS","商城没有这个商品可以购买 id: "..type_id)
end

--==============================--
--desc:获取总价格(不绑定元宝购买)
--time:2018-10-12 08:01:20
--@return 
--==============================--
function My.GetTotalPrice(type_id,num)
	if not num then num=1 end
	type_id=tostring(type_id)
	local total = 0
	for i=4,0,-1 do
		local tb=My.storeDic[tostring(i)]
		if tb then
			for k,v in pairs(tb) do
				if v.PropId==type_id then
					total=v.curPrice*num
					return total
				end
			end
		end
	end
	return total
end

function My.TypeIdTpBuy(tp,type_id,num,isTip)
	local id = tostring(type_id)
	if id=="40003" then id="40001" end
	if not num then num=1 end
	local iscan = My.CanBuy3(tp,type_id,num)
	if iscan==false then return false end
	if isTip==false then
		My.BuyCb()
	else
		My.BuyTip()
	end
end

--是否有足够钱购买
function My.IsCanBuyT(type_id, num)
	type_id=tostring(type_id)
	if type_id=="40003" then type_id="40001" end
	if not num then num=1 end
	local isEnough = My.CanBuy1(type_id, num)
	return isEnough
end

--能否购买
function My.IsCanBuy(type_id,num)
	type_id=tostring(type_id)
	if type_id=="40003" then type_id="40001" end
	if not num then num=1 end
	local isEnough = My.CanBuy1(type_id, num)
	return isEnough
end

--==============================--
--desc:元宝不足跳充值
--time:2018-12-18 02:58:57
--@return 
--==============================--
function My.JumpRechange()
	JumpMgr:Clear()
	MsgBox.ShowYesNo("元宝不足，是否充值？",My.yesCb)
end

function My.ReqBugGoods(id,num)
	if not num then num=1 end
	if not id then id=shop_id num=shop_num end
	My.network.ReqBugGoods(tonumber(id),tonumber(num))
end

--购买询问
function My.BuyTip()
	local store = StoreData[tostring(shop_id)]
	local price = store.curPrice*shop_num
	local id = store.PropId
	local name = store.name
	if id=="40001" then name="7天小精灵" elseif id=="40002" then name="7天小仙女" end
	local msg = string.format( "是否花费%s购买%s？",price,name)
	MsgBox.ShowYesNo(msg, My.BuyCb)
end

function My.BuyCb()
	local temp = StoreData[tostring(shop_id)]
	local priceTp = temp.priceTp
	local price = temp.curPrice*shop_num
	if priceTp==3 then 
		My.BindGoldTip(price)
	else
		My.GoldAndOtherTip(priceTp,price)
	end
end

--元宝和其他提示（除价格类型为3）
function My.GoldAndOtherTip(priceTp,price)
	local isenough = RoleAssets.IsEnoughAsset(priceTp,price)
	if isenough==false then
		UITip.Log(string.format( "%s不足",RoleAssets:GetTypeName(priceTp)))
		if priceTp==2 then --元宝 
			My.JumpRechange()
		end
	else
		My.ReqBugGoods()
	end
end

--价格类型为3，绑元and非绑购买提示
function My.BindGoldTip(price)
	local bindGold = RoleAssets.BindGold
	local lerp = price-bindGold
	if lerp>0 then 
		lerp_Money=lerp
		local tip=string.format( "绑元不足，不足部分是否用%s元宝购买？",lerp)
		MsgBox.ShowYesNo(tip, My.ReqBugGoods)
	else
		My.ReqBugGoods()
	end
end

function My.yesCb()
	VIPMgr.OpenVIP(1)
end


--打开商城界面
function My.OpenStore(tp)
	if not tp then tp=2 end
	storeTp=tp
	UIMgr.Open(UIStore.Name,My.StoreCb)
end

--高亮选择某个道具
function My.OpenStoreId(type_id)
	local tp,id = My.StoreToId(type_id)
	if tp==nil or id==nil then 
		UITip.Log("无法购买此道具")
		return 
	end
	StoreMgr.selectId=id
	My.OpenStore(tp)
end

--打开VIP商城
function My.OpenVIPStore(tp)
	if not tp then tp=1 end
	storeTp=tp
	UIMgr.Open(UIVIPStore.Name,My.StoreCb)
end

--高亮选择某个道具
function My.OpenVIPStoreId(type_id)
	local tp,id = My.VIPStoreToId(type_id)
	if tp==nil or id==nil then iTrace.eError("xiaoyu","商城没有此道具，请检查配置商城表 type_id: "..type_id)return end
	StoreMgr.selectId=id
	My.OpenVIPStore(tp-9)
end

function My.StoreToId(type_id)
	for i=5,0,-1 do
		local tb=My.storeDic[tostring(i)]
		if tb then
			for k,v in pairs(tb) do
				if v.PropId==tostring(type_id) then
					local isbuy = My.CanBuy2(v.id)
					if isbuy==true then 
						return i,k
					end
				end
			end
		end
	end
	return nil,nil
end

function My.VIPStoreToId(type_id)
	for i=10,11 do
		local tb=My.storeDic[tostring(i)]
		if tb then
			for k,v in pairs(tb) do
				if v.PropId==tostring(type_id) then
					return i,k
				end
			end
		end
	end
	return nil,nil
end

function My.StoreCb(name)
	local ui = UIMgr.Get(name)
	if ui then
		ui:SwatchTg(storeTp)
	end
end

--打开高亮选择某个道具
function My.OpenSelectId(type_id, tp)
	local tb = My.storeDic[tostring(tp)]
	if tb == nil then return end
	if tp == 99 then
		if CustomInfo:IsJoinFamily() == false then return end
	end
	local id = nil
	if type_id~=nil then
		for k,v in pairs(tb) do
			if v.PropId == tostring(type_id) then
				local cate = User.instance.MapData.Category
				local isShow = (v.cate==0) or (cate==v.cate)
				if isShow then id = k end
				break
			end
		end
		if id==nil then UITip.Log("无法在道绩商城购买此道具") return end
		StoreMgr.selectId = id
	end
	My.OpenStore(tp, id)
end

function My.Clear()
	TableTool.ClearDic(My.limitDic)
end

return My