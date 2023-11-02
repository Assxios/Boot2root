get ssh into any user first. or reserve shell

run https://github.com/The-Z-Labs/linux-exploit-suggester/blob/master/linux-exploit-suggester.sh
```
➜  ~ cat out

Available information:

Kernel version: 3.2.0
Architecture: i386
Distribution: ubuntu
Distribution version: 12.04
Additional checks (CONFIG_*, sysctl entries, custom Bash commands): performed
Package listing: from current OS

Searching among:

81 kernel space exploits
49 user space exploits

Possible Exploits:

[+] [CVE-2016-5195] dirtycow

   Details: https://github.com/dirtycow/dirtycow.github.io/wiki/VulnerabilityDetails
   Exposure: highly probable
   Tags: debian=7|8,RHEL=5{kernel:2.6.(18|24|33)-*},RHEL=6{kernel:2.6.32-*|3.(0|2|6|8|10).*|2.6.33.9-rt31},RHEL=7{kernel:3.10.0-*|4.2.0-0.21.el7},[ ubuntu=16.04|14.04|12.04 ]
   Download URL: https://www.exploit-db.com/download/40611
   Comments: For RHEL/CentOS see exact vulnerable versions here: https://access.redhat.com/sites/default/files/rh-cve-2016-5195_5.sh
```

you can learn how ditrycow works here:
https://github.com/dirtycow/dirtycow.github.io/wiki/VulnerabilityDetails

Here's a quick explanation of how it works:
as you can see we're going to write to a write protected file `/etc/passwd`, normally this would not be possible but we can bypass this thanks to a race condition in the kernel:

First we used `mmap` to map the file to our virtual memory, of course since the file is write protected we can't write to it so we'll have to use the `MAP_PRIVATE` will which create a copy of the file in our virtual memory when we try writing to it (COW = copy on write). However until we try to write to the file, our mapping to the file will point to the actual file's memory.

Here's where the exploit starts happening, because of the behavior I just described. We will have two process, one which will try to write each character of our string to the corresponding position in the file a lot of times and the other one which will tell the kernel that we don't need that memory anymore (`madvise` with `MADV_DONTNEED`). So while the kernel tries to get rid of the pages as madvise told him to, it is also trying to make a private copy for the COW because we are trying to write to it with ptrace. If we get lucky (or run it a lot of times like we do), there will be a race condition where ptrace sucessfully writes to the file before the kernel can make a copy of the page. This will result in the file being modified.
Once the COW mechanism, writing to the write protected file is no longer possible and any further writes will be done to the copy of the file in our virtual memory.
*But we still have a lot of loops simply because we don't know, how many attempts it will take to get the race condition to happen.*

I will use the pokemon c code with a few modifications to get a root shell.
you can see the modified c code here ![exploit.c](scripts/exploit.c)
Alright, let's write `root:As.Qw2p5l2zVE:0:0::/root:/bin/bash\n` within the /etc/passwd file. You can learn how I crafted this string in the exploit.c file's comments.

```
cat /etc/passed
compile
execute
cat /etc/passwd
omg it's here modified
```

let's try to login to root with the password `Password` *this is the password before it was hashed to `As.Qw2p5l2zVE`*
```
su root
id
```

it works