/* 
   Authenticator.m

   Class to allow loginpanel to authenticate users

   Copyright (C) 2000 Free Software Foundation, Inc.

   Author:  Gregory John Casamento <borgheron@yahoo.com>
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
*/

/* Authenticator.m created by me on Wed 17-Nov-1999 */

#import "Authenticator.h"

#if defined(GNUSTEP)
#import <security/pam_appl.h>
#endif

@implementation Authenticator
// Initialization methods
- init
{
  [super init];
  username = nil;
  password = nil;
  
  return self;
}

- initWithUsername: (NSString *)user
          password: (NSString *)pass
{
  [self init];
  username = [user copy];
  password = [pass copy];
  return self;
}

// Accessor methods
- (void)setUsername: (NSString *)user
{
  username = user;
}

- (void)setPassword: (NSString *)pass
{
  password = pass;
}

- (NSString *)username
{
  return username;
}

- (NSString *)password
{
  return password;
}

// Action methods. 
- (BOOL)isPasswordCorrect
{
  BOOL result = NO;

#if defined(GNUSTEP)
#endif

  return result;
}

- (void)setEnvironment
{
#ifndef GNUSTEP  
  /* Set environment */
  environ = malloc(sizeof(char*) * 2);
  environ[0] = 0;
#else
#endif

  chdir(pw->pw_dir);
}

- (void)startSession
{
#ifndef DEBUG
  // Set user and group ids
  if ((initgroups(pw->pw_name, pw->pw_gid) != 0) 
      || (setgid(pw->pw_gid) != 0) 
      || (setuid(pw->pw_uid) != 0)) 
    {
      NSLog(@"Could not switch to user id %@.", username);
      exit(0);
    }
#endif
}
@end
