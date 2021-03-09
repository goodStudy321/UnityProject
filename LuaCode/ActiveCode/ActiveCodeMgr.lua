--[[
 	authors 	:Liu
 	date    	:2018-5-28 14:42:08
 	descrition 	:激活码管理
--]]

ActiveCodeMgr = {Name = "ActiveCodeMgr"}

local My = ActiveCodeMgr

function My:Init()
    self:AddLnsr()
    self.eActCode = Event()
end

--添加监听
function My:AddLnsr()
    ProtoLsnr.Add(21072,self.RespActCode, self)
end

--移除监听
function My:RemoveLsnr()
	ProtoLsnr.Remove(21072,self.RespActCode, self)
end

--请求激活码
function My:ReqActCode(code)
    local msg = ProtoPool.GetByID(21071)
    msg.code = code
	ProtoMgr.Send(msg)
end

--响应激活码
function My:RespActCode(msg)
    local err = msg.err_code
    if (err>0) then
        MsgBox.ShowYes(ErrorCodeMgr.GetError(err))
        return
    else
        self.eActCode(err)
    end
end

--清理缓存
function My:Clear()
    
end

--释放资源
function My:Dispose()
    self:RemoveLsnr()
end

return My