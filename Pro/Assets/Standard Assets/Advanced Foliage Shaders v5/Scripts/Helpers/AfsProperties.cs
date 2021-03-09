using UnityEngine;
using System.Collections;

public class AfsHeader : PropertyAttribute {
	
	public string labeltext;

	public AfsHeader (string labeltext) {
		this.labeltext = labeltext;
	}
}
