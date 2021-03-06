# Get-LANFacts
Given a base IP and CIDR (up to Class C), returns the IP, Hostname, and MAC address to stdout or an optional CSV

## Usage
To use this script, clone this repo to your local system, then `Import-Module .\Get-LANFacts.ps1

To run:
```
PS C:\> Get-LanFacts -SubNet 192.168.1.0/24 -Intensity 3 -FileOut computers.csv
```

### Arguments
There is one mandatory argument:
* subnet
And two optional
* intensity (default = 2)
* fileout (file name)

#### Subnet
LAN to pull data from, currently can function from a /24 up to /32

#### intensity
cooresponds to number of ARP queries made, greater intensity == more populated ARP table

#### fileout
output filename (defaults to a csv format)
