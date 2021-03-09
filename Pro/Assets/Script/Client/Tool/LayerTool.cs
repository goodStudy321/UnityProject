using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /*
     * 1,符合PascalCase,利用反射根据字段名称进行同层定义 
     * 反之,层的名称就需要手动对应字段并进行检查
     */

    /// <summary>
    /// AU:Loong
    /// TM:2014.03.05
    /// BG:层工具
    /// </summary>
    public static class LayerTool
    {
        #region 字段
        /// <summary>
        /// UI层
        /// </summary>
        public static readonly int UI;

        /// <summary>
        /// 遮挡墙层
        /// </summary>
        public static readonly int Wall;

        /// <summary>
        /// 单位层
        /// </summary>
        public static readonly int Unit;

        /// <summary>
        /// 地面层
        /// </summary>
        public static readonly int Ground;

        /// <summary>
        /// 寻路层
        /// </summary>
        public static readonly int PathFind;

        /// <summary>
        /// 3DUI层
        /// </summary>
        public static readonly int ThreeDUI;

        /// <summary>
        /// 在线奖励
        /// </summary>
        public static readonly int OnlineRewards;
        /// <summary>
        /// NPC
        /// </summary>
        public static readonly int NPC;
        /// <summary>
        /// UI模型
        /// </summary>
        public static readonly int UIModel;
        public static readonly int UIModelBG;
        /// <summary>
        /// 投影层
        /// </summary>
        public static readonly int ShadowCaster;
        /// <summary>
        /// 摄像机墙
        /// </summary>
        public static readonly int CameraWall;
        /// <summary>
        /// 特效
        /// </summary>
        public static readonly int FX;

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        static LayerTool()
        {
            Check(ref UI, "UI");
            Check(ref Wall, "Wall");
            Check(ref Unit, "Unit");
            Check(ref Ground, "Ground");
            Check(ref PathFind, "PathFind");
            Check(ref ThreeDUI, "ThreeDUI");
            Check(ref OnlineRewards, "OnlineRewards");
            Check(ref NPC, "NPC");
            Check(ref UIModel, "UIModel");
            Check(ref UIModelBG, "UIModelBg");
            Check(ref ShadowCaster, "ShadowCaster");
            Check(ref CameraWall, "CameraWall");
            Check(ref FX, "FX");
        }
        #endregion

        #region 私有方法

        private static void Check(ref int layer, string layerName)
        {
            layer = LayerMask.NameToLayer(layerName);
            if (layer != -1) return;
            iTrace.Error("Loong", string.Format("没有发现层:{0}", layerName));
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        /// <summary>
        /// 设置物体的层,包含子物体
        /// </summary>
        public static void Set(Transform target, int layer)
        {
            if (target == null) return;
            Transform[] arr = target.GetComponentsInChildren<Transform>(true);
            int length = arr.Length;
            for (int i = 0; i < length; i++)
            {
                Transform tran = arr[i];
                tran.gameObject.layer = layer;
            }
        }

        /// <summary>
        /// 设置物体的层,包含子物体
        /// </summary>
        public static void Set(Transform parent, string layerName)
        {
            int layer = LayerMask.NameToLayer(layerName);
            Set(parent, layer);
        }
        #endregion
    }
}