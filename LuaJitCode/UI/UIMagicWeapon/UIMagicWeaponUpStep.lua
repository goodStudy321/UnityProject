LJ
    L  <  	-  9   X�-  9   BK   �OnShowSkillTip;  	-  9   X�-  9   BK   �OnShowItemTip;  	-  9   X�-  9   BK   �OnShowItemTip]  -  9 9 X�-  9  X�-  9  BK   �OnUpdateFightactiveSelfgo� + s9  = 9 96 96 9 6 	 '
  + B=  6
 	 '
  + B=	  6
 	 '
  + B=  6 	 '
  + B=  6 	 '
  + B=   '	 B= 6 96 B= 9  9	  ' B	 A9 3 =6 96 B= 9  9	  ' B	9
 B9 3! = 6 96# B=" 9"  9	  '$ B	 A9" 3% = 9" 3' =&+  =(   9) B  9* B2  �K  AddEventInitData
Items OnShowFight StepPropertyUIMagicWeaponPropertyPropertyView OnShowItemTipOnShowTipActiveUIMagicWeaponActiveActiveView OnShowSkillTip
Skill	InitUIMagicWeaponSkillObjPoolSkillViewList/ScrollView/Grid/ItemPrefabList/ScrollView/GridUIGrid	GridList/ScrollViewUIScrollView
PanelBackBtntranBtnUIButtonEquipBtnUILabel	StepFindChildTransToolGetComTooltransformgo	Name�  	 #6  99   X� 9 9   B9   X� 9 9   B9   X�) 9  ) M� 9 899	 
  BO�K  OnClickCellgameObject
SkillOnClickTranBtnEquipBtnOnClickBackBtnBackBtnSetLsnrSelfUITool;   	9    X�4  =    9 BK  InitItems
Items� 
  ) 6  9 ) M�6 6  98B6  98  X�  9 6	  9		8		BO�  9 BK  GridRepositionAddItemDictostringIDListMagicWeaponMgr� 	  /  X�K  6  9B6 99 B=99 9=96
 9=	96
 9=6 9 9   B9 6 9 B<9 8 9B9 8 9 BK  UpdateData	InitNewUICellMagicWeapon
ItemsOnClickItemSetLsnrSelfUIToolonelocalScale	zeroVector3localPosition	Gridparenttransform	namePrefabInstantiateGameObject
KeyIDtostringA   	  9   B  9  BK  UpdateDataUpdateList{     X�K  6  9B9   X�9 8  X�K  9 8 9 BK  UpdateData
Items
KeyIDtostring�   9  X�K  =  9  X�K  9 6 9B=9  9 B9 X�9	  9 B9
  9+ B9	  9+ BX�9
  9 B9
  9+ B9	  9+ B  9  BK  UpdateEquipSetActiveActiveViewPropertyViewIsActiveUpdateDataSkillView	steptostring	text	Step	Info	Datan   6  9B6  9 + B9  BK  OnSelectCellGetIndexMagicWeaponMgr	nametonumber�   9    X�K  9  9  X�K    X�K  9  X�6 9
  X�6 99 X�+ X�+ 9  =K  IDCurEquipIDMagicWeaponMgrIsActiveEnabledEquipBtnj   9    X�K  9  8  X�K   9B  9 9BK  	DataUpdateDataIsSelect
Items    9  BK  OnShowLvView�   9    X�6 9' ' BK  6 99  9BK  IDreqMagicWeaponEquipMgr#没有法宝可以幻化！！hs
ErroriTrace	Dataj   9    X�9   9B9   X�9  9BK  PropertyViewUpdateItemListActiveViewA   9    X�9   9BK  UpdateNimbusPropertyView�   9   9B9   9B9)  X�9 + =X�9 + =K  isDrag
Panel
CountGetChildListReposition	Grid�   9    X�9   9 B X�9 ) B9   X�9  99 BK  	DataUpdateDataPropertyViewOnSelectCellSetActivego�   W9   9B9   X�9  9  )   X�U�9  9 8 9B9 +  <6 99  BX�9   X�9  9B6 99 B+  = 9	   X�9	  9B6 99	 B+  =	 9
   X�9
  9B6 99
 B+  =
 +  = +  = +  = +  = +  = +  = +  = +  = K  Prefab	Grid
PanelgoEquipBtnRightBtnLeftBtn	StepSkillViewActiveViewAddObjPoolPropertyViewremove
tableDispose
Items
ClearOnShowLvView�  / ;4   7   6   ' = 6 B= 6 B= 6 B= 6 B= 6 B= 3
 =	 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3  = 3" =! 3$ =# 3& =% 3( =' 3* =) 3, =+ 3. =- K   Dispose SetActive GridReposition NimbusUpdate UpdateItemList OnClickTranBtn OnClickBackBtn SelectItem UpdateEquip OnClickItem UpdateData UpdateList UpdateActive AddItem InitItems InitData AddEvent 	Init NewOnUpdateFightOnShowItemTipOnSelectCellOnShowSkillTip
EventOnShowLvViewUI法宝进阶界面	NameUIMagicWeaponUpStep 