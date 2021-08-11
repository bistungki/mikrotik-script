# :log info "hostpot-5000-24h.rsc is running...!!"
# /ip hotspot user add name="5fdwxxx" comment="jun/16/2021 13:30:00" password="5fdwxxx" profile="hotspot-5000-24-jam" 
        # :local getS [$getSize username="mio"]; 
:local toMb do={
    local satuBytes 1024;
    local satuKb (1024 * 1024);
    local satuMb (1024 * 1024 * 1024);
    local satuGb ($satuMb * 1024);
    :if ($size <= $satuBytes) do={ :return ($size . "B")}
    :if ($size <= $satuKb) do={ :return (($size / $satuBytes) . "KB")}
    :if ($size <= $satuMb) do={ :return (($size / $satuKb) . "MB")}
    :if ($size <= $satuGb) do={
        :local r ($size / $satuKb)
        :set r ([:pick $r 1 2])
        :local d ($size/$satuMb) 
        :local k "";
        :if ($r != "") do= { :set $k "."}  
       :return (  $d . $k . $r . "GB")
    }
}
:local  getSize do={
        local bi [/ip hotspot user get [find  name=$username] "bytes-in"]
        local bo [/ip hotspot user get [find  name=$username] "bytes-out"]
        local total ($bi + $bo);
        :if ([/ip hotspot active find user=$username]) do={
            local acbi [/ip hotspot active get [find  user=$username] "bytes-in"]
            local acbo [/ip hotspot active get [find  user=$username] "bytes-out"]
            :set $total ( $total + ($acbi + $acbo))
        }
        :return $total
}

:local dateint do={
    :local montharray ("jan","feb","mar","apr","may","jun","jul","aug","sep","oct","nov","dec" );
    :local days [ :pick $d 4 6 ];
    :local month [ :pick $d  0 3 ];
    :local year [ :pick $d 7 11 ];
    :local monthint ([ :find $montharray $month]);
    :local month ($monthint + 1);
    :if ( [len $month] = 1) do={
        :local zero ("0");
        :return [:tonum ("$year$zero$month$days")];
    } else={
        :return [:tonum ("$year$month$days")];
    }
};

:local timeint do={ 
    :local hours [ :pick $t 0 2 ]; 
    :local minutes [ :pick $t 3 5 ]; 
    :return ($hours * 60 + $minutes) ; 
}; 
:local date [ /system clock get date ]; 
:local time [ /system clock get time ]; 
:local today [$dateint d=$date] ; 
:put $date;
:local curtime [$timeint t=$time] ;
 :foreach i in [ /ip hotspot user find where profile="hotspot-5000-24-jam" ] do={ 
    :local comment [ /ip hotspot user get $i comment]; 
    :local name [ /ip hotspot user get $i name]; 
    #vc-584-07.06.21-
    #aug/01/2021 19:05:42
    :local gettime [:pick $comment 12 20]; 
    :if ([:pick $comment 3] = "/" and [:pick $comment 6] = "/") do={
    :put $name;
        :local expd [$dateint d=$comment] ; 
        :local expt [$timeint t=$gettime] ; 
        :if (($expd < $today and $expt < $curtime) or ($expd < $today and $expt > $curtime) or ($expd = $today and $expt < $curtime)) do={
            :local tot ([$toMb size=[$getSize username=$name]]);
            :log info ("hotspot user " . $name ." deleted and bytes total=" . $tot)
            [ /ip hotspot user remove $i];
            [ /ip hotspot active remove [find where user=$name] ];
            [/queue simple remove $name];
            /ip firewall mangle remove [:ip firewall mangle find where new-connection-mark="mc-$name"]
            /ip firewall mangle remove [:ip firewall mangle find where new-packet-mark="mp-$name"]
        }
    }
}
