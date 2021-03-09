#if UNITY_EDITOR
using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        87eaa83b-cbd7-4743-97ba-4f9c52804663
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/21 16:43:13
    /// BG:玩家测试
    /// </summary>
    [AddComponentMenu("Loong/玩家测试")]
    public class TestPlayer : TestMonoBase
    {
        #region 字段
        private bool running = false;

        private Animation anim = null;


        /// <summary>
        /// 移动速度
        /// </summary>
        public float speed = 6f;


        /// <summary>
        /// 玩家
        /// </summary>
        public Player player = new Player();
        #region 相机设置
        /// <summary>
        /// 相机偏移值
        /// </summary>
        public Vector3 offset = new Vector3(0, 3, -2);

        /// <summary>
        /// 相机角度偏移
        /// </summary>
        public Vector3 eulerOffset = new Vector3(-16, 0, 0);
        #endregion


        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void Awake()
        {
            iTrace.eLog("Loong", "开始测试");
        }

        private void Start()
        {
            Camera main = Camera.main;
            if (main == null)
            {
                iTrace.Error("Loong", "没有发现主相机");
            }
            else
            {
                CameraFollow.Instance.Camera = main;
                CameraFollow.Instance.transform = main.transform;
            }
        }

        private bool Check()
        {
            anim = GetComponent<Animation>();
            if (anim == null)
            {
                iTrace.Error("Loong", string.Format("没有在预设:{0}上发现动画组件", gameObject.name));
                running = false;
            }
            if (anim.GetClipCount() == 0)
            {
                iTrace.Error("Loong", string.Format("预设:{0}的动画(Animation)组件上没有任何动画剪辑", gameObject.name));
                running = false;
            }
            running = true;
            return running;
        }

        private void Entry()
        {
            if (!Check()) return;
            gameObject.name = "英雄";
            transform.position = Vector3.zero;
            CameraFollow.Instance.Target = transform;
            CameraFollow.Instance.Offset = offset;
            PlayerMove.Speed = speed;
            PlayerMove.Target = transform;
            PlayerMove.Refresh();
            player.transform = transform;
            player.Anim = anim;
            player.Init();
        }


        private void Update()
        {
            if (!running) return;
            player.Update();
            CameraFollow.Instance.Update();
        }



        private void DrawTest()
        {

        }
        #endregion

        #region 保护方法
        protected override void OnGUICustom()
        {
            if (running)
            {
                GUILayout.Label("玩家位置:" + transform.position, lblOpts);
            }
            else
            {

                if (GUILayout.Button("开始", btnOpts))
                {
                    Entry();
                }

            }
            DrawTest();
        }
        #endregion

        #region 公开方法

        #endregion
    }
}
#endif