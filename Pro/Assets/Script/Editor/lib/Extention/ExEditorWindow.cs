using UnityEngine;
using UnityEditor;

namespace Loong.Edit
{
    /// <summary>
    /// AU:Loong
    /// TM:2014.4.12
    /// BG:编辑器窗口扩展
    /// </summary>
    public static class ExEditorWindow
    {
        #region 字段

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

        /// <summary>
        /// 在窗口上显示一个信息
        /// </summary>
        /// <param name="win">窗口</param>
        /// <param name="msg">信息</param>
        public static void ShowTip(this EditorWindow win, string msg)
        {
            win.ShowNotification(new GUIContent(msg));
        }

        /// <summary>
        /// 设置窗口标题内容
        /// </summary>
        /// <param name="win">窗口</param>
        /// <param name="title">标题</param>
        public static void SetTitle(this EditorWindow win, string title)
        {
            win.titleContent = new GUIContent(title);
        }

        /// <summary>
        /// 设置窗口标题内容
        /// </summary>
        /// <param name="win">窗口</param>
        /// <param name="title">标题</param>
        /// <param name="tooltip">提示</param>
        public static void SetTitle(this EditorWindow win, string title, string tooltip)
        {
            win.titleContent = new GUIContent(title, tooltip);
        }

        /// <summary>
        /// 设置窗口标题内容
        /// </summary>
        /// <param name="win">窗口</param>
        /// <param name="tilte">标题</param>
        /// <param name="tooltip">提示</param>
        /// <param name="image">图片</param>
        public static void SetTitle(this EditorWindow win, string tilte, string tooltip, Texture2D image)
        {
            win.titleContent = new GUIContent(tilte, image, tooltip);
        }


        /// <summary>
        /// 设置窗口位置在屏幕中间并设置最小尺寸为显示大小的一半
        /// </summary>
        /// <param name="win">窗口</param>
        /// <param name="width">宽度</param>
        /// <param name="height">高度</param>
        public static void SetSize(this EditorWindow win, int width, int height)
        {
            win.SetSize(null, width, height);
        }

        /// <summary>
        /// 设置窗口位置在另一个窗口中间并设置最小尺寸为显示大小的一半
        /// </summary>
        /// <param name="win"></param>
        /// <param name="anchorWin"></param>
        /// <param name="width"></param>
        /// <param name="height"></param>
        public static void SetSize(this EditorWindow win, EditorWindow anchorWin, int width, int height)
        {
            Vector2 size = WinUtil.GetSize(width, height);
            Vector2 pos = WinUtil.GetRelativePosition(anchorWin, size);
            win.position.Set(pos.x, pos.y, size.x, size.y);
            Vector2 halfSize = size * 0.5f;
            win.minSize = halfSize;
        }

        /// <summary>
        /// 设置窗口位置在屏幕中间并设置固定尺寸
        /// </summary>
        /// <param name="win">窗口</param>
        /// <param name="width">宽度</param>
        /// <param name="height">高度</param>
        public static void SetStaticSize(this EditorWindow win, int width, int height)
        {
            win.SetStaticSize(null, width, height);
        }

        /// <summary>
        /// 设置窗口位置在另一个窗口的中间并设置固定尺寸
        /// </summary>
        /// <param name="win"></param>
        /// <param name="anchorWin"></param>
        /// <param name="width"></param>
        /// <param name="height"></param>
        public static void SetStaticSize(this EditorWindow win, EditorWindow anchorWin, int width, int height)
        {
            Vector2 size = WinUtil.GetSize(width, height);
            Vector2 pos = WinUtil.GetRelativePosition(anchorWin, size);
            win.position.Set(pos.x, pos.y, size.x, size.y);
            win.minSize = size;
            win.maxSize = size;
        }

        #endregion

    }
}
