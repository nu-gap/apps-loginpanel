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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

*/

#import <AppKit/AppKit.h>

#ifndef DEFAULT_XSERVER
#define DEFAULT_XSERVER /usr/X11R6/bin/X
#endif

@interface XServerManager : NSObject
{
  pid_t serverPID;
}

// Initialization Methods
+ (id) sharedXServerManager;

// Accessors
-(pid_t) serverPID;
-(void) setServerPID:(pid_t)pid;

// start and stop the server
-(BOOL) startXServer;
-(BOOL) stopXServer;

@end
