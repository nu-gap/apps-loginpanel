/* 
   Authenticator.m

   Class to allow loginpanel to authenticate users

   Copyright (C) 2000-2009 GNUstep Application Project

   Author:  Gregory John Casamento <borgheron@yahoo.com>
   Date: 2000
   Author: Riccardo Mottola <rmottola@users.sf.net>
   
   This file is part of loginpanel, GNUstep Application Project

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
#include <security/pam_appl.h>
#endif

/* needed on linux to get crypt from unistd */
#ifdef __linux__
#define _XOPEN_SOURCE
#endif

#include <unistd.h>


@implementation Authenticator
// Initialization methods
- (id)init
{
  [super init];
  NSLog(@"Initing authenticator");
  username = nil;
  password = nil;
#ifdef __linux__
  passwordFilePath = @"/etc/shadow";
#else 
  passwordFilePath = @"/etc/master.passwd";
#endif
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

- (void)_readLine :(FILE *)f :(char *)l
{
    int ch;
    
    ch = fgetc(f);
    while (ch != EOF && ch != '\n')
    {
        *l = ch;
        l++;
        ch = fgetc(f);
    }
    *l = '\0';
}

// Accessor methods
- (void)setUsername: (NSString *)user
{
  username = user;
}

- (void)setPassword: (NSString *)pass
{
  password = pass;
  NSLog(@"Setting password to: %@", password);
}

- (NSString *)username
{
  return username;
}

- (NSString *)password
{
  return password;
}

/** perform the actual password verification */
- (BOOL)isPasswordCorrect
{
  NSLog(@"Verifying... %@", username);
  if(YES)  // we should do this if we have a master password file
    {
      NSString *pwdFileStr;
      NSEnumerator *enu;
      NSArray *usersArray;
      NSString *userLine;
      NSString *userNameWithColon;
      unsigned int userNameLen;
      NSString *cryptedPwdFromFile;

      userNameWithColon = [username stringByAppendingString:@":"];
      userNameLen = [userNameWithColon length];
      NSLog(@"password: %@", password);

      pwdFileStr = [NSString stringWithContentsOfFile:passwordFilePath];
      if ([pwdFileStr length] == 0)
        NSLog(@"Empty password file");
      usersArray = [pwdFileStr componentsSeparatedByString:@"\n"];
      cryptedPwdFromFile = nil;
      enu = [usersArray objectEnumerator];
      while((userLine = [enu nextObject]) && cryptedPwdFromFile == nil)
        {
	  NSLog(@"line %@", userLine);
	  if ([userLine length] > userNameLen)
	    {
	     if ([userLine compare: userNameWithColon options:NSLiteralSearch
	      range:NSMakeRange(0, userNameLen)] == NSOrderedSame)
	        {
		  NSArray *pwdLineArray;
	          NSLog(@"found %@", userLine);
                  pwdLineArray = [userLine componentsSeparatedByString:@":"];
		  cryptedPwdFromFile = [pwdLineArray objectAtIndex:1];
	        }
            }
	}
      if (cryptedPwdFromFile != nil)
	{
	  unsigned int saltEnd;
	  
	  NSLog(@"pass from file: %@", cryptedPwdFromFile);
	  saltEnd = 3;
	  while (saltEnd < [cryptedPwdFromFile length] && [cryptedPwdFromFile
	  characterAtIndex:saltEnd] != '$')
	    saltEnd++;
	  if (saltEnd < [cryptedPwdFromFile length])
	    {
	      NSString *salt;
	      NSString *recrypted;
	      
	      salt = [cryptedPwdFromFile substringFromRange:NSMakeRange(0, saltEnd)];
	      NSLog(@"Salt: %@", salt);
	      recrypted = [NSString stringWithCString:crypt([password cString],
	      [salt cString])];
	      NSLog(@"recrypted: %@", recrypted);
	      if ([recrypted compare:cryptedPwdFromFile options:NSLiteralSearch]
	      == NSOrderedSame)
	        {
		  NSLog(@"Equal");
		  pw = getpwnam([username cString]);
		  return YES;
		}
		else
	        {
		  NSLog(@"Not Equal");
		  return NO;
		}
	    }
	    else
	    {
	      NSLog(@"error, no salt found in password");
	      return NO;
	    }
	}
    }
  return NO;
}

- (void)setEnvironment
{
  chdir(pw->pw_dir);
}

- (void)startSession
{
  NSString *sessioncmd;
  int pid = 0;

  /* fork ourselves before downgrade...
     vfork blocks the father process */
  pid = vfork();
  if(pid == 0)
    {
      NSLog(@"user dir: %s", pw->pw_dir);
      /* change home directory */
      if(setenv("HOME", pw->pw_dir, YES) < 0)
      {
        NSLog(@"%d could not switch home to %s", errno, pw->pw_dir);
      }
      /* change current directory */
      chdir(pw->pw_dir);
      // Set user and group ids
      if ((initgroups(pw->pw_name, pw->pw_gid) != 0) 
	  || (setgid(pw->pw_gid) != 0) 
	  || (setuid(pw->pw_uid) != 0)) 
	{
	  NSLog(@"Could not switch to user id %@.", username);
	  exit(0);
	}
      sessioncmd = [NSString stringWithFormat: @"sh %s/.xsession",pw->pw_dir];
      system([sessioncmd cString]);
    }
}
@end
