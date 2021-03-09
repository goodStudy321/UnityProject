using System;
using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using Object = UnityEngine.Object;

namespace Loong.Game
{

    /// <summary>
    /// AU:Loong
    /// TM:2015.9.2
    /// BG:无参数游戏对象委托处理
    /// </summary>
    public class DelGbj : DelObj<GameObject>
    {
        #region 字段
        public event GbjHandler handler = null;
        #endregion

        #region 属性

        #endregion

        #region 构造方法

        #endregion

        #region 私有方法

        #endregion

        #region 保护方法

        #endregion

        #region 公开方法

        protected override GameObject Get(Object obj)
        {
            GameObject go = null;
            if (obj != null)
            {
#if UNITY_EDITOR
                var ty = obj.GetType().Name;
                if (ty == typeof(AssetBundle).Name)
                {
                    iTrace.Error("Loong", "Beg ------------------------------");
                    iTrace.Error("Loong", "名为{0} prefab,有资源AB名相同,如下:");
                    var ab = obj as AssetBundle;
                    var names = ab.GetAllAssetNames();
                    int length = names.Length;
                    for (int i = 0; i < length; i++)
                    {
                        var name = names[i];
                        iTrace.Error("Loong", name);
                    }
                    iTrace.Error("Loong", "End ------------------------------");
                    return go;
                }
#endif
                go = GameObject.Instantiate(obj) as GameObject;
                go.name = obj.name;
                QualityMgr.instance.ChangeGoQuality(go);
#if UNITY_EDITOR
                ShaderTool.eResetGbj(go);
#endif
            }
            return go;
        }

        protected override void Execute(GameObject t)
        {
            if (handler != null)
            {
                handler(t);
                handler = null;
            }
        }

        #endregion
    }
}