using System;
using System.Collections.Generic;
using UnityEngine;
using System.Collections;
using System.IO;
using System.Runtime.InteropServices;
using System.Runtime.Serialization.Formatters.Binary;
using Object = UnityEngine.Object;

public static class Utility
{
    /// 定义代理 ///
    public delegate void VoidDelegate();
    public delegate void BoolDelegate(bool tf);
    public delegate void ObjectDelegate(Object obj);
    public delegate void MultiObjectsDelegate(Object[] objs);


    /// <summary>
    /// 深度拷贝
    /// </summary>
    public static T DeepClone<T>(T cp)
    {
        MemoryStream stream = new MemoryStream();
        BinaryFormatter formater = new BinaryFormatter();
        formater.Serialize(stream, cp);
        stream.Position = 0;
        T t = (T)formater.Deserialize(stream);
        stream.Dispose();
        return t;
    }

    /// <summary>
    /// 毫秒转换秒
    /// </summary>
    public static float MilliSecToSec(long ms)
    {
        return ms * 0.001f;
    }

    /// <summary>
    /// 获取当前时间（毫秒）
    /// </summary>
    /// <returns></returns>
    private static DateTime stTime = DateTime.Parse("1970-1-1");
    public static double GetCurTime()
    {
        TimeSpan ts = DateTime.UtcNow - stTime;
        double curTime = ts.TotalMilliseconds;
        return curTime;
    }

    /// <summary>
    /// 文件夹是否存在
    /// </summary>
    public static bool ContainsFolder(string path, string folderName)
    {
        path += "/" + folderName + "/";
        DirectoryInfo di = new DirectoryInfo(path);
        return di.Exists;
    }

    /// <summary>
    /// 查找GameObject节点
    /// </summary>
    public static GameObject FindNode(GameObject go, string nodeName)
    {
        if (go == null)
            return null;

        if (string.IsNullOrEmpty(nodeName))
            return go;

        Transform[] nodes = go.GetComponentsInChildren<Transform>(true);
        for (int i = 0; i < nodes.Length; ++i)
        {
            if (nodes[i] == null)
                continue;

            if (nodes[i].name == nodeName)
                return nodes[i].gameObject;
        }

        return null;
    }

    /// <summary>
    /// 查找节点--泛型查找
    /// </summary>
    public static T FindNode<T>(GameObject go, string childname) where T : Component
    {
        GameObject ret = FindNode(go, childname);
        if (ret == null)
            return null;

        return ret.GetComponent<T>();
    }

    /// <summary>
    /// 查找Transform节点
    /// </summary>
    public static Transform FindNode(Transform[] nodes, string name)
    {
        for (int i = 0; i < nodes.Length; i++)
        {
            if (nodes[i].name == name) return nodes[i];
        }
        return null;
    }

    /// <summary>
    /// 查找Transform节点列表
    /// </summary>
    public static List<Transform> FindNodes(Transform[] nodes, string name)
    {
        List<Transform> list = new List<Transform>();
        for (int i = 0; i < nodes.Length; i++)
        {
            if (nodes[i].name == name)
            {
                list.Add(nodes[i]);
            }
        }
        return list;
    }

    /// <summary>
    /// 查找节点--泛型查找
    /// </summary>
    public static T FindNode<T>(Transform[] nodes, string name) where T : Component
    {
        Transform tr = FindNode(nodes, name);
        if (tr) return tr.GetComponent<T>();
        return null;
    }

    /// <summary>
    /// 查找节点列表--泛型查找
    /// </summary>
    public static List<T> FindNodes<T>(Transform[] nodes, string name) where T : Component
    {
        List<T> list = new List<T>();
        List<Transform> trs = FindNodes(nodes, name);
        if (trs.Count > 0)
        {
            for (int i = 0; i < trs.Count; i++)
            {
                list.Add(trs[i].GetComponent<T>());
            }
        }
        return list;
    }

    /// <summary>
    /// 三维坐标拷贝
    /// </summary>
    public static void Vector3_Copy(ProtoBuf.Vector3Data v1, ref Vector3 v2, float scale = 1)
    {
        v2.x = v1.Vector3Data_X;
        v2.y = v1.Vector3Data_Y;
        v2.z = v1.Vector3Data_Z;

        v2 *= scale;
    }

    /// <summary>
    /// 旋转
    /// </summary>
    public static void Rotate(ref float x, ref float z, float angle)
    {
        float sin = Mathf.Sin(angle);
        float cos = Mathf.Cos(angle);
        float locationX = sin * z + cos * x;
        float locationZ = cos * z - sin * x;
        x = locationX;
        z = locationZ;
    }


    /// <summary>
    /// 矩形求交
    /// </summary>
    public static float CrossProduct(float x0, float y0, float x1, float y1) { return x0 * y1 - y0 * x1; }
    public static bool RectangleHitDefineCollision(
         Vector3 HitDefPos, float HitDefOrientation,
         Vector3 HitDef,
         Vector3 AttackeePos, float AttackeeOrientation,
         Vector3 AttackeeBounding)
    {
        //排除高度影响，以XZ平面坐标作为判定基准
        if (HitDefPos.y > AttackeePos.y + AttackeeBounding.y ||
            AttackeePos.y > HitDefPos.y + HitDef.y)
        {
            return false;
        }

        // 计算出第一个四边形的四个定点
        float x0 = -HitDef.x * 0.5f, z0 = -HitDef.z * 0.5f;
        float x1 = -HitDef.x * 0.5f, z1 = HitDef.z * 0.5f;
        Rotate(ref x0, ref z0, HitDefOrientation);
        Rotate(ref x1, ref z1, HitDefOrientation);
        Vector2 maxHit = new Vector2(Mathf.Max(Mathf.Abs(x0), Mathf.Abs(x1)), Mathf.Max(Mathf.Abs(z0), Mathf.Abs(z1)));
        float[] HitDefPointX = new float[4] {
         HitDefPos.x - x0,
         HitDefPos.x - x1,
         HitDefPos.x + x0,
         HitDefPos.x + x1};

        float[] HitDefPointZ = new float[4] {
         HitDefPos.z - z0,
         HitDefPos.z - z1,
         HitDefPos.z + z0,
         HitDefPos.z + z1};

        // 计算出第二个四边形的四个顶点
        x0 = -AttackeeBounding.x * 0.5f;
        z0 = -AttackeeBounding.z * 0.5f;
        x1 = -AttackeeBounding.x * 0.5f;
        z1 = AttackeeBounding.z * 0.5f;
        Rotate(ref x0, ref z0, AttackeeOrientation);
        Rotate(ref x1, ref z1, AttackeeOrientation);
        Vector2 maxAtk = new Vector2(Mathf.Max(Mathf.Abs(x0), Mathf.Abs(x1)), Mathf.Max(Mathf.Abs(z0), Mathf.Abs(z1)));
        float[] AttackeePointX = new float[4] {
         AttackeePos.x - x0,
         AttackeePos.x - x1,
         AttackeePos.x + x0,
         AttackeePos.x + x1};

        float[] AttackeePointZ = new float[4] {
         AttackeePos.z - z0,
         AttackeePos.z - z1,
         AttackeePos.z + z0,
         AttackeePos.z + z1};

        if (HitDefPos.x > AttackeePos.x + maxHit[0] + maxAtk[0] ||
            HitDefPos.x < AttackeePos.x - maxHit[0] - maxAtk[0] ||
            HitDefPos.z > AttackeePos.z + maxHit[1] + maxAtk[1] ||
            HitDefPos.z < AttackeePos.z - maxHit[1] - maxAtk[1])
            return false;

        // 拿四边形的四个顶点判断，是否在另外一个四边形的四条边的一侧
        for (int i = 0; i < 4; i++)
        {
            x0 = HitDefPointX[i];
            x1 = HitDefPointX[(i + 1) % 4];
            z0 = HitDefPointZ[i];
            z1 = HitDefPointZ[(i + 1) % 4];

            bool hasSameSidePoint = false;
            for (int j = 0; j < 4; j++)
            {
                float v = CrossProduct(x1 - x0, z1 - z0, AttackeePointX[j] - x0, AttackeePointZ[j] - z0);
                if (v < 0)
                {
                    hasSameSidePoint = true;
                    break;
                }
            }

            // 如果4个定点都在其中一条边的另外一侧，说明没有交点
            if (!hasSameSidePoint)
                return false;
        }

        // 所有边可以分割另外一个四边形，说明有焦点。
        return true;
    }

    /// <summary>
    /// 圆柱求交
    /// </summary>
    public static bool CylinderHitDefineCollision(
        Vector3 HitDefPos, float HitDefOrientation,
        float HitRadius, float HitDefHeight,
        Vector3 AttackeePos, float AttackeeOrientation,
        Vector3 AttackeeBounding)
    {
        //排除高度影响，以XZ平面坐标作为判定基准
        if (HitDefPos.y > AttackeePos.y + AttackeeBounding.y ||
            AttackeePos.y > HitDefPos.y + HitDefHeight)
            return false;

        float vectz = HitDefPos.z - AttackeePos.z;
        float vectx = HitDefPos.x - AttackeePos.x;
        if (vectx != 0 || vectz != 0)
            Rotate(ref vectx, ref vectz, -AttackeeOrientation);

        if ((Mathf.Abs(vectx) > (HitRadius + AttackeeBounding.z)) || (Mathf.Abs(vectz) > (HitRadius + AttackeeBounding.x)))
            return false;

        return true;
    }

    /// <summary>
    /// 圆环求交
    /// </summary>
    public static bool RingHitDefineCollision(
        Vector3 HitDefPos, float HitDefOrientation,
        float HitInnerRadius, float HitDefHeight, float HitOutRadius,
        Vector3 AttackeePos, float AttackeeOrientation,
        Vector3 AttackeeBounding)
    {
        //排除高度影响，以XZ平面坐标作为判定基准
        if (HitDefPos.y > AttackeePos.y + AttackeeBounding.y ||
            AttackeePos.y > HitDefPos.y + HitDefHeight)
            return false;

        float radius = Mathf.Min(AttackeeBounding.x, AttackeeBounding.z);
        float distance = (AttackeePos - HitDefPos).magnitude;
        if (distance + radius < HitInnerRadius || distance - radius > HitOutRadius)
            return false;

        return true;
    }

#if UNITY_EDITOR
    static GameObject mTempGo = null;
#endif
    /// <summary>
    /// 扇形求交
    /// </summary>
    public static bool FanHitDefineCollision(
        Vector3 HitDefPos, float HitDefOrientation,
        float HitRadius, float HitDefHeight, float HitStartAngle, float HitEndAngle,
        Vector3 AttackeePos, float AttackeeOrientation,
        Vector3 AttackeeBounding)
    {
        Vector3 selfForward = Quaternion.Euler(0, HitDefOrientation * Mathf.Rad2Deg, 0) * Vector3.forward;
        Vector3 targetForward = AttackeePos - HitDefPos;
        float angle = Vector3.Angle(selfForward, targetForward);
        if (angle > HitStartAngle / 2)
            return false;
        float distance = Vector3.Distance(HitDefPos, AttackeePos);
        if (distance > HitRadius)
            return false;

#if UNITY_EDITOR
        if (mTempGo != null)
            GameObject.DestroyImmediate(mTempGo);
        mTempGo = new GameObject("FanAttackFrame");
        JMLEllipsoidCurve jml = mTempGo.AddComponent<JMLEllipsoidCurve>();
        jml.Radius = new Vector2(HitRadius * 2, HitRadius * 2);
        jml.EllipsoidAmplitude = HitStartAngle * Mathf.Deg2Rad;
        jml.Offset = HitDefOrientation - (Mathf.PI / 2.0f) - (HitStartAngle * Mathf.Deg2Rad / 2.0f);
        jml.Offset = jml.Offset > Mathf.PI * 2 ? jml.Offset - Mathf.PI : jml.Offset;
        mTempGo.transform.position = HitDefPos;
        mTempGo.transform.rotation = Quaternion.Euler(new Vector3(-90f, 0f, 0f));
#endif

        return true;
    }

    /// <summary>
    /// 两个包围盒求交
    /// </summary>
    public static bool BoundIntersect(Bounds bound0, Bounds bound1)
    {
        if (bound0.min.x > bound1.max.x) return false;
        if (bound0.min.y > bound1.max.y) return false;
        if (bound0.min.z > bound1.max.z) return false;

        if (bound0.max.x < bound1.min.x) return false;
        if (bound0.max.y < bound1.min.y) return false;
        if (bound0.max.z < bound1.min.z) return false;

        return true;
    }

    /// <summary>
    /// 方向换算角度
    /// </summary>
    public static float HorizontalAngle(Vector3 direction)
    {
        return Mathf.Atan2(direction.x, direction.z) * Mathf.Rad2Deg;
    }

    /// <summary>
    /// 根据坐标轴位置获取直线上的点
    /// </summary>
    /// <param name="linePot1">直线点1</param>
    /// <param name="linePot2">直线点2</param>
    /// <param name="coord">坐标系数（确定的x或y）</param>
    /// <param name="type">0：已知x求y， 1：已知y求x</param>
    /// <returns></returns>
    public static float GetPointOnLine(Vector2 linePot1, Vector2 linePot2, float coord, int type)
    {
        /// 平行于Y轴 ///
        if (linePot1.x == linePot2.x)
        {
            if (type == 0)
            {
                Debug.Log("LY : can not get y according to x !!! ");
                return 0;
            }
            else if (type == 1)
            {
                return linePot1.x;
            }
            else
            {
                Debug.Log("LY : Utility::GetPointOnLine type error !!! ");
                return 0;
            }
        }
        /// 平行于X轴 ///
        else if (linePot1.y == linePot2.y)
        {
            if (type == 0)
            {
                return linePot1.y;
            }
            else if (type == 1)
            {
                Debug.Log("LY : can not get x according to y !!! ");
                return 0;
            }
            else
            {
                Debug.Log("LY : Utility::GetPointOnLine type error !!! ");
                return 0;
            }
        }

        float a = (linePot1.y - linePot2.y) / (linePot1.x - linePot2.x);
        float b = linePot1.y - a * linePot1.x;

        return GetPointOnLine(a, b, coord, type);
    }

    /// <summary>
    /// 根据坐标轴位置获取直线上的点(直线方程：y = ax + b)
    /// </summary>
    /// <param name="ratioA">系数a</param>
    /// <param name="ratioB">系数b</param>
    /// <param name="coord">坐标系数（确定的x或y）</param>
    /// <param name="type">0：已知x求y， 1：已知y求x</param>
    /// <returns></returns>
    private static float GetPointOnLine(float ratioA, float ratioB, float coord, int type)
    {
        if (type == 0)
        {
            return ratioA * coord + ratioB;
        }
        else if (type == 1)
        {
            /// 平行于x轴 ///
            if (ratioA == 0)
            {
                return 0;
            }
            return (coord - ratioB) / ratioA;
        }
        else
        {
            Debug.Log("LY : Utility::GetPointOnLine type error !!! " + type);
        }

        return 0f;
    }

    /// <summary>
    /// 实例对象
    /// </summary>
    /// <param name="obj"></param>
    /// <returns></returns>
    public static Object Instantiate(Object obj)
    {
        Object newObj = Object.Instantiate(obj);
        return newObj;
    }

    /// <summary>
    /// 平滑插值
    /// </summary>
    /// <param name="SrcNum">原数据</param>
    /// <param name="DstNum">目标数据</param>
    /// <param name="DeltaTime">时间系数</param>
    /// <param name="PowParam">影响缩放速度参数</param>
    /// <returns></returns>
    public static float SmoothSlerp(ref float SrcNum, ref float DstNum, float DeltaTime, float PowParam)
    {
        return SrcNum + (DstNum - SrcNum) * (1 - Mathf.Pow(0.5f, PowParam * DeltaTime));
    }

    /// <summary>
    /// 设置物体及子物体的层
    /// </summary>
    /// <param name="trans"></param>
    /// <param name="layerName"></param>
    public static void SetGOLayerIncludeChilden(Transform trans, string layerName)
    {
        int index = LayerMask.NameToLayer(layerName);
        if (index < 0)
        {
            return;
        }

        trans.gameObject.layer = index;
        for (int a = 0; a < trans.childCount; a++)
        {
            SetGOLayerIncludeChilden(trans.GetChild(a), layerName);
        }
    }

    /// <summary>
    /// 缩放游戏对象
    /// </summary>
    /// <param name="go"></param>
    /// <param name="scale"></param>
    public static void ScaleGameOject(GameObject go, Vector3 scale)
    {
        if (go == null)
            return;
        if (go.transform.localScale == scale)
            return;
        go.transform.localScale = scale;
    }

    #region xiaoyu
    /// <summary>
    /// 计算单个文字的准确位置
    /// </summary>
    /// <param name="lab">显示字符串的UI控件</param>
    /// <param name="text">要显示的所有文字</param>
    /// <param name="index">要计算位置的文字的index</param>
    /// <returns></returns>
    private static List<Vector3> verts = new List<Vector3>();
    private static List<int> indices = new List<int>();

    public static Vector2 CalculateSinglePos(UILabel lab, string text, string indexStr)
    {
        while(verts.Count>0)
        {
            verts.RemoveAt(verts.Count - 1);
        }
        while (indices.Count > 0)
        {
            indices.RemoveAt(indices.Count - 1);
        }
        return CalculateSinglePos(lab, text, indexStr.Length - 1);
    }

    public static Vector2 CalculateSinglePos(UILabel lab, string text, int index)
    {
        UpdateCharacterPosition(lab, text);
        index = indices.IndexOf(index);
        Vector3 p1;
        if (index != -1 && verts.Count > index * 2 + 1)
            p1 = (verts[index * 2] + verts[index * 2 + 1]) * 0.5f;
        else
            p1 = (verts[verts.Count - 1] + verts[verts.Count - 2]) * 0.5f;
        return p1;
    }


    public static void UpdateCharacterPosition(UILabel lab, string str)
    {
        //计算当前所有字符的位置
        lab.text = str;
        lab.UpdateNGUIText();
        NGUIText.PrintExactCharacterPositions(str, Utility.verts, Utility.indices);
        List<Vector3> verts = Utility.verts;
        for (int i = 0; i < verts.Count; i++)
        {
            switch (lab.pivot)
            {
                case UIWidget.Pivot.TopLeft:
                    verts[i] += new Vector3(0, 0, 0);
                    break;
                case UIWidget.Pivot.Top:
                    verts[i] += new Vector3(-lab.width * 0.5f, 0, 0);
                    break;
                case UIWidget.Pivot.TopRight:
                    verts[i] += new Vector3(-lab.width, 0, 0);
                    break;
                case UIWidget.Pivot.Left:
                    verts[i] += new Vector3(0, lab.height * 0.5f, 0);
                    break;
                case UIWidget.Pivot.Center:
                    verts[i] += new Vector3(-lab.width * 0.5f, lab.height * 0.5f, 0);
                    break;
                case UIWidget.Pivot.Right:
                    verts[i] += new Vector3(-lab.width, lab.height * 0.5f, 0);
                    break;
                case UIWidget.Pivot.BottomLeft:
                    verts[i] += new Vector3(0, lab.height, 0);
                    break;
                case UIWidget.Pivot.Bottom:
                    verts[i] += new Vector3(-lab.width * 0.5f, lab.height, 0);
                    break;
                case UIWidget.Pivot.BottomRight:
                    verts[i] += new Vector3(-lab.width, lab.height, 0);
                    break;
                default:
                    break;
            }
        }
    }
    #endregion
}