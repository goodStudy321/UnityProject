-module(cfg_daily_mission).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(101, {c_daily_mission,101,"55~70级日常任务",10,"1,60000,1"})
?C(102, {c_daily_mission,102,"71~84级日常任务",10,"1,60000,1"})
?C(103, {c_daily_mission,103,"85~90级日常任务",10,"1,60000,1"})
?C(104, {c_daily_mission,104,"92~139级日常任务",10,"1,60000,1"})
?C(105, {c_daily_mission,105,"150~199级日常任务",10,"1,60000,1"})
?C(106, {c_daily_mission,106,"200~249级日常任务",10,"1,60000,1"})
?C(107, {c_daily_mission,107,"250~299级日常任务",10,"1,60000,1"})
?C(108, {c_daily_mission,108,"300~349级日常任务",10,"1,60000,1"})
?C(109, {c_daily_mission,109,"350~399级日常任务",10,"1,60000,1"})
?C(110, {c_daily_mission,110,"400~999级日常任务",10,"1,60000,1"})
?C(201, {c_daily_mission,201,"帮派任务",10,"32001,1,1"})
?C(202, {c_daily_mission,202,"帮派任务",10,"32001,1,1"})
?C(203, {c_daily_mission,203,"帮派任务",10,"32001,1,1"})
?C(204, {c_daily_mission,204,"帮派任务",10,"32001,1,1"})
?C(205, {c_daily_mission,205,"帮派任务",10,"32001,1,1"})
?CFG_E.