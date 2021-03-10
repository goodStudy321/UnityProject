#!/bin/bash

#更新说明：
#添加了对so文件的重签支持
#优化了重签framework的速度
#添加了自动查找ipa文件和配置文件的功能
#10.21 增加对extension拓展签名的支持
#10.26 修改了路径报错的问题

#用法：
#1.把脚本与mobileprovision配置文件和需要重签的IPA放在同一文件夹
#2.CERTIFICATE处填写证书名，可在keychain处查找
#3.BUNDLE_ID处填写和证书及配置文件对应的bundleID
#4.进入终端cd到当前路径，输入chmod 777 resignature_v4.sh给脚本授权
#5.输入./resignature_v5.sh自动执行

#注意：
#确保mobileprovision配置文件为重签所使用的证书所生成的
#如不确定，可以进入https://developer.apple.com登录开发者门户网站
#重新创建App ID，bundle ID，配置服务权限
#然后新建Provisioning Profiles,下载放到同一文件夹中
#此脚本所处文件夹中只能存在一个IPA包，否则处理失败


#自动查找IPA
ORIGINAL_FILE=`find *.ipa`
#证书名称------------------------------------------需修改
CERTIFICATE="iPhone Distribution: Shenzhen ijiami Technology Co. Ltd"
#自动查找证书配置文件
MOBILEPROVISION=`find *.mobileprovision`
#重新签名后的bundle_id------------------------------需修改--可以cat查看配置文件的application-identifier字段
#BUNDLE_ID="cn.dongguanbank.ebank.mbank"
BUNDLE_ID="cn.ijiami.resigntool"

#KEY="group.com.youzu.keychain.sharing"



function unzip_IPA() 
{
	echo "================================1.正在解压IPA包=========================================="
	ipa="$ORIGINAL_FILE" 
	unzip -o "$ipa"  -d extracted > unzip.log
	APP_PATH=`find extracted/Payload -name *.app`
} 

function create_Entitlements() 
{
 	echo "==============================2.正在生成授权文件========================================="
 	/usr/libexec/PlistBuddy -x -c "print :Entitlements " /dev/stdin <<< $(security cms -D -i ${MOBILEPROVISION}) > app.entitlements
 	SN_CODE=$(/usr/libexec/PlistBuddy -c "Print :com.apple.developer.team-identifier" app.entitlements) 
 	/usr/libexec/PlistBuddy -c "Set :application-identifier ${SN_CODE}.${BUNDLE_ID}" app.entitlements

 	echo "$SN_CODE"
} 

function set_BundleID() 
{
 	echo "==============================3.正在修改bundleID========================================="
 	/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $BUNDLE_ID" $APP_PATH/Info.plist

 	find extracted/Payload -name *.appex > appex.log
	while IFS='' read -r line || [[ -n "$line" ]]; 
	do
		/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$line/Info.plist" >> oldAppexID.log
		NEW=`awk -F'.' '{print$4}' oldAppexID.log`

		/usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier ${BUNDLE_ID}.${NEW}" "$line/Info.plist"
	done < appex.log

}


function del_OldCodeSign()
{
	echo "==============================4.正在删除旧的签名========================================="
	rm -r $APP_PATH/_CodeSignature/
	#rm -r $APP_PATH/archived-expanded-entitlements.xcent

} 

function copy_EmbeddedProvision()
{
 	echo "==============================5.正在拷贝配置文件========================================="
 	cp app.entitlements $APP_PATH/app.entitlements
 	cp $MOBILEPROVISION $APP_PATH/embedded.mobileprovision
} 

function reSignFrameworks()
{
 	echo "===========================6.正在对frameworks进行签名===================================="
	find extracted/Payload -name *.dylib -o -name *.app -o -name *.framework -o -name *.appex -o -name *.so > frameworks.log

	while IFS='' read -r line || [[ -n "$line" ]];
	do
		/usr/bin/codesign --continue -f -s "$CERTIFICATE" --no-strict "app.entitlements" "$line"
	done < frameworks.log
}

function reSignApp()
{
 	echo "==================================7.正在对app签名========================================"
 	codesign -f -s "$CERTIFICATE" --entitlements app.entitlements $APP_PATH
} 

function rezip_IPA()
{
 	echo "====================================8.正在打包==========================================="
 	cd extracted
 	original_IPA=`basename "$ORIGINAL_FILE"`
 	re_IPA=`echo ${original_IPA/.ipa/-resigned.ipa}`
 	zip -qry ../"$re_IPA" *
 	cd ..
 	echo "==================================重-签-名-完-成=========================================" 
}


unzip_IPA 
create_Entitlements
set_BundleID
del_OldCodeSign 
copy_EmbeddedProvision 
reSignFrameworks
reSignApp
rezip_IPA
rm -rf "extracted"
rm -rf unzip.log frameworks.log oldAppexID.log appex.log

