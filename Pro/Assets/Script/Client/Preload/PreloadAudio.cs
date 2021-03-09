/*=============================================================================
 * Copyright (C) 2014, 金七情(Loong) jinqiqing@qq.com
 * Created by Loong in 2014.6.3 10:11:25
 ============================================================================*/

namespace Loong.Game
{
    /// <summary>
    /// 预加载音效
    /// </summary>
    public class PreloadAudio : PreloadBase
    {
        #region 字段

        #endregion

        #region 属性

        #endregion

        #region 构造方法
        public PreloadAudio()
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
                var dg = ObjPool.Instance.Get<DelAudioParam>();
                dg.Name = name;
                dg.Persist = cur.Value;
                AssetMgr.Instance.Add(name, dg.Callback);
            }
        }
        #endregion

        #region 公开方法

        #endregion
    }
}