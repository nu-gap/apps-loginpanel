/* 
   LoginTheme.m

   Class to allow customization of the loginpanel's appearance.

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

/* LoginTheme.m created by me on Sun 14-Nov-1999 */

#import "LoginTheme.h"

@implementation LoginTheme
- init
{
  panelImage = nil;;
  backgroundImage = nil;;
  powerButtonImage = nil;
  restartButtonImage = nil;
  userfieldText = nil;
  passfieldText = nil;
  backgroundColor = nil;
  usernameFieldBackgroundColor = nil;
  passwordFieldBackgroundColor = nil;
  [super init];
  
  return self;
}

- (id)initWithCoder: (NSCoder *)aCoder
{
  // This is version zero... please remember to
  // make update the version if there is anything added
  // or removed from this method in order to maintain
  // backwards compatibility.
  panelImage = [[aCoder decodeObject] retain];
  backgroundImage = [[aCoder decodeObject] retain];
  powerButtonImage = [[aCoder decodeObject] retain];
  restartButtonImage = [[aCoder decodeObject] retain];
  userfieldText = [[aCoder decodeObject] retain];
  passfieldText = [[aCoder decodeObject] retain];
  backgroundColor = [[aCoder decodeObject] retain];
  usernameFieldBackgroundColor = [[aCoder decodeObject] retain];
  passwordFieldBackgroundColor = [[aCoder decodeObject] retain];
  return self;
}

- (void)encodeWithCoder: (NSCoder *)aCoder
{
  [aCoder encodeObject: panelImage];
  [aCoder encodeObject: backgroundImage];
  [aCoder encodeObject: powerButtonImage];
  [aCoder encodeObject: restartButtonImage];
  [aCoder encodeObject: userfieldText];
  [aCoder encodeObject: passfieldText];
  [aCoder encodeObject: backgroundColor];
  [aCoder encodeObject: usernameFieldBackgroundColor];
  [aCoder encodeObject: passwordFieldBackgroundColor];
  return;
}

// accessor methods
// "Get" methods
- (NSString *)panelImage
{
  return panelImage;
}

- (NSString *)backgroundImage
{
  return backgroundImage;
}

- (NSString *)powerButtonImage
{
  return powerButtonImage;
}

- (NSString *)restartButtonImage
{
  return restartButtonImage;
}

- (NSString *)userfieldText
{
  return userfieldText;
}

- (NSString *)passfieldText
{
  return passfieldText;
}

- (NSColor *)backgroundColor
{
  return backgroundColor;
}

- (NSColor *)usernameFieldBackgroundColor
{
  return usernameFieldBackgroundColor;
}

- (NSColor *)passwordFieldBackgroundColor
{
  return passwordFieldBackgroundColor;
}

// "Set" methods
- (void)setPanelImage: (NSString *)imageFile
{
  panelImage = [imageFile copy]; 
}

- (void)setBackgroundImage: (NSString *)imageFile
{
  backgroundImage = [imageFile copy];
}

- (void)setPowerButtonImage: (NSString *)imageFile
{
  powerButtonImage = [imageFile copy];
}

- (void)setRestartButtonImage: (NSString *)imageFile
{
  restartButtonImage = [imageFile copy];
}

- (void)setUserfieldText: (NSString *)text
{
    userfieldText = [text copy];
}

- (void)setPassfieldText: (NSString *)text
{
  passfieldText = [text copy];
}

- (void)setBackgroundColor: (NSColor *)color
{
  backgroundColor = [color copy];
}

- (void)setUsernameFieldBackgroundColor: (NSColor *)color
{
  usernameFieldBackgroundColor = [color copy];
}

- (void)setPasswordFieldBackgroundColor: (NSColor *)color
{
  passwordFieldBackgroundColor = [color copy];
}
@end
