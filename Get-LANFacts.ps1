function Get-LANFacts {
<#
    .SYNOPSIS
        resolves hostnames/IPs on or up to a local class C subnet (254 IPs)
    .DESCRIPTION
        Basically a wrapper for arp +  nslookup 
		base idea thanks to https://stackoverflow.com/questions/41785413/use-powershell-to-get-device-names-and-their-ipaddress-on-a-home-network
		w/ help from https://www.kittell.net/code/powershell-ipv4-range/
			https://gallery.technet.microsoft.com/scriptcenter/Start-and-End-IP-addresses-bcccc3a9
			https://stackoverflow.com/questions/58821053/how-to-get-ip-address-range-from-subnet-and-netmask
		
		TODO: 
				Add support for interface specification 
#>
[CmdletBinding()]
[ValidateNotNullorEmpty()]
param(
        [Parameter(Mandatory)]
        [string]$SubNet,
		
		[Parameter()]
        [int]$Intensity = 2,

        [Parameter()]
        [string]$FileOut

)
	$octals = $SubNet.split('.')
	$prefix = ($octals[0..2] -join '.') + '.'
	$suffix = $octals[3].split('/')[0]
	$cidr = $octals[3].split('/')[1]
	
	switch($cidr){
		24 {$mask = '255.255.255.0'}
		25 {$mask = '255.255.255.128'}
		26 {$mask = '255.255.255.192'}
		27 {$mask = '255.255.255.224'}
		28 {$mask = '255.255.255.240'}
		29 {$mask = '255.255.255.248'}
		30 {$mask = '255.255.255.252'}
		31 {$mask = '255.255.255.254'}
		32 {$mask = '255.255.255.255'}
	}
	
	##in case we fuck up range calc
	$range = 1..254
	
	$ip = $prefix + $suffix
	$ipBits = [int[]]$ip.Split('.')
	$maskBits = [int[]]$mask.Split('.')
	$NetworkIDBits = 0..3 | Foreach-Object { $ipBits[$_] -band $maskBits[$_] }
	$BroadcastBits = 0..3 | Foreach-Object { $NetworkIDBits[$_] + ($MaskBits[$_] -bxor 255) }
	$NetworkID = $NetworkIDBits -join '.'
	$Broadcast = $BroadcastBits -join '.'
	
	$range = $NetworkID.split('.')[3]..$Broadcast.split('.')[3]
	$ipRegex = '('
	
	## Ping subnet to get live host IPs in ARP table
	ForEach ($r in $range){
		Start-Process -WindowStyle Hidden ping.exe -Argumentlist "-n 1 -l 0 -f -i 2 -w 1 -4 $prefix$r"
		$ipRegex += $prefix + $r + '.*dynam)|('
	}
	
	$ipRegex+= '127.0.0.1)'
	
	
	if($Intensity > 5){
		$Intensity = 5
	}
	
	## more intensity == louder, but prob better results since ARP table populated
	foreach ($i in $Intensity){
		$Computers = arp.exe -a
	}
	
	#original pattern "$prefix.*dynam, my regex is fucking gross"
	
	#parse computerlist from ARP table (computername, IPv4, MAC)
	$Computers =(arp.exe -a | Select-String -Pattern $ipRegex) -replace ' +',','|
	  ConvertFrom-Csv -Header Computername,IPv4,MAC,x,Vendor |
					   Select Computername,IPv4,MAC

	
	#resolve hostname for each computer found (bless this regex)
	ForEach ($Computer in $Computers){
	  nslookup $Computer.IPv4|Select-String -Pattern "^Name:\s+([^\.]+).*$"|
		ForEach-Object{
		  $Computer.Computername = $_.Matches.Groups[1].Value
		}
	}
	#output table
	$Computers | ft
	
	#output file
	if ($FileOut){
		$Computers | Export-Csv $FileOut -NotypeInformation
	}

}
