using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2014.09.23
    /// BG:释放工具
    /// </summary>
    public static class DisposeTool
    {
        #region 字段
        private static bool indirect = false;
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        static DisposeTool()
        {
            //MonoEvent.update += Update;
        }
        #endregion

        #region 私有方法
        private static void Update()
        {
            if (indirect)
            {
                DirectGC();
                indirect = false;
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        /// <summary>
        /// 释放所有
        /// </summary>
        public static void All()
        {
            try
            {
                iTrace.eWarning("hs", "登出遊戲開始釋放所有數據");
                HeartBeat.instance.Reset();
                CameraMgr.Clear();
                InputMgr.instance.Clear();
                HangupMgr.instance.Dispose();
                UISkill.instance.Clear();
                PathTool.PathMoveMgr.instance.Clear();
                //MapPathMgr.instance.DisposeMapData(0, 0);
                /// LY add begin ///
                uint curMapId = MapPathMgr.instance.CurMapId;
                uint nextMapId = 0;
                if (GameSceneManager.instance.SceneInfo != null)
                {
                    nextMapId = GameSceneManager.instance.SceneInfo.mapId;
                }
                MapPathMgr.instance.DisposeMapData(curMapId, nextMapId, true);
                /// LY add end ///
                CurScene(true);
                ModuleMgr.Clear();
                iTrace.eWarning("hs", "登出遊完成戲釋放所有數據");
                User.instance.IsInitLoadScene = true;
                Resources.UnloadUnusedAssets();
                GC.Collect();
            }
            catch (Exception e)
            {

                iTrace.Error("HS", "DisposeTool.All err:{0}", e.Message);
            }
            /**
            ObjPool.Instance.Dispose();
            **/
        }

        /// <summary>
        /// 不销毁野外场景卸载
        /// </summary>
        public static void PartResetClear(string unloadName = null)
        {
            NPCMgr.instance.CleanNPCList();
            UnitMgr.instance.Dispose(false);
            User.instance.CleanOtherData(false);
            SymbolMgr.Dispose();
            SceneGridMgr.Dispose();
            FlowChartMgr.Dispose();
            CollectionMgr.Dispose();
            SceneTriggerMgr.Dispose();
            UIMgr.CloseAll();
            UIMgr.Dispose();
            AudioPool.Instance.Dispose();
            if(!string.IsNullOrEmpty(unloadName))
                AssetMgr.Instance.Unload(unloadName, Suffix.Scene);

            DropMgr.CleanDropList();
           PathTool.PathMoveMgr.instance.Clear();
            /// LY add begin ///
            uint curMapId = MapPathMgr.instance.CurMapId;
            uint nextMapId = 0;
            if (GameSceneManager.instance.SceneInfo != null)
            {
                nextMapId = GameSceneManager.instance.SceneInfo.mapId;
            }
            MapPathMgr.instance.DisposeMapData(curMapId, nextMapId);
            /// LY add end ///
        }


        /// <summary>
        /// 清除 需要重新更新的数据
        /// </summary>
        public static void ResetClear(bool destroyAll = false)
        {
            NPCMgr.instance.CleanNPCList();
            UnitMgr.instance.Dispose(destroyAll);
            User.instance.CleanOtherData(destroyAll);
            SymbolMgr.Dispose();
            SceneGridMgr.Dispose();
            FlowChartMgr.Dispose();
            CollectionMgr.Dispose();
            SceneTriggerMgr.Dispose();
            UIMgr.CloseAll();
            UIMgr.Dispose();
            AudioPool.Instance.Dispose();
            AssetMgr.Instance.Dispose();
            DropMgr.CleanDropList();
            PathTool.PathMoveMgr.instance.Clear();
            /// LY add begin ///
            uint curMapId = MapPathMgr.instance.CurMapId;
            uint nextMapId = 0;
            if(GameSceneManager.instance.SceneInfo != null)
            {
                nextMapId = GameSceneManager.instance.SceneInfo.mapId;
            }
            MapPathMgr.instance.DisposeMapData(curMapId, nextMapId);
            /// LY add end ///
        }

        public static void Reconnection()
        {
            //ResetClear();
            FlowChartMgr.Dispose();
            GameSceneManager.instance.SceneStatus = SceneStatus.Normal;
            NetworkClient.DisableSend = false;
            NetworkMgr.IsLoadReady = false;
            NetworkMgr.ReqPreID = 0;
            User.instance.CleanReconnection();
            SettingMgr.instance.Clear();
            ShowEffectMgr.instance.Clear();
            ModuleMgr.Clear(true);
            UIMgr.SetCamActive(true);
        }

        /// <summary>
        /// 当前场景
        /// </summary>
        /// <param name="destroyAll"></param>
        /// <param name="dontDestroy"> 不释放场景资源 释放部分场景数据 </param>
        public static void CurScene(bool destroyAll = false)
        {
            try
            {
                PickIcon.DestroyPickIcon(-1);
                ResetClear(destroyAll);
                GbjPool.Instance.Dispose();
            }
            catch (Exception e)
            {
                iTrace.Error("HS", "DisposeTool.CurScene err:{0}", e.Message);
            }
        }

        /// <summary>
        /// 当前场景部分资源销毁
        /// </summary>
        /// <param name="destroyAll"></param>
        /// <param name="dontDestroy"> 不释放场景资源 释放部分场景数据 </param>
        public static void CurPartScene(string unloadName = null)
        {
            try
            {
                PartResetClear(unloadName);
            }
            catch (Exception e)
            {
                iTrace.Error("HS", "DisposeTool.CurPartScene err:{0}", e.Message);
            }
        }

        /// <summary>
        /// 相同場景
        /// </summary>
        public static void SameScene()
        {
            try
            {
                User.instance.CleanOtherData();
                NPCMgr.instance.CleanmNPCDic();
                UnitMgr.instance.Dispose();
                CollectionMgr.Dispose();
                SceneTriggerMgr.Stoping = true;
                DropMgr.CleanDropList();
            }
            catch (Exception e)
            {
                iTrace.Error("HS", "SameScene err:{0}", e.Message);
            }
        }

        /// <summary>
        /// 直接垃圾回收和释放无用资源
        /// </summary>
        public static void DirectGC()
        {
            Resources.UnloadUnusedAssets();
            GC.Collect();
            //iTrace.Log("Loong", "调用垃圾回收和释放无用资源");
        }

        /// <summary>
        /// 间接垃圾回收和释放无用资源,在主线程中执行
        /// </summary>
        public static void IndirectGC()
        {
            iTrace.Log("Loong", "设置见解调用垃圾回收和释放无用资源");
            indirect = true;
        }
        #endregion
    }
}