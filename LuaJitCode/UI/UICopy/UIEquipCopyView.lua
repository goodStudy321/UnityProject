LJ
    L  �   F9  = 96 96 9 6 	 '
  + B=  6
 	 '
	  + B=	   '	 B=   '	 B=   '	 B=  6 	 '
  + B=  6 	 '
  + B=   '	 B= 4  = +  =   9 B  9 BK  InitDataInitEventSelectItem
ItemsScrollView/Grid/ItemPrefabScrollView/GridUIGrid	GridScrollViewUIScrollView
PanelCleanMatch	Btn3Button2	Btn2Button1	Btn1UIButtonNumBtnUILabelNumFindChildTransToolGetComTooltransformgo	Name�  
 #6  99   X� 9 9   B9   X� 9 9   B9   X� 9 9   B9   X� 9 9	   BK  OnClickBtn3	Btn3OnClickBtn2	Btn2OnClickBtn1	Btn1OnClickNumBtnNumBtnSetLsnrSelfUITool�   06  9  X�K  6  98  X�K  99 )  ) M�8
	 
 X�6 
 B8  X�  9 
  BO�9  9B  9	 	 B  9
 B  9 BK  UpdateBtnStatusUpdateSelectUpdateDataReposition	GridAddItemtostringDicIndexOf
Equip	CopyCopyMgr�   *6  99 B6  B=99 9=6	 9
=6	 9= 9+	 B6 9 B	 9B	 9
 B9 <6 9	 9
   BK  ClickItemsSetLsnrSelfUITool
ItemsUpdateInfo	InitNewUICellEquipCopyItemSetActive	zerolocalPositiononeVector3localScale	Gridparenttransform	nametostringPrefabInstantiateGameObject� 
 G-  9 -  9+ +   X�99  X�+ X�+  X�6 	 B6 99 X�+ X�+ 9   X�9  9	  X� X	�+ X	�+ B9
   X�9
  9	  X� X� X	�+ X	�+ B9   X	�9  9	 X� X� BK  �	Btn3	Btn2SetActive	Btn1UIDStrMapData	UsertostringCaptIdTeamIdIsMatchingTeamInfo*   =    9 BK  UpdateNum	Data�   7'  9   X�K  6 96 9B89  X�99 6	 9
' 	 
 B X�6	 9
'	 
 B X�6	 9
'	 
 B 9   X�9 =9   X�9 )    X�+ X�+ =K  EnabledNumBtn	text[ff0000]%s[-][F8D7B4]%s[-](%s/%s)formatstringBuyNumnum	typetostring	CopyCopyMgr	Temp�  	 6   96  9B  X�9 6 99B  X�8  X�  9 89BK  GOClickItemsid	Temptostring
Items
EquipGetCurCopyCopyMgr� 
  09 9 8  X�K   9B X�K  9   X�9 99 99  X�K  9  9+ B=  9+ B9= 6 96 9	8  X�K    9
 	 BK  UpdateData
Equip	CopyCopyMgr	TempIsSelectGOSelectItemIsOpen
Items	name�   9  6   X�K  6 96 9B89  X�99!6 9	6	
 9		'  B	9
   BK  OnBuyCopyNum2还能购买%s次副本进入,是否购买？formatstringShowYesNoMsgBoxBuybuy	typetostring	CopyCopyMgr	item	Temp�  '9    X�K  6 96 9B89  X�99!	  X�6 9'	 BK  6
 999 X	�6 96 9'
 9B A K  K  C购买进入次数需要%s元宝。元宝不足，不能购买formatstring
bCost	GoldinstanceRoleAssets>已达到今日的购买上限，不能继续购买次数ShowYesMsgBoxBuybuy	typetostring	CopyCopyMgr	Temp � 
 @9    X�6 9' BK  6 99  X�6 9' BK  6 9	9
9 X�6 9' BK  -  9 X�-   99+ B6 99B)   X�-   99+	 BX�6 99+ B6 96 9BK  �	NameUICopy
Close
UIMgrReqPreEnterMgrReqStartCopyTeamPlayerLengthLuaToolidReqTeamMatchIsMatching)进入失败，不满足进入等级lv
LevelMapData	User需要队伍才能进入TeamIdTeamInfoTeamMgr没有副本信息ShowYesMsgBox	Temp� 
 /9    X�6 9' BK  6 99  X
�6 96	 9
9   B9 BK  6 96 99B-  9 X�6 9' BK  -   999-	  9		BK  �LimitLvlvidReqSetCopyTeam队伍成员已满PlayerLimitPlayerLengthLuaTooleCloseOpenUITeam	NameUITeam	Open
UIMgrTeamIdTeamInfoTeamMgr没有副本信息ShowYesMsgBox	Temp)   6  98  X �K  Dic
UIMgr|  9    X�6 9' BK  -   99+ BK  �idReqTeamMatch没有副本信息ShowYesMsgBox	Temp�   6  96  98  X�K    9  B  9 B  9 BK  UpdateSelectUpdateUserLvUpdateData
Equip	CopyCopyMgrV 
  9    X	�6  BH�	 9BFR�K  UpdateRealInfo
pairs
Items�  	 +  =  9   X�9  9B6 99 B+  = +  = +  = +  = +  = K  go
TableTypePrefab
ItemsAddObjPoolDispose	RectSelectItem�  + 14   7   6   '  = 6 6 B= 3 = 3 = 3
 =	 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3  = 3" =! 3$ =# 3& =% 3( =' 3* =) 2  �K   Dispose UpdateUserLv UpdateCopyData OnClickBtn3 OpenUITeam OnClickBtn2 OnClickBtn1 OnBuyCopyNum OnClickNumBtn ClickItems UpdateSelect UpdateNum UpdateData UpdateBtnStatus AddItem InitData InitEvent 	Init New
EventeCloseTeamMgr	NameUIEquipCopyView 