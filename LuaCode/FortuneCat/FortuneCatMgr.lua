--[[
    招财猫管理类
]]


FortuneCatMgr = Super:New{Name = "FortuneCatMgr"};
local My = FortuneCatMgr;

My.LogList= {};
My.drawCount = 0;
My.rate = 0;
My.wardItem = {{k = 0,v = 0,b = false}};
My.eUpdateLog = Event();
My.eUpdateRate = Event();
My.CfgNum = 0;
function My:Init()
    
  self:CalCount();
  self:SetLsnr(ProtoLsnr.Add);
end

function My:SetLsnr(fun)
  fun(27008, self.ResqLogInfo, self);
  fun(27010, self.ResqLogAddInfo, self);
  fun(27012, self.ResqAwardInfo, self);
end

--打开面板
function My:OpenUI()
  UIMgr.Open(UIFortuneCatPanel.Name);
end

--上线推送，抽奖记录
function My:ResqLogInfo(msg)
  local list = msg.logs;
  My.drawCount = msg.times + 1;
  My.LogList = {};
  
  for k,v in ipairs(list) do
    local tab ={name = v.name, 
                consumeGold = v.consume_gold,
                rate = v.rate/100,
                addGold = v.add_gold}
    table.insert(My.LogList,tab);
  end
end

--抽奖之后返回，一次抽奖记录
function My:ResqLogAddInfo(msg)
  local log = msg.logs;
  for k,v in ipairs(log) do
    local tab ={name = v.name, 
                consumeGold = v.consume_gold,
                rate = v.rate/100,
                addGold = v.add_gold}
    table.insert(My.LogList,1,tab);
  end
  --My.eUpdateLog();
end

--抽奖请求
function My:ReqAward()
  local msg = ProtoPool.GetByID(27011);
  msg.times = self.drawCount;
  ProtoMgr.Send(msg);
end

--计算FortuneCatCfg数量
function My:CalCount()
  local num = 0;
  local cfg = FortuneCatCfg;
  for k,v in pairs(cfg) do
    num = num + 1;
  end
  My.CfgNum = num;
end

--抽奖返回的奖励信息
function My:ResqAwardInfo(msg)
  local error = msg.err_code;
  if error ~= nil and error > 0 then
    local errStr = ErrorCodeMgr.GetError(error);
    UITip.Error(errStr);
    My.eUpdateRate(false);
    return ;
  else
    
    My.rate = msg.rate;
    self.drawCount = self.drawCount +1;
    My.wardItem[1].k = msg.gold_list[1].id;
    My.wardItem[1].v = tostring(msg.gold_list[1].val);
    My.wardItem[1].b = false;
    My.eUpdateRate(true);
  end
  UIFortuneCatPanel:ShowBtnLab();
end

function My:Clear()
  self.LogList ={};
  My.drawCount = 0;
  My.rate = 0;
  My.wardItem = {{k = 0,v = 0,b = false}};
end


return My;