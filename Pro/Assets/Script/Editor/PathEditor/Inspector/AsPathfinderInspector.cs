using UnityEditor;
using UnityEngine;
//using System.Collections;

//[CanEditMultipleObjects]
[CustomEditor(typeof(AsPathfinderInEditor))]
public class AsPathfinderInspector : Editor
{
    private AsPathfinderInEditor mTarget;

    void OnEnable()
    {
        mTarget = target as AsPathfinderInEditor;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if(mTarget == null)
        {
            return;
        }

        mTarget.MapId = (uint)EditorGUILayout.IntField("地图ID", (int)mTarget.MapId);
        mTarget.MapType = (uint)EditorGUILayout.IntField("地图类型(1:野外 2：副本)", (int)mTarget.MapType);
        mTarget.Tilesize = EditorGUILayout.FloatField("格子大小", mTarget.Tilesize);
        mTarget.MaxFalldownHeight = EditorGUILayout.FloatField("最大掉落高度", mTarget.MaxFalldownHeight);
        mTarget.ClimbLimit = EditorGUILayout.FloatField("最大爬坡高度", mTarget.ClimbLimit);
        mTarget.MoveDiagonal = EditorGUILayout.Toggle("允许斜线移动", mTarget.MoveDiagonal);

        mTarget.MapPortalTag = EditorGUILayout.TextField("传送点标签", mTarget.MapPortalTag);
        //mTarget.MapEventPointTag = EditorGUILayout.TextField("事件点标签", mTarget.MapEventPointTag);

        mTarget.DrawMap = EditorGUILayout.Toggle("显示寻路范围", mTarget.DrawMap);
        mTarget.CheckFullTileSize = EditorGUILayout.Toggle("标准检测", mTarget.CheckFullTileSize);
    }

    private void OnSceneGUI()
    {
        //SceneView.RepaintAll();
    }
}
