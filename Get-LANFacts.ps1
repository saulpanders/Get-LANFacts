function Get-LANFacts {
<#
    .SYNOPSIS
        resolves hostnames/IPs on a local class C subnet (254 IPs)
    .DESCRIPTION
        Basically a wrapper for nslookup 
		base idea thanks to https://stackoverflow.com/questions/41785413/use-powershell-to-get-device-names-and-their-ipaddress-on-a-home-network
		w/ help from https://www.kittell.net/code/powershell-ipv4-range/
			https://gallery.technet.microsoft.com/scriptcenter/Start-and-End-IP-addresses-bcccc3a9
		
		TODO: currently hardcoded for /24, add support for all local netblocks (i.e. convert to INT -> calcualte start & end addresses -> convert to IP)
#>
[CmdletBinding()]
[ValidateNotNullorEmpty()]
param(
        [Parameter(Mandatory)]
        [string]$SubNet,

        [Parameter()]
        [string]$FileOut

)
	$octals = $SubNet.split('.')
	$prefix = ($octals[0..2] -join '.') + '.'
	$range = 1..254
	
	
	## Ping subnet to get live host IPs in ARP table
	ForEach ($r in $range){
		Start-Process -WindowStyle Hidden ping.exe -Argumentlist "-n 1 -l 0 -f -i 2 -w 1 -4 $prefix$r"
	}
	
	#parse computerlist from ARP table (computername, IPv4, MAC)
	$Computers =(arp.exe -a | Select-String "$prefix.*dynam") -replace ' +',','|
	  ConvertFrom-Csv -Header Computername,IPv4,MAC,x,Vendor |
					   Select Computername,IPv4,MAC

	
	#resolve hostname for each computer found (bless this regex)
	ForEach ($Computer in $Computers){
	  nslookup $Computer.IPv4|Select-String -Pattern "^Name:\s+([^\.]+).*$"|
		ForEach-Object{
		  $Computer.Computername = $_.Matches.Groups[1].Value
		}
	}
	$Computers
	if ($FileOut){
		$Computers | Export-Csv $FileOut -NotypeInformation
	}

}
