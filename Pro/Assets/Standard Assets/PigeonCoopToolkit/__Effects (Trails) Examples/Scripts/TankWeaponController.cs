using UnityEngine;
using System.Collections;

public class TankWeaponController : MonoBehaviour
{

    public TankProjectile ProjectilePrefab;
    public Transform Nozzle;

	
	// Update is called once per frame
	void Update () {
	    if(GetComponent<Animation>().isPlaying == false && Input.GetKeyDown(KeyCode.Space))
	    {
	        GetComponent<Animation>().Play();
            Instantiate(ProjectilePrefab, Nozzle.position, Nozzle.rotation);
	    }
	}
}
