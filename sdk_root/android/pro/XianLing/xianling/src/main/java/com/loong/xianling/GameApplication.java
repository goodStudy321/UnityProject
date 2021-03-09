package com.loong.xianling;

import com.supersdk.application.SuperApplication;
import com.qipa.gmsupersdk.base.GMHelper;

public class GameApplication extends SuperApplication {
    @Override
    public void onCreate(){
        super.onCreate();
        GMHelper.init(this);
    }
}
