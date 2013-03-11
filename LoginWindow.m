/* 
   LoginWindow.h

   Class to allow the display of a borderless window.  It also
   provides the necessary functionality for some of the other nice
   things we want the window to do.

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

#import "LoginWindow.h"

#ifdef GNUSTEP
#import "unistd.h"
#else
#import "libc.h"
#endif

#define SHRINKFACTOR 70

@implementation LoginWindow
- (id)initWithContentRect:(NSRect)contentRect
		styleMask:(NSUInteger)styleMask
		  backing:(NSBackingStoreType)bufferingType
		    defer:(BOOL)flag
{
  id lw;
  
  // It was neccesary to override this method to get the borderless
  // window since it is not available from InterfaceBuilder.
  NSLog(@"LoginWindow class has been instantiated...");
  lw = [super initWithContentRect: contentRect
		styleMask: NSBorderlessWindowMask
		backing: bufferingType
		defer: flag];
  savedWindowRect = [self frame];
  return lw;
}

- (void)waggle
{
  NSPoint origin, savedOrigin;
  NSRect windowRect;
  int i = 0, j = 0;
    

  NSLog(@"Waggling window... %@",self);
  windowRect = [self frame];
  savedOrigin = windowRect.origin;
  origin = savedOrigin;

  for( j = 0; j < 4; j++ )
    {
      for( i = 0; i < 2; i++ )
        {
	  origin.x += 30;
	  [self setFrameOrigin: origin];
        }

      for( i = 0; i < 4; i++ )
        {
	  origin.x -= 30;
	  [self setFrameOrigin: origin];
        }

      for( i = 0; i < 2; i++ )
        {
	  origin.x += 30;
	  [self setFrameOrigin: origin];
        }
    }
  [self setFrameOrigin: savedOrigin];
  // [self close];
}

- (void)shrink
{
  NSPoint origin, savedOrigin;
  NSRect windowRect;
  int i = 0, w = 0;

  windowRect = [self frame];
  savedWindowRect = windowRect;
  savedOrigin = windowRect.origin;
  origin = savedOrigin;
  w = windowRect.size.width;
  for( i = 0; i < (w - SHRINKFACTOR); i+=SHRINKFACTOR )
    {
      windowRect.size.width-=SHRINKFACTOR;
      windowRect.origin.x+=SHRINKFACTOR/2;
      [self setFrame: windowRect display: YES];
    }
  [self close];
}

- (void)restore
{
  [self setFrame: savedWindowRect display: YES];
}

- (BOOL)canBecomeKeyWindow
{
  return YES;
}

- (BOOL)canBecomeMainWindow
{
  return YES;
}

- (void)displayPanel
{
  NSData *imageData = nil;
  NSString *imagePath = nil;
  NSImage *image = nil;
  NSRect windowRect;

  // Initialize the login image (TDB: This will change later when login images become
  // configurable.)
  imagePath = [[NSBundle mainBundle] pathForResource: @"loginPanel" ofType: @"tiff"];
  imageData = [NSData dataWithContentsOfFile: imagePath];
  image = [[NSImage alloc] initWithData: imageData];

  windowRect = [self frame];
  windowRect.size = [image size];
  savedWindowRect = windowRect;
  [self setFrame: windowRect display: NO];
  [loginImageView setImage: image];
  [loginImageView setNeedsDisplay: YES];
  [loginImageView setEditable: NO];
}

- (void)displayPowerButton
{
  NSData *imageData = nil, *altImageData = nil;
  NSString *imagePath = nil, *altImagePath = nil;
  NSImage *image = nil, *altImage = nil;

  // Initialize the power button image (TDB: This will change later 
  // when login images become configurable.)
  imagePath = [[NSBundle mainBundle] pathForResource: @"power" 
				     ofType: @"tiff"];
  altImagePath = [[NSBundle mainBundle] pathForResource: @"power_invert" 
					ofType: @"tiff"];
  imageData = [NSData dataWithContentsOfFile: imagePath];
  altImageData = [NSData dataWithContentsOfFile: altImagePath]; 
  image = [[NSImage alloc] initWithData: imageData];
  altImage = [[NSImage alloc] initWithData: altImageData];
  [powerButton setImage: image];
  [powerButton setAlternateImage: altImage];
  [powerButton setNeedsDisplay: YES];
}

- (void)displayRestartButton
{
  NSData *imageData = nil, *altImageData = nil;
  NSString *imagePath = nil, *altImagePath = nil;
  NSImage *image = nil, *altImage = nil;

  // Initialize the restart button image (TDB: This will change later 
  // when login images become configurable.)
  imagePath = [[NSBundle mainBundle] pathForResource: @"restart" 
				     ofType: @"tiff"];
  altImagePath = [[NSBundle mainBundle] pathForResource: @"restart_invert" 
					ofType: @"tiff"];
  imageData = [NSData dataWithContentsOfFile: imagePath];
  altImageData = [NSData dataWithContentsOfFile: altImagePath]; 
  image = [[NSImage alloc] initWithData: imageData];
  altImage = [[NSImage alloc] initWithData: altImageData];
  [restartButton setImage: image];
  [restartButton setAlternateImage: altImage];
  [restartButton setNeedsDisplay: YES];
}

- (void)displayHostname
{
  char hostname[256], displayname[256];
  int  namelen = 256, index = 0;
  NSString *host_name = nil;

  // Initialize hostname
  gethostname( hostname, namelen );
  for(index = 0; index < 256 && hostname[index] != '.'; index++)
    {
      displayname[index] = hostname[index];
    }
  displayname[index] = 0;
  host_name = [NSString stringWithCString: displayname];
  [hostnameText setStringValue: host_name];
}

- (void)initializeInterface
{
#ifdef DEBUG
  NSLog(@"Initialize interface window=%@",self);
#endif
  // Set up all elements of the display...
  [self displayPanel];
  [self displayPowerButton];
  [self displayRestartButton];
  [self displayHostname];
  [self center];
}
@end





