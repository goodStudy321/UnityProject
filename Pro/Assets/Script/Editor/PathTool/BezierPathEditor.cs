#pragma warning disable 612, 618 //for handles. will fix
/* Based on the free Bezier Curve Editor by Arkham Interactive */

#if UNITY_EDITOR

using UnityEngine;
using UnityEditor;
using System.Collections;
using System.Collections.Generic;
using System.Linq;

namespace PathTool{

	[CustomEditor(typeof(BezierPath))]
	public class BezierPathEditor : Editor
    {
		private BezierPoint selectedPoint;
		private BezierPath path{
			get {return (BezierPath)target;}
		}
		
		public override void OnInspectorGUI(){

			base.OnInspectorGUI();

            path.id = (uint)EditorGUILayout.IntField("曲线Id:", (int)path.id);
            path.Resolution = EditorGUILayout.IntField("平滑度:", path.Resolution);
            path.drawColor = EditorGUILayout.ColorField("曲线颜色:", path.drawColor);

            for(int a = 0; a < path.points.Count; a++)
            {
                string pointName = "点" + a.ToString();
                path.points[a].position = EditorGUILayout.Vector3Field(pointName, path.points[a].position);
            }

            if (GUILayout.Button("Add Point")){
				var last = path.points.LastOrDefault();
				if (last != null){
					path.AddPointAt(last.position + Vector3.one);
				} else {
					path.AddPointAt(path.transform.position + Vector3.one);
				}
				SceneView.RepaintAll();
			}
		}

		void OnSceneGUI(){
			for (int i = 0; i < path.pointCount; i++){
				DrawPointSceneGUI(path[i], i);
			}
		}

		void DrawPointSceneGUI(BezierPoint point, int index){	
			Handles.BeginGUI();
			var e = Event.current;

			Handles.Label(point.position + new Vector3(0, HandleUtility.GetHandleSize(point.position) * 0.4f, 0), index.ToString());
			Handles.color = Color.green;
			var pointGUISize = HandleUtility.GetHandleSize(point.position) * 0.1f;
			if (e.type == EventType.MouseDown){
				
				var screenPos = HandleUtility.WorldToGUIPoint(point.position);
				var nextPoint = index < path.points.Count-1? path[index + 1] : null;
				var previousPoint = index > 0? path[index - 1] : null;

				if ( ((Vector2)screenPos - e.mousePosition).magnitude < 13 ){
					
					if (e.button == 0){
						selectedPoint = point;
						SceneView.RepaintAll();
					}

					if (e.button == 1){
						path.SetDirty();
						var menu = new GenericMenu();
						if (nextPoint != null){
							menu.AddItem( new GUIContent("Add Point After"), false, ()=>{ path.AddPointAt( BezierPath.GetPoint(point, nextPoint, 0.5f), index +1 ); } );
						}
						if (previousPoint != null){
							menu.AddItem( new GUIContent("Add Point Before"), false, ()=>{ path.AddPointAt( BezierPath.GetPoint(previousPoint, point, 0.5f), index ); } );
						}
						menu.AddItem( new GUIContent("Tangent/Connected"), false, ()=>{ point.handleStyle = BezierPoint.HandleStyle.Connected; } );
						menu.AddItem( new GUIContent("Tangent/Broken"), false, ()=>{ point.handleStyle = BezierPoint.HandleStyle.Broken; } );
						if (path.points.Count > 2){
							menu.AddSeparator("/");
							menu.AddItem( new GUIContent("Delete"), false, ()=>{ path.RemovePoint(point); } );
						}
						menu.ShowAsContext();
						e.Use();
					}
				}
			}

			var newPosition = point.position;
			if (point == selectedPoint){
				newPosition = Handles.PositionHandle(point.position, Quaternion.identity);
			}
			Handles.FreeMoveHandle(point.position, Quaternion.identity, pointGUISize, Vector3.zero, Handles.RectangleCap);

			if(newPosition != point.position){
				point.position = newPosition;
				path.SetDirty();
			}
			
			if(point.handleStyle != BezierPoint.HandleStyle.None){
				Handles.color = Color.cyan;
				var newGlobal1 = Handles.FreeMoveHandle(point.globalHandle1, Quaternion.identity, HandleUtility.GetHandleSize(point.globalHandle1)*0.075f, Vector3.zero, Handles.CircleCap);
				if(point.globalHandle1 != newGlobal1){
					point.globalHandle1 = newGlobal1;
					path.SetDirty();
					//if(point.handleStyle == BezierPoint.HandleStyle.Connected) point.globalHandle2 = -(newGlobal1 - point.position) + point.position;
				}
				
				var newGlobal2 = Handles.FreeMoveHandle(point.globalHandle2, Quaternion.identity, HandleUtility.GetHandleSize(point.globalHandle2)*0.075f, Vector3.zero, Handles.CircleCap);
				if(point.globalHandle2 != newGlobal2){
					point.globalHandle2 = newGlobal2;
					path.SetDirty();
					//if(point.handleStyle == BezierPoint.HandleStyle.Connected) point.globalHandle1 = -(newGlobal2 - point.position) + point.position;
				}
				
				Handles.color = Color.yellow;
				Handles.DrawLine(point.position, point.globalHandle1);
				Handles.DrawLine(point.position, point.globalHandle2);
			}

			Handles.EndGUI();
		}

        void OnDestroy()
        {
            //string rootName = "(๑*◡*๑) PATHS";
            //GameObject root = null;

            //root = GameObject.Find(rootName);
            //if(root != null)
            //{
            //    for(int a = root.transform.childCount - 1; a >= 0; a--)
            //    {
            //        DestroyImmediate(root.transform.GetChild(a).gameObject);
            //    }
            //    DestroyImmediate(root);
            //}
        }

    }
}

#endif