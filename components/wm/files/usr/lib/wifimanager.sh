# Libraries
. /usr/lib/randomizer.sh # To use get_rnd functions

# TODO: Change sed,grep... manipulation of string for awk
# TODO: multi ip per wireless link ¿ using iw? ¿taps? ¿netns?
# TODO: Speedtest using http://proof.ovh.net/files/ time wget http://proof.ovh.net/files/10Mio.dat -O- > /dev/null

show_ssid_list(){
    local _ssid_lst=$(cat $wfdb_pth | awk -F ', |,' '{print $1}'| tr -d \")
    local _n=0
    for _ssid in $_ssid_lst;do
     if [ $_n -gt 0 ]; then
        echo $_ssid
     fi
     _n=$(expr $_n + 1)
    done
}


there_ssid(){
    local _ssid=$1


    if [ "$(awk -v m=$_ssid '$0 ~ m'  $wfdb_pth)" != "" ];then
        echo true
    else
        echo false
    fi
}

decode_ssid(){
        local _ssid=$1

        echo $(echo $_ssid| sed 's/@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@/ /g')
}

do_scan(){
    # Generate a list of SSID without quotes "", and conding ssid spaces as 34 @ on a wireless scan,
    # saving it in $scan_rst_pth
    #
    # @param $1
    #   Type: string; wlan device

    # @return
    #   Type: boolean; true --> results
    #                  false --> no results

    local _wm_dev=$1 # wlan device
    local _wst_tm=$wst_tm_dfl # Seconds between retries
    
    #TODO: Filter "Extended capabilities: SSID List" string.

    
    #echo ">>>> do_scan $_wm_dev $_wst_tm" >> /root/wm.log
    
    echo '' > $scan_rst_pth # Clean previous results

    # Generate a invalid scan output
    local _junk=$(iw INVENT-GOD-JC scan 2> /dev/null | awk '/SSID/NR==1{gsub("\tSSID: ","",$0);gsub(" ","@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",$0);print $0}' | awk 'NR==1{printf "%s",$0}' | cut -c 15-55)
    #echo ">>>> do_scan _junk: $_junk" >> /root/wm.log
    while :
    do
        logger -t "WM" "Scanning using $_wm_dev ...."
        sleep "$(expr $_wst_tm  / 2)" # Half time between retries
        # Scan, extract ssid, and coding spaces
        local _wf_scan_lst=$(iw $_wm_dev  scan 2> /dev/null |awk '/SSID/{gsub("\tSSID: ","",$0);gsub(" ","@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@",$0);print $0}' | cut -c 1-81920)

        # Obtain wlan devices status
        local _status=$(iw dev $_wm_dev info 2> /dev/null | grep "$_wm_dev")

        # Results validation
        if [ "$_wf_scan_lst" != "\n" ]; then # There are results
            if [ "$_wf_scan_lst" != "" ]; then # There are results
                local _grep_rst=$( echo $_wf_scan_lst | grep -F "$_junk" 2>/dev/null | cut -c 1-10)
                #echo ">>>> do_scan _grep_rst: $_grep_rst" >> /root/wm.log
                if [ "$_grep_rst" = "" ]; then # They are not junk
                    if [ "$_status" != "" ]; then # Wireless devices is ok
                        echo "$_wf_scan_lst" > $scan_rst_pth # Store scan in a file , to avoid overflows in shell variables
                        #echo ">>>> _wf_scan_lst: \"$_wf_scan_lst" >> /root/wm.log
                        break
                    fi
                fi
            fi
        fi
        sleep "$(expr $_wst_tm  / 2)" # Half time between retries
    done
}


has_internet(){
    # Checks internet conectivity
    #
    # @param $1
    #   Type: string; wlan device

    # @return
    #   Type: boolean;  true  --> Internet conectivity OK.
    #                   false --> There isn't conectivity.

    local _wm_dev=$1 # wlan device
    local _lnk_tmo=$lnk_tmo_dfl # Wireless link timeout in seconds
    local _net4_tmo=$net4_tmo_dfl # Network ipv4 timeout in seconds
    local _http_tmo=$http_tmo_dfl # Http client timeout in seconds
    local _ping_tmo=$ping_tmo_dfl # Ping timeout in seconds
    local _useragent=$useragent_dfl # Http user agent

    if [ "$tst_uri_dfl" = "random-uri" ];then # Sets uri to be used in test
        local _tst_uri="$(get_rnd_uri)"  # Random uri using randomizer library
    else
        local _tst_uri="$tst_uri_dfl"  # Random uri using randomizer library
    fi

    local _errs_cnt=0

    # Wait for wireless link finish
    local _retry_cnt=0
    local _link_status=$(iw dev "$_wm_dev" link 2>/dev/null | grep "Connected to")
    while [ "$_link_status" == "" ];do
        local _link_status=$(iw dev "$_wm_dev" link 2>/dev/null | grep "Connected to")
        #echo "LINK" >> /root/wm.log
        sleep 1
        _retry_cnt=$(expr $_retry_cnt + 1)
        if [ "$_retry_cnt" == "$_lnk_tmo" ]; then local _errs_cnt=1;break;fi
    done

    # Wait for wireless net ipv4 configuration
    if [ $_errs_cnt = 0 ];then
        _retry_cnt=0
        local _net4_status=$(ifconfig "$_wm_dev" 2>/dev/null  | grep "inet addr:")
        while [ "$_net4_status" == "" ];do
            local _net4_status=$(ifconfig "$_wm_dev" 2>/dev/null  | grep "inet addr:")
            #echo "NET" >> /root/wm.log
            sleep 1
            _retry_cnt=$(expr $_retry_cnt + 1)
            if [ "$_retry_cnt" == "$_net4_tmo" ]; then local _errs_cnt=$(expr $_errs_cnt + 10);break;fi
        done
    fi

    # Check internet connection
    # PING checks
    #if [ $_errs_cnt = 0 ];then
    #    ping -W $_ping_tmo $_tst_uri -4 -c2 >/dev/null 2>&1
    #    local _errs_cnt=$(expr $_errs_cnt + $? \* 100 )  # _errs_cnt+= exit_code_ping_lookup, 0 ok 1 error
    #fi

    # DNS checks
    #TODO: External timeout control, nslookup minimal version not soporte set timeout
    #if [ $_errs_cnt = 0 ];then
    #    nslookup $_tst_uri 8.8.8.8 >/dev/null 2>&1
    #    local _errs_cnt=$(expr $_errs_cnt + $?)  # _errs_cnt+= exit_code_dns_lookup, 0 ok 1 error
    #fi

    # Web checks
    if [ $_errs_cnt = 0 ];then
        wget -U $_useragent -T $_http_tmo http://$_tst_uri -O- >/dev/null 2>&1
        logger -t "WM" "Testing connectivity with http://$_tst_uri as $_useragent ."
        #echo " Test internet: wget -U $_useragent -T $_http_tmo http://$_tst_uri -O- " >> /root/wm.log
        local _errs_cnt=$(expr $_errs_cnt + $? \* 1000)  # _errs_cnt+= exit_code_wget, 0 ok 1 error
    fi

    # Decides return value
    if [ $_errs_cnt = 0 ];then
        echo true # It has internet, no errors.
    else
        logger -t "WM" "Fail internet connectivity checks, error code = $_errs_cnt"
        echo false # It hasn't internet, some errors error code = _errs_cnt
    fi
}

get_encrypt(){
    local _ssid=$1
    echo $(cat $wfdb_pth | grep -w "$_ssid" | awk -F ', |,' '{print $2}'| tr -d \")
}

get_key(){
    local _ssid=$1
    echo $(cat $wfdb_pth | grep -w "$_ssid" | awk -F ', |,' '{print $3}'| tr -d \")
}

get_bssid(){
    local _ssid=$1
    echo $(cat $wfdb_pth | grep -w "$_ssid" | awk -F ', |,' '{print $4}'| tr -d \")
}


do_conf(){
    # Setup wireless enviroment
    #
    # @param $1
    #   Type: string; wlan device
    # @param $2
    #   Type: string; phy radio device

    # @return
    #   Type: string list; Configuration parameters, wm wireless device and UCI wireless
    #                       configuration reference. $_conf = $_wm_dev $_wicfg_ref

    local _wm_dev=$1 # wlan device to create if not exits
    local _phy_dev=$2 # phy radio devices

    #echo "_wm_dev: $_wm_dev _phy_dev: $_phy_dev" >> /root/wm.log
    # Set default wlan device name
    if [ "$_wm_dev" = "" ];then
        _wm_dev=$wdev_nm
    fi
    
    # Set default physical device
    if [ "$_phy_dev" = "" ];then
        _phy_dev=$wphy_nm
    fi
    
    #echo "_wm_dev: $_wm_dev _phy_dev: $_phy_dev" >> /root/wm.log
    
    logger -t "WM" "Setting wireless enviroment."

    # UCI wireless element configuration reference
    local _wicfg_ref="$(uci add wireless wifi-iface)"

    # Auto physical device configuration
    if [ "$_phy_dev" = "auto" ];then
        # Use first Wiphy available device
        # TODO: Add multi radioX devices support
        _phy_dev=$(iw list | grep Wiphy | awk -F ' ' 'NR==1{print $2}')
    fi

    #echo "_phy_dev: "$_phy_dev >> /root/wm.log

    # wlan device creation and setup
    iw phy $_phy_dev interface add $_wm_dev type station  >/dev/null 2>&1
    ifconfig $_wm_dev  up >/dev/null 2>&1
    if [ $? ];then echo "$_wm_dev" >> $wdev_lst_pth; fi # wlan devices list,if not creation error add it to device list
    # Loads network and firewall templates
    # TODO: Block Enable IGMP Snooping (switch protocol) use firewall.uci template
    # DON'T USE wireless templates break wpa_supplicant daemon !!!!!!!!!!!!
    # WORKAROUND: filter wireless templates use to avoid break wpa_supplican and wireless module
    for tpl in $(ls $tplcfg_pth | grep -vE "wireless");do
        #echo "cat "${tplcfg_pth}${tpl}" | uci import $tpl" 
        cat "${tplcfg_pth}${tpl}" | uci import $tpl >> /root/wm.log
        uci commit $tpl
    done

    
    # WORKAROUND: Fail autogeneration base on standar autoconfiguration devices native in owrt
    # Wifi device initialization
    uci set wireless.radio0=wifi-device
    uci set wireless.radio0.type='mac80211'
    uci set wireless.radio0.hwmode='11g'
    uci set wireless.radio0.path='platform/ar933x_wmac'
    #uci set wireless.radio0.channel='11'
    uci set wireless.radio0.htmode='HT20'
    #uci set wireless.radio0.country='00'
    #uci set wireless.radio0.txpower='18'
    #uci set wireless.radio0.distance='200'
    
    
    
    
    # Wireless driver tunning
    # TODO: iw tool fail changing some configuration, check driver and iw
    # WORKAROUND: Some basic configurations can be setted using uci. (safe way)
    #iw dev $_wm_dev set power_save off >/dev/null 2>&1
    #iw reg set 00 >/dev/null 2>&1 # 00 = World, all frecuencies available
    uci set wireless.radio0.country='00'

    
    # TODO add info todo autotune
    # iw dev $_wm_dev  station dump

    # TODO test with do_scan, some conf breaks scanning

    ## All terrain fail tolerance and recovery confs
    #iw phy $_phy_dev set retry [short <limit>] [long <limit>] # More retries keep connection working in high
                                                               # demanded APs, but incress delays and latencies.


    #iw phy $_phy_dev set retry short 2 long 7 >/dev/null 2>&1  # Agressive conf in short to fast connection establish pefect
                                                                # for high density connection zone, and conservative in long
                                                                # to have stability data transfers.

    #iw phy $_phy_dev set rts <rts threshold|off> # Enable and set size 256-2346 (bytes) of RTS. Request to Send packet
    # is a trasmits unit of data to the intended recipient and waits for the recipient to acknowledge that it is ready

    #iw phy $_phy_dev set rts 2304 >/dev/null 2>&1  # Low values, better behaviour in high density areas and less bandwidth :(

    #iw phy $_phy_dev set frag <fragmentation threshold|off> # Enable and set size 256-2346 (bytes) maximum frame size

    #iw phy $_phy_dev set frag 256 >/dev/null 2>&1   # By default align with RTS, but using a 1/9 don't lost bandwidth :) and keep very
                                                    # good behaviour in high density connection areas, only lantencies could be incress
                                                    # depending of enviroment conditions.

    ## Radio performance
    #iw dev $_wm_dev set txpower <auto|fixed|limit> [<txpowermbm>]
    #iw dev $_wm_dev set txpower auto >/dev/null 2>&1  # Without poweroff = maxtx
    #iw phy $_phy_dev  set txpower auto >/dev/null 2>&1 # Without poweroff = maxtx
    uci set wireless.radio0.txpower='18'

    #iw phy $_phy_dev set coverage <coverage class> # set coverage class (1 for every 3us of air prop time 0-255)
    #iw phy $_phy_dev set coverage 1 >/dev/null 2>&1 # Coverage class: 1 (up to 450m)

    #iw phy $_phy_dev set distance <auto|distance> # set appropriate coverage class (0-114750 meters)
    #iw phy $_phy_dev set distance 100 >/dev/null 2>&1 # 50 meters best indoor high concurrence area.
    uci set wireless.radio0.distance='200'

    # Setting wireless client mode

    # TODO: Setting other radioX depending of phyX available
    uci set wireless.${_wicfg_ref}.device="radio0"
    uci set wireless.${_wicfg_ref}.ifname="$_wm_dev"

    # Rnadom MAC address
    uci set wireless.${_wicfg_ref}.macaddr="$macaddr_dfl"
    uci set wireless.${_wicfg_ref}.mode="sta"  # Client mode

    # Applies changes
    uci commit wireless
    #wifi reload
    #/etc/init.d/network reload
    reload_config

    # Generates uci reference
    local _wfif_n=$(expr $(cat $wdev_lst_pth | wc -l) - 1)

    # Generates output function value
    local _conf="$_wm_dev @wifi-iface[$_wfif_n]"

    echo $_conf # Return wm device and UCI wireless configuration element

}

do_connect(){
    # Setup wireless connection and launch connection process
    #
    # @param $1
    #   Type: string; SSID
    # @param $2
    #   Type: string; MAC address (none for default)
    # @param $3
    #   Type: string; Hostname used in DHCP request (none for default)
    #  @param $4
    #   Type: string; wlan device
    # @param $5
    #   Type: string; UCI wireless configuration reference


    # @return
    #   Type: boolean;  true  --> Connection process launched.
    #                   false --> Not supported SSID.

    local _ssid=$1 # SSID
    local _macaddr_vl=$2 # MAC address (none for default)
    local _hostname_vl=$3 # Hostname used in DHCP request (none for default)
    local _wm_dev=$4 #wlan device
    local _wicfg_ref=$5 # UCI wireless configuration reference

    #echo " >>>>>>>>> CONN _ssid: $_ssid  _wm_dev: $_wm_dev _wicfg_ref: $_wicfg_ref _macaddr_vl: $_macaddr_vl _hostname_vl: $_hostname_vl" >> /root/wm.log
    
    # Checks enviroment configurations
    if [ "$_wm_dev" = "" ];then # Not found creates one
        set -- $(do_conf)
        _wm_dev=$1
        _wicfg_ref=$2
    else  # Partial initialization case
        if [ "$_wicfg_ref" = "" ];then
            set -- $(do_conf $_wm_dev)
            _wm_dev=$1
            _wicfg_ref=$2
        fi
    fi
    
    
    
    if "$(there_ssid $_ssid)" ;then # Checks if the SSID is known

        if [ "$(get_bssid $_ssid)" != "" ]; then # Checks if BBSID field is null
            uci set wireless.${_wicfg_ref}.bssid="$(get_bssid $_ssid)"
        fi

        # Setting network wireless wan
        uci set wireless.${_wicfg_ref}.network="wwan"

        # Hostname selection
        if [ "$_hostname_vl" = "" ];then # Default hostname case
            _hostname_vl="$hostname_dfl"
        fi

        uci set network.wwan.hostname="$_hostname_vl"
        uci set network.wwan.ifname="$_wm_dev"

        # Setting wireless configurations
        uci set wireless.${_wicfg_ref}.encryption="$(get_encrypt $_ssid)"
        uci set wireless.${_wicfg_ref}.key="$(get_key $_ssid)"
        uci set wireless.${_wicfg_ref}.ssid="$_ssid"

        # MAC address selection
        if [ "$_macaddr_vl" = "" ]; then # default case
            _macaddr_vl="$macaddr_dfl"
        fi

        uci set wireless.${_wicfg_ref}.macaddr="$_macaddr_vl"

        uci set wireless.${_wicfg_ref}.mode="sta"  # Client mode

        # Apply changes witout restart services
        uci commit wireless
        uci commit network
        #wifi reload
        #/etc/init.d/network reload
        reload_config

        logger -t "WM" "Launched tasks to connect with SSID \"$_ssid\" with hostname \"$_hostname_vl\" and MAC address \"$_macaddr_vl\". "
        echo true # Connection process launched.
    else
        logger -t "WM" "Not found configuration for SSID \"$_ssid\" ."
        echo false  # Not supported SSID.
    fi
    #echo " <<<<<<<< CONN _ssid: $_ssid  _wm_dev: $_wm_dev _wicfg_ref: $_wicfg_ref _macaddr_vl: $_macaddr_vl _hostname_vl: $_hostname_vl" >> /root/wm.log
}


do_backup(){
    # Backup state
    logger -t "WM" "Doing backup of the current state."
    local _bck_lst="wireless network firewall"
    mkdir -p $prvcfg_pth
    for bck in $_bck_lst;do
        logger -t "WM" "    exporting $bck configuration."
        uci export $bck > ${prvcfg_pth}${bck}".uci"
    done
}

do_recover(){
    # Restore previous state
    logger -t "WM" "Recovering previous state."
    local _bck_lst="wireless network firewall"
    for bck in $_bck_lst;do
        logger -t "WM" "    importing $bck configuration."
        cat ${prvcfg_pth}${bck}".uci" | uci import $bck
        uci commit $bck
    done

    wifi reload
    /etc/init.d/network reload
}

do_clean_all(){
    # Remove all wireless configuration, and creates a new clean base configuration.

    # TODO: Test with  hostapd or AP confs running
    logger -t "WM" "Removing all wireless configuration, and creates a new clean base configuration."
    if [ ! -f "$wdev_lst_pth" ];then # Entry cleanup
        # New clean wireless driver setup with radio enable
        rm /etc/config/wireless >/dev/null 2>&1
        wifi detect |grep -vE "option disabled 1|#" > /etc/config/wireless
        #wifi up >/dev/null 2>&1

        # Delete default wireless configurations and devices (OpenWrt AP)
        uci delete wireless.@wifi-iface[0] >/dev/null 2>&1
        local _n=0
        while [ ! $? ] ;do
            uci delete wireless.@wifi-iface[$_n] >/dev/null 2>&1
            _n=$(expr _n + 1 )
        done

        # Forces close hostap process
        killall -9 hostapd >/dev/null 2>&1

    else # Exit cleanup before recover
        #echo "_exit" >> /root/wm.log
        for wdev in "$(cat $wdev_lst_pth)"; do
            #echo "wdev: "$wdev >> /root/wm.log
            iw dev $wdev del  >/dev/null 2>&1
            
            # BE CAREFULL !!!!! with kill process managed by netifd and wifi scripts
            # This brokes wpa_supplicant 
            # Kill all related proccess for every wlan devices            
            #kill -9 $(ps | awk -F ' ' '/$wdev/{printf "%s ", $1}')  >/dev/null 2>&1
        done
        rm $wdev_lst_pth >/dev/null 2>&1 # Remove list devices
        rm $scan_rst_pth >/dev/null 2>&1 # Remove scan results
    fi
}

connectivity_watchdog(){
    # Waits for lose internet connectivity
    #
    # @param $1
    #   Type: string; wlan device
    # @param $2
    #   Type: string; Time between internet conectivity checks
        # @return
    #   Type: command;  break , with custom case and connectivity fail

    local _wm_dev=$1 # wlan device 
    local _tbc_tm=$2 #  Time between internet conectivity checks

    #echo "connectivity_watchdog $1 $2" >> /root/wm.log
    # Check for default behaviour or custom timing
    if [ "$_tbc_tm" = "" ];then  # Default case
        _tbc_tm=$tbc_tm_dfl # Set default value
        while $(has_internet $_wm_dev);do  # Checks in a loop internet connectivity
            logger -t "WM" "Connection established correctly with internet. Next check in $_tbc_tm seconds."
            sleep $_tbc_tm
        done
    else # Custom case to use combined with anonymity_watchdog
            if $(has_internet $_wm_dev);then # Internet connectivity works
                logger -t "WM" "Connection established correctly with internet. Next check in $_tbc_tm seconds."
                echo true
                sleep $_tbc_tm
            else # Internet connectivity fails
                echo false
            fi
    fi
}



do_scan_connect(){
    # Scan waiting for results and launch do_connect if match some SSID
    #
    # @param $1
    #   Type: string; MAC address (optional)
    # @param $2
    #   Type: string; Hostname used in DHCP request (optional)
    #  @param $3
    #   Type: string; wlan device (optional)
    # @param $4
    #   Type: string; UCI wireless configuration reference (optional)


    local _macaddr_vl=$1 # MAC address
    local _hostname_vl=$2 # Hostname used in DHCP request
    local _wm_dev=$3 #wlan device
    local _wicfg_ref=$4 # UCI wireless configuration reference

    local _result='false'
    
    # TODO: ¿ Retry counter and error message?
    #echo ">>>> do_scan_connect _wm_dev: $_wm_dev _wicfg_ref: $_wicfg_ref _macaddr_vl: $_macaddr_vl _hostname_vl: $_hostname_vl" >> /root/wm.log
    do_scan $_wm_dev $_wicfg_ref # Scan for encode SSID list and wait for it
    #echo "2222222222" >> /root/wm.log
    for cSSDI in $(cat $scan_rst_pth); do # Check scan list results
        local _ssid=$(decode_ssid $cSSDI) # Decode SSID, to avoid issues with spaces
        #echo "33333 _ssid: $_ssid" >> /root/wm.log
        if "$(there_ssid $_ssid)" ;then # Checks if the SSID is known
            logger -t "WM" "Trying to connect with \"$_ssid\" ...."
            #echo "44444 _ssid: $_ssid" >> /root/wm.log
            
            if "$(do_connect $_ssid $_macaddr_vl $_hostname_vl $_wm_dev $_wicfg_ref)";then # Launch a connection, if all it's fine (true) continue
                 if $(has_internet $_wm_dev); then # Check internet connectivity
                     #echo "5555 _ssid: $_ssid" >> /root/wm.log
                    _result='true'
                    break # If it is connect to internet exit do_scan_connect function
                fi
            fi
        fi
    done
    echo $_result
    #echo "xXXXxxxxXXXXXXXXXXxxxxxxxxxxxxxxxxxxxxxxxxxx _result: $_result" >> /root/wm.log
}

get_new_ident_static_ttl(){
    local _ident_ttl=$1 # Identity Time to live
    local _timestamp=$(date +%s) # Timestamp in second (epoc)

    if [ "$_ident_ttl" = "" ]; then # If not setted
        _ident_ttl="$(get_rnd_num $ttl_prm)" # Uses a random one, between $ttl_prm range (seconds)
    fi
    #echo "PPPPPPP _ident_ttl: $_ident_ttl" >> /root/wm.log
    echo "@$(expr $_timestamp + $_ident_ttl )@" # Return a new identity static TTL
    logger -t "WM" "Setted new identity rotation time, next in at least $_ident_ttl seconds."

}

identity_is_live(){
    local _ident_ttl=$1 # Identity Time to live

    local _ident_lock="$(echo $_ident_ttl | grep @)" # Check state

    if [ "$_ident_ttl" = "0" ]; then # Identity rotation disable
        echo true # always true
    else # Identity rotation enable case
        #echo "AAAAAAAA _timestamp: $_timestamp _ident_lock: $_ident_lock " >> /root/wm.log
        if [ "$_ident_lock" = "" ]; then # Not initilized  case (there aren't @ in the string)
            echo false
            #echo "DEAD DEAD DEAD DEAD DEAD DEAD" >> /root/wm.log
        else # Setted TTL identity case
            local _deadtime="$(echo $_ident_ttl | sed 's/@//g')" # Remove @
            local _timestamp=$(date +%s) # Timestamp in second (epoc)
    
            #echo "CCCCCCCCCC _deadtime: $_deadtime _timestamp: $_timestamp" >> /root/wm.log
            # Check identity is state
            if [ $_deadtime -lt $_timestamp ]; then # Identity is dead
                echo false
                #echo "DEAD DEAD DEAD" >> /root/wm.log
            else # Identity is live
                echo true
                #echo "LIVE LIVE LIVE" >> /root/wm.log
            fi
        fi
    fi
}

anonymity_watchdog(){
    # Waits for identity dead
    #
    # @param $1
    #   Type: string; wlan device
    # @param $2
    #   Type: string; Identity Time to live
    # @param $3
    #   Type: string; Time between internet conectivity checks

    local _wm_dev=$1 # wlan device
    local _ident_ttl=$2 # Identity Time to live
    local _tbc_tm=$3 #  Time between internet conectivity checks

    #echo "anonymity_watchdog $1 $2 $3" >> /root/wm.log
    while $(identity_is_live $_ident_ttl);do  # Checks in a loop if the identity is life
        if [ "$_tbc_tm" = "" ]; then # If not setted time between checks
            #Lauch connectivity watchdog, using a random tbc, between $tbc_prm range (seconds)
            if ( ! $(connectivity_watchdog $_wm_dev $(get_rnd_num $tbc_prm) ) );then # Connectivity fail case
                break        
            fi    
        else
            #Lauch connectivity watchdog
            if ( ! $(connectivity_watchdog $_wm_dev $_tbc_tm) );then # Connectivity fail case
                break        
            fi    
        
        fi
    done
}

do_autoconnect(){
    # Setup wireless connection and launch connection process
    #
    # @param $1
    #   Type: string; Profile ("" for default, anonymity , furtive ) (optional)
    #              
    # @param $2
    #   Type: string; MAC address ("" for default) (optional)
    # @param $3
    #   Type: string; Hostname used in DHCP request ("" for default) (optional)
    # @param $4
    #   Type: string; Identity Time to live ("" for default) (optional)
    #  @param $5
    #   Type: string; Time between internet conectivity checks ("" for default) (optional)
    # @param $6
    #   Type: string; wlan device (optional)
    # @param $7
    #   Type: string; UCI wireless configuration reference (optional)

    local _profile_nm=$1 # Profile
    local _macaddr_vl=$2 # MAC address
    local _hostname_vl=$3 # Hostname used in DHCP request
    local _ident_ttl=$4 # Identity Time to live
    local _chk_tm=$5 #  Time between internet conectivity checks
    local _wm_dev=$6 #wlan device
    local _wicfg_ref=$7 # UCI wireless configuration reference
    
    # Setting default and automatic parameters according profile
    case $_profile_nm in
        'anonymity'|[a,A]*) # Anonymity case
            _ident_ttl="0" # Disable identity rotation
            _profile_nm='anon'
            ;;
        'furtive'|[f,F]*) # Furtive case
            _ident_ttl="" # Generates ramdon time during connection to rotate the identity
            _profile_nm='anon'
            ;;
            
        'manual'|[m,M]*) # Manual case
                # TODO: Checks manual parameters
                logger -t "WM" "Autoconnect using manual configuration."
                _profile_nm='man'
                local _ident_ttl_prm=$_ident_ttl
            ;;

        ''|'default'|[d,D]*|*) # All, no set and default cases
            #Set default values to all identity values
            _macaddr_vl="$macaddr_dfl "
            _hostname_vl="$hostname_dfl"
            _ident_ttl="0"
            _profile_nm=''
            ;;
    esac
    
    ## Checks enviroment configurations (not move to do_scan_connect, there creates a lot of wpa_supplicant process)
    #if [ "$_wm_dev" = "" ];then # Not found creates one
    #    set -- $(do_conf)
    #    _wm_dev=$1
    #    _wicfg_ref=$2
    #else # Partial initialization case
    #    set -- $(do_conf $_wm_dev)
    #    _wm_dev=$1
    #    _wicfg_ref=$2
    #fi
    
        # Checks enviroment configurations
    if [ "$_wm_dev" = "" ];then # Not found creates one
        set -- $(do_conf)
        _wm_dev=$1
        _wicfg_ref=$2
    else  # Partial initialization case
        if [ "$_wicfg_ref" = "" ];then
            set -- $(do_conf $_wm_dev)
            _wm_dev=$1
            _wicfg_ref=$2
        fi
    fi

    while : # Daemon LOOP
    do
        case $_profile_nm in
        '') # Default case
        # Check if identity rotation is disable
        #if [ "$_ident_ttl" = "0" ];then  # Disabled rotation identity case
            # Checks for a correct scan and connect
            if $(do_scan_connect $_macaddr_vl $_hostname_vl $_wm_dev $_wicfg_ref);then  # Scan and connect waiting for a valid internet connection
                    #echo "545454545454545454545454545454545" >> /root/wm.log
                connectivity_watchdog $_wm_dev # Launch conectivity watchdog
            fi
         ;;
         'anon') # Anonymity and furtive case
        #else  # Enabled rotation identity case
            #echo "1111111" >> /root/wm.log
            if $(identity_is_live $_ident_ttl); then # Live identity case
                logger -t "WM" "Creating new random identity ..."
                # Checks for a correct scan and connect
                if $(do_scan_connect $(get_rnd_identity $id_rnd_prm) $_wm_dev $_wicfg_ref);then # Scan and connect waiting for a valid internet connection
                    #echo "121212121212121212121212" >> /root/wm.log
                    anonymity_watchdog $_wm_dev $_ident_ttl
                fi
                #_ident_ttl=$4 # Reset to ttl time non static received as parameter in this function
            else # Initialization, dead identity , non anonymity case
                _ident_ttl="$(get_new_ident_static_ttl $_ident_ttl)" # Set new ident static ttl time

            fi
            ;;
            
            'man') # Anonymity case
        #else  # Enabled rotation identity case
            #echo "1111111" >> /root/wm.log
            if $(identity_is_live $_ident_ttl); then # Live identity case
                # Checks for a correct scan and connect
                if $(do_scan_connect $_macaddr_vl $_hostname_vl $_wm_dev $_wicfg_ref);then  # Scan and connect waiting for a valid internet connection
                    #echo "121212121212121212121212" >> /root/wm.log
                    anonymity_watchdog $_wm_dev $_ident_ttl $_chk_tm
                fi
                _ident_ttl=$_ident_ttl_prm # Reset to ttl time non static received as parameter in this function
            else # Initialization, dead identity , non anonymity case
                _ident_ttl="$(get_new_ident_static_ttl $_ident_ttl)" # Set new ident static ttl time

            fi
            ;;
            
        esac   
        #fi
    done
}

rm_conf(){
    local _wm_dev=$1 # wlan device
    local _wicfg_ref=$2 # UCI wireless configuration reference

    # Delete conf and wireless device
    uci delete wireless.${_wicfg_ref}
    iw dev $_wm_dev del  >/dev/null 2>&1

    # Update wireless devices list
    cat $wdev_lst_pth | grep -v "$_wm_dev" > $wdev_lst_pth


    # Applies changes
    uci commit wireless
    wifi reload
    /etc/init.d/network reload
}