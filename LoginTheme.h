/* 
   LoginTheme.h

   Class to allow customization of the loginpanel's appearance.

   Copyright (C) 2000 Free Software Foundation, Inc.

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

/* LoginTheme.h created by me on Sun 14-Nov-1999 */

#import <AppKit/AppKit.h>

@interface LoginTheme : NSObject <NSCoding>
{
  NSString *panelImage;
  NSString *backgroundImage;
  NSString *powerButtonImage;
  NSString *restartButtonImage;
  NSString *userfieldText;
  NSString *passfieldText;
  NSColor *backgroundColor;
  NSColor *usernameFieldBackgroundColor;
  NSColor *passwordFieldBackgroundColor;    
}
// initialization methods
- init;
// accessor methods
// "Get" methods
- (NSString *)panelImage;
- (NSString *)backgroundImage;
- (NSString *)powerButtonImage;
- (NSString *)restartButtonImage;
- (NSString *)userfieldText;
- (NSString *)passfieldText;
- (NSColor *)backgroundColor;
- (NSColor *)usernameFieldBackgroundColor;
- (NSColor *)passwordFieldBackgroundColor;

// "Set" methods
- (void)setPanelImage: (NSString *)imageFile;
- (void)setBackgroundImage: (NSString *)imageFile;
- (void)setPowerButtonImage: (NSString *)imageFile;
- (void)setRestartButtonImage: (NSString *)imageFile;
- (void)setUserfieldText: (NSString *)text;
- (void)setPassfieldText: (NSString *)text;
- (void)setBackgroundColor: (NSColor *)color;
- (void)setUsernameFieldBackgroundColor: (NSColor *)color;
- (void)setPasswordFieldBackgroundColor: (NSColor *)color;
@end
