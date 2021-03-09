using UnityEngine;
using System.Collections;
using UnityEditor;
using System;

namespace FastOcean
{
    [CustomEditor(typeof(FOceanGrid))]
	[ExecuteInEditMode]
	public class FOceanGridEditor : Editor
	{
        SerializedProperty baseParam;
        SerializedProperty gwParam;
        SerializedProperty dwParam;
        SerializedProperty reflParam;
        
        SerializedProperty oceanMaterial;

        SerializedProperty renderEnabled;

        SerializedProperty projectedMesh;
        SerializedProperty usedGridSize;
        SerializedProperty oceanHeight;
        SerializedProperty boundPos;
        SerializedProperty boundRot;
        SerializedProperty boundSize;
        SerializedProperty minBias;
        
        SerializedProperty gwDir;
        SerializedProperty gwFlow;
        SerializedProperty gwScale;
        SerializedProperty gwAmplitude;
        SerializedProperty gwLength;
        SerializedProperty gwChoppiness;
        SerializedProperty gwSpeed;
        SerializedProperty gwDrift;
        SerializedProperty interpolators;

        SerializedProperty mode;
		SerializedProperty normalMap;
		SerializedProperty bumpTiling;
		SerializedProperty parallaxMap;
		SerializedProperty parallax1;
		SerializedProperty parallax2;
        SerializedProperty fftResolution;
        SerializedProperty waveScale;
        SerializedProperty waveSpeed;
        SerializedProperty useMipMaps;

        SerializedProperty quality;
        SerializedProperty reflectionMask;
		SerializedProperty useSkybox;
		SerializedProperty clearColor;
        SerializedProperty clipPlaneOffset;
        SerializedProperty blurEnabled;
        SerializedProperty blurSpread;

        void OnEnable()
        {
            baseParam = serializedObject.FindProperty("baseParam");
            gwParam = serializedObject.FindProperty("gwParam");
            dwParam = serializedObject.FindProperty("dwParam");
            reflParam = serializedObject.FindProperty("reflParam");

            oceanMaterial = serializedObject.FindProperty("oceanMaterial");
            
            renderEnabled = serializedObject.FindProperty("renderEnabled");
            
            projectedMesh = baseParam.FindPropertyRelative("projectedMesh");
            usedGridSize = baseParam.FindPropertyRelative("usedGridSize");
            oceanHeight = baseParam.FindPropertyRelative("oceanHeight");
            
            boundSize = baseParam.FindPropertyRelative("boundSize");
            boundPos = baseParam.FindPropertyRelative("boundPos");
            boundRot = baseParam.FindPropertyRelative("boundRotate");
            minBias = baseParam.FindPropertyRelative("minBias");

            gwDir = gwParam.FindPropertyRelative("gwDirection");
            gwFlow = gwParam.FindPropertyRelative("gwFlow");
            gwScale = gwParam.FindPropertyRelative("gwScale");

            gwAmplitude = gwParam.FindPropertyRelative("gwAmplitude");
            gwLength = gwParam.FindPropertyRelative("gwLength");

            gwChoppiness = gwParam.FindPropertyRelative("gwChoppiness");
            gwSpeed = gwParam.FindPropertyRelative("gwSpeed");
            gwDrift = gwParam.FindPropertyRelative("gwDrift");
            interpolators = gwParam.FindPropertyRelative("interpolators");

            mode = dwParam.FindPropertyRelative("mode");

			normalMap = dwParam.FindPropertyRelative("normalMap");
			bumpTiling = dwParam.FindPropertyRelative("bumpTiling");
			parallaxMap = dwParam.FindPropertyRelative("parallaxMap");
			parallax1 = dwParam.FindPropertyRelative("parallax1");
			parallax2 = dwParam.FindPropertyRelative("parallax2");

            fftResolution = dwParam.FindPropertyRelative("fftResolution");

            waveScale = dwParam.FindPropertyRelative("waveScale");
            waveSpeed = dwParam.FindPropertyRelative("waveSpeed");
            useMipMaps = dwParam.FindPropertyRelative("useMipMaps");

            quality = reflParam.FindPropertyRelative("quality");
			useSkybox = reflParam.FindPropertyRelative("useSkybox");
			clearColor = reflParam.FindPropertyRelative("clearColor");
            reflectionMask = reflParam.FindPropertyRelative("reflectionMask");
            clipPlaneOffset = reflParam.FindPropertyRelative("clipPlaneOffset");

            blurEnabled = reflParam.FindPropertyRelative("blurEnabled");
            blurSpread = reflParam.FindPropertyRelative("blurSpread");
        }

        void LayoutSurParam(FOceanGrid fg)
        {
            EditorGUILayout.PropertyField(baseParam);

            if (baseParam.isExpanded)
            {
                EditorGUI.indentLevel = 1;

                usedGridSize.intValue = EditorGUILayout.IntSlider("Used Grid Size", fg.baseParam.usedGridSize, 32, 254);

                projectedMesh.boolValue = EditorGUILayout.Toggle("Projected Mesh", fg.baseParam.projectedMesh);
                EditorGUI.indentLevel = 2;
                if (!projectedMesh.boolValue)
                {
                    boundPos.vector3Value = EditorGUILayout.Vector3Field("Bound Pos", fg.baseParam.boundPos);
                    boundRot.floatValue = EditorGUILayout.Slider("Bound Rot", fg.baseParam.boundRotate, 0 ,360);
                    boundSize.vector3Value = EditorGUILayout.Vector3Field("Bound Size", fg.baseParam.boundSize);
                }
                else
                {
                    oceanHeight.floatValue = EditorGUILayout.FloatField("Ocean Height ", fg.baseParam.oceanHeight);
                    minBias.vector4Value = EditorGUILayout.Vector4Field("Min Bias & Lod", fg.baseParam.minBias);
                }
                EditorGUI.indentLevel = 1;

                EditorGUI.indentLevel = 0;
            }
        }

        static bool gwParamOpen = true;
        static bool waveLenOpen = true;
        static bool waveInplOpen = true;
        void LayoutGWParam(FOceanGrid fg)
        {
            gwParamOpen = EditorGUI.Foldout(EditorGUILayout.GetControlRect(), gwParamOpen, "Wave Shape", true);
            if (gwParamOpen)
            {
                EditorGUI.indentLevel = 1;
                gwScale.floatValue = Mathf.Max(EditorGUILayout.FloatField("Scale", fg.gwParam.gwScale), 0.01f);
                gwAmplitude.floatValue = EditorGUILayout.Slider("Amplitude", fg.gwParam.gwAmplitude, 0f, 0.5f);
                gwFlow.floatValue = EditorGUILayout.Slider("Flow", fg.gwParam.gwFlow, 0f, 1f);
                waveInplOpen = EditorGUI.Foldout(EditorGUILayout.GetControlRect(), waveInplOpen, "Interpolators", true);
                if (waveInplOpen)
                {
                    EditorGUI.indentLevel = 2;
                    Color c = GUI.color;
                    GUI.color = Color.red;
                    float wx = EditorGUILayout.Slider("X", fg.gwParam.interpolators.x, 0.0f, 1f);
                    GUI.color = Color.green;
                    float wy = EditorGUILayout.Slider("Y", fg.gwParam.interpolators.y, 0.0f, 1f);
                    GUI.color = Color.yellow;
                    float wz = EditorGUILayout.Slider("Z", fg.gwParam.interpolators.z, 0.0f, 1f);
                    GUI.color = Color.gray;
                    float ww = EditorGUILayout.Slider("W", fg.gwParam.interpolators.w, 0.0f, 1f);
                    GUI.color = c;
                    interpolators.vector4Value = new Vector4(wx, wy, wz, ww);
                    EditorGUI.indentLevel = 1;
                }
                gwChoppiness.floatValue = EditorGUILayout.Slider("Choppiness", fg.gwParam.gwChoppiness, 0f, 5f);
                EditorGUILayout.Separator();
                waveLenOpen = EditorGUI.Foldout(EditorGUILayout.GetControlRect(), waveLenOpen, "Length", true);
                if (waveLenOpen)
                {
                    EditorGUI.indentLevel = 2;
                    Color c = GUI.color;
                    GUI.color = Color.red;
                    float glx = EditorGUILayout.Slider("X", fg.gwParam.gwLength.x, 0.25f, 1f);
                    GUI.color = Color.green;
                    float gly = EditorGUILayout.Slider("Y", fg.gwParam.gwLength.y, 0.25f, 1f);
                    GUI.color = Color.yellow;
                    float glz = EditorGUILayout.Slider("Z", fg.gwParam.gwLength.z, 0.25f, 1f);
                    GUI.color = Color.gray;
                    float glw = EditorGUILayout.Slider("W", fg.gwParam.gwLength.w, 0.25f, 1f);
                    GUI.color = c;
                    gwLength.vector4Value = new Vector4(glx, gly, glz, glw);
                    EditorGUI.indentLevel = 1;
                }

                gwDir.floatValue = EditorGUILayout.Slider("Direction", fg.gwParam.gwDirection, 0f, 360f);
                gwSpeed.floatValue = EditorGUILayout.Slider("Speed", fg.gwParam.gwSpeed, 0f, 2f);
                gwDrift.floatValue = EditorGUILayout.Slider("Drift", fg.gwParam.gwDrift, 0f, 1f);

                EditorGUI.indentLevel = 0;
            }
        }

        static bool dwParamOpen = true;
        static bool bumpTileOpen = true;
        void LayoutDWParam(FOceanGrid fg)
        {
            dwParamOpen = EditorGUI.Foldout(EditorGUILayout.GetControlRect(), dwParamOpen, "Wave Detail", true);
            if (dwParamOpen)
            {
                EditorGUI.indentLevel = 1;

                mode.enumValueIndex = (int)(eFShaderMode)EditorGUILayout.EnumPopup("Quality Mode", fg.dwParam.mode);

                if (mode.enumValueIndex == (int)eFShaderMode.FFT)
                {
                    //hack: shift 6 bits to index
                    fftResolution.enumValueIndex = ((int)(eFFTResolution)EditorGUILayout.EnumPopup("FFT Resolution", fg.dwParam.fftResolution) >> 6);
                    EditorGUILayout.PropertyField(waveScale);
                    EditorGUILayout.PropertyField(waveSpeed);

                    EditorGUILayout.PropertyField(useMipMaps);
                }
                else 
                {
					EditorGUILayout.PropertyField(normalMap);

                    bumpTileOpen = EditorGUI.Foldout(EditorGUILayout.GetControlRect(), bumpTileOpen, "Bump Tiling & Speed", true);
                    if (bumpTileOpen)
                    {
                        EditorGUI.indentLevel = 2;
                        float bx = EditorGUILayout.Slider("Tiling X", fg.dwParam.bumpTiling.x, 0.1f, 1f);
                        float by = EditorGUILayout.Slider("Tiling Y", fg.dwParam.bumpTiling.y, 0.1f, 1f);
                        float bz = EditorGUILayout.Slider("Speed X", fg.dwParam.bumpTiling.z, 0, 1f);
                        float bw = EditorGUILayout.Slider("Speed Y", fg.dwParam.bumpTiling.w, 0, 1f);

                        bumpTiling.vector4Value = new Vector4(bx, by, bz, bw);
                        EditorGUI.indentLevel = 1;
                    }
                    if (mode.enumValueIndex == (int)eFShaderMode.High)
                    {
                        EditorGUILayout.Separator();

                        EditorGUILayout.PropertyField(parallaxMap);
                        EditorGUILayout.PropertyField(parallax1);
                        EditorGUILayout.PropertyField(parallax2);
                    }
                }

                EditorGUI.indentLevel = 0;
            }
        }

        static bool reflParamOpen = true;
        void LayoutReflParam()
        {
            reflParamOpen = EditorGUI.Foldout(EditorGUILayout.GetControlRect(), reflParamOpen, "Reflection", true);
            if (reflParamOpen)
            {
                EditorGUI.indentLevel = 1;
                EditorGUILayout.PropertyField(quality);
                EditorGUILayout.PropertyField(reflectionMask);

				EditorGUILayout.PropertyField(useSkybox);
				if (!useSkybox.boolValue)
				{
					EditorGUI.indentLevel = 2;
					EditorGUILayout.PropertyField(clearColor);
					EditorGUI.indentLevel = 1;
				}
                EditorGUILayout.PropertyField(clipPlaneOffset);

                EditorGUILayout.PropertyField(blurEnabled);
                if (blurEnabled.boolValue)
				{
					EditorGUI.indentLevel = 2;
                    EditorGUILayout.PropertyField(blurSpread);
					EditorGUI.indentLevel = 1;
				}
                EditorGUI.indentLevel = 0;
            }
        }

        public override void OnInspectorGUI()
	    {
	        serializedObject.Update();

            FOceanGrid fg = (FOceanGrid)target;

            if(fg == null)
                return;

           int tmp = EditorGUI.indentLevel;
            
            LayoutSurParam(fg);
            LayoutGWParam(fg);
			EditorGUILayout.Separator();
            LayoutDWParam(fg);
			EditorGUILayout.Separator();
            LayoutReflParam();

			EditorGUILayout.Separator();

            EditorGUILayout.PropertyField(oceanMaterial);

            EditorGUILayout.PropertyField(renderEnabled);

            serializedObject.ApplyModifiedProperties();

            EditorGUI.indentLevel = tmp;
		}
	}
}
