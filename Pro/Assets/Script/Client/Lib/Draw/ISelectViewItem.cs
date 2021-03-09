#if UNITY_EDITOR
namespace Loong.Game
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.9.28
    /// BG:选择视图条目接口
    /// </summary>
    public interface ISelectViewItem
    {
        #region 属性

        #endregion

        #region 方法
        /// <summary>
        /// 绘制选择条目
        /// </summary>
        /// <param name="obj"></param>
        void DrawItem(UnityEngine.Object obj);
        #endregion

        #region 事件

        #endregion

        #region 索引器

        #endregion
    }
}
#endif