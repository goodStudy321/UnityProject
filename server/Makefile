####################################################################
## @date 2016-03-31
## @description 编译脚本
## 使用 make Options[可选参数]
####################################################################

# 当前目录
SHELL := /bin/bash
SHELL_DIR := $(shell /bin/pwd)


# erlang 命令
ERL := /usr/local/bin/erl
ESCRIPT := /usr/local/bin/escript
EBIN_DIRS := ebin
EBIN_DIRS_INTER := $(addprefix ../../, $(EBIN_DIRS))

# erlang编译beam Options
MAKE_OPTS := {d, 'dummmmmy'}
# 编译mmake.er Options
MMAKE_OPTS := {d, 'dummmmmy'}


# 项目使用的核心模块
DEPS_DIRS := db lib log script time mongodb pbkdf2 poolboy bson deps/ejson deps/emysql deps/json deps/mochiweb deps/sync \
deps/recon deps/meck

# 编译代码保存的操作数据，如：hrl文件关联编译等
META_DIR := script/make/
ETS_MEAT_FILE =: script/make/ets_meta_config

# erlang 静态分析文件
DIALYZER_PLT := $(SHELL_DIR)/.dialyzer_plt
DIALYZER_MY_PLT := $(SHELL_DIR)/.my_plt
DIALYZER_OUTPUT := $(SHELL_DIR)/.dialyzer_output
# 预先判断是否静态分析文件
IS_DIALYZER_PLT := $(shell if [ -f $(DIALYZER_PLT) ]; then echo 1; else echo 0; fi;)


# erlang doc 文档生成参数
EDOC_OPTS=[{todo,true},{packages,false}]
EDOC_META=<meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\" />

ifdef MOUTPUT
  MMAKE_OPTS+=,{d,moutput}
endif

ifdef HIPE
  MAKE_OPTS+=,native,{hipe,o3}
endif

ifdef INLINE
  MAKE_OPTS+=,inline
endif

ifneq ($(DEBUG), false)
  MAKE_OPTS+=,debug_info
  MMAKE_OPTS+=,debug_info
endif

ifneq ($(TEST), false)
	MAKE_OPTS+=,{d,'TEST'}
	MMAKE_OPTS+=,{d,'TEST'}
endif

MAKE_OPTS+=,{d,'GREAT_THAN_70'}


# 项目配置参数
AGENT_CODE := $(shell $(ESCRIPT) ./script/tool/escript_tool.es $(SHELL_DIR) get_common_config agent_code)

ifndef SERVER_ID
	SERVER_ID := $(shell $(ESCRIPT) ./script/tool/escript_tool.es $(SHELL_DIR) get_common_config server_id)
endif

GAME_CODE := $(shell $(ESCRIPT) ./script/tool/escript_tool.es $(SHELL_DIR) get_common_config game_code)

PROCESS_NUMS := $(shell bash ./script/make/get_process_num.sh)
WORKER_NUMS := $(shell expr $(PROCESS_NUMS) + 1)

# 发布目录
RELEASE := /data/$(GAME_CODE)_$(AGENT_CODE)_$(SERVER_ID)/server

# ebin 根目录
RELEASE_EBIN := $(RELEASE)/ebin
RELEASE_SETTING :=  $(RELEASE)/setting


# 定位那些文件发生变化，即需要重新执行脚本重新生成

# game_proto.txt生成的文件
PROTO_DYN_FILES := include/all_pb.hrl src/gateway/gateway_proto_router.erl\
front/proto/GameProto.cs  front/proto/ProtoAlias.cs front/xml/Proto.xml src/gateway/gateway_switching_modules.erl

# map地图生成的文件
vpath %.bin config/map
vpath %.erl config/map_dyn
vpath %.beam ebin
MAP_SRC_FILES = $(wildcard config/map/*.bin)

# 任务配置
MISSION_DYN_FILES := config/dyn/cfg_mission.erl

# 掉落配置
DROP_DYN_FILES := config/dyn/cfg_drop.erl

# 仙盟Boss掉落配置
DROP_DYN_FILES := config/dyn/cfg_family_boss_drop.erl

# 成就配置
ACHIEVEMENT_DYN_FILES := config/dyn/cfg_achievement.erl

# 天书配置
GOD_BOOK_DYN_FILES := config/dyn/cfg_god_book.erl

# 掉落阈值控制
DROP_ITEM_DYN_FILES := config/dyn/cfg_drop_item.erl

# 7天目标配置
DAY_TARGET_DYN_FILES := config/dyn/cfg_day_target.erl

# 特殊掉落配置
DAY_SPECIAL_DROP_FILES := config/dyn/cfg_special_drop.erl

# 寻宝配置
TREASURE_DYN_FILES := config/dyn/cfg_rune_treasure.erl

# 元宝宏定义配置
GOLD_DYN_FILE := config/dyn/cfg_gold_log.erl

# 天机印强化表
INTENSIFY_DYN_NATURE := config/dyn/cfg_new_nature_intensify.erl

# hrl定义数据信息
HRLS = ${wildcard include/*.hrl}
RECORD_INFO_FILE := src/common/record_info.erl

# protobuff
PROTOBUFF = front/proto/proto.proto deps/enif_protobuf-master/deps/gpb/bin/proto.erl deps/enif_protobuf-master/deps/gpb/include/proto.hrl

# 模块配置信息
CFG_MODULE_ETC_FILE := config/dyn/cfg_module_etc.erl

# 配置文件 *.config
CFG_FILES := $(wildcard config/cfg/*.config)

# Makefile 伪目标
.PHONY: h help all clean dialyzer deploy setting proto config map\
init_make mmake make_pre make_proto make_module_etc make_mission make_drop make_achievement make_god_book make_drop_item make_special_drop make_treasure make_gold_config make_record_info make_proto make_map_multi make_user_default_hrl erl deps erl_compile compile make_nature_intensify
.DEFAULT_GOAL := help

h: help

help:
	@echo "用法:"
	@echo "  make 目标 编译选项"
	@echo "目标:"
	@echo "  help		        - 显示本信息"
	@echo "  all		        - 编译项目"
	@echo "  clean		        - 清理所有生成的代码"
	@echo "  rebuild 	        - 重编译make clean && make all"
	@echo "  erl		        - 编译所有erlang代码"
	@echo "  proto		        - 编译通信协议"
	@echo "  config                - 编译配置文件"
	@echo "  setting 	        - 拷贝setting到运行目录"
	@echo "  dialyzer 	        - 静态分析"
	@echo "  dialyzer_clean 	- 清除静态分析文件"
	@echo "编译选项:"
	@echo "  HIPE=true             - hipe编译"
	@echo "  INLINE=true           - 内链编译"
	@echo "  DEBUG=true            - 编译时添加debug_info"
	@echo "  DEP_HRL=true          - 表示编译时自动检查hrl文件，并关联重编译"
	@echo "  MOUTPUT=true          - 表示编译时打印所有日志输出"

# 编译全部
all: compile deploy

compile: init_make mmake make_pre make_proto make_module_etc make_mission make_drop make_achievement make_god_book make_drop_item make_special_drop make_treasure make_gold_config make_record_info make_map_multi make_user_default_hrl erl_compile make_nature_intensify

# 编译初始化
init_make:
	@(mkdir -p ebin)
	@(mkdir -p $(RELEASE_EBIN))
	@(mkdir -p $(SHELL_DIR)/deps/script/ebin)
	@(mkdir -p config/dyn)

# 编译mmake.erl可以执行多核编译项目
mmake:
	@(rm -f $(SHELL_DIR)/deps/script/ebin/mmake.beam)
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"deps/script/src/mmake.erl\"], [$(MMAKE_OPTS), {outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
	@(cp -rf ./deps/script/ebin/* ./ebin/)

# 提前编译的文件定义，一般是工具类，没有副作用的代码提前编译
make_pre:mmake
	@($(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"deps/lib/src/lib_tool.erl\",\
	\"deps/log/src/log_loglevel.erl\",\
	\"deps/lib/src/lib_config.erl\",\
	\"src/common/common_config.erl\"], \
	[$(MAKE_OPTS), {i,\"include\"}, {i,\"include\proto\"}, {i,\"config/erl\"}, {outdir, \"ebin\"}]) of error -> halt(1); _ -> halt(0) end")
	@(cd src/pre && $(ERL) -pa ../../ebin -noinput -meta_root ../../$(META_DIR) \
	-eval "case mmake:all($(WORKER_NUMS),[$(MAKE_OPTS), {outdir, \"../../ebin\"}]) of up_to_date -> halt(0); error -> halt(1) end");
	@(cd $(SHELL_DIR))


# proto协议生成 
make_proto:
	($(ESCRIPT) ./script/make/gen_proto.es)

# 地图文件生成
MAP_ERLS = ${MAP_SRC_FILES:config/map/%.bin=map_%.erl}
MAP_COMPILER = ebin/map_compile.beam

map_%.erl: %.bin
	@(echo "Recompile $<")
	@($(ESCRIPT) ${MAP_COMPILER} $< config/map_dyn/)

make_map_multi:
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"src/map/map_compile.erl\"], [$(MMAKE_OPTS), {outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
	@(make -j$(WORKER_NUMS) make_map)

make_map: ${MAP_COMPILER} ${MAP_ERLS}

# 任务配置
make_mission: $(MISSION_DYN_FILES)
$(MISSION_DYN_FILES) : config/excel/cfg_mission_excel.erl
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"config/excel/cfg_mission_excel.erl\"], [$(MMAKE_OPTS), {outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
	@($(ESCRIPT) ./script/make/gen_mission.es)


# 掉落配置
make_drop: $(DROP_DYN_FILES)
$(DROP_DYN_FILES) : config/excel/cfg_drop_config.erl config/excel/cfg_monster_i.erl config/excel/cfg_drop_boss.erl config/excel/cfg_equip_start_create_i.erl config/excel/cfg_drop_equip.erl config/excel/cfg_family_boss_drop.erl
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"config/excel/cfg_drop_boss.erl\",\"config/excel/cfg_drop_config.erl\", \"config/excel/cfg_monster_i.erl\", \"config/excel/cfg_drop_equip.erl\", \"config/excel/cfg_equip_start_create_i.erl\", \"config/excel/cfg_family_boss_drop.erl\"], [$(MMAKE_OPTS), {outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
	@($(ESCRIPT) ./script/make/gen_drop.es)


# 成就配置
make_achievement: $(ACHIEVEMENT_DYN_FILES)
$(ACHIEVEMENT_DYN_FILES) : config/excel/cfg_achievement_excel.erl
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"config/excel/cfg_achievement_excel.erl\"], [$(MMAKE_OPTS), {outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
	@($(ESCRIPT) ./script/make/gen_achievement.es)

# 天书系统
make_god_book: $(GOD_BOOK_DYN_FILES)
$(GOD_BOOK_DYN_FILES) : config/excel/cfg_god_book_excel.erl
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"config/excel/cfg_god_book_excel.erl\"], [$(MMAKE_OPTS), {outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
	@($(ESCRIPT) ./script/make/gen_god_book.es)

# D 掉落阈值控制
make_drop_item: $(DROP_ITEM_DYN_FILES)
$(DROP_ITEM_DYN_FILES) : config/excel/cfg_drop_item_excel.erl
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"config/excel/cfg_drop_item_excel.erl\"], [$(MMAKE_OPTS), {outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
	@($(ESCRIPT) ./script/make/gen_drop_item.es)

# 阈值掉落
make_special_drop: $(DAY_SPECIAL_DROP_FILES)
$(DAY_SPECIAL_DROP_FILES) : config/excel/cfg_special_drop_excel.erl
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"config/excel/cfg_special_drop_excel.erl\"], [$(MMAKE_OPTS), {outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
	@($(ESCRIPT) ./script/make/gen_special_drop.es)

# 寻宝
make_treasure: $(TREASURE_DYN_FILES)
$(TREASURE_DYN_FILES) : config/excel/cfg_rune_treasure_excel.erl
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"config/excel/cfg_rune_treasure_excel.erl\"], [$(MMAKE_OPTS), {outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
	@($(ESCRIPT) ./script/make/gen_treasure.es)

# 天机印强化表
make_nature_intensify: $(INTENSIFY_DYN_NATURE)
$(INTENSIFY_DYN_NATURE) : config/excel/cfg_nature_intensify.erl
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	-eval "case make:files([\"config/excel/cfg_nature_intensify.erl\"], [$(MMAKE_OPTS), {outdir, \"deps/script/ebin\"}]) of error -> halt(1); _ -> halt(0) end."
	@($(ESCRIPT) ./script/make/gen_nature_intensify.es)


make_gold_config: $(GOLD_DYN_FILE)
$(GOLD_DYN_FILE) : include/behavior_log.hrl
	@($(ESCRIPT) ./script/make/gen_gold_log.es)

$(GOLD_LOG) : config/excel/cfg_mission_excel.erl
# record info 生成【HRL】定义数据结构信息
make_record_info: $(RECORD_INFO_FILE)
$(RECORD_INFO_FILE): ${HRLS}
	($(ESCRIPT) ./script/make/gen_record_info.es)

# 模块配置信息
make_module_etc: $(CFG_MODULE_ETC_FILE)
$(CFG_MODULE_ETC_FILE): src/role/*/*.erl
	($(ESCRIPT) ./script/make/gen_cfg_module.es)

# user_default.hrl的生成
make_user_default_hrl:
	@($(ESCRIPT) ./script/make/gen_user_default_hrl.es)

# 编译erl文件并拷贝
erl: erl_compile deploy

erl_compile: init_make mmake make_pre deps
	@mkdir -p $(RELEASE_EBIN)
	@$(ERL) -pa $(EBIN_DIRS) -noinput -meta_root $(META_DIR) \
	  -eval "case mmake:all($(WORKER_NUMS),[$(MAKE_OPTS)]) of up_to_date -> halt(0); error -> halt(1) end."

# 编译核心代码
deps:
	@for deps_dir in $(DEPS_DIRS); \
	do \
	( if [ -d ./deps/$$deps_dir/ebin ]; then cp -rf ./deps/$$deps_dir/ebin/* ./ebin/ ;  fi; \
	  if [ -d ./deps/$$deps_dir/app ]; then cp -rf ./deps/$$deps_dir/app/* ./ebin/ ;  fi;); \
	done
	@(cd ./deps/ && $(ERL) -pa ../ebin  -noinput -meta_root ../$(META_DIR) \
	-eval "case mmake:all($(WORKER_NUMS),[$(MAKE_OPTS)]) of up_to_date -> halt(0); error -> halt(1) end.")
	@(cd ..)

####@(/bin/cp -rf ./deps/enif_protobuf-master/priv/enif_protobuf.so ebin/)

# 重新编译
rebuild: clean all

pre: make_pre

map: make_map_multi

# 编译协议
proto: make_pre make_proto

# 编译配置文件
config: init_make mmake make_pre make_map_multi make_module_etc make_mission make_drop make_achievement make_gold_config make_record_info

# 编译生成前端配置
front: init_make mmake make_pre make_proto

# 清除
clean:
	@(rm -rf user_default.beam)
	@(rm -rf $(ETS_MEAT_FILE))
	@(rm -rf ebin/*; rm -rf *.dump)
	@(rm -rf config/dyn/*)
	@(rm -rf $(PROTO_DYN_FILES))
	@(rm -rf $(PROTOBUFF))
	@(rm -rf $(SHELL_DIR)/deps/script/ebin)
	@(rm -rf include/proto/*)
	@(rm -f $(CFG_MODULE_ETC_FILE))
	@(rm -rf config/map_dyn/*)
	@(mkdir -p $(SHELL_DIR)/deps/script/ebin)

# 发布服务
deploy:
	@(mkdir -p $(RELEASE))
	@(mkdir -p $(RELEASE_EBIN))
	@(mkdir -p $(RELEASE_SETTING))
	@(/bin/rm -rf $(RELEASE)/ebin/*)
	@(/bin/rm -rf $(RELEASE)/config/{app,dyn,erl,excel,map_dyn})
	@(/bin/rm -f $(RELEASE)/config/start_config.json)
	@(/bin/cp -rf config/app/*.app ebin/)
	@(/bin/cp -rf ebin/user_default.beam $(RELEASE))
	@(/bin/cp -rf ebin/*.app $(RELEASE_EBIN) 2> /dev/null)
	@(/bin/cp -rf ebin/*.beam $(RELEASE_EBIN))
	@(/bin/cp -rf ebin/user_default.beam .)
	@(mkdir -p $(RELEASE)/config)
	@(/bin/cp config/start_config.json $(RELEASE)/config)
	@(mkdir -p $(RELEASE)/script/tool)
	@(/bin/cp -rf script/run $(RELEASE)/script/)
	@(/bin/cp -rf script/update $(RELEASE)/script/)
	@(/bin/cp -rf script/tool/{escript_tool.es,lixiancheji.sh} $(RELEASE)/script/tool/)
	@(/bin/cp -f mgectl $(RELEASE)/mgectl)
	@(/bin/cp -f server_version.txt $(RELEASE)/server_version.txt)
	@(/bin/cp -f setting/common.config $(RELEASE_SETTING))

# 部署setting配置
setting:
	@(mkdir -p $(RELEASE_SETTING))
	@(cp setting/common.config $(RELEASE_SETTING))

# dialyzer分析
dialyzer: .dialyzer_plt
	make clean
	make compile GEN_PROTO_TEMPLATE=false DEBUG=true TEST=false
	rm -fr ebin/rfc* ebin/meck* ebin/recon* ebin/gateway_packet*
	dialyzer -n --plt .dialyzer_plt ebin

.dialyzer_plt:
	dialyzer --build_plt --apps erts kernel stdlib compiler xmerl ssl crypto inets percept runtime_tools syntax_tools tools  --output_plt .dialyzer_plt

# dialyzer clean
dialyzer_clean:
	rm -fr .dialyzer_plt

