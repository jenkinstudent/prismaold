#!/bin/bash

#This script will detect machine type i.e Mac or Linux and 32 bit or 64 bit
#Then downloads appropreate .deb/.rpm/.dmg and installs.
#Cusomizes config files i.e. updates.conf, serverinfo.conf, commonsettings.conf

IsCloud=1
HttpHost=""
CloudHost=cl.escanav.com
CompanyId="0BA486CADD"
GroupPath='Managed Computers'
CloudAntiSpamUrl=http://www.microworldsystems.com/sendinfo

#DEB32DIR="http://www.microworldsystems.com/download/wmclmclient/deb"
#DEB64DIR="http://www.microworldsystems.com/download/wmclmclient/deb"
#RPM32DIR="http://www.microworldsystems.com/download/wmclmclient/rpm"
#RPM64DIR="http://www.microworldsystems.com/download/wmclmclient/rpm"
DEB32DIR="http://www.microworldsystems.com/download/wmclmclient/deb/cloud"
DEB64DIR="http://www.microworldsystems.com/download/wmclmclient/deb/cloud"
RPM32DIR="http://www.microworldsystems.com/download/wmclmclient/rpm/cloud"
RPM64DIR="http://www.microworldsystems.com/download/wmclmclient/rpm/cloud"
MAC32DIR="http://www.microworldsystems.com/download/wmclmclient/mac"
DEB32="escan-antivirus.i386.deb"
DEB64="escan-antivirus.amd64.deb"
RPM32="escan-antivirus.i386.rpm"
RPM64="escan-antivirus.x86_64.rpm"
MAC32="eScan_Anti-Virus.dmg"

CLEANOLD=1

function waitForMonitorEvent()
{
	if [ ! -f /var/MicroWorld/var/log/.winclientcache.log ]; then
		return
	fi
	packageManager=$1
	seconds=0
	while [ $seconds -le 120 ]; 
	do
		sleep 1
		seconds=`expr $seconds + 1`
		if [ $packageManager -ne 2 ]; then
			unloadedLine=`grep -rn "10153" /var/MicroWorld/var/log/.winclientcache.log | tail -n1 | awk -F: '{print $1}'`
			loadedLine=`grep -rn "10152" /var/MicroWorld/var/log/.winclientcache.log | tail -n1 | awk -F: '{print $1}'`
		else
			unloadedLine=`grep -rn "15153" /var/MicroWorld/var/log/.winclientcache.log | tail -n1 | awk -F: '{print $2}'`
			loadedLine=`grep -rn "15152" /var/MicroWorld/var/log/.winclientcache.log | tail -n1 | awk -F: '{print $2}'`
		fi
		if [ "x$unloadedLine" == "x" ]; then
			unloadedLine=0
		fi
		if [ "x$loadedLine" == "x" ]; then
			loadedLine=0
		fi
		if [ $unloadedLine -lt $loadedLine ]; then
			return;
		fi
	done
	return
}

#function waitForWinclientCache()
#{
#	if [ ! -f /var/MicroWorld/var/log/.winclientcache.log ]; then
#		return
#	fi
#	oldTime=`ls -l --full-time /var/MicroWorld/var/log/.winclientcache.log | awk '{print $7}'`
#	newTime=`ls -l --full-time /var/MicroWorld/var/log/.winclientcache.log | awk '{print $7}'`
#	seconds=0
#	while [ $seconds -le 20 ]; 
#	do
#		sleep 1
#		seconds=`expr $seconds + 1`
#		newTime=`ls -l --full-time /var/MicroWorld/var/log/.winclientcache.log | awk '{print $7}'`
#		if [ "x$oldTime" != "x$newTime" ]; then
#			oldTime=$newTime
#			seconds=0
#		fi
#	done
#	return
#}

function removeDir()
{
	dir=$1
	if [ "x$dir" == "x" ]; then
		echo "Invalid parameter to removeDir()";
		return 1;
	fi
	if [ -d $dir ]; then
		rm -fr $dir
		if [ $? -eq 0 ]; then
			echo "Directory removed : $dir"
		else
			echo "Failed to remove directory : $dir"
		fi
	fi
	return
}

function cleanOldProductData()
{
	echo "Cleaning old products"
	if [ -f /etc/.instpasswd ]; then
		rm -f /etc/.instpasswd
	fi
	if [ -f /opt/MicroWorld/etc/.instpasswd ]; then
		rm -f /opt/MicroWorld/etc/.instpasswd
	fi
	if [ $packageManager -eq  0 ]; then
		dpkg -P escan-antivirus 
		dpkg -P mwagent
	elif [ $packageManager -eq  1 ]; then
		rpm -e escan-antivirus
		rpm -e mwagent
	elif [ $packageManager -eq  2 ]; then
		#Mac uninstallation
		if [ -d "/Applications/eScan/eScan Uninstaller.app" ]; then
			/Applications/eScan/eScan\ Uninstaller.app/Contents/Resources/postinstall > /dev/null 2>&1
		fi

		if [ -f /opt/MicroWorld/bin/mwagent ] && [ -f /opt/MicroWorld/bin/winclient ] && [ -f /opt/MicroWorld/etc/mwagent.conf ] && [ -f /opt/MicroWorld/etc/winclient.conf ]; then
			launchctl remove winclient > /dev/null 2>&1
			launchctl unload /Library/LaunchDaemons/com.eScan.winclient.plist > /dev/null 2>&1

			#Below two lines are for mwagent
			launchctl remove mwagent > /dev/null 2>&1
			launchctl unload /Library/LaunchDaemons/com.eScan.mwagent.plist > /dev/null 2>&1

			rm -rf /opt
			rm -rf /var/MicroWorld

			rm -rf /Library/LaunchDaemons/com.eScan.winclient.plist
			rm -rf /Library/LaunchDaemons/com.eScan.mwagent.plist
			dscl . -delete /Users/mwconf
			dscl . -delete /Groups/mwconf

			killall mwagent > /dev/null 2>&1
			killall winclient > /dev/null 2>&1
		fi
	fi
	removeDir /opt/MicroWorld/
	removeDir /var/MicroWorld/
}

function reStartService()
{
	SERVICENAME=$1
	ISSUCCESS=1

	if [ "x" = "x$SERVICENAME" ]; then
		echo "Invalid service name to restart"
		return -1
	fi
	if [ $packageManager -ne 2 ]; then
		if [ -f /bin/systemctl ]; then
			/bin/systemctl restart ${SERVICENAME}.service >/dev/null 2>&1
			ISSUCCESS=$?
			if [ $ISSUCCESS -eq 0 ]; then
				echo "restarted $SERVICENAME using systemctl."
			fi

		fi
		if [ -d /etc/init/ ] && [ $ISSUCCESS -ne 0 ] && [ -f /etc/init/${SERVICENAME}.conf ]; then
			if [ -f /sbin/initctl ]; then
				/sbin/initctl restart $SERVICENAME >/dev/null 2>&1
				ISSUCCESS=$?
				if [ $ISSUCCESS -eq 0 ]; then
					echo "restarted $SERVICENAME using initctl."
				fi
			fi
		fi
		if [ -f /usr/sbin/invoke-rc.d ] && [ $ISSUCCESS -ne 0 ] && [ -f /etc/init.d/${SERVICENAME} ]; then
			invoke-rc.d $SERVICENAME  restart >/dev/null 2>&1
			ISSUCCESS=$?
			if [ $ISSUCCESS -eq 0 ]; then
				echo "restarted $SERVICENAME using invoke-rc.d."
			fi

		fi
		if [ $ISSUCCESS -ne 0 ] && [ -f /etc/init.d/${SERVICENAME} ]; then
			/etc/init.d/${SERVICENAME} restart >/dev/null 2>&1
			echo "restarted $SERVICENAME using init.d ."
		fi
		if [ $ISSUCCESS -ne 0 ]; then
			echo "Failed to restart service $SERVICENAME"
		fi
		return $ISSUCCESS
	else
		SERVICEPLISTFILE="com.eScan.${SERVICENAME}.plist"

		if [ ! -f  ${SERVICEPLISTFILE} ]; then
			cp -f  /opt/MicroWorld/etc/init.d/${SERVICEPLISTFILE} /Library/LaunchDaemons/${SERVICEPLISTFILE}
		fi
		launchctl load /Library/LaunchDaemons/${SERVICEPLISTFILE} > /dev/null 2>&1
		if [ $? -eq 0 ]; then
			echo "restarted $SERVICENAME using launchctl"
		else
			echo "Failed to restart service $SERVICENAME"
		fi
	fi

}


function isRootUser()
{
	if [ "$(id -u)" != 0 ]; then
		echo "This execution requires root privileges, please execute this script as a root user"
		exit 1;
	fi
}

function replaceKey()
{
	file=$1
	key=$2
	value=$3
	if [ "x$file" == "x" ]; then
		echo "Invalid file argument to $0"
		return 1;
	fi
	if [ ! -f $file ]; then
		echo "File not found : $file"
		return 1;
	fi
	if [ "x$key" == "x" ]; then
		echo "Invalid key argument to $0"
		return 1;
	fi
	modFile=`echo "${file}_tmp"`
	> $modFile
	noOfKeysReplaced=0;
	while read line; 
	do
		fkey=`echo $line | tr -d '[:space:]' | awk -F= '{print $1}'`
		if [ "x$fkey" == "x$key" ]; then
			noOfKeysReplaced=`expr $noOfKeysReplaced + 1`;
			if [ "x$value" == "xNA" ]; then
				echo "$key = \"\"" >> $modFile
			else
				echo "$key = \"$value\"" >> $modFile
			fi
		else
			echo "$line" >> $modFile
		fi
	done < $file
	mv $modFile $file
	echo "Key '$key' replaced $noOfKeysReplaced time(s)."
}

function removeKey()
{
	file=$1
	key=$2
	if [ "x$file" == "x" ]; then
		echo "Invalid file argument to $0"
		return 1;
	fi
	if [ ! -f $file ]; then
		echo "File not found : $file"
		return 1;
	fi
	if [ "x$key" == "x" ]; then
		echo "Invalid key argument to $0"
		return 1;
	fi
	modFile=`echo "${file}_tmp"`
	> $modFile
	noOfKeysRemoved=0
	while read line; 
	do
		#fkey=`echo $line | awk '{print $1}'`
		fkey=`echo $line | tr -d '[:space:]' | awk -F= '{print $1}'`
		if [ "x$fkey" != "x$key" ]; then
			echo "$line" >> $modFile
		else
			noOfKeysRemoved=`expr $noOfKeysRemoved + 1`
		fi
	done < $file
	mv $modFile $file
	echo "Removed key $key, $noOfKeysRemoved times from $file"
}



function customizeConf()
{
	IsCloud=$1
	HttpHost=$2
	CloudHost=$3
	bits=$4
	packageManager=$5
	groupName=$6

	#If IsCloud is "0" then do nothing, it's not an cloud build
	if [ $IsCloud -eq 0 ]; then
		echo "Cloud settings is disabled, leaving configuration as default."
		return 1;
	fi

	if [ ! -f /opt/MicroWorld/etc/updates.conf ]; then
		echo "File not accessible, leaving configuration as default : /opt/MicroWorld/etc/updates.conf"
		return 1;
	fi
	cp /opt/MicroWorld/etc/updates.conf /opt/MicroWorld/etc/updates.conf_ORIG_CUSTOM
	#Set CloudHost in updates.conf as CloudHost
	removeKey /opt/MicroWorld/etc/updates.conf CloudHost

	if [ "x$HttpHost" == "xNA" ]; then
		#Empty HttpHost, download from cloud
		echo "CloudHost = \"$CloudHost\"" >> /opt/MicroWorld/etc/updates.conf
	elif [ "x$HttpHost" == "x$CloudHost" ]; then
		#HttpHost & CloudHost are same, download from cloud
		echo "CloudHost = \"$CloudHost\"" >> /opt/MicroWorld/etc/updates.conf
	fi	

	#If HttpHost and CloudHost are different then get IP from HttpHost and set vServerListWMC, ServerListWMC, ServerListWMCP in updates.conf
	HttpHostIp=`echo $HttpHost | grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}'`
	if [ "x$HttpHostIp" == "x" ]; then
		echo "IP address not found in HttpHost entry : $HttpHost. leaving some configuration as default."
		replaceKey /opt/MicroWorld/etc/updates.conf ServerListWMC "NA"
		replaceKey /opt/MicroWorld/etc/updates.conf ServerListWMCP "NA"
		replaceKey /opt/MicroWorld/etc/updates.conf vServerListWMC "NA"
		replaceKey /opt/MicroWorld/etc/winclient.conf Server "127.0.0.1"

		if [ $packageManager -ne 2 ]; then
			#Dont create serverinfo.conf for Mac OS
			if [ "x$groupName" != "xNA" ]; then
				echo "[Group]" > /opt/MicroWorld/etc/serverinfo.conf
				echo "GroupName = \"$groupName\"" >> /opt/MicroWorld/etc/serverinfo.conf
			fi
		else
			echo "The serverinfo.conf will not be created for Mac OS."
		fi

		#if [ -f /opt/MicroWorld/etc/serverinfo.conf ]; then
		#	rm -f /opt/MicroWorld/etc/serverinfo.conf
		#fi
		if [ -f /opt/MicroWorld/sbin/commonutil ]; then
			/opt/MicroWorld/sbin/commonutil startwinclient
		fi
		return 1;
	fi

	if [ $packageManager -eq 2 ]; then
		replaceKey /opt/MicroWorld/etc/updates.conf ServerListWMC "http://${HttpHostIp}:2221/AVX"
		replaceKey /opt/MicroWorld/etc/updates.conf ServerListWMCP "http://${HttpHostIp}:2221/AVXMIR/av32bit"
	elif [ $bits -eq 64 ]; then
		replaceKey /opt/MicroWorld/etc/updates.conf ServerListWMC "http://${HttpHostIp}:2221/MAC/AVX"	
		replaceKey /opt/MicroWorld/etc/updates.conf ServerListWMCP "http://${HttpHostIp}:2221/AVXMIR/av64bit"	
	else
		replaceKey /opt/MicroWorld/etc/updates.conf ServerListWMC "http://${HttpHostIp}:2221/AVX"	
		replaceKey /opt/MicroWorld/etc/updates.conf ServerListWMCP "http://${HttpHostIp}:2221/AVXMIR/av32bit"	
	fi
	replaceKey /opt/MicroWorld/etc/updates.conf vServerListWMC "http://$HttpHostIp:2221/update"
	replaceKey /opt/MicroWorld/etc/winclient.conf Server $HttpHostIp

	if [ $packageManager -ne 2 ]; then
		#Dont create serverinfo.conf for Mac OS
		if [ "x$groupName" != "xNA" ]; then
			echo "[Group]" > /opt/MicroWorld/etc/serverinfo.conf
			echo "GroupName = \"$groupName\"" >> /opt/MicroWorld/etc/serverinfo.conf
		else
			echo "The GroupName is empty, will not be added in serverinfo.conf"
			> /opt/MicroWorld/etc/serverinfo.conf
		fi
		echo "[IP]" >> /opt/MicroWorld/etc/serverinfo.conf
		echo "IpList = \"$HttpHostIp\"" >> /opt/MicroWorld/etc/serverinfo.conf
	else
		echo "The serverinfo.conf will not be created for Mac OS."
	fi

	#if [ -f /opt/MicroWorld/sbin/agentconfiguration.sh ]; then
	#	echo "Configuring update agent suing agentConfiguration.sh..."
	#	/opt/MicroWorld/sbin/agentconfiguration.sh $HttpHostIp
	#else
	#	echo "The agentconfiguration.sh was missing, startup scripts of some services might not be configured."
	#fi

	if [ -f /opt/MicroWorld/sbin/commonutil ]; then
		/opt/MicroWorld/sbin/commonutil startwinclient
	fi

	return 0;	
}

function getPackageManager()
{
	packageManager=`which dpkg`
	if [ "x$packageManager" != "x" ]; then
		return 0; //Debian based linux
	fi
	packageManager=`which rpm`
	if [ "x$packageManager" != "x" ]; then
		return 1; //RPM based linux
	fi
	if [ -d "/Applications/" ]; then
		return 2; //Mac
	fi
	return 100;
}

function getMachineBits()
{
	GETCONFIG=`which getconf`
	if [ "x$GETCONFIG" == "x" ]; then
		echo "Required command is missing: getconf"
		return 100;
	fi
	bits=`getconf LONG_BIT`
	return $bits;
}

#Enough permissions? ============================================================================
isRootUser

#Mac or Linux? =================================================================================
getPackageManager
packageManager=$?
if [ $packageManager -eq 100 ]; then
	echo "Unable to detect package manager of system"
	exit 1;
fi

#32 bit or 64 bit?
getMachineBits
bits=$?
if [ $bits -eq 100 ]; then
	echo "Unable to detect machine's number of bits"
	exit 1;
fi

#Which package to download? =====================================================================
file_to_download="$DEB64" #Default
download_url="$DEB64DIR/$file_to_download" #default
if [ $packageManager -eq 0 ]; then
	if [ $bits -eq 32 ]; then
		echo "Machine type: Debian based Linux 32 bit"
		file_to_download="$DEB32"
		download_url="$DEB32DIR/$file_to_download"
	elif [ $bits -eq 64 ]; then
		echo "Machine type: Debian based Linux 64 bit"
		file_to_download="$DEB64"
		download_url="$DEB64DIR/$file_to_download"
	else
		echo "Error: Number of bits must be 32 or 64."
		exit 1;
	fi
elif [ $packageManager -eq 1 ]; then
	if [ $bits -eq 32 ]; then
		echo "Machine type: RPM based Linux 32 bit"
		file_to_download="$RPM32"
		download_url="$RPM32DIR/$file_to_download"
	elif [ $bits -eq 64 ]; then
		echo "Machine type: RPM based Linux 64 bit"
		file_to_download="$RPM64"
		download_url="$RPM64DIR/$file_to_download"
	else
		echo "Error: Number of bits must be 32 or 64."
		exit 1;
	fi
elif [ $packageManager -eq 2 ]; then
	echo "Machine type: Mac OS X"	
	file_to_download="$MAC32"
	download_url="$MAC32DIR/$file_to_download"
fi

#Download package =====================================================================================
WGET=`which wget`
CURL=`which curl`
if [ $packageManager -eq 0 ] || [ $packageManager -eq 1 ]; then
	if [ "x$WGET" == "x" ]; then
		echo "Required command is missing: wget"
		exit 1;
	fi
elif [ $packageManager -eq 2 ]; then
	if [ "x$CURL" == "x" ]; then
		echo "Required command is missing: curl"
		exit 1;
	fi
fi


if [ -f "$file_to_download" ]; then
	echo "Package file $file_to_download already present, will not be downloaded."
else
	echo "Package file not found on current working directory, downloading $file_to_download..."
	echo ""
	echo "-----------------------------------------------------------------------------------"
	if [ $packageManager -eq 2 ]; then
		curl -L -O "$download_url"
	else
		wget "$download_url"
	fi
	echo "-----------------------------------------------------------------------------------"
	echo ""
fi

if [ $CLEANOLD -eq 1 ]; then
	cleanOldProductData $packageManager
fi


#Install package =========================================================================================
echo "Installing $file_to_download..."
success=1
if [ $packageManager -eq 0 ]; then
	dpkg -i "$file_to_download"
	success=$?
elif [ $packageManager -eq 1 ]; then
	rpm -i "$file_to_download"
	success=$?
elif [ $packageManager -eq 2 ]; then
	if [ -f "/Volumes/eScan Anti-Virus/eScan Anti-Virus.pkg" ]; then
		hdiutil eject "/Volumes/eScan Anti-Virus"
	fi
	hdiutil mount "$file_to_download" 
	if [ $? == 0 ] && [ -f "/Volumes/eScan Anti-Virus/eScan Anti-Virus.pkg" ]; then
		installer -pkg "/Volumes/eScan Anti-Virus/eScan Anti-Virus.pkg" -target /
		success=$?
		hdiutil eject "/Volumes/eScan Anti-Virus"
	fi
fi
if [ $success -ne 0 ]; then
	echo "Installation faild."
	exit 1;
fi

if [ ! -d /opt/MicroWorld/etc/ ]; then
	echo "Directory was not exist, created /opt/MicroWorld/etc/"
	mkdir -p /opt/MicroWorld/etc/
fi

if [ -f /opt/MicroWorld/etc/commonsettings.conf ]; then
	cat /opt/MicroWorld/etc/commonsettings.conf | grep -v "Cloud\|IsCloud\|HttpHost\|CloudHost\|CompanyId\|GroupPath\|CloudAntiSpamUrl" > /opt/MicroWorld/etc/commonsettings.conf.tmp
	if [ ! -f /opt/MicroWorld/etc/commonsettings.conf.tmp ]; then
		echo "Failed to remove old values from commonsettings.conf"
		exit 1;
	fi
	mv /opt/MicroWorld/etc/commonsettings.conf.tmp /opt/MicroWorld/etc/commonsettings.conf
fi

echo "[Cloud]" >> /opt/MicroWorld/etc/commonsettings.conf
if [ "x$HttpHost" != "x" ]; then
	#HttpHost is non-empty
	if [ "x$HttpHost" == "x$CloudHost" ]; then
		#HttpHost & CloudHost are same, connect to cloud
		echo "IsCloud = \"1\"" >> /opt/MicroWorld/etc/commonsettings.conf
	else
		#HttpHost & CloudHost are different, connect to update agent
		echo "IsCloud = \"0\"" >> /opt/MicroWorld/etc/commonsettings.conf
	fi
else
	#HttpHost is empty
	echo "IsCloud = \"$IsCloud\"" >> /opt/MicroWorld/etc/commonsettings.conf
fi
echo "HttpHost = \"$HttpHost\"" >> /opt/MicroWorld/etc/commonsettings.conf
echo "CloudHost = \"$CloudHost\"" >> /opt/MicroWorld/etc/commonsettings.conf
echo "CompanyId = \"$CompanyId\"" >> /opt/MicroWorld/etc/commonsettings.conf
echo "GroupPath = \"$GroupPath\"" >> /opt/MicroWorld/etc/commonsettings.conf
echo "CloudAntiSpamUrl = \"$CloudAntiSpamUrl\"" >> /opt/MicroWorld/etc/commonsettings.conf

if [ "x$HttpHost" == "x" ]; then
	HttpHost="NA"
fi
if [ "x$GroupPath" == "x" ]; then
	GroupPath="NA"
fi

customizeConf $IsCloud $HttpHost $CloudHost $bits $packageManager "$GroupPath"

reStartService mwagent
reStartService winclient
echo "Installation completed successfully"

echo "Updating virus databases..."
/opt/MicroWorld/usr/bin/updatenow
waitForMonitorEvent $packageManager

echo "Updating eScan database & policies..."
/opt/MicroWorld/usr/bin/updatenow_avs

touch /var/MicroWorld/var/log/.winclientcache.log
waitForMonitorEvent $packageManager
/opt/MicroWorld/usr/bin/updatenow_avs
exit 0
