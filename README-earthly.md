---
title: "Earthly build in a container"
permalink: "earthly-signify"
layout: document.html
---


Spring cleaning for builds




One use case for a container build is web software.

I want an accurate copy of the production environment inside a container, but I still want to be able to edit files

In this case I want something like the 

[web.sh script in the Pinfactory project](https://github.com/pinfactory/pinfactory/blob/master/web.sh).

All the dependencies get installed in the Dockerfile,
but then the source code (including all the template
files, CSS, and graphics) is in a volume shared with
the container.  This way I can do a 
<code>[flask run](https://flask.palletsprojects.com/en/master/server/)</code>

inside the container, and when I edit a file in the volume, it Just Works and auto-reloads.


But sometimes I 


Building one project from source isn't hard, but I have found that I often get a big stack of
dependencies and configuration changes that are hard to repeat.


Containers are a big win for local development and testing on even simple web software.

Here's a simple [Dockerfile for a Jekyll project](https://github.com/dmarti/smmd/blob/gh-pages/Dockerfile) that I can use to preview

(I now have a personal RPM that conflicts out all the Ruby packages, so that I know I

<span class="aside">Memo to self: when they add time travel to Git, send that Dockerfile back in time to when I trying to maintain a company web
site on Jekyll and it never came out quite the same on everyone's machine.</span>


So now I'm taking the container idea that works so well for web 






Background

I run my own mail server and other services. (My blog is on a VPS with a static site generator.) 

That means tracking and deploying a bunch of files that end up in a bunch of different places.

I want to be able to check them

The mail server has config files for SpamAssassin, Postfix, and Dovecot, along with 

If you have a bunch of stuff deployed it's nice to be able to check signatures on files

But setting up Gnu Privacy Guard on all those systems is kind of a pain.

What I really need is a lighter-weight signature tool, that I can use to sign and check my config files.

Looking around, I found 



Signify

Looks like what I need.  Sign stuff, be able to check the integrity of files on a remote system


But I need to be able to build and run the same signify on my VPSs (mostly Debian) and on my client systems (mostly Fedora)



The Signify build

Fortunately, Signify has a very nice build that facilitates what I want to do


I can build a statically linked signify, and the man page, and install them everywhere.



## About Earthly


The build process looks roughly like this.


Get the base system including any native packages needed for the build.


Then get the specific dependency specified by the signify Makefile -- the right version of
libbsd.  Save that.


Finally, copy in my version of the code, run make, and save the artifacts I want.


Seems pretty simple.


Target: this is like a target in a Makefile, except that the result is an entire container image, including all side effects.
If anything in your build leaves stray files behind in /tmp or the user's home directory, they will be peristed.

Recipe: the steps needed to build a target

More info: [Earthfile reference](https://docs.earthly.dev/earthfile) 


## The build already does what I want

Good news. The signify build is already set up to download libbsd and build it into a statically
linked singify binary.  All I have to do is...

  RUN make BUNDLED_LIBBSD=1 static

That's great.  Let's make it work with the build plan.


## Try it 

First whack at getting the dependencies

make libbsd-download

I'll just run that in the container to get the bundled libbsd before doing the build.

	RUN gpg --import /root/keys/libbsd.asc
	RUN make BUNDLED_LIBBSD=1 libbsd-download

Denied!  It turns out that if I try to do the whole
`libbsd-download` target, then GPG will try to leave
a socket behind under `.gnupg` in the build user's
home directory.


```
+build | ERROR: (RUN [make BUNDLED_LIBBSD=1 static]) executor failed running [/bin/sh -c  /bin/sh -c 'make BUNDLED_LIBBSD=1 static']: buildkit-runc did not terminate successfully: context canceled: context canceled
Error: solve side effects: build error group: solve: failed to solve: rpc error: code = Unknown desc = failed to compute cache key: failed to create hash for /root/.gnupg/S.gpg-agent: archive/tar: sockets not supported
```

If you were Googling for the above error message, the
tl;dr answer is: either (1) don't try to do any build steps
that run GPG until the final stage of your Earthfile,
or (2) remove the sockets by adding 

	RUN rm -f /root/.gnupg/S*

before the `SAVE IMAGE`.

So this technically works.  Copy the signify sources over,
then import the key, then `make` the libbsd-download step.

Then remove the GPG sockets because they can't be saved in the container image, and save the image.

	RUN gpg --import /root/keys/libbsd.asc
	RUN make BUNDLED_LIBBSD=1 libbsd-download
	RUN rm -f /root/.gnupg/S*
	SAVE IMAGE



## Fixing the libbsd problem.

The problem with that is that if I change something in the

signify source code, the Earthly build has to go download libsd again.

This is slow, and bad style, and

Ideally you have all your dependencies 

so if there's a network outage, or a trade war, or
some developer rage-quits and takes their downloads
down, the build will still go brrrrr.







If I change something in one of the C source files, I don't want to go out on the network and get libbsd again.  So
I'll make a separate 


<hr>

Markdown source for this article: [signify/README-earthly.md at earth-wip · dmarti/signify](https://github.com/dmarti/signify/blob/earth-wip/README-earthly.md)

