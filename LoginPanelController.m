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
   31 Milk Street #960789 Boston, MA 02196 USA.

   You can reach me at:
   Gregory Casamento, 14218 Oxford Drive, Laurel, MD 20707, 
   USA
*/

#import "LoginPanelController.h"
#import "Authenticator.h"
#import "XServerManager.h"
#include <sys/stat.h>
#include <sys/wait.h>
#include <unistd.h>
#include <grp.h>
#include <errno.h>
#include <signal.h>
#include <string.h>
#include <stdlib.h>
#include <X11/Xlib.h>

static volatile sig_atomic_t quittingSignal = 0;

static void
catchQuittingSignal(int sig)
{
  quittingSignal = sig;
}

@interface LoginPanelController (SessionManagement)

- (void)pollSession: (NSTimer *)timer;
- (void)setUserDisplayAccess: (BOOL)allowed;
- (void)sessionFailed;

@end

@implementation LoginPanelController

- (id)init
{
  self = [super init];
  if (self != nil)
    {
      authenticator = [[Authenticator alloc] init];
      defaults = [NSUserDefaults standardUserDefaults];
    }
  return self;
}

- (void)dealloc
{
  [sessionTimer invalidate];
  DESTROY(sessionTimer);
  DESTROY(authenticator);
  DESTROY(nextAttempt);
  DESTROY(statusField);
  DEALLOC;
}

- (void)applicationDidFinishLaunching: (NSNotification *)notification
{
  [self initializeInterface];
  signal(SIGQUIT, catchQuittingSignal);
  signal(SIGINT, catchQuittingSignal);
  signal(SIGHUP, catchQuittingSignal);
  signal(SIGTERM, catchQuittingSignal);
  sessionTimer = RETAIN([NSTimer scheduledTimerWithTimeInterval: 0.25
    target: self selector: @selector(pollSession:) userInfo: nil repeats: YES]);
  [[NSRunLoop currentRunLoop] addTimer: sessionTimer forMode: NSModalPanelRunLoopMode];
  [[NSRunLoop currentRunLoop] addTimer: sessionTimer forMode: NSEventTrackingRunLoopMode];
}

- (void)applicationWillTerminate: (NSNotification *)notification
{
  if (sessionPID > 0)
    {
      [self killProcessGroup: sessionPID];
      while (waitpid(sessionPID, NULL, 0) < 0 && errno == EINTR)
        ;
      sessionPID = 0;
    }
  [self setUserDisplayAccess: NO];
  [authenticator closeSession];
  [[XServerManager sharedXServerManager] stopXServer];
}

- (void)initializeInterface
{
  [statusField setStringValue: @"Enter your name and password."];
  [window restore];
  [window makeKeyAndOrderFront: self];
  [window makeFirstResponder: usernameField];
}

- (void)passwordEntered: (id)sender
{
  if (sessionPID > 0 || (nextAttempt != nil && [nextAttempt timeIntervalSinceNow] > 0))
    return;
  [statusField setStringValue: @"Checking login…"];
  [statusField display];
  [authenticator setUsername: [usernameField stringValue]];
  [authenticator setPassword: [passwordField stringValue]];
  if ([authenticator isPasswordCorrect])
    {
      [self logUserIn];
    }
  else
    {
      ASSIGN(nextAttempt, [NSDate dateWithTimeIntervalSinceNow: 2]);
      [self rejectEntries];
    }
  [authenticator setPassword: nil];
  [passwordField setStringValue: @""];
}

- (void)powerButton: (id)sender
{
  if (sessionPID > 0 || geteuid() != 0)
    return;
  if (NSRunAlertPanel(@"Shut Down", @"Shut down this computer?",
                      @"Cancel", @"Shut Down", nil) == NSAlertAlternateReturn)
    {
      if (system("/sbin/shutdown -h now") != 0)
        NSRunAlertPanel(@"Shut Down", @"The computer could not shut down.", @"OK", nil, nil);
    }
}

- (void)restartButton: (id)sender
{
  if (sessionPID > 0 || geteuid() != 0)
    return;
  if (NSRunAlertPanel(@"Restart", @"Restart this computer?",
                      @"Cancel", @"Restart", nil) == NSAlertAlternateReturn)
    {
      if (system("/sbin/reboot") != 0)
        NSRunAlertPanel(@"Restart", @"The computer could not restart.", @"OK", nil, nil);
    }
}

- (void)usernameEntered: (id)sender
{
  if ([[usernameField stringValue] length] > 0)
    [window makeFirstResponder: passwordField];
  else
    [self rejectEntries];
}

- (void)awakeFromNib
{
  NSButton *loginButton;
  [NSApp setDelegate: self];
  [passwordField setBackgroundColor: [NSColor textBackgroundColor]];
  [passwordField setTextColor: [NSColor textColor]];
  [passwordField setDrawsBackground: YES];
  [usernameField setTarget: self];
  [usernameField setAction: @selector(usernameEntered:)];
  [passwordField setTarget: self];
  [passwordField setAction: @selector(passwordEntered:)];
  loginButton = [[NSButton alloc] initWithFrame: NSMakeRect(20, 16, 100, 30)];
  [loginButton setTitle: @"Log In"];
  [loginButton setTarget: self];
  [loginButton setAction: @selector(passwordEntered:)];
  [[window contentView] addSubview: loginButton];
  RELEASE(loginButton);
  statusField = [[NSTextField alloc] initWithFrame: NSMakeRect(20, 63, 420, 18)];
  [statusField setEditable: NO];
  [statusField setSelectable: NO];
  [statusField setBordered: NO];
  [statusField setBezeled: NO];
  [statusField setTextColor: [NSColor blackColor]];
  [statusField setDrawsBackground: NO];
  [statusField setFont: [NSFont systemFontOfSize: 11]];
  [[window contentView] addSubview: statusField];
  [window setReleasedWhenClosed: NO];
  [window initializeInterface];
  [usernameField setNextKeyView: passwordField];
  [passwordField setNextKeyView: usernameField];
}

- (void)rejectEntries
{
  [passwordField setStringValue: @""];
  [statusField setStringValue: @"Incorrect username or password. Please try again."];
  NSBeep();
  [window waggle];
  [window makeFirstResponder: passwordField];
}

- (void)sessionFailed
{
  [self initializeInterface];
  NSRunAlertPanel(@"Login Failed",
    @"The desktop session could not start. Check the session script and system login configuration.",
    @"OK", nil, nil);
}

- (void)logUserIn
{
  if (![authenticator openSession])
    {
      [authenticator closeSession];
      [self sessionFailed];
      return;
    }
  [self setUserDisplayAccess: YES];
  [self startSession];
  if (sessionPID > 0)
    {
      [window orderOut: self];
      [usernameField setStringValue: @""];
      [passwordField setStringValue: @""];
    }
  else
    {
      [self setUserDisplayAccess: NO];
      [authenticator closeSession];
      [self sessionFailed];
    }
}

- (void)startSession
{
  struct passwd *pw = [authenticator getPasswordEntity];
  if (pw == NULL)
    return;
  sessionPID = fork();
  if (sessionPID == 0)
    {
      extern char **environ;
      char *display = strdup(getenv("DISPLAY") != NULL ? getenv("DISPLAY") : "");
      char script[4096];
      const char *systemScripts[] = { "/etc/X11/Xsession", "/etc/X11/xinit/xinitrc",
                                     "/etc/X11/xdm/Xsession", NULL };
      int i;
      struct stat info;

      if (display == NULL || setsid() < 0)
        _exit(125);
      signal(SIGQUIT, SIG_DFL);
      signal(SIGINT, SIG_DFL);
      signal(SIGHUP, SIG_DFL);
      signal(SIGTERM, SIG_DFL);
      umask(022);
      /* Never pass the privileged greeter's environment to a desktop. */
      environ = NULL;
      [authenticator setEnvironment];
      if (setenv("DISPLAY", display, 1) != 0
          || setenv("HOME", pw->pw_dir, 1) != 0
          || setenv("USER", pw->pw_name, 1) != 0
          || setenv("LOGNAME", pw->pw_name, 1) != 0
          || setenv("SHELL", pw->pw_shell[0] ? pw->pw_shell : "/bin/sh", 1) != 0
          || setenv("PATH", "/usr/GNUstep/System/Tools:/usr/GNUstep/Local/Tools:/usr/local/bin:/usr/bin:/bin", 1) != 0)
        _exit(125);
      free(display);
      if (geteuid() == 0)
        {
          if (initgroups(pw->pw_name, pw->pw_gid) != 0
              || setgid(pw->pw_gid) != 0 || setuid(pw->pw_uid) != 0)
            _exit(125);
        }
      if (getuid() != pw->pw_uid || geteuid() != pw->pw_uid
          || getgid() != pw->pw_gid || chdir(pw->pw_dir) != 0)
        _exit(125);
      /* Access user-owned scripts only after dropping privileges. */
      snprintf(script, sizeof(script), "%s/.xsession", pw->pw_dir);
      if (stat(script, &info) != 0 || !S_ISREG(info.st_mode) || access(script, R_OK) != 0)
        snprintf(script, sizeof(script), "%s/.xinitrc", pw->pw_dir);
      for (i = 0; stat(script, &info) != 0 || !S_ISREG(info.st_mode)
           || access(script, R_OK) != 0; i++)
        {
          if (systemScripts[i] == NULL)
            _exit(125);
          snprintf(script, sizeof(script), "%s", systemScripts[i]);
        }
      /* Do not leak the greeter's X or other privileged connections. */
      {
        long limit = sysconf(_SC_OPEN_MAX);
        int descriptor;
        if (limit < 0)
          limit = 1024;
        for (descriptor = 3; descriptor < limit; descriptor++)
          close(descriptor);
      }
      execl("/bin/sh", "sh", script, (char *)NULL);
      _exit(125);
    }
}

- (void)pollSession: (NSTimer *)timer
{
  int status;
  pid_t result;
  if (quittingSignal != 0)
    {
      [NSApp terminate: self];
      return;
    }
  if (sessionPID <= 0)
    return;
  result = waitpid(sessionPID, &status, WNOHANG);
  if (result == 0 || (result < 0 && errno == EINTR))
    return;
  [self killProcessGroup: sessionPID];
  sessionPID = 0;
  [self setUserDisplayAccess: NO];
  [authenticator closeSession];
  [self initializeInterface];
  if (result < 0 || !WIFEXITED(status) || WEXITSTATUS(status) != 0)
    [self sessionFailed];
}

- (void)killProcessGroup: (pid_t)pid
{
  if (pid <= 1 || pid == getpgrp())
    return;
  kill(-pid, SIGTERM);
  kill(-pid, SIGKILL);
}

- (void)killXClients
{
  /* Cleanup is restricted to the session process group.  A display may
     contain other users' clients, including the greeter itself. */
  if (sessionPID > 0)
    [self killProcessGroup: sessionPID];
}

- (void)setUserDisplayAccess: (BOOL)allowed
{
  Display *display;
  XServerInterpretedAddress address;
  XHostAddress host;
  if (!allowed && !xAccessGranted)
    return;
  display = XOpenDisplay(NULL);
  if (display == NULL)
    return;
  address.type = "localuser";
  address.typelength = strlen(address.type);
  address.value = (char *)[[authenticator username] UTF8String];
  address.valuelength = strlen(address.value);
  host.family = FamilyServerInterpreted;
  host.address = (char *)&address;
  host.length = sizeof(address);
  if (allowed)
    {
      XHostAddress *hosts;
      int count, i;
      Bool enabled;
      hosts = XListHosts(display, &count, &enabled);
      for (i = 0; i < count; i++)
        {
          if (hosts[i].family == FamilyServerInterpreted)
            {
              XServerInterpretedAddress *existing = (void *)hosts[i].address;
              if (existing->typelength == address.typelength
                  && existing->valuelength == address.valuelength
                  && memcmp(existing->type, address.type, address.typelength) == 0
                  && memcmp(existing->value, address.value, address.valuelength) == 0)
                break;
            }
        }
      if (i == count)
        {
          XAddHost(display, &host);
          xAccessGranted = YES;
        }
      if (hosts != NULL)
        XFree(hosts);
    }
  else
    {
      XRemoveHost(display, &host);
      xAccessGranted = NO;
    }
  XSync(display, False);
  XCloseDisplay(display);
}

- (void)showInfo: (id)sender
{
  if (infoPanel == nil)
    [NSBundle loadNibNamed: @"InfoPanel" owner: self];
  [infoPanel makeKeyAndOrderFront: self];
}

@end
