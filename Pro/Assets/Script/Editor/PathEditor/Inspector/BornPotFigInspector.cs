using UnityEditor;
using UnityEngine;
//using System.Collections;

//[CanEditMultipleObjects]
[CustomEditor(typeof(BornPotFig))]
public class BornPotFigInspector : Editor
{
    private BornPotFig mTarget;

    void OnEnable()
    {
        mTarget = target as BornPotFig;
        //if(mTarget.mJumpPaths.Count <= 0)
        //{
        //    mTarget.AddOneJumpPath();
        //}
    }

    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        if(mTarget == null)
        {
            return;
        }

        mTarget.mCampId = (uint)Mathf.Abs(EditorGUILayout.IntField("阵型Id", (int)mTarget.mCampId));
        
    }
}
