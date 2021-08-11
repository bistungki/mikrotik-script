    # :log info "FUP Monitoring is progress..."
    local satuGiga (1024 * 1024 * 1024);
    local satuMb (1024 * 1024);
    local satuKb 1024;
    local totalPaket ($satuGiga * 2)
    local paketPerTingkat ($totalPaket / 3)
    local fup1 ($totalPaket / 3)
    local fup2  ($totalPaket / 2)
    local fup3  ($totalPaket / 1)

# :local setQuee do={
#     :if ($fupNumber = "1") do={
#         /queue simple add name=$username target=$ipaddress parent="total-bandwidth" max-limit=$maxlimit place-before=yutube   comment=("FUP" . $fupNumber ." " . $hostname)
#     } else={
#         /queue simple set $username max-limit=$maxlimit comment=("FUP" . $fupNumber . " " . $hostname)
#     }
# }


    :foreach k in=[/ip hotspot user find] do={
        # local ipaddress ([/ip hotspot user get $k address]);
        local mac ([/ip hotspot user get $k mac-address]);
        local username ([/ip hotspot user get $k name]);
        local bytesout ([/ip hotspot user get $k bytes-out]);
        local bytesin ([/ip hotspot user get $k bytes-in]);
        local totalbytes (bytesout + bytesin)

        # /ip hotspot user set $username bytes-out=$findBytesOut

            local c [/ip hotspot active find user=$username]
            :if ($c) do={
                local findBytesOut ([/ip hotspot active get $c bytes-out])
                local findBytesIn ([/ip hotspot active get $c bytes-in])
                :set $totalbytes ( $totalbytes + ($findBytesOut + $findBytesIn))
            }
            :if ($totalbytes > 0 && [len $mac] > 0 ) do={
                :put [[len $mac]]
                local findHost ([/ip dhcp-server lease find mac-address=$mac])
                local hostname "do-not-know"
                :if ($findHost != "") do={
                    :set $hostname ([/ip dhcp-server lease get $findHost host-name])
                } 
                local numberQuee ([/queue simple find name=$username])
            
                :if ($totalbytes > $fup3 && [len $numberQuee] > 0) do={
                    local commentFup3 ([/queue simple get $numberQuee comment])
                    :if ($commentFup3  != "") do={
                        local g3 [:pick $commentFup3 0 4]; #substring
                        :if ($g3 != "FUP3") do={
                            /queue simple set $username max-limit=128k/128k comment=("FUP3 " . $hostname )
                            :log info ($hostname . " : " . $username .  " --> masuk dalam FUP3, melebihi batas pemakaian wajar")
                        }
                    }
                } else={
                    :if ($totalbytes > $fup2 && [len $numberQuee] > 0) do={
                            local commentFup2 ([/queue simple get $numberQuee comment])
                            :if ($commentFup2 != "") do={
                                local g2 [:pick $commentFup2 0 4]; #substring
                                :if ($g2 != "FUP2") do={
                                    /queue simple set $username max-limit=384k/512k comment=("FUP2 " . $hostname)
                                    :log info ($hostname . " : " . $username .  " --> masuk dalam FUP2, melebihi batas pemakaian wajar")
                                }
                            }
                    } else={
                        :if ($totalbytes > $fup1) do={
                                :if ($numberQuee = "") do={ # jika list queue masih kosong maka buat baru
                                    /queue simple add name=$username target=10.10.10.0/24 parent=total-bandwidth max-limit=512k/768k place-before=yutube packet-marks="mp-$username"   comment=("FUP1 " . $hostname)
                                    :log info ($hostname . " : " . $username . " --> masuk dalam FUP1, melebihi batas pemakaian wajar")
                                }
                        }
                    }
                }
            
            }
        }