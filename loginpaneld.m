/* 
   loginpanel daemon application

   daemon spawning the login panel.

   Copyright (C) 2000-2013 Free Software Foundation

   Author: Sebastian Reitenbach <sebastia@l00-bugdead-prods.de>
   
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

*/

#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>
#import <Foundation/Foundation.h>

int main(int argc, const char *argv[]) {
  char *loginpanel[] = {"loginpanel", NULL};
  pid_t panelPID;

  while (1)
    {
      switch ((panelPID = fork()))
        {
	  case 0:
            execvp(loginpanel[0], loginpanel);
	    break;
	  case -1:
	    break;
	  default:
	    waitpid(panelPID, NULL, NULL);
	}
    }

}
