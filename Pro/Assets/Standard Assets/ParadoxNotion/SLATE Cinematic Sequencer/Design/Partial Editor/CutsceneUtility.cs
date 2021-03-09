#if UNITY_EDITOR

using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;

namespace Slate{

	///Utilities specific to Cutscenes
	public static class CutsceneUtility {

		[System.NonSerialized]
		private static string copyJson;
		[System.NonSerialized]
		private static System.Type copyType;
		[System.NonSerialized]
		private static IDirectable _selectedObject;
		[System.NonSerialized]
		public static Dictionary<AnimatedParameter, ChangedParameterCallbacks> changedParameterCallbacks = new Dictionary<AnimatedParameter, ChangedParameterCallbacks>();

		public static event System.Action<IDirectable> onSelectionChange;
		public static event System.Action<IAnimatableData> onRefreshAllAnimationEditors;

		public struct ChangedParameterCallbacks{
			public System.Action Restore;
			public System.Action Commit;
			public ChangedParameterCallbacks(System.Action restore, System.Action commit){
				Restore = restore;
				Commit = commit;
			}
		}

		public static IDirectable selectedObject{
			get {return _selectedObject;}
			set
			{
				//select the root cutscene which in turns display the inspector of the object within it.
				if (value != null){	UnityEditor.Selection.activeObject = value.root.context; }
				_selectedObject = value;
				if (onSelectionChange != null){
					onSelectionChange(value);
				}
			}
		}

		public static void RefreshAllAnimationEditorsOf(IAnimatableData animatable){
			if (onRefreshAllAnimationEditors != null){
				onRefreshAllAnimationEditors(animatable);
			}
		}

		public static System.Type GetCopyType(){
			return copyType;
		}

		public static void SetCopyType(System.Type type){
			copyType = type;
		}

		public static void CopyClip(ActionClip action){
			copyJson = JsonUtility.ToJson(action, false);
			copyType = action.GetType();
		}

		public static void CutClip(ActionClip action){
			copyJson = JsonUtility.ToJson(action, false);
			copyType = action.GetType();
			(action.parent as CutsceneTrack).DeleteAction(action);
		}

		public static ActionClip PasteClip(CutsceneTrack track, float time){
			if (copyType != null){
				var newAction = track.AddAction(copyType, time);
				JsonUtility.FromJsonOverwrite(copyJson, newAction);
				newAction.startTime = time;

				var nextAction = track.actions.FirstOrDefault(a => a.startTime > newAction.startTime);
				if (nextAction != null && newAction.endTime > nextAction.startTime){
					newAction.endTime = nextAction.startTime;
				}

				return newAction;
			}
			return null;
		}		
	}
}

#endif