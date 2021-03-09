using System;
using Loong.Game;
using UnityEditor;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Edit
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        227c58e1-d028-4919-a03e-d4e23f6bdd40
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/21 18:01:10
    /// BG:
    /// </summary>
    [CustomEditor(typeof(TestPlayer))]
    public class TestPlayerInspector : Editor
    {
        #region 字段
        private Animation anim = null;

        private TestPlayer testPlayer = null;

        private CameraFollow cameraFollow = null;
        #endregion

        #region 属性

        #endregion

        #region 构造方法
        private bool CheckCamera()
        {
            if (!Application.isPlaying) return false;
            if (cameraFollow == null) cameraFollow = CameraFollow.Instance;
            if (cameraFollow == null) return false;
            return true;
        }

        private void SetCameraFollow()
        {
            if (!Application.isPlaying) return;
            if (CameraMgr.Main == null) return;
            cameraFollow = CameraFollow.Instance;
        }

        private void SpeedChange()
        {
            PlayerMove.Speed = testPlayer.speed;
        }

        private void OffsetChange()
        {
            if (CheckCamera())
            {
                cameraFollow.Offset = testPlayer.offset;
            }
        }

        private void EulerOffsetChange()
        {
            if (CheckCamera())
            {
                cameraFollow.EulerOffset = testPlayer.eulerOffset;
                cameraFollow.Focus();
            }
        }

        private void OnEnable()
        {
            testPlayer = target as TestPlayer;
            SetCameraFollow();
        }
        #endregion

        #region 私有方法
        private void DrawBasicProp()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.LabelField("基础设置:");
            UIEditLayout.FloatField("移动速度:", ref testPlayer.speed, testPlayer, SpeedChange);
            EditorGUILayout.EndVertical();
        }

        private void DrawCameraProp()
        {
            EditorGUILayout.BeginVertical(StyleTool.Group);
            EditorGUILayout.LabelField("相机设置:");
            UIEditLayout.Vector3Field("跟随偏移值:", ref testPlayer.offset, testPlayer, OffsetChange);
            UIEditLayout.Vector3Field("角度偏移值:", ref testPlayer.eulerOffset, testPlayer, EulerOffsetChange);
            EditorGUILayout.EndVertical();
        }

        private void DrawActionStatus()
        {
            testPlayer.player.Status.Anim = anim;
            testPlayer.player.Status.Draw(testPlayer, null, 0);
            int length = testPlayer.player.Status.Groups.Count;
            for (int i = 0; i < length; i++)
            {
                testPlayer.player.Status.Groups[i].Anim = anim;
            }
        }
        #endregion

        #region 保护方法

        #endregion

        #region 公开方法
        public override void OnInspectorGUI()
        {
            if (anim == null)
            {
                anim = testPlayer.gameObject.GetComponent<Animation>();
            }
            if (anim == null)
            {
                UIEditLayout.HelpError("动画组件为空");
            }
            else
            {
                DrawBasicProp();
                DrawCameraProp();
                DrawActionStatus();
            }
        }
        #endregion
    }
}