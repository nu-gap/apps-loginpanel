/* 
   LoginPanelController.m

   Controller class which handles all activity in the loginpanel.

   Copyright (C) 2000 Gregory John Casamento

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

#ifdef HAVE_PAM
#import <gscrypt/GSPam.h>
#endif

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

  NSLog(@"");
  [self initialize];

  // Eliminate the application icon!!
  origin.x = -1000;
  origin.y = -1000;
  [[NSApp iconWindow] setFrameOrigin: origin];

  signal(SIGQUIT, catchQuittingSignal);
  signal(SIGKILL, catchQuittingSignal);
  signal(SIGHUP, catchQuittingSignal);
  signal(SIGTERM, catchQuittingSignal);
}

- (void)initialize
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
  [authenticator startSession];
#endif
  NSLog(@"resetting itself");
  [self initialize];
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


