//---------------------------------
//           JML Curves
// Copyright © 2012 JML's Universe
//---------------------------------

using UnityEngine;
using System.Collections;

public class JMLEllipsoidCurve : JMLCurve
{	
	public float EllipsoidAmplitude = Mathf.PI;
	public Vector2 Radius = new Vector2(5,5);
	public float Offset = 0;
	
	public override Vector3 GetPoint(float t)
	{
		float cos = Mathf.Cos(t * EllipsoidAmplitude + Offset) * Radius.x * 0.5f;
		float sin = Mathf.Sin(t * EllipsoidAmplitude + Offset) * Radius.y * 0.5f;
		
		Vector3 circlePos = new Vector3(cos,sin,0);
		
		
		
		return transform.position + transform.rotation * circlePos;
	}
	
	public override float Lenght
	{
		get
		{
			// Ramanujan's approximation 
			float radiusX = Mathf.Abs(Radius.x);
			float radiusY = Mathf.Abs(Radius.y);
			
			float numerator = 3 * Mathf.Pow((radiusX - radiusY)/(radiusX + radiusY), 2);
			float subDenominator = 4 - numerator;
			float denominator = 10 + Mathf.Sqrt(subDenominator);
			
			
			
			return EllipsoidAmplitude * (radiusX + radiusY) * (1 + (numerator / denominator));
		}
	}
	
	/*void Update()
	{
		Debug.Log(Lenght.ToString() + " - " + base.Lenght.ToString());
	}*/
	
	public override void EditorInit()
	{	
	}
	
	//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-//-
		
	protected override void OnDrawGizmos()
	{
		if(!DrawGizmos)
		{
			return;
		}
		
		if(EllipsoidAmplitude == 0)
		{
			return;
		}
				
		base.OnDrawGizmos();
		
		if(EllipsoidAmplitude < Mathf.PI * 2)
		{
			Gizmos.color = StartColor;
			Gizmos.DrawLine(transform.position, GetPoint(0));
			
			Gizmos.color = EndColor;
			Gizmos.DrawLine(transform.position, GetPoint(1));				
		}
	}
}
