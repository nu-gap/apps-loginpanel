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
   31 Milk Street #960789 Boston, MA 02196 USA.

*/

#include <sys/types.h>
#include <unistd.h>
#include <sys/wait.h>
#include <stdlib.h>
#import <Foundation/Foundation.h>

#include <signal.h>
#include <errno.h>

static volatile sig_atomic_t stopping = 0;
static volatile sig_atomic_t childPID = 0;

static void
stopSupervisor(int signalNumber)
{
  stopping = 1;
  if (childPID > 0)
    kill(childPID, signalNumber);
}

int
main(int argc, const char *argv[])
{
  char **arguments;
  int arg;
  pid_t result;
  sigset_t signals, previous;
  struct sigaction action;

  arguments = calloc(argc + 4, sizeof(char *));
  if (arguments == NULL)
    return 1;
  arguments[0] = "loginpanel";
  arguments[1] = "-GSX11HandlesWindowDecorations";
  arguments[2] = "NO";
  for (arg = 1; arg < argc; arg++)
    arguments[arg + 2] = (char *)argv[arg];
  sigemptyset(&signals);
  sigaddset(&signals, SIGTERM);
  sigaddset(&signals, SIGINT);
  sigaddset(&signals, SIGHUP);
  memset(&action, 0, sizeof(action));
  action.sa_handler = stopSupervisor;
  sigemptyset(&action.sa_mask);
  sigaction(SIGTERM, &action, NULL);
  sigaction(SIGINT, &action, NULL);
  sigaction(SIGHUP, &action, NULL);
  while (!stopping)
    {
      sigprocmask(SIG_BLOCK, &signals, &previous);
      childPID = fork();
      if (childPID == 0)
        {
          signal(SIGTERM, SIG_DFL);
          signal(SIGINT, SIG_DFL);
          signal(SIGHUP, SIG_DFL);
          sigprocmask(SIG_SETMASK, &previous, NULL);
          execvp(arguments[0], arguments);
          _exit(127);
        }
      sigprocmask(SIG_SETMASK, &previous, NULL);
      if (childPID > 0)
        {
          do
            result = waitpid(childPID, NULL, 0);
          while (result < 0 && errno == EINTR);
        }
      childPID = 0;
      if (!stopping)
        sleep(1);
    }
  free(arguments);
  return 0;
}

