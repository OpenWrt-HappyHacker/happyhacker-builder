get_rnd_num(){
    
    if [ $1 -lt $2 ];then # Corect ranges to avoid tr issues
        local _min_vl=$1
        local _max_vl=$2
    else
        local _min_vl=$2
        local _max_vl=$1
    fi
    
    #echo "---------------------" >> /tmp/aap.log
    local _min_rg="0"
    # Max range limit
    if [ "$_min_vl" -eq "0" ];then
        local _max_rg=$_max_vl    
    else
        local _max_rg=$(expr $_max_vl - $_min_vl) # Set max range
    fi
    
    local _result=""
    local _max_rg_sz=${#_max_rg}
    local _map_chr=$(expr $_max_rg_sz - 1) # Correct mapping characers and length string. ex: length=3 0,1,2 characters mapped
    
    # Generate reverser sequence, not supported by defualt in openwrt expansion like {0..1} or rev command
    local _seq_rev=""
    for p in $(seq 0 $_map_chr); do # Iterates from 0 to length -1 (_map_chr)
        _seq_rev=${p}" "${_seq_rev}
    done
    
        local _rnd_num=""
        local _min_dg=0
        local _max_dg=""
    
    for p in $_seq_rev; do # Iterates from length
        if [ $p -eq 0 ];then
            local _p_1=$(expr $p - 1)
            local _max_dg_last=${_max_rg:${p_1}:1}
            _max_dg=${_max_rg:${p}:1}
            if [ "$_rnd_num" != "" ] ;then
                if [ "$_max_dg_last" != "" ];then
                    if [ $_max_dg_last -lt $_rnd_num ];then # If max range digit in position p is more little than last random number used
                        _max_dg=$(expr $_max_dg - 1) # Compesates excess
                        if [ "$_max_dg" -lt "0" ];then _max_dg="0"; fi # Correct negative value
                    fi
                fi
            fi
            _rnd_num=$(cat /dev/urandom | tr -cd ${_min_rg}-${_max_dg} | dd bs=1 count=1 2>/dev/null) # Generates a random number between min_rg and max_rg

            local _tresult="${_rnd_num}${_result}" # Temporal result
            while [ $_tresult -lt $_min_rg ]; # If temporal result is more little than min range digit in position p
            do
                _rnd_num=$(cat /dev/urandom | tr -cd ${_min_rg}-${_max_dg} | dd bs=1 count=1 2>/dev/null)
                _tresult="${_rnd_num}${_result}"
            done       
         else
            _min_dg=0
            _max_dg=9
            _rnd_num=$(cat /dev/urandom | tr -cd ${_min_rg}-${_max_dg} | dd bs=1 count=1 2>/dev/null)
        fi
         
       _result="${_rnd_num}${_result}"
    done
    
    
    _result=$(echo $_result | awk '{sub(/^0*/,"")}1') # Remove leftside zeros
    if [ "$_result" == "" ];then # Check por 0 value killed by previous remove leftside zeros
       echo "$_min_vl" # Reasing 0, 0 + min value = min value
    else
        echo "$(expr $_result + $_min_vl)" # Non zero empty result detected, min value + rnd number between 0 and diff (max-min)
    fi
}

get_rnd_LET(){
     # Get random upcase letter
     echo $(cat /dev/urandom | tr -cd A-Z | dd bs=1 count=1 2>/dev/null) 
}

get_rnd_let(){
    # Get random downcase letter
    echo $(cat /dev/urandom | tr -cd a-z | dd bs=1 count=1 2>/dev/null) 
}


get_rnd_MAC(){
    # Get random mac address 
    local _type=$1 # mobile laptop all
    
    # MAC VENDOR CODES
    # Source list: https://www.adminsub.net/mac-address-finder
    
    local _vendor_apple="00:1B:63 00:23:DF 00:26:4A 00:F4:B9 30:F7:C5"
    local _vendor_motorola="00:17:84 00:1A:DB 00:1C:C1 00:22:B4 00:26:BA"
    local _vendor_samsung="F0:72:8C D8:57:EF B8:D9:CE 94:51:03 64:77:91"
    local _vendor_huawei="00:25:9E 34:6B:D3 78:F5:FD AC:E2:15 F8:3D:FF"
    local _vendor_lg="F8:95:C7 C4:9A:02 AC:0D:1B A0:39:F7 58:3F:54"
    
    local _vendor_intel="60:6C:66 5C:51:4F 4C:34:88 18:FF:0F 0C:8B:FD"
    local _vendor_broadcom="E0:3E:44 18:C0:86 00:10:18 00:0A:F7 00:05:B5"
    local _vendor_atheros="88:12:4E 00:B0:52 00:13:74 00:03:7F 8C:FD:F0"

    
    # Mobile devices mac vendor codes
    local _mobile_lst="$_vendor_lg $_vendor_huawei $_vendor_samsung $_vendor_motorola"
    local _mobile_lst_sz="$(echo $_mobile_lst | wc -w)" # Number of elements
    local _vendor_apple_sz="$(echo $_vendor_apple | wc -w)" # Number of elements
    
    
    # Laptops vendors codes
    local _laptop_lst="$_vendor_intel $_vendor_broadcom $_vendor_atheros"
    local _laptop_lst_sz="$(echo $_laptop_lst | wc -w)" # Number of elements
    local _vendor_intel_sz="$(echo $_vendor_intel | wc -w)" # Number of elements
    
    # All vendors codes
    local _all_lst="$_mobile_lst $_laptop_lst" # All mac vendors code list
    local _all_lst_sz="$(echo $_all_lst | wc -w)" # Number of elements
    
    case $_type in
        [m,M]*) # Mobiles android devices phones or tables mac address
                local _vendor_vl=$(echo $_mobile_lst |awk -F ' ' -v p=$(get_rnd_num 1 $_mobile_lst_sz) '{print $p}')
            ;;
        
        [a,A]*) # Apple mac address
                local _vendor_vl=$(echo $_vendor_apple |awk -F ' ' -v p=$(get_rnd_num 1 $_vendor_apple_sz) '{print $p}')
            ;;
        [i,I]*) # Intel mac address (common in Apple laptops)
                local _vendor_vl=$(echo $_vendor_intel |awk -F ' ' -v p=$(get_rnd_num 1 $_vendor_intel_sz) '{print $p}')
            ;;
    
        [l,L]*) # Laptop computers mac address
                local _vendor_vl=$(echo $_laptop_lst |awk -F ' ' -v p=$(get_rnd_num 1 $_laptop_lst_sz) '{print $p}')
            ;;
            
        *) # All mac address type available
                local _vendor_vl=$(echo $_all_lst |awk -F ' ' -v p=$(get_rnd_num 1 $_all_lst_sz) '{print $p}')
            ;;
    esac
    
    # Generates random mac address
    printf '%s:%02X:%02X:%02X' $_vendor_vl $(get_rnd_num 0 255) $(get_rnd_num 0 255) $(get_rnd_num 0 255)
}

get_rnd_hash(){
        # Generates a random hash
        local _length=$1 # lenght of hash
        local _nums=$2 # true/false with numbers/wo numbers
        local _updow=$3 # up --> upcase letters down --> downcase letters
        
        local _chr_nm=""
        local _result=""
        for n in $(seq 1 $_length);do
            
            if [ $_nums ];then
                # Generate randomly a letter or number
                case $(get_rnd_num 0 1) in
                    [0]*) # Number case
                        _chr_nm=$(get_rnd_num 0 9) # Generates a number
                    ;;    
                    [1]*) # Letter case
                        case $_updow in
                            [f,F,0,d,D]*) # Downcase 
                                _chr_nm=$(get_rnd_let)
                            ;;    
                            [t,T,1,u,U]*) # Upcase
                                _chr_nm=$(get_rnd_LET)
                            ;;        
                        esac            
                    ;;        
                esac
            else
                
                case $_updow in
                    [f,F,0,d,D]*) # Downcase 
                        _chr_nm=$(get_rnd_let)
                    ;;    
                    [t,T,1,u,U]*) # Upcase
                        _chr_nm=$(get_rnd_LET)
                    ;;        
                esac                
            fi
                _result=$(printf '%s%s' $_result $_chr_nm)            
        done
        
        echo $_result    
}

get_rnd_name(){
    # Selects a random name in a list
    # Source list: https://en.wikipedia.org/wiki/List_of_most_popular_given_names#Europe
    local _name_lst='Jan Antoni Jakub Aleksander Franciszek Adam Filip Stanislaw Szymon Mikolaj Lukas Lucas Leo Emil Jack Luca Luka Nikola Liam Joao Ivan Marko Filip Karlo Petar Leon Josip Fran David Oliver Jack Harry Jacob Charlie Thomas George Oscar James William Rasmus Robin Oliver Maksim Robert Martin Kaspar Oskar Henri Markus Alexander Maxim Dmitry Hugo Daniel Pablo Alejandro Alvaro Adrian Anna Hannah Sophia Emma Marie Lena Sarah Sophie Laura Mia Amelia Olivia Emily Isla Poppy Ava Isabella Jessica Lily Hanna Anna Jazmin Lili Zsofia Emma Boglarka Zoe Nora Zofia Zuzanna Julia Hanna Alicja Maria Maja Natalia Aleksandra Lucia Maria Martina Paula Daniela Sofia Valeria Carla Sara Alba Elsa Alice Maja Saga Ella Lily Olivia Ebba Wilma Julia Osa Lara Sarah Charlotte'
    
    # Calculates sizes of list
    local _name_lst_sz="$(echo $_name_lst | wc -w)" # Number of elements
    
    # TODO: Check for a valid return --> !=""
    # Generates a random name
    echo $(echo $_name_lst |awk -F ' ' -v p=$(get_rnd_num 1 $_name_lst_sz) '{print $p}')
}

get_rnd_uri(){
    # Selects a random uri in a list
    # Source list: https://en.wikipedia.org/wiki/List_of_most_popular_websites
    local _uri_lst='google.com youtube.com facebook.com yahoo.com amazon.com wikipedia.org twitter.com linkedin.com bing.com ebay.com instagram.com reddit.com'
    
    # Calculates sizes of list
    local _uri_lst_sz="$(echo $_uri_lst | wc -w)" # Number of elements
    
    # Generates a random name
    echo $(echo $_uri_lst |awk -F ' ' -v p=$(get_rnd_num 1 $_uri_lst_sz) '{print $p}')
}


get_rnd_host(){
    # Generates a random hostname
    local _type=$1 # Devices type, mobile , laptop
    local _subtype=$2 # Operating system, android, ios  | windows, macos
    
    # HOSTNAMES TEMPLATE LIST:
    # default hostname used in dhcp request by operating system
    local _tpl_android_lst="android-$(get_rnd_hash 16 true down)"
    local _tpl_ios_lst="$(get_rnd_name)s-iPhone $(get_rnd_name)s-iPad $(get_rnd_name)s-iPod"
    local _tpl_macos_lst="$(get_rnd_name)s-MacBook"
    local _tpl_windows_lst="$(get_rnd_name)-Notebook $(get_rnd_name)-Laptop $(get_rnd_name)-PC $(get_rnd_name)-PC$(get_rnd_num 0 4)  $(get_rnd_name)-Computer WIN-$(get_rnd_hash 11 true up)"
    
    
    # Calculates sizes of list
    local _tpl_android_lst_sz="$(echo $_tpl_android_lst | wc -w)" # Number of elements
    local _tpl_ios_lst_sz="$(echo $_tpl_ios_lst | wc -w)" # Number of elements
    local _tpl_macos_lst_sz="$(echo $_tpl_macos_lst | wc -w)" # Number of elements
    local _tpl_windows_lst_sz="$(echo $_tpl_windows_lst | wc -w)" # Number of elements
    
   
    # Select a random template into selected devices type and os
    local _hostname_vl=""
    case $_type in # Selects devices type
        [m,M]*) # Mobile devices such as phones, tables, or music players
                case $_subtype in # Select mobile os
                    ['a','A']*) # Android mobile phone or tablet hostname
                            _hostname_vl="$(echo $_tpl_android_lst|awk -F ' ' -v p=$(get_rnd_num 1 $_tpl_android_lst_sz) '{print $p}')"
                        ;;
                
                    ['i','I']*) # IOS , iphone, ipad or ipod hostname
                            _hostname_vl="$(echo $_tpl_ios_lst|awk -F ' ' -v p=$(get_rnd_num 1 $_tpl_ios_lst_sz) '{print $p}')"
                        ;;
                esac
            ;;
    
        [l,L]*) # Laptop computers devices
                case $_subtype in # Select computer os
                    [w,W]*) # Windows laptop hostname
                            _hostname_vl="$(echo $_tpl_windows_lst|awk -F ' ' -v p=$(get_rnd_num 1 $_tpl_windows_lst_sz) '{print $p}')"
                        ;;
                
                    [m,M]*) # Mac OS laptop hostname
                            _hostname_vl="$(echo $_tpl_macos_lst|awk -F ' ' -v p=$(get_rnd_num 1 $_tpl_macos_lst_sz) '{print $p}')"
                        ;;
                esac
            ;;
    esac
   
    # Expand template selected randomly to replace $get_XXX functions
    echo "$(echo $_hostname_vl)"
}

get_rnd_identity(){
    local _type="$1"
    local _subtype="$2"
    
    # Witout parameters random ones will be generate
    if [ "$_type" = "" ];then _type=$(get_rnd_num 0 1); fi
    if [ "$_subtype" = "" ];then _subtype=$(get_rnd_num 0 1); fi
    
    
    local _hostname_vl=""
    local _macaddr_vl=""
    case $_type in # Selects devices type
        [0,m,M]*) # Mobile devices such as phones, tables, or music players
                case $_subtype in # Select mobile os
                    [0,a,A]*) # Android: phone or tablet identity
                            #echo "MOBILE ANDROID ">> /tmp/aap.log   
                            _hostname_vl="$(get_rnd_host mobile android)"
                            _macaddr_vl="$(get_rnd_MAC mobile)"
                        ;;
                
                    [1,i,I]*) # IOS: iphone, ipad or ipod identity
                            #echo "MOBILE IOS ">> /tmp/aap.log   
                            _hostname_vl="$(get_rnd_host mobile ios)"
                            _macaddr_vl="$(get_rnd_MAC apple)"
                        ;;
                esac
            ;;
    
        [1,l,L]*) # Laptop computers devices
                case $_subtype in # Select computer os
                    [0,w,W]*) # Windows laptop identity
                            #echo "LAPTOP WINDOWS">> /tmp/aap.log
                            _hostname_vl="$(get_rnd_host laptop windows)"
                            _macaddr_vl="$(get_rnd_MAC laptop)"
                        ;;
                
                    [1,m,M]*) # Mac OS laptop identity
                            #echo "LAPTOP MACOS">> /tmp/aap.log
                            _hostname_vl="$(get_rnd_host laptop macos)"
                            _macaddr_vl="$(get_rnd_MAC intel)"
                        ;;
                esac
            ;;
    esac
    #echo ">>>>>>>>>> $_macaddr_vl $_hostname_vl">> /tmp/aap.log
    echo "$_macaddr_vl $_hostname_vl"
}