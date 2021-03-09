-module(cfg_robot_offline_solo).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C({2000,3000}, {c_robot_offline_solo,2000,3000,[65,68],90,108930,30000,50000})
?C({1000,1999}, {c_robot_offline_solo,1000,1999,[68,72],100,130282,50000,100000})
?C({500,999}, {c_robot_offline_solo,500,999,[72,75],110,138966,100000,150000})
?C({300,499}, {c_robot_offline_solo,300,499,[75,78],120,148170,150000,200000})
?C({100,299}, {c_robot_offline_solo,100,299,[78,82],130,156854,200000,250000})
?C({50,99}, {c_robot_offline_solo,50,99,[82,85],140,165538,250000,300000})
?C({11,49}, {c_robot_offline_solo,11,49,[85,88],150,279277,300000,400000})
?C({1,10}, {c_robot_offline_solo,1,10,[88,92],160,288481,400000,500000})
?CFG_E.