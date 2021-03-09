using UnityEditor;
using UnityEngine;
//using System.Collections;

//[CanEditMultipleObjects]
[CustomEditor(typeof(DoorBlock))]
public class DoorBlockInspector : Editor
{
    private DoorBlock mTarget;

    void OnEnable()
    {
        mTarget = target as DoorBlock;
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if(mTarget == null)
        {
            return;
        }

        mTarget.mDoorBlockId = (uint)Mathf.Abs(EditorGUILayout.IntField("动态门Id", (int)mTarget.mDoorBlockId));
        mTarget.mDefaultState = EditorGUILayout.Toggle("默认打开", mTarget.mDefaultState);
    }
}
