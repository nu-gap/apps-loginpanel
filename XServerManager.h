/* 
   XServerManager.h

   Copyright (C) 2013 Sebastian Reitenbach

   Author:  Sebastian Reitenbach <sebastia@l00-bugdead-prods.de>
   Date: 2013
   
   This file is part of the GNUstep Application Project.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
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

#import <AppKit/AppKit.h>

#include <X11/Xlib.h>

#ifndef DEFAULT_XSERVER
#define DEFAULT_XSERVER {"X", ":0", "-nolisten", "tcp", NULL}
#endif

#ifndef DEFAULT_DISPLAY
#define DEFAULT_DISPLAY ":0"
#endif

@interface XServerManager : NSObject
{
  pid_t serverPID;
  Display *Dpy;
  NSString *displayName;
}

// Initialization Methods
+ (id) sharedXServerManager;

// Accessors
-(pid_t) serverPID;
-(void) setServerPID:(pid_t)pid;
-(NSString *) displayName;
-(void) setDisplayName:(NSString *)name;

// start and stop the server
-(BOOL) hasUsableDisplay;
-(BOOL) startXServer;
-(BOOL) stopXServer;
-(BOOL) waitForServer;
- (BOOL) serverTimeout:(int)timeout showMessage:(char *)text;

@end
