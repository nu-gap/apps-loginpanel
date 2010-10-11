/* 
   LoginPanelController.h

   Controller class which handles all activity in the loginpanel.

   Copyright (C) 2000 Gregory John Casamento 

   Author:  Gregory John Casamento <greg_casamento@yahoo.com>
   Date: 2000
   
   This file is part of GNUstep.

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

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "LoginWindow.h"

// Declare classes here
@class Authenticator;

@interface LoginPanelController : NSObject
{
    IBOutlet NSSecureTextField *passwordField;
    IBOutlet NSTextField *usernameField;
    IBOutlet LoginWindow *window;
    IBOutlet NSPanel *infoPanel;
    Authenticator *authenticator;
    NSUserDefaults *defaults;
}
- (void)applicationDidFinishLaunching: (NSNotification *)notification;
- (void)initialize;
- (void)passwordEntered:(id)sender;
- (void)powerButton:(id)sender;
- (void)restartButton:(id)sender;
- (void)usernameEntered:(id)sender;
- (void)rejectEntries;
- (void)logUserIn;
- (void)showInfo: (id)sender;

@end
