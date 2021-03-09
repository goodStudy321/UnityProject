using System;
using System.IO;
using Loong.Game;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

#if UNITY_EDITOR
using UnityEditor;
#endif

namespace Phantom
{
    /*
     * CO:            
     * Copyright:   2017-forever
     * CLR Version: 4.0.30319.42000  
     * GUID:        a4892075-c93b-4fa4-a74b-56c2527ac76d
    */

    /// <summary>
    /// AU:Loong
    /// TM:2017/6/23 15:09:19
    /// BG:场景时间线动画
    /// </summary>
    [Serializable]
    public class SceneAnimLineNode : FlowChartNode
    {
        #region 字段
        [SerializeField]
        private string id = "";

        /// LY add begin ///
        [SerializeField]
        private bool openLoadingEnd = false;
        /// LY add end ///
        #endregion


        #region 属性
        /// <summary>
        /// 动画ID
        /// </summary>
        public string ID
        {
            get { return id; }
            set { id = value; }
        }

        /// LY add begin ///

        /// <summary>
        /// 动画结尾打开loading界面
        /// </summary>
        public bool OpenLoadingEnd
        {
            get { return openLoadingEnd; }
            set { openLoadingEnd = value; }
        }

        /// LY add end ///
        #endregion

        #region 委托事件

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法
        private void PlayCallback(CutscenePlayer.StopType type)
        {
            if (type == CutscenePlayer.StopType.ST_Error)
            {
                string error = string.Format("调用ID为:{0}场景动画发生错误", ID);
                Debug.LogError(Format(error));
            }
            Complete();
            InputMgr.instance.JoyStickControlMdl = true;
        }
        #endregion

        #region 保护方法
        protected override void ReadyCustom()
        {
            CutscenePlayMgr.instance.PlayCutscene(ID, null, false, true, true, PlayCallback, openLoadingEnd);
        }
        #endregion

        #region 公开方法
        public override void Read(BinaryReader br)
        {
            base.Read(br);
            //id = br.ReadString();
            ExString.Read(ref id, br);
            openLoadingEnd = br.ReadBoolean();
        }

        public override void Write(BinaryWriter bw)
        {
            base.Write(bw);
            //bw.Write(id);
            ExString.Write(id, bw);
            bw.Write(openLoadingEnd);
        }

        public override void Preload()
        {
            //string prefabName = string.Format("{0}_cs", ID);
            string prefabName = ID;
            PreloadMgr.prefab.Add(prefabName);

            /// 预加载关联资源 ///

            List<string> lActors = new List<string>();
            List<string> lAnimClips = new List<string>();
            List<string> lAudioClips = new List<string>();

            List<CutsRes> resList = CutsResManager.instance.GetList();
            for (int a = 0; a < resList.Count; a++)
            {
                CutsRes checkCutsRes = resList[a];
                if (checkCutsRes != null && checkCutsRes.cutsName == prefabName)
                {
                    int tCon1Val = CutscenePlayMgr.instance.GetGameConVal(checkCutsRes.conType1);
                    if (checkCutsRes.conVal1 == tCon1Val)
                    {
                        List<CutsRes.groupRes> tGroupRes = checkCutsRes.resList.list;
                        List<CutsRes.clips> tClips = checkCutsRes.trackClips.list;
                        for (int b = 0; b < tGroupRes.Count; b++)
                        {
                            if (lActors.Contains(tGroupRes[b].actorName) == false)
                            {
                                lActors.Add(tGroupRes[b].actorName);
                            }

                            for (int c = 0; c < tClips[b].list.Count; c++)
                            {
                                if (checkCutsRes.replType == 1)
                                {
                                    string animResName = tClips[b].list[c] + ".anim";
                                    if(lAnimClips.Contains(animResName) == false)
                                    {
                                        lAnimClips.Add(animResName);
                                    }
                                }
                                else if (checkCutsRes.replType == 2)
                                {
                                    string tPostfix = ".mp3";
                                    if (string.IsNullOrEmpty(checkCutsRes.postfix) == false)
                                    {
                                        tPostfix = checkCutsRes.postfix;
                                    }
                                    string audioResName = tClips[b].list[c] + tPostfix;
                                    if(lAudioClips.Contains(audioResName) == false)
                                    {
                                        lAudioClips.Add(audioResName);
                                    }
                                }
                            }
                        }
                    }
                }
            }

            for(int a = 0; a < lActors.Count; a++)
            {
                PreloadMgr.prefab.Add(lActors[a]);
            }
            for (int a = 0; a < lAnimClips.Count; a++)
            {
                AssetMgr.Instance.Add(lAnimClips[a], null);
            }
            for (int a = 0; a < lAudioClips.Count; a++)
            {
                AssetMgr.Instance.Add(lAudioClips[a], null);
            }
        }

        public override void Dispose()
        {
            base.Dispose();
            CutscenePlayMgr.instance.SkipCutscene();
        }
        #endregion

        #region 编辑器字段/属性/方法

#if UNITY_EDITOR
        public override void EditCopy(FlowChartNode other)
        {
            if (other == null) return;
            var node = other as SceneAnimLineNode;
            if (node == null) return;
            id = node.id;
            openLoadingEnd = node.openLoadingEnd;
        }

        public override void EditInitialize()
        {
            base.EditInitialize();
            style = "flow node 5";
        }

        public override void EditDrawProperty(Object o)
        {
            EditorGUILayout.BeginVertical(GUI.skin.box);
            UIEditLayout.TextField("动画ID", ref id, o);
            if (string.IsNullOrEmpty(id)) UIEditLayout.HelpError("无效字符");
            /// LY add begin ///
            UIEditLayout.Toggle("结尾打开Loading", ref openLoadingEnd, o);
            /// LY add end ///
            EditorGUILayout.EndVertical();
        }

#endif
        #endregion
    }
}