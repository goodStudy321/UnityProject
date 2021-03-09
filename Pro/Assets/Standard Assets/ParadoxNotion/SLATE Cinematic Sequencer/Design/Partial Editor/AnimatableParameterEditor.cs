#if UNITY_EDITOR

using UnityEngine;
using UnityEditor;
using System.Collections.Generic;
using System.Linq;

namespace Slate{

	public static class AnimatableParameterEditor {

		private static bool isDraggingTime;
		private static Dictionary<AnimatedParameter, Rect> fixedCurveRects = new Dictionary<AnimatedParameter, Rect>();

		public static void ShowParameter(AnimatedParameter animParam, IKeyable keyable, SerializedProperty serializedProperty = null){

			if (!animParam.isValid){
				GUILayout.Label("Animatable Parameter is invalid");
				return;
			}

			var e = Event.current;
			var keyableLength = keyable.endTime - keyable.startTime;
			var rootTime = keyable.root.currentTime;
			var localTime = Mathf.Clamp(rootTime - keyable.startTime, 0, keyableLength);
			var isRecording = rootTime >= keyable.startTime && rootTime <= keyable.endTime && rootTime > 0;
			var foldOut = EditorTools.GetObjectFoldOut(animParam);
			var hasAnyKey = animParam.HasAnyKey();
			var hasKeyNow = animParam.HasKey(localTime);
			var hasChanged = animParam.HasChanged();
			var parameterEnabled = animParam.enabled;
			var lastRect = new Rect();

			GUI.backgroundColor = new Color(0, 0.4f, 0.4f, 0.5f);
			GUILayout.BeginVertical(Slate.Styles.headerBoxStyle);
			GUI.backgroundColor = Color.white;

			GUILayout.BeginHorizontal();


			var sFold = foldOut? "▼" : "▶";
			var sName = animParam.ToString();


			GUI.backgroundColor = hasAnyKey && parameterEnabled? new Color(1,0.6f,0.6f) : Color.white;
			GUI.backgroundColor = hasAnyKey && parameterEnabled && isRecording? Slate.Styles.recordingColor : GUI.backgroundColor;
			GUILayout.Label(sFold, GUILayout.Width(13));
			lastRect = GUILayoutUtility.GetLastRect();
			GUI.enabled = !animParam.isExternal || isRecording;

			DoParameterField(string.Format("<b>{0}</b>", sName), animParam, localTime);

			GUI.enabled = true;
			GUI.backgroundColor = Color.white;


			EditorGUIUtility.AddCursorRect(lastRect, MouseCursor.Link);
			if (e.type == EventType.MouseDown && e.button == 0 && lastRect.Contains(e.mousePosition)){
				EditorTools.SetObjectFoldOut(animParam, !foldOut);
				e.Use();
			}



			GUI.enabled = hasAnyKey && parameterEnabled;
			if (GUILayout.Button(Slate.Styles.previousKeyIcon, GUIStyle.none, GUILayout.Height(20), GUILayout.Width(16))){
				keyable.root.currentTime = animParam.GetKeyPrevious(localTime) + keyable.startTime;
			}
			EditorGUIUtility.AddCursorRect(GUILayoutUtility.GetLastRect(), MouseCursor.Link);


			GUI.enabled = parameterEnabled;
			GUI.color = hasKeyNow && parameterEnabled? new Color(1,0.3f,0.3f) : Color.white;
			GUI.color = hasAnyKey && hasChanged? Color.green : GUI.color;
			if (GUILayout.Button(Slate.Styles.keyIcon, GUIStyle.none, GUILayout.Height(20), GUILayout.Width(16))){
				if (e.alt){ //temporary solution
					animParam.scriptExpression = "value";
					EditorTools.SetObjectFoldOut(animParam, true);
				} else {
					if (!hasKeyNow || hasChanged){
						animParam.SetKeyCurrent(localTime);
					} else {
						animParam.RemoveKey(localTime);
					}
				}
			}
			GUI.color = Color.white;
			EditorGUIUtility.AddCursorRect(GUILayoutUtility.GetLastRect(), MouseCursor.Link);


			GUI.enabled = hasAnyKey && parameterEnabled;
			if (GUILayout.Button(Slate.Styles.nextKeyIcon, GUIStyle.none, GUILayout.Height(20), GUILayout.Width(16))){
				keyable.root.currentTime = animParam.GetKeyNext(localTime) + keyable.startTime;
			}
			EditorGUIUtility.AddCursorRect(GUILayoutUtility.GetLastRect(), MouseCursor.Link);


			GUILayout.Space(2);

			GUI.enabled = (hasAnyKey && parameterEnabled) || animParam.isExternal;
			if (GUILayout.Button(Slate.Styles.gearIcon, GUIStyle.none, GUILayout.Height(20), GUILayout.Width(16))){
				DoParamGearContextMenu(animParam, keyable);
			}
			EditorGUIUtility.AddCursorRect(GUILayoutUtility.GetLastRect(), MouseCursor.Link);

			GUI.enabled = true;
			GUILayout.EndHorizontal();

			//...
			GUILayout.EndVertical();


			if ( EditorGUILayout.BeginFadeGroup(EditorTools.GetObjectFoldOutFaded(animParam)) ){

				GUI.color = new Color(0.5f,0.5f,0.5f,0.3f);
				GUILayout.BeginVertical(Slate.Styles.clipBoxFooterStyle);
				GUI.color = Color.white;

#if USE_EXPRESSIONS
				var exp = animParam.scriptExpression;
				if (!string.IsNullOrEmpty(exp)){
					exp = EditorGUILayout.TextField(exp);
					if (exp != animParam.scriptExpression){
						animParam.scriptExpression = exp;
						animParam.CompileExpression();
					}

					if (animParam.compileException != null){
						EditorGUILayout.HelpBox(animParam.compileException.Message, MessageType.Error);
					}
				}
#endif

				string info = null;
				if (!parameterEnabled){
					info = "Parameter is disabled or overriden.";
				}

				if (info == null && !hasAnyKey){
					info = "Parameter is not yet animated. You can make it so by creating the first key.";
				}

				if (info == null && keyableLength == 0 && hasAnyKey){
					info = "Length of Clip is zero. Can not display Curve Editor.";
				}

				if (info != null){

					GUILayout.Label(info);

				} else {

					if (animParam.isExternal && !isRecording){
						GUILayout.Label("This Parameter can only be edited when time is within the clip range.");
					}

					DoCurveBox(animParam, keyable, isRecording);
				}

				GUILayout.EndVertical();
				GUILayout.Space(5);
			}

			EditorGUILayout.EndFadeGroup();			
		}

		//This is basicaly used in Tracks. Shows only the parameter controls in a vertical style for space conservation.
		public static void ShowMiniParameterKeyControls(AnimatedParameter animParam, IKeyable keyable){
			
			if (animParam == null){
				return;
			}

			var rootTime = keyable.root.currentTime;
			var keyableLength = keyable.endTime - keyable.startTime;
			var keyableTime = Mathf.Clamp(rootTime - keyable.startTime, 0, keyableLength);
			var isRecording = rootTime >= keyable.startTime && rootTime <= keyable.endTime && rootTime > 0;

			var hasAnyKey = animParam.HasAnyKey();
			var hasKeyNow = animParam.HasKey(keyableTime);
			var hasChanged = animParam.HasChanged();

			GUI.color = EditorGUIUtility.isProSkin? new Color(0,0,0,0.2f) : new Color(0,0,0,0.5f);
			GUILayout.BeginHorizontal(Slate.Styles.headerBoxStyle);
			GUI.color = Color.white;
			GUILayout.FlexibleSpace();
			
			if (GUILayout.Button(Slate.Styles.previousKeyIcon, GUIStyle.none, GUILayout.Height(18), GUILayout.Width(18))){
				keyable.root.currentTime = animParam.GetKeyPrevious(keyableTime) + keyable.startTime;
			}

			GUI.color = hasKeyNow? Color.red : Color.white;
			GUI.color = hasAnyKey && hasChanged? Color.green : GUI.color;
			if (GUILayout.Button(Slate.Styles.keyIcon, GUIStyle.none, GUILayout.Height(18), GUILayout.Width(18))){
				if (!hasKeyNow || hasChanged){
					animParam.SetKeyCurrent(keyableTime);
				} else {
					animParam.RemoveKey(keyableTime);
				}
			}
			GUI.color = Color.white;

			if (GUILayout.Button(Slate.Styles.nextKeyIcon, GUIStyle.none, GUILayout.Height(18), GUILayout.Width(18))){
				keyable.root.currentTime = animParam.GetKeyNext(keyableTime) + keyable.startTime;
			}

			GUILayout.FlexibleSpace();
			GUILayout.EndHorizontal();

			GUI.enabled = !animParam.isExternal || isRecording;
			
			GUI.color = EditorGUIUtility.isProSkin? new Color(0.5f,0.5f,0.5f,0.5f) : new Color(0,0,0,0.3f);
			GUILayout.BeginVertical(Slate.Styles.clipBoxFooterStyle);
			GUI.color = Color.white;
			DoParameterField(null, animParam, keyableTime);
			GUILayout.EndVertical();
			GUI.enabled = true;
		}

		public static void DoParamGearContextMenu(AnimatedParameter animParam, IKeyable keyable){
			
			var keyableLength = keyable.endTime - keyable.startTime;
			var keyableTime = Mathf.Clamp(keyable.root.currentTime - keyable.startTime, 0, keyableLength);

			var menu = new GenericMenu();
			if (animParam.HasKey(keyableTime)){
				menu.AddDisabledItem(new GUIContent("Add Key"));
				menu.AddItem(new GUIContent("Remove Key"), false, ()=>{ animParam.RemoveKey(keyableTime); });
			} else {
				menu.AddItem(new GUIContent("Add Key"), false, ()=>{ animParam.SetKeyCurrent(keyableTime); });
				menu.AddDisabledItem(new GUIContent("Remove Key"));
			}

			menu.AddItem(new GUIContent("Pre Wrap Mode/Clamp"), false, ()=>{ animParam.SetPreWrapMode(WrapMode.ClampForever); });
			menu.AddItem(new GUIContent("Pre Wrap Mode/Loop"), false, ()=>{ animParam.SetPreWrapMode(WrapMode.Loop); });
			menu.AddItem(new GUIContent("Pre Wrap Mode/PingPong"), false, ()=>{ animParam.SetPreWrapMode(WrapMode.PingPong); });

			menu.AddItem(new GUIContent("Post Wrap Mode/Clamp"), false, ()=>{ animParam.SetPostWrapMode(WrapMode.ClampForever); });
			menu.AddItem(new GUIContent("Post Wrap Mode/Loop"), false, ()=>{ animParam.SetPostWrapMode(WrapMode.Loop); });
			menu.AddItem(new GUIContent("Post Wrap Mode/PingPong"), false, ()=>{ animParam.SetPostWrapMode(WrapMode.PingPong); });

			// menu.AddItem(new GUIContent( animParam.enabled? "Disable" : "Enable" ), false, ()=>{ animParam.SetEnabled( !animParam.enabled, keyableTime ); });

			menu.AddSeparator("/");
			menu.AddItem(new GUIContent("Reset Animation"), false, ()=>
			{
				if (EditorUtility.DisplayDialog("Reset Animation", "All animation keys will be removed for this parameter.\nAre you sure?", "Yes", "No")){
					if (animParam.isExternal){animParam.RestoreSnapshot();}
					animParam.Reset();
					if (animParam.isExternal){animParam.SetSnapshot();}
				}
			});

			if (animParam.isExternal){
				menu.AddItem(new GUIContent("Remove Parameter"), false, ()=>
				{
					if (EditorUtility.DisplayDialog("Remove Parameter", "Completely Remove Parameter.\nAre you sure?", "Yes", "No")){
						animParam.RestoreSnapshot();
						keyable.animationData.animatedParameters.Remove( animParam );
						CutsceneUtility.RefreshAllAnimationEditorsOf(keyable.animationData);
					}
				});
			}

			menu.ShowAsContext();
			Event.current.Use();
		}		

		///Used when the Animated Parameter is a property and we don't have a SerializedProperty.
		public static void DoParameterField(string name, AnimatedParameter animParam, float time){

			if (animParam == null){
				GUILayout.Label("null parameter"); //this should never happen but it did
				return;				
			}

			if (animParam.targetObject == null || animParam.targetObject.Equals(null)){
				GUILayout.Label("Target is Null");
				return;
			}

			if (!animParam.enabled){
				GUILayout.Label(name);
				return;					
			}

			try
			{
				var type = animParam.animatedType;
				var animParamAtt = animParam.animatableAttribute;
				var value = animParam.GetCurrentValue();
				var newValue = value;
				
				EditorGUI.BeginChangeCheck();

				if (type == typeof(bool)){
					name = name == null? "Value" : name;
					newValue = EditorGUILayout.Toggle(name, (bool)value);
				}

				if (type == typeof(float)){
					if (animParamAtt != null && animParamAtt.min != null && animParamAtt.max != null){
						name = name == null? string.Empty : name;
						var min = animParamAtt.min.Value;
						var max = animParamAtt.max.Value;
						newValue = EditorGUILayout.Slider(name, (float)value, min, max);
					} else {
						name = name == null? "Value" : name;
						newValue = EditorGUILayout.FloatField(name, (float)value);
					}
				}

				if (type == typeof(int)){
					if (animParamAtt != null && animParamAtt.min != null && animParamAtt.max != null){
						name = name == null? string.Empty : name;
						var min = animParamAtt.min.Value;
						var max = animParamAtt.max.Value;
						newValue = EditorGUILayout.IntSlider(name, (int)value, (int)min, (int)max);
					} else {
						name = name == null? "Value" : name;
						newValue = EditorGUILayout.IntField(name, (int)value);
					}
				}

				if (type == typeof(Vector2)){
					name = name == null? string.Empty : name;
					newValue = EditorGUILayout.Vector2Field(name, (Vector2)value);
				}

				if (type == typeof(Vector3)){
					name = name == null? string.Empty : name;
					newValue = EditorGUILayout.Vector3Field(name, (Vector3)value);
				}		

				if (type == typeof(Color)){
					name = name == null? string.Empty : name;
					GUI.backgroundColor = Color.white; //to avoid tinting
					newValue = EditorGUILayout.ColorField(name, (Color)value);
				}

				if (EditorGUI.EndChangeCheck() && newValue != value){
					animParam.SetCurrentValue(newValue);
					if (Prefs.autoKey || (animParam.isExternal && !animParam.HasAnyKey()) ){
						animParam.TryAutoKey(time);
					}
				}
			}
			
			catch (System.Exception exc)
			{
				GUILayout.Label(string.Format("<color=#f25c5c>{0}</color> (<size=8>{1}</size>)", name, exc.Message));
			}
		}


		static void DoCurveBox(AnimatedParameter animParam, IKeyable keyable, bool isRecording){
			
			var e = Event.current;
			var keyableLength = keyable.endTime - keyable.startTime;
			var rootTime = keyable.root.currentTime;
			var localTime = Mathf.Clamp(rootTime - keyable.startTime, 0, keyableLength);

			GUILayout.Label("INVISIBLE TEXT", GUILayout.Height(0));
			var lastRect = GUILayoutUtility.GetLastRect();
			GUILayout.Space(250);

			var timeRect = new Rect(0, 0, keyableLength, 0);
			var posRect = new Rect();
			if (e.type == EventType.Repaint || !fixedCurveRects.TryGetValue(animParam, out posRect)){
				posRect = new Rect(lastRect.x, lastRect.yMax + 5, lastRect.width, 240);
				fixedCurveRects[animParam] = posRect;
			}
			
			GUI.color = EditorGUIUtility.isProSkin? new Color(0,0,0,0.5f) : new Color(0,0,0,0.3f);
			GUI.Box(posRect, "", (GUIStyle)"textfield" );
			GUI.color = Color.white;

			var dragTimeRect = new Rect(posRect.x, posRect.y + 1, posRect.width, 10);
			GUI.Box(dragTimeRect, "");
			if (dragTimeRect.Contains(e.mousePosition)){
				EditorGUIUtility.AddCursorRect(dragTimeRect, MouseCursor.SplitResizeLeftRight);
				if (e.type == EventType.MouseDown && e.button == 0){
					isDraggingTime = true;
					e.Use();
				}
			}

			if (isDraggingTime){
				var iLerp = Mathf.InverseLerp(posRect.x, posRect.xMax, e.mousePosition.x);
				keyable.root.currentTime = Mathf.Lerp(keyable.startTime, keyable.endTime, iLerp);
			}

			if (e.rawType == EventType.MouseUp){
				isDraggingTime = false;
			}

			if (e.type == EventType.KeyDown && posRect.Contains(e.mousePosition)){
				if (e.keyCode == KeyCode.Comma){
					GUIUtility.keyboardControl = 0;
					keyable.root.currentTime = animParam.GetKeyPrevious(localTime) + keyable.startTime;
					e.Use();
				}

				if (e.keyCode == KeyCode.Period){
					GUIUtility.keyboardControl = 0;
					keyable.root.currentTime = animParam.GetKeyNext(localTime) + keyable.startTime;
					Event.current.Use();
				}
			}

			var dopeRect = new Rect(posRect.x, dragTimeRect.yMax + 1, posRect.width, 12);
			GUI.Box(dopeRect, "");
			DopeSheetEditor.DrawDopeSheet(animParam, keyable, dopeRect, 0, keyableLength);

			var curvesRect = new Rect(posRect.x, dopeRect.yMax, posRect.width, posRect.height - dopeRect.height - dragTimeRect.height);
			CurveEditor.DrawCurves(animParam, keyable, curvesRect, timeRect);

			if (isRecording){
				var iLerp = Mathf.InverseLerp(keyable.startTime, keyable.endTime, rootTime);
				var lerp = Mathf.Lerp(posRect.x, posRect.xMax, iLerp);
				var a = new Vector3(lerp, posRect.y, 0);
				var b = new Vector3(lerp, posRect.yMax, 0);
				Handles.color = EditorGUIUtility.isProSkin? Slate.Styles.recordingColor : Color.red;
				Handles.DrawLine(a, b);
				Handles.color = Color.white;
			}				
		}

	}
}

#endif