using System.Collections;
using System.Collections.Generic;
using UnityEditor;
using UnityEngine;

namespace Hello.Game
{
    public static partial class UIEditTool
    {
        private static Texture2D backdropTex;
        private static Texture2D contrastTex;
        private static Texture2D gradientTex;
        private static Texture2D antiAliasTex;

        /// <summary>
        /// 1x1的白色空白图
        /// </summary>
        public static Texture2D BlankTex
        {
            get
            {
                return EditorGUIUtility.whiteTexture;
            }
        }

        /// <summary>
        /// 16x16背景图
        /// </summary>
        public static Texture2D BackdropTex
        {
            get
            {
                if (backdropTex == null)
                {
                    backdropTex = CreateCheckerTex(new Color(0.1f, 0.1f, 0.1f, 0.5f),
                    new Color(0.2f, 0.2f, 0.2f, 0.5f));
                }
                return backdropTex;
            }
        }
        /// <summary>
        /// 16x16对比图
        /// </summary>
        public static Texture2D ContrastTex
        {
            get
            {
                if (contrastTex == null)
                {
                    contrastTex = CreateCheckerTex(new Color(0f, 0.0f, 0f, 0.5f),
                    new Color(1f, 1f, 1f, 0.5f));
                }
                return contrastTex;
            }
        }
        /// <summary>
        /// 1x16渐变图
        /// </summary>
        public static Texture2D GradientTex
        {
            get
            {
                if (gradientTex == null)
                {
                    gradientTex = CreateGradientTex();
                }
                return gradientTex;
            }
        }

        /// <summary>
        /// 1x3抗锯齿图
        /// </summary>
        public static Texture2D AntiAliasTex
        {
            get
            {
                if (antiAliasTex == null)
                {
                    antiAliasTex = new Texture2D(1, 3, TextureFormat.ARGB32, true);
                    antiAliasTex.SetPixel(0, 0, new Color(1, 1, 1, 0));
                    antiAliasTex.SetPixel(0, 1, Color.white);
                    antiAliasTex.SetPixel(0, 2, new Color(1, 1, 1, 0));
                    antiAliasTex.Apply();
                }

                return antiAliasTex;
            }
        }

        /// <summary>
        /// 创建具有对比效果的图片
        /// </summary>
        /// <param name="c0"></param>
        /// <param name="c1"></param>
        /// <returns></returns>
        private static Texture2D CreateCheckerTex(Color c0, Color c1)
        {
            Texture2D tex = new Texture2D(16, 16);
            tex.name = "Checker Texture";
            tex.hideFlags = HideFlags.DontSave;

            for (int y = 0; y < 8; ++y) for (int x = 0; x < 8; ++x) tex.SetPixel(x, y, c1);
            for (int y = 8; y < 16; ++y) for (int x = 0; x < 8; ++x) tex.SetPixel(x, y, c0);
            for (int y = 0; y < 8; ++y) for (int x = 8; x < 16; ++x) tex.SetPixel(x, y, c0);
            for (int y = 8; y < 16; ++y) for (int x = 8; x < 16; ++x) tex.SetPixel(x, y, c1);

            tex.Apply();
            tex.filterMode = FilterMode.Point;
            return tex;
        }
        /// <summary>
        /// 创建具有渐变效果的图片
        /// </summary>
        /// <returns></returns>
        private static Texture2D CreateGradientTex()
        {
            Texture2D tex = new Texture2D(1, 16);
            tex.name = "[Generated] Gradient Texture";
            tex.hideFlags = HideFlags.DontSave;

            Color c0 = new Color(1f, 1f, 1f, 0f);
            Color c1 = new Color(1f, 1f, 1f, 0.4f);

            for (int i = 0; i < 16; ++i)
            {
                float f = Mathf.Abs((i / 15f) * 2f - 1f);
                f *= f;
                tex.SetPixel(0, i, Color.Lerp(c0, c1, f));
            }

            tex.Apply();
            tex.filterMode = FilterMode.Bilinear;
            return tex;
        }

        /// <summary>
        /// 绘制一个平铺的图片
        /// </summary>
        /// <param name="rect">指定的矩形区域</param>
        /// <param name="tex">图片</param>
        public static void DrawTiledTex(Rect rect, Texture2D tex)
        {
            GUI.BeginGroup(rect);
            {
                int width = Mathf.RoundToInt(rect.width);
                int height = Mathf.RoundToInt(rect.height);

                for (int h = 0; h < height; h += tex.height)
                {
                    for (int w = 0; w < width; w += tex.width)
                    {
                        GUI.DrawTexture(new Rect(w, h, tex.width, tex.height), tex);
                    }
                }
            }
        }

        /// <summary>
        /// 绘制一个像素宽度的外边框
        /// </summary>
        /// <param name="rect">指定的矩形区域</param>
        public static void DrawOutline(Rect rect)
        {
            if (Event.current.type == EventType.Repaint)
            {
                Texture2D tex = ContrastTex;
                GUI.color = Color.white;
                DrawTiledTex(new Rect(rect.xMin, rect.yMax, 1f, -rect.height), tex);
                DrawTiledTex(new Rect(rect.xMax, rect.yMax, 1f, -rect.height), tex);
                DrawTiledTex(new Rect(rect.xMin, rect.yMin, rect.width, 1f), tex);
                DrawTiledTex(new Rect(rect.xMin, rect.yMax, rect.width, 1f), tex);
            }
        }
        /// <summary>
        /// 绘制一个像素宽度的外边框
        /// </summary>
        /// <param name="rect">指定的矩形区域</param>
        /// <param name="color">颜色</param>
        public static void DrawOutline(Rect rect, Color color)
        {
            if (Event.current.type == EventType.Repaint)
            {
                Texture2D tex = BlankTex;
                GUI.color = color;
                GUI.DrawTexture(new Rect(rect.xMin, rect.yMin, 1f, rect.height), tex);
                GUI.DrawTexture(new Rect(rect.xMax, rect.yMin, 1f, rect.height), tex);
                GUI.DrawTexture(new Rect(rect.xMin, rect.yMin, rect.width, 1f), tex);
                GUI.DrawTexture(new Rect(rect.xMin, rect.yMax, rect.width, 1f), tex);
                GUI.color = Color.white;
            }
        }
        /// <summary>
        /// 绘制一个被选中的一个像素宽度的外边框
        /// </summary>
        /// <param name="rect">指定的矩形区域</param>
        /// <param name="relative">相对的矩形区域</param>
        public static void DrawOutline(Rect rect, Rect relative)
        {
            if (Event.current.type == EventType.Repaint)
            {
                float x = rect.xMin + rect.width * relative.xMin;
                float y = rect.yMax - rect.height * relative.yMin;
                float width = rect.width * relative.width;
                float height = -rect.height * relative.height;
                relative = new Rect(x, y, width, height);

                DrawOutline(relative);
            }
        }
        /// <summary>
        /// 绘制一个被选中的一个像素宽度的外边框
        /// </summary>
        /// <param name="rect">指定的矩形区域</param>
        /// <param name="relative">相对的矩形区域</param>
        /// <param name="color">颜色</param>
        public static void DrawOutline(Rect rect, Rect relative, Color color)
        {
            if (Event.current.type == EventType.Repaint)
            {
                float x = rect.xMin + rect.width * relative.xMin;
                float y = rect.yMax - rect.height * relative.yMin;
                float width = rect.width * relative.width;
                float height = -rect.height * relative.height;
                relative = new Rect(x, y, width, height);

                DrawOutline(relative, color);
            }
        }

        /// <summary>
        /// 绘制背景
        /// </summary>
        /// <param name="tex">贴图</param>
        /// <param name="ratio">高度缩放</param>
        /// <returns></returns>
        public static Rect DrawBackground(Texture2D tex, float ratio)
        {
            Rect rect = GUILayoutUtility.GetRect(0f, 0f);
            rect.width = Screen.width - rect.xMin;
            rect.height = rect.width * ratio;
            GUILayout.Space(rect.height);

            if (Event.current.type == EventType.Repaint)
            {
                Texture2D blank = BlankTex;
                Texture2D check = BackdropTex;

                GUI.color = new Color(0f, 0f, 0f, 0.2f);
                GUI.DrawTexture(new Rect(rect.xMin, rect.yMin - 1, rect.width, 1f), blank);
                GUI.DrawTexture(new Rect(rect.xMin, rect.yMax, rect.width, 1f), blank);
                GUI.color = Color.white;

                DrawTiledTex(rect, check);
            }
            return rect;
        }

        /// <summary>
        /// 画一个分隔符
        /// </summary>
        public static void DrawSeparator()
        {
            GUILayout.Space(12f);
            if (Event.current.type == EventType.Repaint)
            {
                Texture2D tex = BlankTex;
                Rect rect = GUILayoutUtility.GetLastRect();
                GUI.color = new Color(0f, 0f, 0f, 0.25f);
                GUI.DrawTexture(new Rect(0f, rect.yMin + 6f, Screen.width, 4f), tex);
                GUI.DrawTexture(new Rect(0f, rect.yMin + 6f, Screen.width, 1f), tex);
                GUI.DrawTexture(new Rect(0f, rect.yMin + 9f, Screen.width, 1f), tex);
                GUI.color = Color.white;
            }
        }


        /// <summary>
        /// 绘制一个可进行折叠的特殊标题 键和表条名称一致 并且改变BG颜色
        /// </summary>
        /// <param name="text">标题名称</param>
        /// <returns></returns>
        public static bool DrawHeader(string text)
        {
            return DrawHeader(text, text);
        }
        /// <summary>
        /// 绘制一个可进行折叠的特殊标题
        /// </summary>
        /// <param name="text">标题名称</param>
        /// <param name="key">偏好设定</param>
        /// <param name="style">样式</param>
        /// <returns></returns>
        public static bool DrawHeader(string text, string key, string style = "Dragtab")
        {
            bool state = EditorPrefs.GetBool(key, true);
            GUILayout.Space(3f);
            if (state) GUI.backgroundColor = Color.grey;
            EditorGUILayout.BeginHorizontal();
            GUILayout.Space(3f);
            GUI.changed = false;

            text = "<b><size=14>" + text + "</size></b>";
            if (state) text = "\u25B2 " + text;
            else text = "\u25BC " + text;
            if (!GUILayout.Toggle(true, text, style, GUILayout.MinWidth(20), GUILayout.MinHeight(30))) state = !state;
            if (GUI.changed) EditorPrefs.SetBool(key, state);
            GUILayout.Space(3f);
            EditorGUILayout.EndHorizontal();
            GUI.backgroundColor = Color.white;
            GUILayout.Space(3f);
            return state;
        }
        /// <summary>
        /// 开始内容区域 会适当缩进 并纵向排列
        /// </summary>
        /// <param name="style">样式</param>
        public static void BeginContents(string style = "hostview")
        {
            EditorGUILayout.BeginHorizontal();
            GUILayout.Space(10f);
            EditorGUILayout.BeginHorizontal(style, GUILayout.MinHeight(10f));
            EditorGUILayout.BeginVertical();
            GUILayout.Space(2f);
        }

        /// <summary>
        /// 结束内容区域 会适当缩进
        /// </summary>

        public static void EndContents()
        {
            GUILayout.Space(3f);
            EditorGUILayout.EndVertical();
            EditorGUILayout.EndHorizontal();
            GUILayout.Space(3f);
            EditorGUILayout.EndHorizontal();
            GUILayout.Space(3f);
        }


        /// <summary>
        /// 绘制属性
        /// </summary>
        /// <param name="label">属性显示文本</param>
        /// <param name="propertyName">属性名称</param>
        /// <param name="sb">序列化对象</param>
        /// <param name="pad">是否进行缩进</param>
        /// <param name="options">布局选项</param>
        public static void DrawProperty(string label, string propertyName, SerializedObject sb, bool pad, params GUILayoutOption[] options)
        {
            SerializedProperty sp = sb.FindProperty(propertyName);

            if (sp == null) return;
            if (pad)
            {
                EditorGUILayout.BeginHorizontal();
                GUILayout.Space(10f);
            }
            if (string.IsNullOrEmpty(label))
            {
                EditorGUILayout.PropertyField(sp, options);
            }
            else
            {
                EditorGUILayout.PropertyField(sp, new GUIContent(label), options);
            }
            if (pad)
            {
                GUILayout.Space(10f);
                EditorGUILayout.EndHorizontal();
            }
        }
        /// <summary>
        /// 绘制水平线
        /// </summary>
        /// <param name="beg"></param>
        /// <param name="length"></param>
        /// <param name="width"></param>
        /// <param name="color"></param>
        public static void DrawHLine(Vector2 beg, float length, float width, Color color)
        {

            Color col = GUI.color;
            GUI.color = color;
            Rect pos = new Rect(beg.x, beg.y - width * 0.5f, length, width);
            GUI.DrawTexture(pos, BlankTex);
            GUI.color = col;
        }
        /// <summary>
        /// 绘制垂直线
        /// </summary>
        /// <param name="beg"></param>
        /// <param name="length"></param>
        /// <param name="width"></param>
        /// <param name="color"></param>
        public static void DrawVLine(Vector2 beg, float length, float width, Color color)
        {

            Color col = GUI.color;
            GUI.color = color;
            Rect pos = new Rect(beg.x - width * 0.5f, beg.y, width, length);
            GUI.DrawTexture(pos, BlankTex);
            GUI.color = col;
        }
        /// <summary>
        /// 绘制中间带有三角形的贝塞尔曲线
        /// </summary>
        /// <param name="beg"></param>
        /// <param name="end"></param>
        /// <param name="width"></param>
        /// <param name="color"></param>
        public static void DrawBezierTriangleLine(Vector2 beg, Vector2 end, Color color, float width)
        {
            DrawBezierLine(beg, end, color, width);
            DrawTriange(beg, end, color);
        }

        /// <summary>
        /// 绘制贝塞尔曲线
        /// </summary>
        /// <param name="beg"></param>
        /// <param name="end"></param>
        /// <param name="color"></param>
        /// <param name="width"></param>
        /// <returns></returns>
        public static void DrawBezierLine(Vector2 beg, Vector2 end, Color color, float width)
        {
            Vector2 begTangent = new Vector2(beg.x, (beg.y + end.y) * 0.5f);
            Vector2 endTangent = new Vector2(end.x, (beg.y + end.y) * 0.5f);
            Handles.BeginGUI();
            Handles.DrawBezier(beg, end, begTangent, endTangent, color, null, width);
            Handles.EndGUI();
        }
        /// <summary>
        /// 绘制中间带有三角形的直线
        /// </summary>
        /// <param name="beg"></param>
        /// <param name="end"></param>
        /// <param name="width"></param>
        /// <param name="color"></param>
        public static void DrawTriangleLine(Vector2 beg, Vector2 end, Color color, float width)
        {
            Handles.color = color;
            Handles.BeginGUI();
            Handles.DrawAAPolyLine(null, width, beg, end);
            Handles.EndGUI();
            DrawTriange(beg, end, color);
        }
        /// <summary>
        /// 绘制三角形
        /// </summary>
        /// <param name="beg"></param>
        /// <param name="end"></param>
        /// <param name="color"></param>
        /// <param name="edgeSize"></param>
        public static void DrawTriange(Vector2 beg, Vector2 end, Color color, float edgeSize = 5f)
        {
            Vector2 middle = (beg + end) * 0.5f;

            Vector2 nor1 = (end - beg).normalized;
            Vector2 arg1 = edgeSize * nor1 * 2;
            Vector2 argM = middle + arg1;

            Vector2 argB = middle - arg1;

            Vector2 arg2 = Vector3.Cross(nor1, Vector3.forward);
            Vector2 argL = argB + edgeSize * arg2;
            Vector2 argR = argB - edgeSize * arg2;
            Handles.color = color;
            Handles.BeginGUI();
#if UNITY_4
            Handles.DrawAAPolyLine(argM, argL, argR, argM);
#else
            Handles.DrawAAConvexPolygon(argM, argL, argR);
#endif
            Handles.EndGUI();
        }
        /// <summary>
        /// 判断直线是否和一个点相交
        /// </summary>
        /// <param name="beg"></param>
        /// <param name="end"></param>
        /// <param name="width"></param>
        /// <param name="point"></param>
        /// <returns></returns>
        public static bool LineOverlap(Vector2 beg, Vector2 end, float width, Vector2 point)
        {
            return HandleUtility.DistancePointToLine(point, beg, end) < width;
        }

        /// <summary>
        /// 判断贝塞尔曲线是否和一个点相交
        /// </summary>
        /// <param name="beg"></param>
        /// <param name="end"></param>
        /// <param name="width"></param>
        /// <param name="point"></param>
        /// <returns></returns>
        public static bool BezierOverlap(Vector2 beg, Vector2 end, float width, Vector2 point)
        {
            Vector2 begTangent = new Vector2(beg.x, (beg.y + end.y) * 0.5f);
            Vector2 endTangent = new Vector2(end.x, (beg.y + end.y) * 0.5f);
            return HandleUtility.DistancePointBezier(point, beg, end, begTangent, endTangent) < width;
        }
    }
}

