//---------------------------------
//           JML Curves
// Copyright © 2012 JML's Universe
//---------------------------------

using UnityEngine;
using System.Collections;

public abstract class JMLCurve : MonoBehaviour
{	
	public abstract Vector3 GetPoint(float t);
	
	public virtual float Lenght
	{
		get
		{
			int steps = 100;
			
			float lenght = 0;
			Vector3 currentPoint = GetPoint(0);	
			
			
			for(int i = 0; i < steps; i++)
			{
				float t = (float)i / (float)steps;
				
				Vector3 nextPoint = GetPoint(t);
				
				lenght += Vector3.Distance(nextPoint, currentPoint);
				
				currentPoint = nextPoint;
			}
			
			return lenght;
		}
	}
	
	static float NormalEpsilon = 0.05f;
	
	Vector3 GetTangentInternal(float t)
	{
		Vector3 lastPoint = Vector3.zero;
		Vector3 currentPoint = GetPoint(t);
		Vector3 nextPoint = Vector3.zero;
			
					
		Vector3 tanA = Vector3.zero;
		Vector3 tanB = Vector3.zero;
			
		if(t > NormalEpsilon)
		{
			lastPoint = GetPoint(t - NormalEpsilon);
			tanA = currentPoint - lastPoint;
		}
			
		if(t < 1.0f - NormalEpsilon)
		{
			nextPoint = GetPoint(t + NormalEpsilon);
			tanB = nextPoint - currentPoint;
		}
		
		return tanA + tanB;
	}
	
	public Vector3 GetTangent(float t)
	{
		return GetTangentInternal(t).normalized;
	}
	
	public virtual float GetTangentSpeed(float t)
	{		
		return 1.0f / GetTangentInternal(t).magnitude;
	}
	
	public Vector3 GetNormal(float t, Vector3 compDirection)
	{
		Vector3 lastPoint = Vector3.zero;
		Vector3 currentPoint = GetPoint(t);
		Vector3 nextPoint = Vector3.zero;
			
					
		Vector3 normalA = Vector3.zero;
		Vector3 normalB = Vector3.zero;
			
		if(t > NormalEpsilon)
		{
			lastPoint = GetPoint(t - NormalEpsilon);
			normalA = Vector3.Cross(currentPoint - lastPoint, compDirection);
		}
			
		if(t < 1.0f - NormalEpsilon)
		{
			nextPoint = GetPoint(t + NormalEpsilon);
			normalB = Vector3.Cross(nextPoint - currentPoint, compDirection);
		}
		
		
		
		return (normalA + normalB).normalized;
	}
	
	public abstract void EditorInit();
	//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-
	public Color StartColor = Color.white;
	public Color EndColor = Color.white;
	
	public bool DrawGizmos = true;
		
	public bool ShowEdges = true;
	public float EdgesSize = 1;
	
	public bool ShowLine = true;
	public bool ShowLinePoints = true;
	public float LinePointsSize = 0.1f;
	public bool ShowTestPoint = true;
	public float TestPoint = 0;
	
	//Vector3[] PreAnchorPoints;
	//Vector3[] DensityPoints;
	public int DebugDensity = 150;
		
	[SerializeField]
	protected bool initialized = false;
	
	
	protected virtual void OnDrawGizmos()
	{
		if(!DrawGizmos)
		{
			return;
		}

		Vector3 firstPoint = GetPoint(0);
		Vector3 endPoint = GetPoint(1);
		
		Gizmos.color = StartColor;
		
		if(ShowEdges)
		{
			Gizmos.DrawWireSphere(firstPoint, EdgesSize);
		}
		
		float colorLerp = 0;
				
		if(ShowLine || ShowLinePoints)
		{
			float t = 0;
			colorLerp = 0;
				
			Vector3 lastPoint = firstPoint;
		
			//DensityPoints[0] = lastPoint;
			
			for(int i = 0; i < DebugDensity - 1; i++)
			{
				Gizmos.color = Color.Lerp(StartColor, EndColor, colorLerp);
				
				t += 1.0f / DebugDensity;
							
				Vector3 nextPoint = GetPoint(t);
			
				//DensityPoints[i + 1] = nextPoint;
				
				if(ShowLine) Gizmos.DrawLine(lastPoint, nextPoint);
			
				lastPoint = nextPoint;
				
				colorLerp += 1.0f / (DebugDensity - 1);
			
				if(ShowLinePoints) Gizmos.DrawWireSphere(lastPoint, LinePointsSize);
			}
		
			Gizmos.color = EndColor;
			if(ShowLine) Gizmos.DrawLine(lastPoint, endPoint);			
		}
		
		if(ShowEdges)
		{
			Gizmos.color = EndColor;
			Gizmos.DrawWireSphere(endPoint, EdgesSize);
		}
				
		if(ShowTestPoint)
		{
			Gizmos.color = Color.Lerp(StartColor, EndColor, TestPoint);
			
			Gizmos.DrawSphere(GetPoint(TestPoint), 0.5f);			
		}
	}
}
