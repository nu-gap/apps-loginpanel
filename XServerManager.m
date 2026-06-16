/* 
   XServerManager.m

   Copyright (C) 2013 Sebastian Reitenbach

   Author:  Sebastian Reitenbach <sebastia@l00-bugdead-prods.de>
   Date: 2013
   
   This file is part of GNUstep Application Project.

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
   31 Milk Street #960789 Boston, MA 02196 USA.

*/

#import "XServerManager.h"

#include <sys/types.h>
#include <sys/wait.h>
#include <unistd.h>
#include <signal.h>
#include <errno.h>
#include <string.h>

#if defined(_POSIX_SOURCE) || defined(SYSV) || defined(SVR4)
# define killpg(pgrp, sig) kill(-(pgrp), sig)
#endif

@implementation XServerManager

+ (id) sharedXServerManager
{
  static XServerManager *_sharedXServerManager = nil;

  if (! _sharedXServerManager)
    {
      _sharedXServerManager = [[XServerManager
			allocWithZone: [self zone]] init];
    }

  return _sharedXServerManager;
}

- (id) init
{
  self = [super init];

  if (self)
    {
      serverPID = 0;
      Dpy = NULL;
      displayName = [@DEFAULT_DISPLAY copy];
    }

  return self;
}

-(pid_t) serverPID
{
  return serverPID;
}

-(void) setServerPID:(pid_t)pid
{
  serverPID = pid;
}

-(NSString *) displayName
{
  return displayName;
}

-(void) setDisplayName:(NSString *)name
{
  if (name == nil || [name length] == 0)
    return;

  ASSIGN(displayName, name);
}

-(BOOL) hasUsableDisplay
{
  Display *display;

  display = XOpenDisplay(NULL);
  if (display == NULL)
    display = XOpenDisplay([displayName cString]);

  if (display == NULL)
    return NO;

  XCloseDisplay(display);
  return YES;
}

-(BOOL) startXServer
{
  char *xServer[] = DEFAULT_XSERVER;
  xServer[1] = (char *)[displayName cString];

  if ([self hasUsableDisplay])
    return YES;

  setenv("DISPLAY", [displayName cString], 1);
  serverPID = fork();

  if (serverPID == -1)
    return NO;

  if (serverPID == 0)
    {
      setpgid(0, 0);
      NSLog(@"spawning X Server: %s", xServer[0]);
      execvp(xServer[0], xServer);
      NSLog(@"failed to spawn X Server %s: %s", xServer[0], strerror(errno));
      _exit(127);
    }

  NSLog(@"loginpanel waiting for X Server");

  return [self waitForServer];
}

-(BOOL) stopXServer
{
  int counter;
  int sig = SIGTERM;
  BOOL result = NO;

  // ignore signals
  signal(SIGQUIT, SIG_IGN);
  signal(SIGINT, SIG_IGN);
  signal(SIGHUP, SIG_IGN);
  signal(SIGPIPE, SIG_IGN);
  signal(SIGTERM, SIG_DFL);
  signal(SIGKILL, SIG_DFL);
  signal(SIGALRM, SIG_DFL);

  if (serverPID <= 0)
    return YES;

  if (Dpy != NULL)
    {
      XCloseDisplay(Dpy);
      Dpy = NULL;
    }

  for (counter = 0;counter < 4;counter++)
    {
      if (killpg (serverPID, sig) == -1)
        {
          switch (errno)
	    {
	      case ESRCH:
	        NSLog(@"no process found in pgrp %d", serverPID);
	        result = YES;
	        break;
	      case EINVAL:
	        NSLog(@"we tried to murder with an invalid signal");
	        break;
	      case EPERM:
	        NSLog(@"we did not murder our children strong enough");
	        break;
	      default:
	        NSLog(@"error while terminating child");
	    }
	  sig = SIGKILL;
	  if (result)
	    break;
	  [self serverTimeout:3 showMessage:"waiting for server to die"];
        }
      else
	{
	  if (![self serverTimeout:3 showMessage:"waiting for server to die"])
	    {
	      result = YES;
	      break;
	    }
	  sig = SIGKILL;
	}
    }
  return result;
}

- (BOOL) waitForServer
{
  int     ncycles = 120;
  int     cycles;

  for (cycles = 0; cycles < ncycles; cycles++)
    {
       if((Dpy = XOpenDisplay([displayName cString])))
              return YES;
       if(![self serverTimeout:1 showMessage:"X server ready"])
              break;
     }
     NSLog(@"failure while waiting for X server to start");

    return NO;
}

- (BOOL) serverTimeout:(int)timeout showMessage:(char *)text
{
  int        i = 0;
  int pidfound = -1;
  static char *lasttext;

    for(;;)
      {
         pidfound = waitpid(serverPID, NULL, WNOHANG);
         if (pidfound == serverPID)
              break;
         if (pidfound == -1 && errno == ECHILD)
              break;
         if (timeout)
           {
             if (i == 0 && text != lasttext)
                NSLog(@"waiting for %s", text);
             else
                NSLog(@".");
           }
         if (timeout)
           sleep(1);
         if (++i > timeout)
           break;
       }
    if (i > 0)
      NSLog(@"\n");

    lasttext = text;
    return !(pidfound == serverPID || (pidfound == -1 && errno == ECHILD));
}

@end
