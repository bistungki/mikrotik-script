:global toMb do={
    local satuBytes 1024;
    local satuKb (1024 * 1024);
    local satuMb (1024 * 1024 * 1024);
    local satuGb ($satuMb * 1024);
    :if ($size <= $satuBytes) do={ :return ($size . "B")}
    :if ($size <= $satuKb) do={ :return (($size / $satuBytes) . "KB")}
    :if ($size <= $satuMb) do={ :return (($size / $satuKb) . "MB")}
    :if ($size <= $satuGb) do={
        :local r ($size / $satuKb)
        # :put $r
        :set r ([:pick $r 1 2])
        :put $r
        :local d ($size/$satuMb) 
        :local k "";
        :if ($r != "") do= { :set $k "."}  
       :return (  $d . $k . $r . "GB")

    }
}
 
:global  getSize do={
        local bi [/ip hotspot user get [find  name=$username] "bytes-in"]
        local bo [/ip hotspot user get [find  name=$username] "bytes-out"]
        local total ($bi + $bo);
        :if ([/ip hotspot active find user=$username]) do={
            local acbi [/ip hotspot active get [find  user=$username] "bytes-in"]
            local acbo [/ip hotspot active get [find  user=$username] "bytes-out"]
            :set $total ( $total + ($acbi + $acbo))
        }
        :log info ("TOTAL GETs: " . $total) ;
        :return $total
}


:local dateint do={
    :local montharray ( "jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec" );
    :local days [ :pick $d 4 6 ];
    :local month [ :pick $d 0 3 ];
    :local year [ :pick $d 7 11 ];
    :local monthint ([ :find $montharray $month]);
    :local month ($monthint + 1);
    :if ( [len $month] = 1) do={
    :local zero ("0");
        :return [:tonum ("$year$zero$month$days")]
    ;} else={
        :return [:tonum ("$year$month$days")]
    ;}
};


# :put [$toMb size=1893741822]

# ip firewall mangle add src-mac-address="1C:4B:D6:2E:C5:2E" chain=prerouting action=mark-connection new-connection-mark="Mc-$user" passthrough=yes comment="#Mc-$user";

# ip firewall mangle add chain=prerouting connection-mark="Mc-$user" comment="#Mp-$user" action=mark-packet passthrough=yes new-packet-mark="Mp-$user";

#:foreach i in=[:ip firewall mangle find where new-connection-mark="mc-$user"] do={ 
#    :local d [ip firewall mangle get $i  src-mac-address]
#    :put [$d];
# }



:local markConnectionName "mc-$user";
:local markPacketName "mp-$user";
:local mac $"mac-address";

:local usermarkcon ([/ip firewall mangle find where new-connection-mark=$markConnectionName]);
:log warning "[$user] new mark connection..."
:if ($usermarkcon = "") do={
    /ip firewall mangle add src-mac-address=$mac chain=prerouting action=mark-connection new-connection-mark=$markConnectionName passthrough=yes comment="Hotspot-MarkConnection-$user";
    /ip firewall mangle add chain=prerouting connection-mark=$markConnectionName comment="Hostpot-MarkPacket-$user" action=mark-packet passthrough=yes new-packet-mark=$markPacketName;
    :log warning "[$user] mark connection and packet added..."
} else={ 
    :log warning "[$user] mark connection and packet change"
    /ip firewall mangle set $usermarkcon src-mac-address=$mac
    :log warning "[$user] mark connection mac change to $mac"
}


/ip firewall mangle remove [:ip firewall mangle find where new-connection-mark="mc-$user"]
/ip firewall mangle remove [:ip firewall mangle find where new-packet-mark="mp-$user"]




