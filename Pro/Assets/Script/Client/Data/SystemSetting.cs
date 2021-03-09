using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System;
using System.Net.NetworkInformation;

public class SystemSetting
{
    public static string GetMacAddress()
    {

        NetworkInterface[] nice = null;
        try
        {
            NetworkInterface.GetAllNetworkInterfaces();
        }
        catch (Exception)
        {

        }
        if (nice == null) return "";
        string physicalAddress = "";
        foreach (NetworkInterface adaper in nice)
        {

            Debug.Log(adaper.Description);

            if (adaper.Description == "en0")
            {
                physicalAddress = adaper.GetPhysicalAddress().ToString();
                break;
            }
            else
            {
                physicalAddress = adaper.GetPhysicalAddress().ToString();

                if (physicalAddress != "")
                {
                    break;
                };
            }
        }

        return physicalAddress;
    }
}
