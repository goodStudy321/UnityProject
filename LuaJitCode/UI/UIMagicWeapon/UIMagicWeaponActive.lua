LJ
    L  �   79  = 96 96 94  = 9  6	 
 '	  + B>9  6	 
 '
  + B>6 9 
 ' B A =  6 	 '
  + B= 9  9B)  = )  =   9 BK  AddEventNeedMaterialNumCurMaterialNum	InitUIButtonActiveBtnActiveMaterialNewUICellQualityMaterialCell
Need2
Need1UILabel	NeedFindChildTransToolGetComTooltransformgameObject	Name�   6  99   X� 9 9   B9   X� 9 99   BK  OnClickCellgameObjectMaterialCellOnClickActiveBtnActiveBtnSetLsnrSelfUITool�  4  X�K  =    9 B6 6 9B8= 6 6 9B8= 9   X�K  9 9  X�  9	 9 99 9
B9 9  X�  9 9 99 9BX�+  =   9 BK  UpdateItem	ItemMatNumUpdateMaterialId
matIdneedLvUpdateMagicWeaponIdneedIdNextIDNextInfoIDtostringMagicWeaponTemp	InfoHideNeed	Data � 	  6  6  B8  X�K  6 9' 9 B  9  BK  SetNeedDes	name[ff0000]%s[-]%s阶formatstringtostringMagicWeaponTemp�  
 "9  
  X�9  
  X
�9  9 X�6 6  B8=  9  
  X�6 9' 9  9 B  9  B  9	 BK  UpdateItemSetNeedDes	name获得[ff0000]%s[-]×%sformatstringtostringItemDataid	Item� 	  A, 9    X�+  )  +  )  = )  = X%�9  99  96 99  9B= 9 9	= 6
 9' 9 9 B 9 9  X�6
 9'  B X�6
 9'  B 9  9 B9  9 B9  9 BK  UpdateLabelUpdateQualityUpdateIconMaterialCell[ffffff]%s[-][ff0000]%s[-]
%s/%sformatstringMatNum	InfoidTypeIdByNumPropMgrquality	iconNeedMaterialNumCurMaterialNum	Item�   6  9 BX�99 X�=9	 9+
 BK  ER�K  SetActive	textactiveSelfgameObject	Needipairs"     9  BK  UpdateItem�  D9    X�K  9  9
  X�9  9  X	�9 9  X�6 9' BK  6 6 9  9	B8
  X�9
9  9 X
�6 96 9' 99	B A K  9  96 9 B  X
�6 9' 6 9'
  B AK  6 9 ) BK  ReqUse%未从道具表找到指定id:%shsiTraceTypeIdByIdPropMgr	name*激活失败，%s等级未达到lv.%sformatstringneedLv	stepneedIdtostringMagicWeaponTemp)激活失败，材料不足！！！
Error
UITipNeedMaterialNumCurMaterialNum
matId	Info `   9    X�9  9  X�K  9   X�9 9  9BK  OnShowItemTip
matId	InfoX 
  6  9 BX�9 9+	 BER�K  SetActivegameObject	Needipairs@   	9    X�9   9 BK  SetActivegameObject�   *9    X�9   )   X�U�6 99  BX�+  =  9   X�9  9B+  = +  = +  = +  = +  = +  =	 +  =
 +  = +  = K  	ItemNextInfo	Info	DataNeedMaterialNumCurMaterialNumActiveBtngameObjectDisposeMaterialCellremove
table	Need�    $4   7   6   +  = ' = 3 = 3 = 3	 = 3 =
 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = 3 = K   Dispose SetActive HideNeed OnClickCell OnClickActiveBtn UpdateItemList SetNeedDes UpdateItem UpdateMaterialId UpdateMagicWeaponId UpdateData AddEvent 	Init NewUI法宝界面激活窗口	NameOnShowItemTipUIMagicWeaponActive 