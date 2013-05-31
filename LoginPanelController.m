/* 
   LoginPanelController.m

   Controller class which handles all activity in the loginpanel.

   Copyright (C) 2000 Gregory John Casamento
                 2013 Riccardo Mottola

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2000
   
   This file is part of GNUstep.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.
   
   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public
   License along with this library; see the file COPYING.LIB.
   If not, write to the Free Software Foundation,
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

   You can reach me at:
   Gregory Casamento, 14218 Oxford Drive, Laurel, MD 20707, 
   USA
*/

#import "LoginPanelController.h"
#import "LoginImageView.h"
#import "Authenticator.h"
#import "XServerManager.h"

#ifdef HAVE_PAM
#include <gscrypt/GSPam.h>
#endif

/* for stat() */
#include <sys/stat.h>
#include <fcntl.h>

#include <sys/wait.h>
#include <sys/types.h>
#include <unistd.h>
#include <grp.h> /* initgroups () */

#include <X11/Xlib.h>
#include <X11/Xatom.h>

/* Signal Handlers */
void catchQuittingSignal(int sig)
{
  NSLog(@"catchQuittingSignal: %d", sig);
  //  [self handleQuittingSignal: sig];
  exit(0);
}

@implementation LoginPanelController
- (id)init
{
  // Initialize the superclass.
  [super init];

  // Laziness is a terrible thing.... I am making the loginpanel
  // application pretend as though it is xdm so that I don't
  // have to write my own .conf file for PAM.   I will get around
  // to writing it once I get this working.
#ifdef HAVE_PAM
  authenticator = [[GSPam alloc] initWithServiceName: @"xdm"];
#else
  authenticator = [[Authenticator alloc] init];
#endif
  defaults = [NSUserDefaults standardUserDefaults];

  return self;
}

- (void)applicationDidFinishLaunching: (NSNotification *)notification
{
  NSPoint origin;

  NSLog(@"LoginPanelController: applicationDidFinishLaunching");
  [self initializeInterface];

  // Eliminate the application icon!!
  origin.x = -1000;
  origin.y = -1000;
  [[NSApp iconWindow] setFrameOrigin: origin];

  signal(SIGQUIT, catchQuittingSignal);
  signal(SIGKILL, catchQuittingSignal);
  signal(SIGHUP, catchQuittingSignal);
  signal(SIGTERM, catchQuittingSignal);
}

- (void)initializeInterface
{
  [window restore]; 
  [window makeKeyAndOrderFront: self];
}

- (void)passwordEntered:(id)sender
{
  char *pwstring = 0;
#ifdef HAVE_PAM
  BOOL verified = NO;
#endif
  
  pwstring = (char *)[[passwordField stringValue] cString];
#ifdef DEBUG 
  printf("Verifying login...\n");
#endif

#if 0 /* no pam working yet */
  if(![authenticator start]) 
    {
      NSLog(@"Failed to start PAM");
    }
#endif

  [authenticator setUsername: [usernameField stringValue]];
  [authenticator setPassword: [passwordField stringValue]];

#ifdef HAVE_PAM
//  verified = [authenticator authenticateWithFlag: PAM_DISALLOW_NULL_AUTHTOK
			    silent: NO];
#endif

  
  if( [authenticator isPasswordCorrect] == YES )
    {
      [self logUserIn];
    }
  else
    {
      [self rejectEntries];
    }

#ifdef HAVE_PAM
  if(![authenticator end]) 
    {
      NSLog(@"Failed to end PAM");
    }
#endif
}

- (void)powerButton:(id)sender
{
#ifdef DEBUG
  puts("Powering down...");
#endif
#ifdef __linux__
  if(system("/sbin/shutdown -g0")) NSLog(@"Problem shutting down");
#else
  if(system("/sbin/halt -p")) NSLog(@"Problem shutting down");
#endif
}

- (void)restartButton:(id)sender
{
#ifdef DEBUG
  puts("Restarting computer...");
#endif
  if(system("/sbin/reboot")) NSLog(@"Problem rebooting system");
}

- (void)usernameEntered:(id)sender
{
#ifdef DEBUG
  printf("Username: %s\n", [[usernameField stringValue] cString]);
#endif
  if( ![[usernameField stringValue] isEqualToString: [NSString string]] )
    {
      [passwordField becomeFirstResponder];
    }
  else
    {
#ifdef DEBUG
      puts("Null usernames are illegal...");
#endif
      [self rejectEntries];
    }
}

- (void)awakeFromNib
{
  puts("The sleeper has awakened -- awakeFromNib");
  if(window == nil) NSLog(@"Window is nil!");
  else NSLog(@"The window = %@",window);
  [window initializeInterface];
  [window waggle];
}

- (void)rejectEntries
{
  [usernameField setStringValue: @""];
  [passwordField setStringValue: @""];
  [window waggle];
  [usernameField becomeFirstResponder];
}

- (void)logUserIn
{
  [window shrink];
  [usernameField setStringValue: @""];
  [passwordField setStringValue: @""];


#ifdef HAVE_PAM
  [authenticator openSessionSilently: NO];  // We will spend a great deal of time here!!
#endif

#ifndef HAVE_PAM
  [self startSession];
#endif
  NSLog(@"resetting itself");
  [self initializeInterface];
}

- (void)startSession
{
  int clientPid;
  pid_t pid;
  struct passwd *pw;
  
  pw = [authenticator getPasswordEntity];

  /* fork ourselves before downgrade... */
  clientPid = 0;
  clientPid = fork();
  if(clientPid == 0)
    {
      int retValue;
      char sessioncmd[MAXPATHLEN];
      struct stat stBuff;

      if (setsid() == -1)
        {
	  perror("Error in setsid: ");
	}
      setlogin(pw->pw_name);

      setpgid(clientPid, clientPid);
      NSLog(@"group process id: %d", getpgid(clientPid));

      unsetenv("GNUSTEP_USER_ROOT");
      unsetenv("MAIL");
      if(setenv("USER", pw->pw_name, YES) < 0)
	NSLog(@"error setting USER %s", pw->pw_name);
      if(setenv("LOGNAME", pw->pw_name, YES) < 0)
	NSLog(@"error setting LOGNAME %s", pw->pw_name);
      NSLog(@"user dir: %s", pw->pw_dir);
      /* change home directory */
      if(setenv("HOME", pw->pw_dir, YES) < 0)
      {
        NSLog(@"%d could not switch HOME to %s", errno, pw->pw_dir);
      }
      /* change current directory */
      chdir(pw->pw_dir);
      // Set user and group ids
      if ((initgroups(pw->pw_name, pw->pw_gid) != 0) 
	  || (setgid(pw->pw_gid) != 0) 
	  || (setuid(pw->pw_uid) != 0)) 
	{
	  NSLog(@"Could not switch to user id %@.", [authenticator username]);
	  exit(0);
	}
      // try to find an appropriate script to be run after login
      // FIXME - RM : this code should all be rewriten using NS* classes !!!
      snprintf(sessioncmd, sizeof(sessioncmd), "%s/.xsession", pw->pw_dir);
      printf("trying: %s\n", sessioncmd);
      if (stat(sessioncmd, &stBuff) != 0)
        snprintf(sessioncmd, sizeof(sessioncmd), "%s/.xinitrc", pw->pw_dir);
      printf("trying: %s\n", sessioncmd);
      if (stat(sessioncmd, &stBuff) != 0)
        snprintf(sessioncmd, sizeof(sessioncmd), "/etc/X11/xinit/xinitrc");
      printf("trying: %s\n", sessioncmd);
      if (stat(sessioncmd, &stBuff) != 0)
        snprintf(sessioncmd, sizeof(sessioncmd), "/etc/X11/xdm/Xsession");
      printf("trying: %s\n", sessioncmd);
      if (stat(sessioncmd, &stBuff) == 0)
	{
	  printf("Using session: %s", sessioncmd);
	  retValue = execl("/bin/sh", "sh", sessioncmd, (char *)NULL);
	}
      else
	{
	  printf ("Lost all hope, no session script found.\n");
	  exit(-1);
	}

      if (retValue < 0)
      {
        NSLog(@"an error in the child occoured : %d", errno);
        perror("exec");
        exit(-1);
      }
    }
  NSLog(@"client PID: %d", clientPid);
  pid = wait(0);
  while (pid != clientPid)
    {
       NSLog(@"group PID: %d", pid);
       pid = wait(0);
    }
  NSLog(@"finally %d = %d", clientPid, pid);

  [self killXClients];
  [self killProcessGroup:pid];
}

- (void)killProcessGroup:(pid_t)pid
{
  NSLog(@"sending term to %i", pid);
  if (killpg (pid, SIGTERM) == -1)
    { 	 
      switch (errno) 	 
        { 	 
        case ESRCH: 	 
          NSLog(@"no process found in pgrp %d", pid); 	 
          break; 	 
        case EINVAL: 	 
          NSLog(@"we tried to murder with an invalid signal"); 	 
          break; 	 
        case EPERM: 	 
          NSLog(@"we did not murder our children strong enough"); 	 
          break; 	 
        default: 	 
          NSLog(@"error while sig-terming child"); 	 
	  	 
        } 	 
    } 	 
  NSLog(@" client did not term..., sending kill"); 	 
  if (killpg (pid, SIGKILL) == -1) 	 
    { 	 
      switch (errno) 	 
        { 	 
        case ESRCH: 	 
          break; 	 
        case EINVAL: 	 
          NSLog(@"we tried to murder with an invalid signal"); 	 
          break; 	 
        case EPERM: 	 
          NSLog(@"we did not murder our children strong enough"); 	 
          break; 	 
        default: 	 
          NSLog(@"Unknown error: %d", errno); 	 
        } 	 
    }
}

- (void)killXClients
{
  Display *disp;
  Window rootWin;
  Window parentWin;
  Window *childrenOfRoot;
  unsigned int numOfChildren;
  unsigned int i;
  Atom atom_NET_WM_PID;

  /* Can we cant it from GNUstep ? */
  disp = XOpenDisplay(NULL);
  if (disp)
    NSLog(@"Got display");

  rootWin = XDefaultRootWindow(disp);

  XQueryTree(disp, rootWin, &rootWin, &parentWin, &childrenOfRoot, &numOfChildren);
  /*
  if(1)
    {
      for(i = 0; i < numOfChildren; i++)
        {
          if(XGetWindowAttributes(disp, childrenOfWin[i], &attr) 
             && (attr.map_state == IsViewable))
            childrenOfWin[i] = XmuClientWindow(disp, childrenOfWin[i]);
          else
            childrenOfWin[i] = 0;
        }
    }
  */
  
  atom_NET_WM_PID = XInternAtom(disp, "_NET_WM_PID", true);
  if (atom_NET_WM_PID == None)
    {
      NSLog(@"XInternAtom failure for _NET_WM_PID");
      return;
    }

  for(i = 0; i < numOfChildren; i++)
    {
      Window wind;
      XWindowAttributes attr;
      int format;
      unsigned long nItems;
      unsigned long bytesAfter;
      unsigned char *props;
      pid_t clientPID;
      Atom atomType;

      wind = childrenOfRoot[i];

      XGetWindowProperty(disp, wind, atom_NET_WM_PID, 0, 1, False, AnyPropertyType, &atomType, &format, &nItems, &bytesAfter, &props);

      clientPID = 0;
      if (props)
        {
          NSLog(@"We got some PID");
          clientPID = (pid_t)*((unsigned long *)props);
          XFree(props);
        }

      NSLog(@"Process ID: %ld", (long int)clientPID);
      if(XGetWindowAttributes(disp, wind, &attr))
        {
          char *winName;

          XFetchName(disp, wind, &winName);
          
          
          if (attr.map_state == IsViewable)
            {
              NSLog(@"killing %u, %s", i, winName);
              XKillClient(disp, childrenOfRoot[i]);
            }
          else
            {
              NSLog(@"hidden:  %u, %s", i, winName);
            }
          XFree(winName);
        }
      
    }

  XFree((char *)childrenOfRoot);
}

- (void)showInfo: (id)sender
{
  // load info panel
  if( infoPanel == nil )
    {
      if( ![NSBundle loadNibNamed: @"InfoPanel"
		     owner: self])
	{
	  NSLog(@"Problem loading info panel...");
	}

    }
  [infoPanel makeKeyAndOrderFront: self];
}


- (void) handleQuittingSignal: (int) sig
{
  NSLog(@"somebody is killing me.... %d", sig);
}

@end


