/* 
   Authenticator.h

   Class to allow the loginpanel app to authenticate users

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

/* Authenticator.h created by me on Wed 17-Nov-1999 */

#import <AppKit/AppKit.h>

#if defined(GNUSTEP)
#import <security/pam_appl.h>
#else
#import <pwd.h>
#endif

@interface Authenticator : NSObject
{
    NSString *username;
    NSString *password;
#if defined(GNUSTEP)
    pam_handle_t *handle;
#endif
}
- init;
- initWithUsername: (NSString *)user
          password: (NSString *)pass;
- (void)setUsername: (NSString *)user;
- (void)setPassword: (NSString *)pass;
- (NSString *)username;
- (NSString *)password;
- (BOOL)isPasswordCorrect;
- (void)setEnvironment;
- (void)startSession;
@end
