LJ
� 
 16  96 9 6 9 ' 9 +	 B=  9 '	 B.  -   9
+ B 9 ' B. -  9
+ B 6 9 ' 9 +	 B= 6 99 ' 9 9 	  BK  ��
Close	MaskSetLsnrClickUIToolBtnGrid/EquipSelfSetActiveGrid/EquipHas	Name	Grid	rootUIGrid	gridFindChildTransToolGetComTool� 
$  X�K  6   BX�6 99	 9		
 B
 9+ B6 9
 8   9 B-  -	  		 	 	<	ER�9  9	BK  �Reposition	NameSetBtnSelfUIToolSetActivetransformBtnFindChildTransToolipairs� 	 (9  9	  X�9 96 96  B8
  X�9
  X�9 X�' 6	 9
 9   BX�  9 BX�6 9' B  9 BK  
Close不能穿戴Log
UITipEquipCbShowYesNoMsgBox�您换下的为[67cc67]套装部件[-]，且无法转移到新的装备上，是否更换该装备[67cc67]（返还全部套装石头）[-]?suitLvtostringhasEquipDicEquipMgrwearParts
equipcanUse	item �   6  999 9 X�6 9' BK  6 9	9
 9) BK  idtbReqUsePropMgr 等级不足，无法穿戴Log
UITipuseLevel	item
LevelMapData	User�   9  9  X�6 9' BK  6 9' 9  9'	 B6
 9 9   B  9 BK  
CloseSaleCbShowYesNoMsgBox装备吗？	name你确定要出售ConcatStrTool该装备不可出售Log
UITip
price	item�  6  9-  B-  6 9 9B9 9<6 9-  BK  �ReqSellPropMgrnumidtbtostringClearDicTableToolX   6  96 99   B  9 BK  
Close
PutCb	NamePropSale	Open
UIMgrI   6  9 B  X� 99 BK  	itemUpDataGet
UIMgr     9  BK  
CloseI   6  96 99   BK  OpenEquip	NameUIEquip	Open
UIMgrF   6  9 B  X� 9) BK  SwatchTgGet
UIMgr     9  BK  
Close     9  BK  
Close     9  BK  
Close     9  BK  
Close�  	 9  
  X�9  9
  X�6  99  9) BX�6 9' ' B  9 BK  
CloseExchange error !!! LY
ErroriTraceReqFamilyExcDepotFamilyMgridtb�  	 9  
  X�9  9
  X
�4 9  9>6  9 BX�6 9' ' B  9 BK  
CloseDonate error !!! LY
ErroriTraceReqFamilyDonateFamilyMgridtb� 	 ] X:�6   B X�= 6 9 9B= X�6   B X�= X�6  B= 6 9 8= 6 9 9B6	 9
8
  X�9   X
�6 96 B= 9  9-  B9  9B9  9 B9   X
�6 96 B= 9  9- B9  9 B9  9B9 9= 9 9= 9  9BK  ��Reposition	grid	itemequipSelfUpData	Open	InitEquipRootGetObjPoolequipHashasEquipDicEquipMgrwearPartsEquipBaseTemp
equipstringtostringtype_idtb
table	type�  '9  
  X�6 99  B9 
  X�6 99 B+  =  +  = -   )   X�U�-  -   8 9+ B-  -   +  <X�K  �SetActiveequipSelfAddObjPoolequipHas�  , 56   9  9  6  95 B7 6 , 4  4  3 =3
 =	3 =3 =3 =3 =3 =3 =3 =3 =3 =3 =3 =3! = 3# ="3% =$3' =&3) =(3+ =*2  �L  CloseCustom UpData Donate Exchange SoldOut Buy 
PutIn GetOut OpenEquip Strengthen  
PutCb PutAway SaleCb 	Sale EquipCb 
Equip ShowBtn InitCustomEquipTip 	NameEquipTipNewUIBaseAssetMgr	Game
Loong 