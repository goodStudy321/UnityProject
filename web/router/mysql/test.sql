delimiter //
use router
drop procedure if exists looppc;
create procedure looppc()
begin 
declare i int;
set i = 2;

repeat 
    insert into server (id) values (i+1);
    set i = i + 1;
until i >= 100

end repeat;

end //
---- 调用
call looppc()