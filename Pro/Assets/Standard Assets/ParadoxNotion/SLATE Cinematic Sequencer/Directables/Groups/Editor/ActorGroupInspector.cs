#if UNITY_EDITOR

using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Reflection;

namespace Slate{

	[CustomEditor(typeof(ActorGroup))]
	public class ActorGroupInspector : CutsceneGroupInspector {

		private ActorGroup group{
			get {return (ActorGroup)target;}
		}

		public override void OnInspectorGUI(){

			base.OnInspectorGUI();

			group.referenceMode = (CutsceneGroup.ActorReferenceMode)EditorGUILayout.EnumPopup("Reference Mode", group.referenceMode);
			group.initialTransformation = (CutsceneGroup.ActorInitialTransformation)EditorGUILayout.EnumPopup("Initial Coordinates", group.initialTransformation);
			if (group.initialTransformation == CutsceneGroup.ActorInitialTransformation.UseLocal){
				group.initialLocalPosition = EditorGUILayout.Vector3Field("Initial Local Position", group.initialLocalPosition);
				group.initialLocalRotation = EditorGUILayout.Vector3Field("Initial Local Rotation", group.initialLocalRotation);
			}
		}
	}
}

#endif