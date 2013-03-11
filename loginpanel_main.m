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
   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

   You can reach me at:
   Gregory Casamento, 14218 Oxford Drive, Laurel, MD 20707, 
   USA
*/

#include <unistd.h>

#import <AppKit/AppKit.h>


int startXServer() {
  int serverPid;
  char *serverArgs[] = { "X", NULL };


  printf("server: %s\n", serverArgs[0]);

  serverPid = vfork();
  if (serverPid == -1)
    return -1;

  if (serverPid == 0)
    {
      printf("child execv'ing\n");
      execv("/usr/bin/X", serverArgs);
    }

  printf("father waitingi\n");
  sleep(2); 
  return serverPid;
}

int main(int argc, const char *argv[]) {
   printf("starting...\n");
   startXServer();
   printf("started...\n");
   return NSApplicationMain(argc, argv);
}
