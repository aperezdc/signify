---
title: "Earthly build in a container"
permalink: "earthly-signify"
layout: document.html
---

Every time I build an open source project from scratch, I end up installing a bunch of dependencies.
And often it's tricky to get the build working the same 
way on multiple systems.  And it's even harder to get new people started on a project.

So just containerize it, right?  So far I have found that Docker containers work great for web applications. 
I get an accurate copy of the standard  production environment inside a container, and I can still edit files and
use my web framework's auto-reload feature.  Here's an example, the [web.sh script in the Pinfactory project](https://github.com/pinfactory/pinfactory/blob/master/web.sh).
All the dependencies get installed in the 
[project Dockerfile](https://github.com/pinfactory/pinfactory/blob/master/Dockerfile),
and then the source code (including all the HTML templates,
CSS, and graphics) is in a volume shared into
the container.  This way I can do a 
<code>[flask run](https://flask.palletsprojects.com/en/master/server/)</code>
inside the container, and when I edit a file in the volume, it Just Works and auto-reloads.  Pinfactory is easy to
work on in containers. You can run one script to do all the unit tests in a container, one script to start up a web
server with real data, and there's even a tricked-out [demo](https://www.socallinuxexpo.org/scale/18x/presentations/designing-market-reduce-software-risk-and-compensate-open-source) script.
that creates a container with multiple users.  Containerizing web applications is a win for small stuff, too. 
Here's a simple [Dockerfile for a Jekyll project](https://github.com/dmarti/smmd/blob/gh-pages/Dockerfile) that I can use to preview a relatively large Jekyll site locally, without installing any Ruby packages. 

Containers for developing and testing web sites locally are great.  So what about containerizing a regular software build?


## Building a simple tool to sign files

I run my own mail server and other services. (My blog is on a VPS with a static site generator.) 
That means tracking and deploying a bunch of files that end up in a bunch of different places, on 
systems running a variety of Linux distributions.

I want to be able to sign important files, and check signatures, so I'm looking for a good, lightweight
digital signature tool.

Looking around, I found [signify, the OpenBSD tool to signs and verify signatures on files, in a portable version.](https://github.com/aperezdc/signify) Looks like just what I need.  Sign stuff, check the signatures of files on a remote system, not a lot to configure, easy to script.  Also, good practice for a new way to make a software build easy to manage and repeatable.

Signify has a very nice build that facilitates what I want to do, driven by a well laid-out Makefile.
I can build a statically linked signify, and the man page, that will work on all my Linux systems of whatever distribution.
Signify is also a good example of a program to build and install, because it includes an interesting dependency and a step where the Makefile needs to check a signature of the dependency. 


## Driving the build with Earthly

Earthly is a build automation tool for
container-based tools.  It uses the
Docker daemon to manage containers.
I have run it with both docker.com's [Docker
Engine](https://docs.docker.com/engine/release-notes/)
and with the [Docker packages for Fedora
32](https://fedoramagazine.org/docker-and-fedora-32/):
`moby-engine` and `docker-compose`.

Earthly is controlled by an `Earthfile`, which is like a Dockerfile, broken out into targets like a Makefile.
Each target produces an entire container image, including all side effects.
If anything in your build leaves stray files behind in /tmp or the user's home directory, they will be persisted.

The install is simple&mdash;it's a single binary.  The install instructions on the Earthly site will put it in `/usr/local/bin` by default,
but there's nothing else to add or configure besides Earthly and Docker.  More info: [Earthfile reference](https://docs.earthly.dev/earthfile) 

There is an example Earthfile for a [C++ project with CMake](https://docs.earthly.dev/examples/cpp) that I'll use as a starting
point.


## Planning a Signify build.

My Signify build will have to be a little more complicated than just installing the
packages I need from the package manager, copying the Signify source code into the
container, and then running `make`.

In order to make a static build with signify's bundled copy of `libbsd`, I will also need
to download and verify a libbsd release.  The signify Makefile already knows how to download libbsd and build it into a statically
linked signify binary.  All I have to add to do is

	make BUNDLED_LIBBSD=1 static

But if I do that, every time I do a build, I have to go out on the network.  Behind the scenes, the
signify Makefile is running `wget` to download first the signature for the libbsd release...

        $(WGET) -cO $@ '$(libbsd_ASC_URL)'

and then the tar file.

        $(WGET) -cO $@ '$(libbsd_TAR_URL)'

So I really want to separate the download step from the build step.  I want something like this.

	1. Set up the base system and save a container image.

	2. Download libbsd and save a container image.

	3. Copy my current version of the code into the container, do the build, save the build artifacts.

Step 3 shouldn't require any network access, so should be really fast.  As fast as a regular `make`, anyway.


## First try, first FAIL

Here's my first attempt at step 2.  I'll take advantage of the nice `libbsd-download` target in the signify Makefile,
and do this right after I copy the code into the container.

	COPY --dir . /code
	RUN make BUNDLED_LIBBSD=1 libbsd-download

No, wait, `libbsd-download` needs to check the signature.  Make that:

	COPY --dir . /code
	RUN gpg --import /root/keys/libbsd.asc
	RUN make BUNDLED_LIBBSD=1 libbsd-download
	SAVE IMAGE

When I first tried this, I was not able to `make` the 
`libbsd-download` target, because GPG tried to leave
a socket behind under `.gnupg` in the build user's
home directory.


```
+build | ERROR: (RUN [make BUNDLED_LIBBSD=1 static]) executor failed running [/bin/sh -c  /bin/sh -c 'make BUNDLED_LIBBSD=1 static']: buildkit-runc did not terminate successfully: context canceled: context canceled
Error: solve side effects: build error group: solve: failed to solve: rpc error: code = Unknown desc = failed to compute cache key: failed to create hash for /root/.gnupg/S.gpg-agent: archive/tar: sockets not supported
```

If you found this page by Googling for
<strong>archive/tar: sockets not supported</strong>,
here's the answer.  It's a
[known bug in buildkit](https://github.com/earthly/earthly/issues/115),
the software build system maintained as part of Moby,
which is the open-source project that forms the basis
of Docker.  Earthly has [fixed the problem](https://github.com/earthly/earthly/issues/115) by
updating to the new version of buildkit.

If you're still seeing this error, you can (1) upgrade your
Earthly and Docker, (2) don't try to do any build
steps that run GPG until the final target, or (3)
remove the sockets by adding

	RUN rm -f /root/.gnupg/S*

before the `SAVE IMAGE`.

So my first attempt at getting Signify to build was:

 * copy the signify sources over
 * import the key
 * Do a `make libbsd-download`
 * remove the GPG sockets because they can't be saved in the container image
 * finally, save the image.

In Earthfile, that looks like this.

	RUN gpg --import /root/keys/libbsd.asc
	RUN make BUNDLED_LIBBSD=1 libbsd-download
	RUN rm -f /root/.gnupg/S*
	SAVE IMAGE

But that's a sub-optimal solution.

## Splitting out download, copy, and build steps

The problem with the above method is that if I change something in the
signify source code, the Earthly build has to go download libbsd again.

This is slow, and bad style, and it means if you need to make a quick change to the
C source code, the build still goes and gets some unchanged dependencies.

Ideally you have all your dependencies stored
locally, so if there's a network outage, or a trade
war, or some developer rage-quits and takes their
downloads page down, the build will still go brrrrr.
Not that anything like that would happen in the case
of signify, but you never know.  And since Earthly is
new enough that early Earthfiles will end up being
copied and changed for generations, like Makefiles,
I might as well figure out a generally good way to
do it.


## Making it all work.

So here's the solution I came up with.  First, I'll get the base system set up.
This should be familiar to Docker users.  The `root` user is going to need a copy of the
public key needed to check libbsd, so we'll get that too.

```
# build.earth
FROM debian:stable

# install build dependencies, then clean up system packages
RUN apt-get -y update && \
    apt-get -y install build-essential file make gcc git pkg-config wget && \
    apt-get -y --purge autoremove && \
    apt-get -y clean 

# Fetch the public key for the libbsd release.  This will be needed in
# the build step.
RUN mkdir -m 700 -p /root/keys /root/.gnupg
RUN wget https://www.hadrons.org/~guillem/guillem-4F3E74F436050C10F5696574B972BF3EA4AE57A3.asc -O /root/keys/libbsd.asc

WORKDIR /code
```

Now it's time to get the bundled libbsd.  Instead of running the entire
`make libbsd-download`, we'll just grab the files.  We can apply the
"Don't Repeat Yourself" principle to the URLs, by having the Makefile tell us
what they are, using the `libbsd-print-urls` target.

```
bundle:
  # This target downloads the bundled libbsd.  This should only run again
  # if the Makefile changes.
  RUN mkdir /bundle
  COPY Makefile /bundle

  # The Makefile includes a "libbsd-print-urls" target that prints the 
  # URLs of the libbsd files needed to work with this version of signify.
  RUN (cd /bundle && make BUNDLED_LIBBSD=1 libbsd-print-urls | xargs wget)
  RUN rm /bundle/Makefile

  # Now all that is left in /bundle is copies of the files listed by
  # libbsd-print-urls.
  SAVE IMAGE
```

At this point, we have a container image with the libbsd code and signature
in `/bundle`, and the key needed to check it in `/root/keys`.  Now it's time
to copy in the actual code, and add the libbsd files.

```
code:
  # Copy everything, then copy the libbsd files in.
  FROM +bundle
  COPY --dir . /code
  RUN cp /bundle/* /code
  SAVE IMAGE
```

The `code` target will get re-run any time that anything gets changed.  But it's fast because it's just local copies.

Hooray, time to build.  We'll do a quick `touch` on
the libbsd files so that the helpful and full-featured
Makefile doesn't try to get them again, then make the
executable, make the compressed man page, run the
test suite, and save the artifacts.

```
build:
  FROM +code

  # The modification date on the libbsd source and signature needs to be
  # new enough for the build not to try downloading it again.
  RUN find . -maxdepth 1 -name 'libbsd*' -exec touch '{}' ';' 

  # The build requires a GPG verify, so import the key
  RUN gpg --import /root/keys/libbsd.asc

  # Make the statically linked binary and the compressed man page.
  RUN make BUNDLED_LIBBSD=1 static signify.1.gz

  # Run the regression tests. (Even though signify is already built with
  # bundled libbsd, we need to use BUNDLED_LIBBSD to keep from checking
  # for a system installed copy.)
  RUN make BUNDLED_LIBBSD=1 check

  # Save the static binary and the man page
  SAVE ARTIFACT signify AS LOCAL signify
  SAVE ARTIFACT signify.1.gz AS LOCAL signify.1.gz
```

No need to `SAVE IMAGE` a container image at this point, because I just need the two artifacts.

And it's all done.

Right now Earthly is pretty new, so most
of the discussion is happening on the
[GitHub page](https://github.com/earthly).

There is also a [Gitter
channel](https://gitter.im/earthly-room/community)
for user questions.

The project is responsive to issues
and suggestions&mdash;they implemented [my
suggestion](https://github.com/earthly/earthly/issues/116)
to move the cache out of `/tmp`
and into what I think should be the
[FHS](https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html)-compliant
place for it.  Watch the
[Examples](https://docs.earthly.dev/examples) on
their docs site for more sample builds.

<hr>

This article and modified versions of this article
may be copied and redistributed under the same terms
as Earthly.

This article and modified versions of
this article may be copied and redistributed under
the same terms as Signify.

Markdown source for this article: [signify/README-earthly.md at earth-wip · dmarti/signify](https://github.com/dmarti/signify/blob/earth-wip/README-earthly.md)

