/* 
   loginpanel application

   main function.

   Copyright (C) 2000-2010 Free Software Foundation

   Author: Gregory John Casamento <greg_casamento@yahoo.com>
           Riccardo Mottola
   
   This file is part of the GNUstep Application Project.

   This program is free software; you can redistribute it and/or
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

   You can reach me at:
   Gregory Casamento, 14218 Oxford Drive, Laurel, MD 20707, 
   USA
*/

#include <unistd.h>
#include <stdlib.h>
#include <string.h>

#import <AppKit/AppKit.h>
#import <XServerManager.h>

int main(int argc, const char *argv[])
{
  NSAutoreleasePool *pool;
  XServerManager *manager;
  char *display;

  pool = [NSAutoreleasePool new];
  manager = [XServerManager sharedXServerManager];
  display = getenv("DISPLAY");

  if (display != NULL && strlen(display) > 0)
    [manager setDisplayName: [NSString stringWithCString: display]];

  if (![manager hasUsableDisplay])
    {
      NSString *loginPanelDisplay;

      loginPanelDisplay = [[[NSProcessInfo processInfo] environment]
        objectForKey: @"LOGINPANEL_DISPLAY"];
      if (loginPanelDisplay != nil)
        [manager setDisplayName: loginPanelDisplay];

      if (![manager startXServer])
        {
          NSLog(@"loginpanel could not start or connect to display %@",
            [manager displayName]);
          [pool release];
          return 1;
        }
    }

  setenv("DISPLAY", [[manager displayName] cString], 1);
  [pool release];

  return NSApplicationMain(argc, argv);
}
