LJ
#  -   9 BK   �
Close/  -   9 BK   �ClickCreateFamily,  -   9 BK   �ChangeLastPage,  -   9 BK   �ChangeNextPage3  -   9    BK   �RenewShowList.   -     9   B K   �JoinFamilyNotice�2 �-  9 = -  -  9 9=6 96 9-   -  9'	 B=-   -  9' B=
-   -  9' B=' -   6 -  9'	 
 + B=-   6 -  9'	 
 + B=-   6 -  9'	 
 + B= 6 -  9' 	 +
 B6 99B3 = 6 -  9'	 
 + B 6 99B3 = 6 -  9'	 
 + B 6 99B3  = 6 -  9'	! 
 + B 6 99B3" =6#  9$-  9B-  9 9%+ B-  9 9%+ B-  + =&-  4  ='-  )  =(-  )  =)-  )  =*-  )  =+6, 9-'. 3/ B6, 9-'0 31 B2  �K   � NewFamilyMemberData NewFamilyBriefAddEventMgrmaxPageallBriefNumcurBriefPagedelayResetCountfamilyInfoItems
mOpenSetActive	InitUINewFamilyPanel 3WndContainer/MainPanel/ConBar/PageBar/NextPage 3WndContainer/MainPanel/ConBar/PageBar/LastPage  onClickgameObjectUIEvent WndContainer/Title/CloseBtnUIButton3WndContainer/MainPanel/ConBar/PageBar/PageInfoUILabelpageLabel/WndContainer/MainPanel/FamilyInfoSV/UIGridUIGridinfoGrid(WndContainer/MainPanel/FamilyInfoSVUIScrollViewinfoScrollViewUI帮派列表界面FamilyCreatePanelnewFamilyPanelObj,WndContainer/MainPanel/ConBar/CreateBtncreateBtnObj=WndContainer/MainPanel/FamilyInfoSV/UIGrid/FamilyCont_99familyInfoMainFindChildTransToolGetComTooltransformwinRootTransgbjwinRootObj�   -  + = -  ) =-  ) =  9 B6  9B X�-  9 9+ BX�-  9 9+ BK   �SetActivecreateBtnObjJoinFamilyFamilyMgrCallShowListmaxPagecurBriefPage
mOpen  -  + = K   �
mOpen� -  9 )   X�-  -  9  = -  9 )   X�-  )  = -  9 9BK   �ResetPositioninfoScrollViewdelayResetCounti  ) -  9  ) M�6 9-  9 8BO�-  4  = K   �AddObjPoolfamilyInfoItems�  
 6  996  X�6 9' 6 ' &BK  6  9	BK  	OpenUINewFamilyPanel级。等级未达到ShowYesMsgBoxCREATE_FAMILY_LV
LevelMapData	User9  	-  9  X�K    9 BK   �
Close
mOpen\ -  9 )  X�K  -  -  9  = 6 BK   �CallShowListcurBriefPageh -  9 -  9 X�K  -  -  9  = 6 BK   �CallShowListmaxPagecurBriefPage� -  9  - " -  9 - "6  9  B  9 BK   ��RenewPageShowReqFamilyBriefFamilyMgrcurBriefPage� 	 C-  9  X�K  
  X� )   X�  X�  9 )  B-  )  =-  ) =  9 BK  -  =-  6 9-  9- #B=-  9)   X�-  ) =   9  B)  ) M�-  98
 98BO�  9 BK   ��ResetDatafamilyInfoItems	ceil	mathRenewPageShowmaxPageallBriefNumRenewFamilyItemNum
mOpenh  -  9 6 -  9B' -  9&=K   �maxPage/curBriefPagetostring	textpageLabel� 
=6  9-  9B9-  999=9-  999=9-  999=9-  999= 9+ B6	 9
6 B 9 B6 99' 6 -	  9				 	 	B A=-  9-  9  <L  �familyInfoItemstostring99	gsubstring	name	InitUIFamilyInfoItemGetObjPoolSetActivelocalScalelocalRotationlocalPositionparenttransformfamilyInfoMainInstantiateGameObject� f) -  9  ) M�-  9 8 9+	 BO� )   X�)  X�-  X�- -  9   X�)  ) M�-  9 8	 9+
 BO�X�) -  9  ) M�-  9 8	 9+
 BO�-  9  !)  ) M�
  9 BO�) -  9  ) M� 	 X�-  9 8	 9+
 BX�-  9 8	 9+
 BO�-  9 9B  9 BK   ��DelayResetSVPositionRepositioninfoGrid	BgOnCloneFamilyInfoItem	ShowfamilyInfoItems )  -  ) = K   �delayResetCount�  * D6   ' B 6   ' B 6    9  5 B 7  4   6 96 9	6
 9) 6 3 =6 3 =6 3 =6 3 =6 3 =6 3 =6 3 =6 3 =6 3 =6 3 =6 3! = 6 3# ="6 3% =$6 3' =&6 3) =(6 2  �L  DelayResetSVPosition RenewFamilyItemNum CloneFamilyInfoItem RenewPageShow RenewShowList CallShowList ChangeNextPage ChangeLastPage JoinFamilyNotice ClickCreateFamily Dispose Update CloseCustom OpenCustom InitCustomTriggerEventMgr
ErrorLogiTraceUIFamilyListWnd 	NameUIFamilyListWndNewUIBase!UI/UIFamily/UINewFamilyPanel!UI/UIFamily/UIFamilyInfoItemrequire 