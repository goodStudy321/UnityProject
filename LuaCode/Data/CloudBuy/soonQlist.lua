--==============================--
--desc:soon
--time:2018-12-12 04:59:49
--@return 
--==============================---
soonQlist=Super:New{Name="soonQlist"};
local My = soonQlist;
--逆向队列
function My:Ctor()
    self.qlist={};
end

function My:Creat(len)
    self.len=len;
end

function My:Add(num)
    if num ==nil then
        return nil;
    end
    if type(num) ~="table" then
        self:Addnum(num)
    else
        for i=#num,1,-1 do 
            self:Addnum(num[i])
        end
    end
    return self.qlist;
end

function My:Addnum( num )
    table.insert( self.qlist,1,num)
    if self.len==nil then
        return;
    end
    if #self.qlist>self.len then
        self:Remove( )
    end
end

function My:Remove( )
    soonTool.ClearList(self.qlist)
end

function My:Dispose( )
    while #self.qlist>0 do
        self:Remove( )
    end
end

return My;