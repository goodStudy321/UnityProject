-module(cfg_friendly_level).
-include("config.hrl").
-export[find/1].
-compile({parse_transform, config_pt}).
?CFG_H

?C(1, {c_friendly_level,1,"萍水相逢",0,[]})
?C(2, {c_friendly_level,2,"相见恨晚",999,[303002]})
?C(3, {c_friendly_level,3,"志同道合",1999,[303003]})
?C(4, {c_friendly_level,4,"患难与共",3344,[303004]})
?C(5, {c_friendly_level,5,"义结金兰",5200,[303005]})
?C(6, {c_friendly_level,6,"情深似海",9999,[303006]})
?C(7, {c_friendly_level,7,"肝胆相照",16920,[303007]})
?C(8, {c_friendly_level,8,"亲密无间",28920,[303008]})
?C(9, {c_friendly_level,9,"心有灵犀",49999,[303009]})
?C(10, {c_friendly_level,10,"心心相印",99999,[303010]})
?CFG_E.