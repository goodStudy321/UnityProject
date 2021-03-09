﻿--******************************************************************************
-- Copyright(C) Phantom CO,.LTD. All rights reserved
-- Created by Loong's tool. Please do not edit it.
-- proto:W_五行幻境.xml, excel:W 五行幻境.xls, sheet:Sheet1
--******************************************************************************
tFvFloor={}
local We=tFvFloor
We[1]={CopyLv=1, CopyName="一层幻境", CopyNeed={811001, 821001, 831001, 841001, 851001, 861001, 871001, 881001}, NextGet={812002, 822002, 832002, 842002, 852002, 862002, 872002, 882002}, MapName="", illMax=96, illSpeed=0.0667, natMax=60000, natSpeed=125, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[2]={CopyLv=2, CopyName="二层幻境", CopyNeed={812002, 822002, 832002, 842002, 852002, 862002, 872002, 882002}, NextGet={813003, 823003, 833003, 843003, 853003, 863003, 873003, 883003}, MapName="", illMax=120, illSpeed=0.0833, natMax=72000, natSpeed=150, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[3]={CopyLv=3, CopyName="三层幻境", CopyNeed={813003, 823003, 833003, 843003, 853003, 863003, 873003, 883003}, NextGet={813004, 823004, 833004, 843004, 853004, 863004, 873004, 883004}, MapName="", illMax=144, illSpeed=0.1, natMax=84000, natSpeed=175, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[4]={CopyLv=4, CopyName="四层幻境", CopyNeed={813004, 823004, 833004, 843004, 853004, 863004, 873004, 883004}, NextGet={813105, 823105, 833105, 843105, 853105, 863105, 873105, 883105}, MapName="", illMax=168, illSpeed=0.1167, natMax=96000, natSpeed=200, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[5]={CopyLv=5, CopyName="五层幻境", CopyNeed={813105, 823105, 833105, 843105, 853105, 863105, 873105, 883105}, NextGet={814106, 824106, 834106, 844106, 854106, 864106, 874107, 884107}, MapName="", illMax=192, illSpeed=0.1333, natMax=108000, natSpeed=225, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[6]={CopyLv=6, CopyName="六层幻境", CopyNeed={814106, 824106, 834106, 844106, 854106, 864106, 874107, 884107}, NextGet={814107, 824107, 834107, 844107, 854107, 864107, 874106, 884106}, MapName="", illMax=216, illSpeed=0.15, natMax=120000, natSpeed=250, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[7]={CopyLv=7, CopyName="七层幻境", CopyNeed={814107, 824107, 834107, 844107, 854107, 864107, 874106, 884106}, NextGet={814207, 824207, 834208, 844208, 854208, 864208, 874207, 884207}, MapName="", illMax=240, illSpeed=0.1667, natMax=132000, natSpeed=275, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[8]={CopyLv=8, CopyName="八层幻境", CopyNeed={814207, 824207, 834208, 844208, 854208, 864208, 874207, 884207}, NextGet={814208, 824208, 834209, 844209, 854209, 864209, 874208, 884208}, MapName="", illMax=264, illSpeed=0.1833, natMax=144000, natSpeed=300, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[9]={CopyLv=9, CopyName="九层幻境", CopyNeed={814208, 824208, 834209, 844209, 854209, 864209, 874208, 884208}, NextGet={815109, 825109, 835110, 845110, 855110, 865110, 875109, 885109}, MapName="", illMax=288, illSpeed=0.2, natMax=156000, natSpeed=325, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[10]={CopyLv=10, CopyName="十层幻境", CopyNeed={815109, 825109, 835110, 845110, 855110, 865110, 875109, 885109}, NextGet={815110, 825110, 835111, 845111, 855111, 865111, 875110, 885110}, MapName="", illMax=312, illSpeed=0.2167, natMax=168000, natSpeed=350, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[11]={CopyLv=11, CopyName="十一层幻境", CopyNeed={815110, 825110, 835111, 845111, 855111, 865111, 875110, 885110}, NextGet={815211, 825211, 835212, 845212, 855212, 865212, 875211, 885211}, MapName="", illMax=336, illSpeed=0.2333, natMax=180000, natSpeed=375, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[12]={CopyLv=12, CopyName="十二层幻境", CopyNeed={815211, 825211, 835212, 845212, 855212, 865212, 875211, 885211}, NextGet={815212, 825212, 835213, 845213, 855213, 865213, 875212, 885212}, MapName="", illMax=360, illSpeed=0.25, natMax=192000, natSpeed=400, dec="[F4DDBDFF]通关本层，获得以下[F39800FF]天机印(%s/8)[-]\n则可进入下层幻境[-]"}
We[13]={CopyLv=13, CopyName="十三层幻境", CopyNeed={815212, 825212, 835213, 845213, 855213, 865213, 875212, 885212}, NextGet={}, MapName="", illMax=384, illSpeed=0.2667, natMax=204000, natSpeed=425, dec="[F4DDBDFF]集齐以下[F39800FF]天机印[-]\n成就最强套装属性[-]"}
