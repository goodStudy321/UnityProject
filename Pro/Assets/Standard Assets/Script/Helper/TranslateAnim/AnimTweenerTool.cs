using UnityEngine;


/// <summary>
/// ���ù���
/// </summary>
static public class AnimTweenerTool
{
    /// <summary>
    /// ��ȡ���ڵ��㼶
    /// </summary>
    /// <param name="obj"></param>
    /// <returns></returns>
    static public string GetHierarchy(GameObject obj)
    {
        if (obj == null) return "";
        string path = obj.name;

        while (obj.transform.parent != null)
        {
            obj = obj.transform.parent.gameObject;
            path = obj.name + "\\" + path;
        }
        return path;
    }


}
