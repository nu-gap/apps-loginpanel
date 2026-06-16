# loginpanel

Loginpanel.app is a graphical login manager for GNUstep systems.  It is
intended to serve the same role as xdm, gdm, or other display managers: start
or attach to an X display, present a greeter, authenticate a local user, start
the user's X session, clean up clients after logout, and return to the greeter.

The build also produces loginpaneld, a small supervisor suitable for launching
from init or a system service.  The supervisor restarts loginpanel if the
greeter exits unexpectedly.

## System Requirements:

Linux, gscrypt, GNUstep

to use PAM for authentication, run make like:
make have-pam=yes

## Runtime:

Run loginpaneld from the system service responsible for the graphical login.
When DISPLAY is already set and usable, loginpanel attaches to it.  When no
display is available, loginpanel starts an X server on :0 by default and sets
DISPLAY for the greeter and user sessions.

Set LOGINPANEL_DISPLAY to choose another display number, for example:

LOGINPANEL_DISPLAY=:1 loginpaneld

The default X server command is compiled from DEFAULT_XSERVER in
XServerManager.h and can be overridden at build time if a system needs a
different server path or arguments.


## Change History
06/2026

Update loginpaneld so that it keeps respawning the
loginpanel once the user logs out.  Fix how loginpanel
interfaces with X to create a session.

11/2000

NSTextField commited to repository.  I need to wait
for further updates in the NSLayoutManager/
GSSimpleLayoutManager code before I can add the 
echoes bullets feature, but it works for now.

The only thing which needs to be done to make
the application of practical use is to find a 
way to install it so that it will work prior to
anyone being logged in to the machine.

10/2000

I am making some progress on the fixes for 
NSSecureTextField.  I believe I should have it 
working sometime soon.

8/2000

The application is getting closer and closer
to completion.  Authentication using PAM now works
under GNUstep on Linux.   It seems as though the
only real obstacle to getting it working completely
is the fact that NSSecureTextField doesn't work.

3/2000

This application is not ready for primetime yet.
It is mostly experimental at this stage.  The
reason I am releasing it now is to let those who
are interested play with it.

It seems to work under OPENSTEP4.2/Mach, at the
moment.  It does everything I expect it too.
It seems to only partially work under GNUstep.
I believe this has something to do with how
the gmodel file is being translated.

Gregory Casamento
