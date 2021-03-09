--=========================================================================
-- Copyright (C) , 金七情(Loong) jinqiqing@qq.com
-- Created by Loong on 2018-02-07 14:35:41
-- CSharp类型在Lua环境中的全局定义
--=========================================================================


local UE = UnityEngine
local Loong = Loong.Game

--CS 类型定义
Screen = UE.Screen
WWWForm = UE.WWWForm
Resources = UE.Resources
Texture2D = UE.Texture2D
Mgr = NetworkMgr
Camera = UE.Camera
CSApp = Loong.App
UApp = UE.Application
User = User.instance
UITip = Loong.UITip
Activity = Loong.Activity
UIEvent = UIEventListener
BoxCollider = UE.BoxCollider
Audio = Loong.Audio.Instance
Device = Loong.Device.Instance
GameObject = UE.GameObject
Transform = UE.Transform
GbjPool = Loong.GbjPool.Instance
Music = Loong.Music.Instance
AssetMgr = Loong.AssetMgr.Instance
ErrorCodeMgr = Loong.ErrorCodeMgr
QualityMgr = QualityMgr.instance
GameSceneManager = GameSceneManager.instance
SendMessageOptions = UE.SendMessageOptions
PlayerPrefs = UE.PlayerPrefs
SceneManager = UE.SceneManagement.SceneManager
LoadSceneMode = UE.SceneManagement.LoadSceneMode
UnityWebRequest = UE.Networking.UnityWebRequest
DownloadHandlerTexture = UE.Networking.DownloadHandlerTexture

--CS 方法定义
Instantiate = GameObject.Instantiate
Destroy = GameObject.Destroy
Destory = Destroy
DestroyImmediate = GameObject.DestroyImmediate

LoadPrefab = Loong.AssetMgr.LoadPrefab

--CS 委托定义

ObjHandler = Loong.ObjHandler
GbjHandler = Loong.GbjHandler

--SDK
if Loong.Sdk then
  CS_Sdk = Loong.Sdk.Instance
end
