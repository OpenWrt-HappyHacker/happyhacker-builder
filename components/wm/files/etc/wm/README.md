wifisdb.csv examples:

"SSID", "ENCRYPTION", "KEY", "BSSID"
"WPA2-example", "psk2", "secretverysecret", ""
"WEP-example", "wep", "44785c71644b3f6b6449212263392745", ""
"Open", "none", ""
 
 Wireless encryption modes :
  
 encrypt
   NONE:
------------------------------------------
   none                --->    open network, without authentication

   WEP:
------------------------------------------
   wep                 --->    WEP by default "open system" authentication
   wep+shared          --->    WEP "shared key" authentication
   wep+open            --->    WEP "open system" authentication

   WPA2:
------------------------------------------
   psk2                --->    WPA2 Personal (PSK)       CCMP
   psk2+tkip+ccmp      --->    WPA2 Personal (PSK) TKIP, CCMP
   psk2+tkip+aes       ---> 	WPA2 Personal (PSK) TKIP, CCMP
   psk2+tkip           --->	WPA2 Personal (PSK) TKIP
   psk2+ccmp           --->    WPA2 Personal (PSK)       CCMP
   psk2+aes            --->    WPA2 Personal (PSK)       CCMP

   WPA:
------------------------------------------
   psk 	               --->    WPA Personal (PSK) 	CCMP
   psk+tkip+ccmp       --->    WPA Personal (PSK) 	TKIP, CCMP
   psk+tkip+aes        --->    WPA Personal (PSK) 	TKIP, CCMP
   psk+tkip            ---> 	WPA Personal (PSK) 	TKIP
   psk+ccmp            ---> 	WPA Personal (PSK) 	TKIP
   psk+aes             ---> 	WPA Personal (PSK) 	TKIP

   WPA/WPA2:
------------------------------------------
   psk-mixed+tkip+ccmp --->    WPA/WPA2 Personal (PSK) mixed mode 	TKIP, CCMP
   psk-mixed+tkip+aes  --->    WPA/WPA2 Personal (PSK) mixed mode 	TKIP, CCMP
   psk-mixed+tkip 	   --->    WPA/WPA2 Personal (PSK) mixed mode 	TKIP
   psk-mixed+ccmp      --->    WPA/WPA2 Personal (PSK) mixed mode 	CCMP
   psk-mixed+aes       --->    WPA/WPA2 Personal (PSK) mixed mode 	CCMP
   psk-mixed           ---> 	WPA/WPA2 Personal (PSK) mixed mode 	CCMP

   WPA2 ENTERPRISE:
------------------------------------------
   wpa2                --->    WPA2 Enterprise CCMP
   wpa2+tkip+ccmp      --->    WPA2 Enterprise TKIP, CCMP
   wpa2+tkip+aes 	   --->    WPA2 Enterprise TKIP, CCMP
   wpa2+ccmp           --->    WPA2 Enterprise CCMP
   wpa2+aes            --->    WPA2 Enterprise CCMP
   wpa2+tkip           ---> 	WPA2 Enterprise TKIP

   WPA ENTERPRISE:
------------------------------------------
   wpa                 --->    WPA Enterprise 	TKIP
   wpa+tkip+ccmp       --->    WPA Enterprise 	TKIP, CCMP
   wpa+tkip+aes        ---> 	WPA Enterprise 	TKIP, CCMP
   wpa+ccmp            --->    WPA Enterprise 	CCMP
   wpa+aes 	           --->    WPA Enterprise 	CCMP
   wpa+tkip            --->    WPA Enterprise 	TKIP

   WPA/WPA2 ENTERPRISE:
------------------------------------------
   wpa-mixed+tkip+ccmp --->    WPA/WPA2 Enterprise mixed mode 	TKIP, CCMP
   wpa-mixed+tkip+aes  --->    WPA/WPA2 Enterprise mixed mode 	TKIP, CCMP
   wpa-mixed+tkip 	   --->    WPA/WPA2 Enterprise mixed mode 	TKIP
   wpa-mixed+ccmp      --->    WPA/WPA2 Enterprise mixed mode 	CCMP
   wpa-mixed+aes       --->    WPA/WPA2 Enterprise mixed mode 	CCMP
   wpa-mixed 	       --->    WPA/WPA2 Enterprise mixed mode 	CCMP
