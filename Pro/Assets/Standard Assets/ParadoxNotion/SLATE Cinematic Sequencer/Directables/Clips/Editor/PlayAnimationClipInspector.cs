#if UNITY_EDITOR

using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Reflection;

namespace Slate{

	[CustomEditor(typeof(ActionClips.PlayAnimationClip))]
	public class PlayAnimationClipInspector : ActionClipInspector<ActionClips.PlayAnimationClip> {

		public override void OnInspectorGUI(){

			base.OnInspectorGUI();

			if (action.animationClip != null && GUILayout.Button("Set at Clip Length")){
				action.length = action.animationClip.length / action.playbackSpeed;	
			}
		}
	}
}

#endif