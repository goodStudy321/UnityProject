#if UNITY_EDITOR

using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System.Linq;

namespace Slate{

	[CustomEditor(typeof(Character))]
	public class CharacterInspector : Editor {

		private Dictionary<BlendShapeGroup, bool> foldStates = new Dictionary<BlendShapeGroup, bool>();

		private Character character{
			get {return (Character)target; }
		}

		void OnEnable(){
			SetWireframeHidden(true);
			if (!Application.isPlaying){
				character.ResetExpressions();
			}
		}

		void OnDisable(){
			SetWireframeHidden(false);
			if (!Application.isPlaying){
				character.ResetExpressions();
			}
		}

		void SetWireframeHidden(bool active){
			#if UNITY_5_5_OR_NEWER

			return;

			#else
			if (character != null){
				foreach(var renderer in character.GetComponentsInChildren<Renderer>(false)){
					EditorUtility.SetSelectedWireframeHidden(renderer, active);
				}
			}
			#endif
		}

		public override void OnInspectorGUI(){

			GUILayout.Space(10);

			EditorTools.Header("Head Look At");
			character.neck = (Transform)EditorGUILayout.ObjectField("Neck Transform", character.neck, typeof(Transform), true);
			character.head = (Transform)EditorGUILayout.ObjectField("Head Transform", character.head, typeof(Transform), true);
			character.upVector = EditorGUILayout.Vector3Field("Up Vector", character.upVector);

			GUILayout.Space(10);
			
			EditorTools.Header("Expressions");
			var skins = character.GetComponentsInChildren<SkinnedMeshRenderer>().Where(s => s.sharedMesh.blendShapeCount > 0).ToList();
			if (skins == null || skins.Count == 0){
				EditorGUILayout.HelpBox("There are no Skinned Mesh Renderers with blend shapes within the actor's GameObject hierarchy.", MessageType.Warning);
				return;
			}

			if (GUILayout.Button("Create New Expression")){
				character.expressions.Add(new BlendShapeGroup());
			}

			GUILayout.Space(5);


			EditorGUI.indentLevel ++;
			foreach(var expression in character.expressions.ToArray()){
				
				var foldState = false;
				if (!foldStates.TryGetValue(expression, out foldState)){
					foldStates[expression] = false;
				}

				GUI.backgroundColor = new Color(0,0,0,0.3f);
				GUILayout.BeginVertical(Slate.Styles.headerBoxStyle);
				GUI.backgroundColor = Color.white;

				GUILayout.BeginHorizontal();
				foldStates[expression] = EditorGUILayout.Foldout(foldStates[expression], expression.name );
				if (GUILayout.Button("X", GUILayout.Width(18))){
					expression.weight = 0;
					character.expressions.Remove(expression);
				}
				GUILayout.EndHorizontal();

				if (foldStates[expression]){

					expression.name = EditorGUILayout.TextField("Name", expression.name);
					expression.weight = EditorGUILayout.Slider("Debug Weight", expression.weight, 0, 1);

			
					foreach(var shape in expression.blendShapes.ToArray()){
						GUILayout.BeginHorizontal("box");

						GUILayout.BeginVertical();
						var skin = shape.skin;
						var name = shape.name;
						var weight = shape.weight;
						skin = EditorTools.Popup<SkinnedMeshRenderer>("Skin", skin, skins);
						if (skin != null){
							name = EditorTools.Popup<string>("Shape", name, skin.GetBlendShapeNames().ToList());
							weight = EditorGUILayout.Slider("Weight", weight, 0, 1);
						}
						GUILayout.EndVertical();

						if (skin != shape.skin || name != shape.name){
							shape.SetRealWeight(0);
						}

						shape.skin = skin;
						shape.name = name;
						shape.weight = weight;

						if (GUILayout.Button("X", GUILayout.Width(18), GUILayout.Height(50))){
							shape.SetRealWeight(0);
							expression.blendShapes.Remove(shape);
						}

						GUILayout.EndHorizontal();
						GUILayout.Space(5);
					}

					if (GUILayout.Button("Add Blend Shape")){
						expression.blendShapes.Add(new BlendShape());
					}

					GUILayout.Space(5);
				}

				GUILayout.EndVertical();
				GUILayout.Space(5);
			}

			EditorGUI.indentLevel --;


			if (GUI.changed){
				EditorUtility.SetDirty(character);
			}
		}
	}
}

#endif