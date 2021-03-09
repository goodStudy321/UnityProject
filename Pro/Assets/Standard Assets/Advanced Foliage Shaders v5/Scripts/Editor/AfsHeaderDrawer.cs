using UnityEngine;
using System.Collections;
using UnityEditor;

[CustomPropertyDrawer (typeof (AfsHeader))]
public class AfsHeaderDrawer : DecoratorDrawer {

	AfsHeader afsheader { get { return ((AfsHeader) attribute); } }

	public override void OnGUI (Rect position)
	{
		Color afsPrimary = new Color(.5f, .8f, .0f, 1f); // Light Green
		if (!EditorGUIUtility.isProSkin) {
			afsPrimary = new Color(0.05f,0.45f,0.0f,1.0f); // Dark Green
			//afsPrimary = Color.green; //black;
		}
		// Custom Label
		GUIStyle afsLabel = new GUIStyle(EditorStyles.boldLabel);
		afsLabel.normal.textColor = afsPrimary;

		position.y += 10; // Add margin top

		EditorGUI.LabelField (position, afsheader.labeltext, afsLabel);
	}

	public override float GetHeight () 
	{
		return (base.GetHeight() + 16); // Add margin top and bottom
	}
}
