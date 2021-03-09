using UnityEngine;
using System.Collections;
using UnityEditor;
using System;
using System.Collections.Generic;

namespace FastOcean
{
	[CustomEditor(typeof(FOcean))]
	[ExecuteInEditMode]
	public class FOceanEditor : Editor
	{
		static FOceanEditor()
	    {
	        EditorApplication.update += Update;
	    }
        
        SerializedProperty envParam;
        SerializedProperty shaderPack;
        SerializedProperty layerDef;

        SerializedProperty blendMode;
        SerializedProperty underWaterMode;
        SerializedProperty sunLight;

        SerializedProperty shadowEnabled;
        SerializedProperty shadowQuality;
        SerializedProperty shadowDistance;
        SerializedProperty shadowStrength;
        SerializedProperty shadowDistort;
        SerializedProperty shadowFade;

        SerializedProperty trailer;
        SerializedProperty trailMapSize;
        SerializedProperty trailMapScale;
        SerializedProperty trailMapFade;
        SerializedProperty trailIntensity;
        
        SerializedProperty skirt;
        SerializedProperty underDepth;
        SerializedProperty underColor;
        SerializedProperty underAmb;
        SerializedProperty depthFade;
        SerializedProperty surfaceFade;
        SerializedProperty distortMag;
        SerializedProperty distortFrq;
        SerializedProperty distortMap;
        SerializedProperty underWaterShader;
        SerializedProperty underButtom;

        void OnEnable()
        {
            envParam = serializedObject.FindProperty("envParam");
            shaderPack = serializedObject.FindProperty("shaderPack");
            layerDef = serializedObject.FindProperty("layerDef");
            
            shadowEnabled = envParam.FindPropertyRelative("shadowEnabled");
            shadowQuality = envParam.FindPropertyRelative("shadowQuality");
            shadowDistance = envParam.FindPropertyRelative("shadowDistance");
            shadowStrength = envParam.FindPropertyRelative("shadowStrength");
            shadowDistort = envParam.FindPropertyRelative("shadowDistort");
            shadowFade = envParam.FindPropertyRelative("shadowFade");

            blendMode = envParam.FindPropertyRelative("blendMode");
            underWaterMode = envParam.FindPropertyRelative("underWaterMode");

            sunLight = envParam.FindPropertyRelative("sunLight");
            
            skirt = envParam.FindPropertyRelative("skirt");
            underDepth = envParam.FindPropertyRelative("underDepth");
            underColor = envParam.FindPropertyRelative("underColor");
            underAmb = envParam.FindPropertyRelative("underAmb");
            depthFade = envParam.FindPropertyRelative("depthFade");
            surfaceFade = envParam.FindPropertyRelative("surfaceFade");
            distortMag = envParam.FindPropertyRelative("distortMag");
            distortFrq = envParam.FindPropertyRelative("distortFrq");

            distortMap = envParam.FindPropertyRelative("distortMap");
            underWaterShader = envParam.FindPropertyRelative("underWaterShader");

            underButtom = envParam.FindPropertyRelative("underButtom");


            trailer = envParam.FindPropertyRelative("trailer");
            trailMapSize = envParam.FindPropertyRelative("trailMapSize");
            trailMapScale = envParam.FindPropertyRelative("trailMapScale");
            trailMapFade = envParam.FindPropertyRelative("trailMapFade");
            trailIntensity = envParam.FindPropertyRelative("trailIntensity");
        }


	    static int tempFrame = 0;
	    static void Update()
	    {
	        if (!Application.isPlaying && !EditorApplication.isCompiling)
	        {
	            if (FOcean.instance && tempFrame < Time.renderedFrameCount)
	            {
                    FOcean.instance.ForceUpdate();
	                tempFrame = Time.renderedFrameCount + 2;
	            }
	        }
	    }

        static bool envConfigOpen = true;
        public override void OnInspectorGUI()
	    {
            serializedObject.Update();

            FOcean no = (FOcean)target;

			if (GUILayout.Button("Refresh Material"))
			{
                HashSet<FOceanGrid> grids = no.GetGrids();
                var _e = grids.GetEnumerator();
                while(_e.MoveNext())
                {
                    Material mat = _e.Current.oceanMaterial;
                    if (mat == null)
                        continue;

                    Material tmpMat = new Material(mat.shader);
                    tmpMat.shaderKeywords = mat.shaderKeywords;
                    tmpMat.renderQueue = mat.renderQueue;

                    int pc = ShaderUtil.GetPropertyCount(tmpMat.shader);
                    for (int i = 0; i < pc; i++)
                    {
                        string name = ShaderUtil.GetPropertyName(tmpMat.shader, i);
                        switch (ShaderUtil.GetPropertyType(tmpMat.shader, i))
                        {
                            case ShaderUtil.ShaderPropertyType.Color:
                                tmpMat.SetColor(name, mat.GetColor(name));
                                break;
                            case ShaderUtil.ShaderPropertyType.Range:
                                tmpMat.SetFloat(name, mat.GetFloat(name));
                                break;
                            case ShaderUtil.ShaderPropertyType.Float:
                                tmpMat.SetFloat(name, mat.GetFloat(name));
                                break;
                            case ShaderUtil.ShaderPropertyType.Vector:
                                tmpMat.SetVector(name, mat.GetVector(name));
                                break;
                            case ShaderUtil.ShaderPropertyType.TexEnv:
                                tmpMat.SetTexture(name, mat.GetTexture(name));
                                break;
                        }
                    }

                    mat.CopyPropertiesFromMaterial(tmpMat);
                    DestroyImmediate(tmpMat);
                }
               

                if (FOcean.instance != null)
                    FOcean.instance.ForceReload(true);
			}

            int tmp = EditorGUI.indentLevel;
            
            if (no != null)
            {
                envConfigOpen = EditorGUI.Foldout(EditorGUILayout.GetControlRect(), envConfigOpen, "Global Config", true);

                if (envConfigOpen)
                {
                    EditorGUI.indentLevel = 1;
 
                    EditorGUILayout.PropertyField(blendMode);

                    underWaterMode.enumValueIndex = (int)(eFUnderWater)EditorGUILayout.EnumPopup("UnderWater Mode", no.envParam.underWaterMode);

                    EditorGUI.indentLevel = 2;

                    if (underWaterMode.enumValueIndex == (int)eFUnderWaterMode.Blend)
                    {
                        EditorGUILayout.PropertyField(underColor);

                        EditorGUILayout.PropertyField(underAmb);
                        
                        EditorGUILayout.PropertyField(underDepth);

                        EditorGUILayout.PropertyField(depthFade);
                        EditorGUILayout.PropertyField(surfaceFade);

                        EditorGUILayout.Space();
                        
                        EditorGUILayout.PropertyField(distortMag);
                        EditorGUILayout.PropertyField(distortFrq);
                        EditorGUILayout.PropertyField(distortMap);

                        EditorGUILayout.Space();
                        
                        EditorGUILayout.PropertyField(skirt);
                        EditorGUILayout.PropertyField(underButtom);
                        EditorGUILayout.PropertyField(underWaterShader);

                        EditorGUILayout.Space();
                    }
                    else if (underWaterMode.enumValueIndex == (int)eFUnderWaterMode.Simple)
                    {
                        EditorGUILayout.PropertyField(underColor);

                        EditorGUILayout.PropertyField(underAmb);
                    }

                    EditorGUI.indentLevel = 1;

                    sunLight.objectReferenceValue = (Light)EditorGUILayout.ObjectField("Sun Light", no.envParam.sunLight, typeof(Light), true);


                    EditorGUILayout.Space();
 
                    EditorGUILayout.PropertyField(trailer);

                    EditorGUI.indentLevel = 2;
                    EditorGUILayout.PropertyField(trailMapSize);
                    EditorGUILayout.PropertyField(trailMapScale);
                    EditorGUILayout.PropertyField(trailMapFade);
                    EditorGUILayout.PropertyField(trailIntensity);
                    EditorGUI.indentLevel = 1;

                    EditorGUILayout.Space();
                    shadowEnabled.boolValue = EditorGUILayout.Toggle("Shadow Enabled", no.envParam.shadowEnabled);

                    if (shadowEnabled.boolValue)
                    {
                        EditorGUI.indentLevel = 2;
                        EditorGUILayout.PropertyField(shadowQuality);
                        shadowDistance.floatValue = EditorGUILayout.FloatField("Shadow Distance", no.envParam.shadowDistance);
                        shadowStrength.floatValue = EditorGUILayout.Slider("Shadow Strength", no.envParam.shadowStrength, 0, 1);
                        shadowDistort.floatValue = EditorGUILayout.Slider("Shadow Distort", no.envParam.shadowDistort, 0.01f, 0.1f);
                        shadowFade.floatValue = EditorGUILayout.Slider("Shadow Fade", no.envParam.shadowFade, 0, 1);
                        EditorGUI.indentLevel = 1;
                    }
                }
            }

            EditorGUILayout.Space();
            EditorGUILayout.PropertyField(layerDef, true);
            EditorGUILayout.Space();
            EditorGUILayout.PropertyField(shaderPack, true);

            serializedObject.ApplyModifiedProperties();

            EditorGUI.indentLevel = tmp;
	    }
	}
}
