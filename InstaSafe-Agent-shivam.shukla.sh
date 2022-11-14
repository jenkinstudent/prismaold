#!/bin/sh
echo "InstaSafe Installer for Linux"
echo "Usage: sudo sh InstaSafe-Agent.sh"
if [ `id -u` != 0 ]; then
 echo "Root permission is needed to run this installer!"
 exit 1
fi
echo "Setting up InstaSafe would require Internet connectivity"
echo "Identifying version of Linux..."
if [ $(grep -c Ubuntu /etc/issue) -ne 0 ] ; then
	 echo "Installing dependencies for Ubuntu"
	 apt-get install openvpn -y --force-yes || { echo "Could not install the dependencies required";  exit 1; } 
	 apt-get install wget -y --force-yes 
	 apt-get install resolvconf -y --force-yes 
	 wget -O /etc/init.d/instasafe http://repo.instasafe.net/pub/instasafe_u >/dev/null 2>&1
	 chmod 700 /etc/init.d/instasafe
     ln -s /usr/sbin/openvpn /usr/sbin/instasafe
	 update-rc.d instasafe defaults
elif [ $(grep -c Peppermint /etc/issue) -ne 0 ] ; then
     echo "Installing dependencies for Ubuntu"
     apt-get install openvpn -y --force-yes || { echo "Could not install the dependencies required";  exit 1; } 
     apt-get install wget -y --force-yes 
     wget -O /etc/init.d/instasafe http://repo.instasafe.net/pub/instasafe_u >/dev/null 2>&1
     chmod 700 /etc/init.d/instasafe
     ln -s /usr/sbin/openvpn /usr/sbin/instasafe
     update-rc.d instasafe defaults
elif [ $(grep -c Mint /etc/issue) -ne 0 ] ; then
	 echo "Installing dependencies for Ubuntu"
	 apt-get install openvpn -y --force-yes || { echo "Could not install the dependencies required";  exit 1; } 
	 apt-get install wget -y --force-yes 
	 wget -O /etc/init.d/instasafe http://repo.instasafe.net/pub/instasafe_u >/dev/null 2>&1
	 chmod 700 /etc/init.d/instasafe
     ln -s /usr/sbin/openvpn /usr/sbin/instasafe
	 update-rc.d instasafe defaults
elif [ $(grep -c Debian /etc/issue) -ne 0 ] ; then
	 echo "Installing dependencies for Debian"
	 apt-get update
	 apt-get install openvpn -y --force-yes || { echo "Could not install the dependencies required" ;exit 1; }
elif [ -s /etc/redhat-release ]; then
                yum -y install wget
                wget -O /etc/init.d/instasafe http://repo.instasafe.net/pub/instasafe_r >/dev/null 2>&1
	        chmod 700 /etc/init.d/instasafe
	        chkconfig --add instasafe
                chkconfig instasafe on
	if [ -s /usr/sbin/openvpn ]; then
	        echo "Required files are installed"
	else 
	        echo "Trying to update the repositories..."
		arch=`uname -i`
		echo "Detected architecture is $arch"
		MAJOR=$(uname -r | grep -o 'el[0-9]')
		if [ $MAJOR == "el5" ]; then
			rpm -Uvh http://repo.instasafe.net/pub/epel-release-5-4.noarch.rpm
			sed -i 's/https/http/g' /etc/yum.repos.d/epel.repo
		elif [ $MAJOR == "el6" ]; then
                 rpm -Uvh http://repo.instasafe.net/pub/epel-release-6-8.noarch.rpm
                 sed -i 's/https/http/g' /etc/yum.repos.d/epel.repo
 		rpm -Uvh http://repo.instasafe.net/pub/rpm/openssl-1.0.1e-57.el6.x86_64.rpm
			rpm -Uvh http://repo.instasafe.net/pub/rpm/lzo-2.03-3.1.el6.x86_64.rpm
                 rpm -Uvh http://repo.instasafe.net/pub/rpm/pkcs11-helper-1.11-3.el6.x86_64.rpm
                 rpm -Uvh http://repo.instasafe.net/pub/rpm/openvpn-2.3.11-1.el6.x86_64.rpm
         elif [ $MAJOR == "el7" ]; then
                 rpm -Uvh http://repo.instasafe.net/pub/epel-release-latest-7.noarch.rpm
         elif [ $MAJOR == "el8" ]; then
                 rpm -Uvh http://repo.instasafe.net/pub/epel-release-latest-8.noarch.rpm
         fi
		echo "A new repository is installed"
		yum check-update 
		yum -y install openvpn || { echo "Could not install the dependencies required for InstaSafe" ;exit 1; }
	        echo "Installed the dependencies"
         wget -O /etc/openvpn/update-resolv-conf http://repo.instasafe.net/pub/update-resolv-conf >/dev/null 2>&1
         chmod 700  /etc/openvpn/update-resolv-conf
	fi
elif [ -s /etc/system-release ] && [ $(grep -c Amazon /etc/system-release) -ne 0 ] ; then
        echo " Installing Dependencies for Amazon Linux "
	  amazon-linux-extras enable epel
	  yum install -y epel-release
        yum -y install openvpn wget
        wget -O /etc/init.d/instasafe http://repo.instasafe.net/pub/instasafe_r >/dev/null 2>&1
        chmod 700 /etc/init.d/instasafe
        chkconfig --add instasafe
        chkconfig instasafe on
elif [ -s /etc/SuSE-release ] && [ $(grep -c SUSE /etc/SuSE-release) -ne 0 ] ; then
        echo " Installing Dependencies for Suze Linux "
        zypper -n in openvpn 
        zypper -n in wget
        wget -O /etc/init.d/instasafe http://repo.instasafe.net/pub/instasafe_s > /dev/null 2>&1
        chmod 700 /etc/init.d/instasafe
        chkconfig --add instasafe
        chkconfig instasafe on
fi
if [ ! -d /etc/instasafe/ ]; then
    mkdir -p /etc/instasafe/
fi
echo "Configuring InstaSafe..."
echo "
# Config file for shivam.shukla
daemon
dev tun
keepalive 10 180
persist-key
nobind
client
server-poll-timeout 30
max-routes 2048
remote-random
#management 127.0.0.1 22222
#management-query-passwords
auth-retry nointeract
route-delay 31 30
reneg-sec 0
remote-random
remote-cert-tls server
float
comp-lzo
auth-nocache
cipher aes-128-cbc
<cert>
-----BEGIN CERTIFICATE-----
MIIEuDCCA6CgAwIBAgIDAVYDMA0GCSqGSIb3DQEBCwUAMIHAMQswCQYDVQQGEwJJ
TjELMAkGA1UECBMCS0ExEjAQBgNVBAcTCUJhbmdhbG9yZTEpMCcGA1UEChMgSW5z
dGFTYWZlIFRlY2hub2xvZ2llcyBQdnQuIExUZC4xLDAqBgNVBAMTI0luc3RhU2Fm
ZSBUZWNobm9sb2dpZXMgUHZ0LiBMVGQuIENBMRUwEwYDVQQpEwxJbnN0YVNhZmUg
Q0ExIDAeBgkqhkiG9w0BCQEWEW9wc0BpbnN0YXNhZmUuY29tMB4XDTIyMTExNDA3
NDYyNloXDTMyMTExMTA3NDYyNlowgYQxCzAJBgNVBAYTAklOMQswCQYDVQQIEwJL
QTESMBAGA1UEBxMJQmFuZ2Fsb3JlMQ8wDQYDVQQKEwZmdXNpb24xHTAbBgNVBAMU
FHNoaXZhbS5zaHVrbGFAZnVzaW9uMSQwIgYJKoZIhvcNAQkBFhVzdXBwb3J0QGlu
c3Rhc2FmZS5jb20wgZ8wDQYJKoZIhvcNAQEBBQADgY0AMIGJAoGBAJQasb6O1TTJ
0LGDVB1bsxlLf462GrXlAAK94D7Kvm2F60YwRWuBZ2Iwa5f6qkU7C35xAXEOgyoC
WYS98ZZJBoI+uziPfXnqW8aRyt+StxlmvZSi4gHNOrI489CRIRK5CW7m2+CRV5/B
+Ry5sqQYtk2n9p3BHL7Fm5p7qZhl5gkRAgMBAAGjggF3MIIBczAJBgNVHRMEAjAA
MC0GCWCGSAGG+EIBDQQgFh5FYXN5LVJTQSBHZW5lcmF0ZWQgQ2VydGlmaWNhdGUw
HQYDVR0OBBYEFGFjAOVUkxZc5Yw0e9Cm6YjrjkRvMIH1BgNVHSMEge0wgeqAFAEq
2witks+L6bx7q0CPL/4ddptUoYHGpIHDMIHAMQswCQYDVQQGEwJJTjELMAkGA1UE
CBMCS0ExEjAQBgNVBAcTCUJhbmdhbG9yZTEpMCcGA1UEChMgSW5zdGFTYWZlIFRl
Y2hub2xvZ2llcyBQdnQuIExUZC4xLDAqBgNVBAMTI0luc3RhU2FmZSBUZWNobm9s
b2dpZXMgUHZ0LiBMVGQuIENBMRUwEwYDVQQpEwxJbnN0YVNhZmUgQ0ExIDAeBgkq
hkiG9w0BCQEWEW9wc0BpbnN0YXNhZmUuY29tggkAmH9vYSEQOPYwEwYDVR0lBAww
CgYIKwYBBQUHAwIwCwYDVR0PBAQDAgeAMA0GCSqGSIb3DQEBCwUAA4IBAQBVt25u
1Qoe836rXoSFYzL5aFR/rguvLXUmKxuBEciYT4WkiTs3xf1X8guYTPMNdx82dJ6s
KKt7hyaOx2HbkFj4jJFdpP7HUvysr/g7F4YONuVrf/FInNujUF60CIm0iB2J9Up2
OnyajCMo07E4FC0nFCczHZNJZ1qOJQO2J0J4ptVsWD987jWMPE22YyObXj2anhtz
6hGVmiszWZ68PL23819oCQY8FIJtzqtxZoNBk0yZNXu88+I3MKuTxE6ThFxPI+R/
YvYOuvxu5ZPj8Cw37PxhzDIguq79xlQcYJDZWIQdsfpTIFmEIJ6bjKnLqYfXfeSR
dBGtvqECtCopbTsB
-----END CERTIFICATE-----
</cert>
<key>
-----BEGIN PRIVATE KEY-----
MIICdwIBADANBgkqhkiG9w0BAQEFAASCAmEwggJdAgEAAoGBAJQasb6O1TTJ0LGD
VB1bsxlLf462GrXlAAK94D7Kvm2F60YwRWuBZ2Iwa5f6qkU7C35xAXEOgyoCWYS9
8ZZJBoI+uziPfXnqW8aRyt+StxlmvZSi4gHNOrI489CRIRK5CW7m2+CRV5/B+Ry5
sqQYtk2n9p3BHL7Fm5p7qZhl5gkRAgMBAAECgYA4uFx4OWWH+P6W7U/qinL17gcl
FbL3FIPDiQp3odf6Q/6N+/CqMn3widC6/MH3D5zgSNEfhkpPbWTxRHlgcAkwhUXi
+oP5YywrNTR2/njk/ZuhLfppapqhmFGoXGVg1ZWyWr1sAv67y1rATWfZza4+UgFd
CfZvA0Qea6fDh/kgwQJBAMPmkNCfyS3ubZGx2c7Nolp1A0SSUknm8JWp1qElTksC
lr7HiNoD5up1TFyW2rrwdZXggtc6D4p74nfYVC6kH+kCQQDBilk5kVjn3JINnZW2
h/4q0zFiRdv+Sw3ZjvrddBRdUHnYtViULolSK3qFrle3gi4HybhFFeg9WJhTuCSW
7E7pAkEAs684BSOKk+at+YT4Ewfqcq4BYVQUxlRdN+mgRA7D0Wl+e17p147crxEI
CaUU24LTV7WmTWOj/ZHEF8kE7gL8gQJAYvE3bBbCPMamZA+L2iTr6zjMplDQhtAX
5IET/uK5Bnt9zyvmfNrNmRRhLrZSYZ5Lqe+WJLtuXu5L8YDSM9XbAQJBAIHq1VJZ
3vT4EBSq8ei7Zyr61jgn9aHaTP8qp9Eatd1Jw89+zJnxZsP+o3M3+7qCEX1iGYTU
ldzXB0L4bjXRm1E=
-----END PRIVATE KEY-----
</key>
<ca>
-----BEGIN CERTIFICATE-----
MIIFUjCCBDqgAwIBAgIJAJh/b2EhEDj2MA0GCSqGSIb3DQEBCwUAMIHAMQswCQYD
VQQGEwJJTjELMAkGA1UECBMCS0ExEjAQBgNVBAcTCUJhbmdhbG9yZTEpMCcGA1UE
ChMgSW5zdGFTYWZlIFRlY2hub2xvZ2llcyBQdnQuIExUZC4xLDAqBgNVBAMTI0lu
c3RhU2FmZSBUZWNobm9sb2dpZXMgUHZ0LiBMVGQuIENBMRUwEwYDVQQpEwxJbnN0
YVNhZmUgQ0ExIDAeBgkqhkiG9w0BCQEWEW9wc0BpbnN0YXNhZmUuY29tMB4XDTE3
MDkxNDA5MDEyMloXDTI3MDkxMjA5MDEyMlowgcAxCzAJBgNVBAYTAklOMQswCQYD
VQQIEwJLQTESMBAGA1UEBxMJQmFuZ2Fsb3JlMSkwJwYDVQQKEyBJbnN0YVNhZmUg
VGVjaG5vbG9naWVzIFB2dC4gTFRkLjEsMCoGA1UEAxMjSW5zdGFTYWZlIFRlY2hu
b2xvZ2llcyBQdnQuIExUZC4gQ0ExFTATBgNVBCkTDEluc3RhU2FmZSBDQTEgMB4G
CSqGSIb3DQEJARYRb3BzQGluc3Rhc2FmZS5jb20wggEiMA0GCSqGSIb3DQEBAQUA
A4IBDwAwggEKAoIBAQDess9gYKzTo+2HG0z8D0fUqaIc17Ju++v2km0ay4nkNkuS
AMeCkXgQYsLBbJJ+GEz8pyYGAhqAH4kI7kPhZyqqLO5xHPe70XteBGj9pusmwZOF
pYL8rh7vLZcAKsPPcbCtY9sZqN6rMs9LKpwBbBQSX/r2kVZZtUr1lOs+6zqv1SD/
6vTknDYT7axYmvaDd9KRzDmVzamLnmyjn20wRUSWGz8UvimPFV9IxX1f0COsxlcL
dyYcK2OT1hyfJ3pomzZUPirF37/gY9QB5J3q9XpJhBjFhO8xntBT/F7YDIc1MFAd
ouu+x++d+xWupDE59rv5t9Tu69x7Tji1/EyPUFlTAgMBAAGjggFLMIIBRzAdBgNV
HQ4EFgQUASrbCK2Sz4vpvHurQI8v/h12m1QwgfUGA1UdIwSB7TCB6oAUASrbCK2S
z4vpvHurQI8v/h12m1ShgcakgcMwgcAxCzAJBgNVBAYTAklOMQswCQYDVQQIEwJL
QTESMBAGA1UEBxMJQmFuZ2Fsb3JlMSkwJwYDVQQKEyBJbnN0YVNhZmUgVGVjaG5v
bG9naWVzIFB2dC4gTFRkLjEsMCoGA1UEAxMjSW5zdGFTYWZlIFRlY2hub2xvZ2ll
cyBQdnQuIExUZC4gQ0ExFTATBgNVBCkTDEluc3RhU2FmZSBDQTEgMB4GCSqGSIb3
DQEJARYRb3BzQGluc3Rhc2FmZS5jb22CCQCYf29hIRA49jAMBgNVHRMEBTADAQH/
MCAGA1UdEQQZMBeBFXN1cHBvcnRAaW5zdGFzYWZlLmNvbTANBgkqhkiG9w0BAQsF
AAOCAQEAl4+sQn/I03vdPQDNnKNWiXdv4B+x74exovoC1k3KVDzVtHodGYzm2+eN
zXYNYe+lziXb79d6NtZrQPGfAO0270VbbpdOxwQz9J/sedmycO5u3zYSF8USRT61
QkjI/OR/1HLpAADYXX3lMFHwkRDSuDN6sHTIMyc//8uFRv1mwBzC9e+4njitaphr
UFx6FKV/TQaHKxa5SQbvlSlXeImjHzN0DrY4SEcpHope8XMKYlHBWgrurfSRpOKD
dd4M68nYV/CChHC8vmO/lzsFHt1nsicbqbUAaq511Snjxy1IRLbVLMTE/PZ3oiGT
aLThcP/FYUuZA4OnWsMIA/Kh6fMRtw==
-----END CERTIFICATE-----
</ca>
<tls-auth>
#
# 2048 bit OpenVPN static key
#
-----BEGIN OpenVPN Static key V1-----
95696434f810ce57f59fed9f1f030137
9ddcd9b0bd04096dfe9f9e81317056b7
9c255ae87ce2000f0793b8490c2a315a
33f9fd4b147160a1259af4eb5947761a
20922a4d0e4b08e6497ae46e07ef7305
7a3611d65cc6e2fb2404d88327c471a6
524914ee4d7c30e37fd6f961ecfcefef
72f765ea966927395320e628740e3b73
a9504e881e40c29c5791c135fc3ad206
fc133f817bef94687c78d0e0a9bc2e44
fbe48be22404ab8ee83a3c0367dd1a67
471b17676d9dd31b9b7f41de91ba054a
8af92194fb329736e1c6e5a7a0e8f107
cdfc721e0d0d2c53ed99f47da83fc7f5
77b8642bc144730d363086d10ea11853
ef59f1d1c3dfee11eb8134a387fb2546
-----END OpenVPN Static key V1-----
</tls-auth>


remote isaawmum16.instasafe.net 1392 udp

log /var/log/instasafe.fusion1.log

script-security 2
up /etc/openvpn/update-resolv-conf
down /etc/openvpn/update-resolv-conf

" > /etc/instasafe/fusion_shivam.shukla.conf ||  echo "Could not configure InstaSafe properly"
    ln -s /usr/sbin/openvpn /usr/sbin/instasafe
echo "Configuration Done"
echo "Installation Complete."
echo "Starting InstaSafe Service..."
echo "This action may prompt for the username/password."
echo "The username/password would be the same as entered on myInstaSafe portal"
service instasafe restart || /etc/init.d/instasafe restart
