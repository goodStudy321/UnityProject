LJ
�   Z9  ' 6 96 96 9  '	 
 B= 9  9	+	 B 6 	 '
  + B=
  6 	 '
  + B=  6 	 '
  + B=  6 	 '
  + B=  6 	 '
  + B=  6 	 '
  + B=  6 	 '
  + B=   '	 
 9   B  '	 
 9   BK  ClosePromoPromotion/PromBGOKBtnCSoloResult/OkBtnSoloResult/ExpValExpValSoloResult/DanTipDanTipSoloResult/DanScoreDanScoreSoloResult/ChallengeChallengeSoloResult/ResultResultPromotion/DanLblUILabelDanLblPromotion/DanIconUISpriteDanIconSetActivePromotionSetLsnrClickUIToolFindChildTransToolGetComTool1v1战斗结算界面	root    K      K  !     9  BK  SetResult    K  � 	  .6  96 99B6  9 B99 X�K  9  9+ B9 9	=9
 9=6 96 B= 9 9 99   B9 ) =9  9BK  
StartsecondsClosePromAddcompleteDateTimerGetObjPool
TimerdanName	textDanLbldanIconspriteNameDanIconSetActivePromotion
scoreRoleInfo	PeakGetDanInfoByScrUIPeak!     9  BK  ClosePromj   9   9+ B9  9B6 99 BK  AddObjPool	Stop
TimerSetActivePromotion� 	  46  9+  6 96  99!B6 9' 9	B9
 X
�9 ' =6 9' 9B X	�9 ' =6 9' 9B 9 =9 =9 =  9 9B  9 9BK  OpenPromoSetDanTipExpValDanScoreChallenge挑战[00ff00]%s[-]失败挑战失败soloRName挑战[00ff00]%s[-]成功挑战成功	textResultIsSuccAddExpX%sformatstring
scoreRoleInfoNewScoretostringFightResult	Peak� 
 
 6  9 B  X�9 ' =X
�9!9 6 9' 9		 B=K  danName)提升至[00ff00]%s[-]还差%s积分formatstring
score1已经达到最顶阶[00ff00]钻石五阶[-]	textDanTipGetNextDanByScrUIPeak>     9  B6 9BK  QuitSceneNetworkMgr
Close�   6     9  5 B 7  6  3 = 3 = 3	 = 3 =
 3 = 3 = 3 = 3 = 3 = 3 = 3 = 2  �L   OKBtnC SetDanTip SetResult CloseProm ClosePromo OpenPromo CloseCustom OpenCustom RemoveCustom AddEvent InitCustomUIPeakResult 	NameUIPeakResultNewUIBase 