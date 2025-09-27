<p align="center">
  <img src="Images/amur-snow-cute.jpg" alt="Amur Laying in Snow" width="400">
</p>


# Amur Tiger: A collection of scripts to automate scanning and various other tasks

This is still very much a work in progress, but I have added several scripts to scan ips, websites, and extract hashes from pcaps.

## IP Scanning:

The ip scanning scripts use rustscan + nmap then are fed to the searchsploit script to try to extract CVEs and possible exploits.

----

Usage for `rustscan_map.sh`:

```bash
 $ ./rustscan_map.sh -h
Usage: ./rustscan_map.sh [ -f FILE OF IPS TO SCAN  ] 
                  [ -n NMAP OUTPUT FILE ] 
                  [ -o OUTPUT FILE ] 
                  [ -p PORTS ] [ -h HELP ]
```

----

Usage for `run_searchsploit.sh`:

```bash
$ ./run_searchsploit.sh -h
Usage: ./run_searchsploit.sh [ -f FILE OF NMAP RESULTS IN GREPPABLE FORMAT ]
        [ -o OUTPUT FILE TO SAVE RESULTS (OPTIONAL) ] 
        [ -h HELP ]
```

----

### Future Plans:

- Add the cve lookup with a local database (https://www.cve-search.org/)
- Add better usage and explanation

## Website Scanning:

This is a bit more in depth but the general idea is to give a list of domains and use both crt(.)sh and subfinder to gather as many domains as possible before running the list through httprobe, katana, and finally nuclei.

----

Usage for `run_crt.sh`:

```bash
$ ./run_crt.sh -h
Usage: ./run_crt.sh [ -f FILE FULL OF DOMAINS TO SCAN ] 
                  [ -o OUTPUTFILE TO SAVE RESULTS ] 
                  [ -h HELP ]
```

----

Usage for `run_subfinder.sh`:

```bash
$ ./run_subfinder.sh -h
Usage: ./run_subfinder.sh [ -f FILE OF DOMAINS  ] 
        [ -o OUTPUT FILE ] 
        [ -h HELP ]
```

----

Usage for `run_httprobe.sh`:

```bash
$ ./run_httprobe.sh -h
Usage: ./run_httprobe.sh [ -f FILE OF DOMAINS  ] 
        [ -o OUTPUT FILE ] 
        [ -h HELP ]
```

----

Usage for `run_katana.sh`:

```bash
$ ./run_katana.sh -h
Usage: ./run_katana.sh [ -f FILE OF DOMAINS  ] 
        [ -o OUTPUT FILE ] 
        [ -h HELP ]
```

----

Usage for `run_nuclei.sh`:

```bash
$ ./run_nuclei.sh -h
Usage: ./run_nuclei.sh [ -f FILE OF DOMAINS TO SCAN ]
        [ -o OUTPUT FILE TO SAVE RESULTS (OPTIONAL) ]
        [ -t TAGS TO USE (eg -t sqli,cve,...) (OPTIONAL) ]
        [ -s SEVERITY OF TAGS TO USE (eg -s high,medium,low) (OPTIONAL) ]
        [ -u USER AGENT FILE TO USE (OPTIONAL) ] 
        [ -h HELP ]
```

----

I do have a `generic-scripts` folder which is for stuff like combining files which is to combine several files of domains and such into a single file to scan with a tool like nuclei.

----

Usage of `combine-files.sh`:

```bash
 $ ./generic-scripts/combine-files.sh -h
Usage: ./generic-scripts/combine-files.sh [ -f LIST OF FILES  ] 
        [ -o OUTPUT FILE ] 
        [ -h HELP ]
```

----

Usage of `grep-sql-endpoints.sh`:

```bash
$ ./generic-scripts/grep-sql-endpoints.sh -h
Usage: ./generic-scripts/grep-sql-endpoints.sh [ -f FILE OF CRAWLED URLS  ] 
        [ -o OUTPUT FILE ] 
        [ -h HELP ]
```

This should be used after katana is ran.

----

### Future Plans:

- Add more scripts in generic as need be
- Add hakrevdns script to get domains from ips
- Add my prips program to convert ip ranges to ips
- Add my ASN lookup script to get all CIDR ranges from ASN

**NOTE: Last two might be better suited from ip scanning or their own seperate folders and I just write a shell script to call each script seperately in here.**

----

## Extract Hashes:

This is to extract hashes from pcaps. I try to use pure bash and tshark, but devs are weird so some of this will probably be in python or some other language.

----

Usage of `extract-kerberos.sh`:

```bash
$ ./extract-kerberos.sh -h
Usage: ./extract-kerberos.sh [ -f PCAP FILE TO EXTRACT HASHES FROM ]
                  [ -o OUTPUT FILE TO SAVE RESULTS IN ]
                  [ -h HELP ]
```

This one does require the `extract-padata.py` to extract the hashes from the padata blob.

For that python script you need to install: python-pyasn1, python-pyasn1-modules, and impacket.

----

Usage of `extract-ntlm.sh`:

```bash
$ ./extract-ntlm.sh -h
|------------------------------------------------------------------------------|

⢰⣆⠀⠀⠀⠀⠀⠀⠀⠀⣿⣓⣩⠴⠊⢁⣠⠾⠟⠀⠀⢈⣙⣄⣒⠂⡀⠀⠀⢀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⢩⠀⠀⠀⠀⠀⣀⣠⡞⠁⣠⣿⣶⣟⣭⠶⠒⢻⡟⠃⠬⣹⣍⢣⣉⡛⢦⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠙⢁⣀⡤⣂⢈⣼⠟⠀⠀⢠⣿⣿⣿⣇⣶⣿⣿⢹⠄⡤⠈⣶⡉⠈⢻⣜⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠈⠉⠁⢠⡿⠟⠁⣠⡔⠀⢨⢿⠛⠟⣛⣿⣿⣿⠈⠐⠒⠁⠈⠁⠀⢠⠟⠳⠶⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣿⠃⢠⣾⡟⢻⣿⡇⢈⡛⠻⠛⣍⠉⠻⡆⠀⢠⣶⡤⠀⠀⠉⠘⣀⠂⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⠀⣻⠂⢻⣿⡇⢸⣿⣿⠺⣷⠌⠐⠠⢤⠀⢸⣿⣿⣿⣷⣦⡄⠀⠀⠀⠀⠈⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⣰⣿⡇⠸⣿⣇⠈⣿⣿⠀⠛⠋⣁⢀⣽⡟⣿⣿⣿⣿⣿⣽⣤⣀⠀⠀⠀⠈⣵⡇⠘⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⠀⢻⣿⡿⡄⢹⣿⡆⢻⣿⣧⣴⣊⣷⣿⣿⣿⣿⣿⣿⣿⣿⡟⢻⡉⠃⠀⠀⠀⠈⠁⣷⣠⡀⠀⠀⠀⠀⠀⠀⠀⠀
⠀⠀⢀⣿⣿⣿⣰⠀⣿⡿⠮⠻⠿⠻⢋⣼⣿⣾⣿⣿⣿⣾⢿⣿⠇⠈⠁⠀⠀⢠⠀⠀⣀⠀⣿⣧⠀⠀  < PCAP NTLM Hash Extractor >
⠀⠀⣾⣿⣿⣿⣎⢶⣾⣧⣀⣶⣾⣿⣿⣿⣿⣿⣻⣿⠛⣹⡀⠀⠀⠀⠀⠀⣀⣾⠀⠄⡭⠀⠹⡏⠀⠀⠀⠀⠀       < By: Alex >
⠀⢰⣿⣿⣿⣿⣿⡸⡆⠙⣿⣿⣦⡽⢿⣿⣿⣿⠷⣶⡦⠄⠻⢷⣦⡄⠀⣾⣿⣶⣖⣒⡇⠀⠀⠃⠀⠀⠀⠀⠀⠀⠀⠀
⠀⣿⣿⣿⣿⣿⣿⣇⢿⡀⠙⠛⠛⠛⠚⢿⣿⣿⣷⠶⠶⣖⣞⣿⠟⠁⠀⠀⠉⠛⠀⢸⠁⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢸⣿⣿⢿⣿⢻⣿⣿⣿⢷⡀⣀⠀⠀⠀⠁⡹⠛⠁⠉⠉⠁⠈⠁⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢸⣿⡷⡼⠣⡾⢻⣿⠛⠈⢿⡿⣶⡄⠀⠈⠀⠞⠀⠀⠀⣰⣶⣤⠀⣄⢠⣄⣸⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
⢸⣿⣷⡄⠀⠁⠘⠛⠃⠀⠀⠀⢿⡆⠀⠀⠀⠀⠀⠀⠈⠈⠟⠛⠛⠃⠈⠋⠉⠀

|------------------------------------------------------------------------------|

[*] Checking arguments...
Usage: ./extract-ntlm.sh [ -f PCAP FILE TO EXTRACT HASHES FROM ]
                  [ -o OUTPUT FILE TO SAVE RESULTS IN ]
                  [ -h HELP ]
```

----

Usage of `extract-snmpv3.py`:

```bash
 $ ./extract-snmpv3.py -h

... ASCII art doesn't want to look right in this README. :(((
    
Starting SNMPv3 Hash Extractor...

usage: extract-snmpv3.py [-h] -p P [-o O] [-v]

Extract SNMPv3 packets and write JtR $SNMPv3$ hashes to a file

options:
  -h, --help  show this help message and exit
  -p P        Specify .pcap/.pcapng file with SNMPv3 data
  -o O        Output file for JtR hashes (default: hashes.txt)
  -v          Verbose; print error messages
```

This is a python script and requires pyshark to be installed. For use in venv, you have to do: `python3 -m venv venv && source venv/bin/activate`
whatever you use for virtualenv. This was written in python because I couldn't get it to cooperate with tshark in my shell script.

----

## Future Plans:

- Add the script that handles mysql both sha1 and sha2. (This required a different strategy because the password is hashed twice before XOR and hash2 is stored on the server so had to do something differently based on the information I had access to)
- Port over `extract-padata.py` to Golang if possible. (I don't see why not, but Golang doesn't have everything ported over yet or there aren't mature libraries). I much prefer Go since it is compiled and I wouldn't have to deal with virtual environments as much.

----

# Conclusion:

This was a pretty quck and dirty PoC, but overtime I plan on cleaning this up more and add things such as usage examples and a lot more stuff.