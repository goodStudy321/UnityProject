using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BezierTool
{
    /// <summary>
    /// ���Ա�����
    /// </summary>
    /// <param name="p1">ʼ��</param>
    /// <param name="p2">�յ�</param>
    /// <param name="t">ʱ��ٷֱ�</param>
    /// <returns></returns>
    public static Vector3 GetLinearPoint(Vector3 p1, Vector3 p2, float t)
    {
        t = Mathf.Clamp01(t);
        return p1 + ((p2 - p1) * t);
    }

    /// <summary>
    /// ���ױ�����
    /// </summary>
    /// <param name="p1">ʼ��</param>
    /// <param name="p2">�м��</param>
    /// <param name="p3">�յ�</param>
    /// <param name="t">ʱ��ٷֱ�</param>
    /// <returns></returns>
    public static Vector3 GetQuadraticCurvePoint(Vector3 p1, Vector3 p2, Vector3 p3, float t)
    {
        t = Mathf.Clamp01(t);
        Vector3 part1 = Mathf.Pow(1 - t, 2) * p1;
        Vector3 part2 = 2 * (1 - t) * t * p2;
        Vector3 part3 = Mathf.Pow(t, 2) * p3;
        return part1 + part2 + part3;
    }

    /// <summary>
    /// ���װ�����
    /// </summary>
    /// <param name="p1">ʼ��</param>
    /// <param name="p2">�м��</param>
    /// <param name="p3">�м��</param>
    /// <param name="p4">�յ�</param>
    /// <param name="t">ʱ��ٷֱ�</param>
    /// <returns></returns>
    public static Vector3 GetCubicCurvePoint(Vector3 p1, Vector3 p2, Vector3 p3, Vector3 p4, float t)
    {
        t = Mathf.Clamp01(t);
        Vector3 part1 = Mathf.Pow(1 - t, 3) * p1;
        Vector3 part2 = 3 * Mathf.Pow(1 - t, 2) * t * p2;
        Vector3 part3 = 3 * (1 - t) * Mathf.Pow(t, 2) * p3;
        Vector3 part4 = Mathf.Pow(t, 3) * p4;
        return part1 + part2 + part3 + part4;
    }
    
    /// <summary>
    /// n�ױ�����
    /// </summary>
    /// <param name="t">ʱ��ٷֱ�</param>
    /// <param name="path">·����</param>
    /// <returns></returns>
    public static Vector3 GetPoint(float t, params Vector3[] path)
    {
        if (t <= 0) return path[0];
        if (t >= 1) return path[path.Length - 1];
        Vector3 a = Vector3.zero;
        Vector3 b = Vector3.zero;
        float total = 0f;
        float segmentDistance = 0f;
        float pathLength = GetLength(path);
        for (int i = 0; i < path.Length - 1; i++)
        {
            segmentDistance = Vector3.Distance(path[i], path[i + 1]) / pathLength;
            if (total + segmentDistance > t)
            {
                a = path[i];
                b = path[i + 1];
                break;
            }
            else
            {
                total += segmentDistance;
            }
        }
        t -= total;
        return Vector3.Lerp(a, b, t / segmentDistance);
    }

    /// <summary>
    /// ��ȡ·���ܳ���
    /// </summary>
    /// <param name="path"></param>
    /// <returns></returns>
    public static float GetLength(Vector3[] path)
    {
        if (path == null)
            return 0;
        float dist = 0f;
        for (int i = 0; i < path.Length; i++)
        {
            dist += Vector3.Distance(path[i], path[i == path.Length - 1 ? i : i + 1]);
        }
        return dist;
    }
}
