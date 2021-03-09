/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 10:11:25
 ============================================================================*/

using System;
using System.Collections;
using System.Collections.Generic;

namespace Loong.Game
{

    /// <summary>
    /// 预加载场景
    /// </summary>
    public class PreloadScene : PreloadBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public PreloadScene()
        {

        }
        #endregion

        #region 私有方法

        #endregion

        #region 保护方法
        public override void Execute()
        {
            if (dic.Count == 0) return;
            var em = dic.GetEnumerator();
            while (em.MoveNext())
            {
                var cur = em.Current;
                var name = cur.Key;
                /*var dp = ObjPool.Instance.Get<DelLoadScene>();
                dp.Name = name;
                dp.Additive = cur.Value;
                AssetMgr.Instance.complete += dp.OnComplete;
                AssetMgr.Instance.LoadSceneCount++;*/
                AssetMgr.Instance.Add(name, Suffix.Scene, null);
            }
            Dispose();
        }
        #endregion

        #region 公开方法
 
        #endregion
    }
}