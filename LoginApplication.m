#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@interface LoginApplication : NSApplication
@end

@implementation LoginApplication
- (id) init
{
  self = [super init];
  if (self != nil)
    {
      NSUserDefaults *defs = [NSUserDefaults standardUserDefaults];
      [defs setBool: YES forKey: @"GSSuppressAppIcon"];
    }
  return self;
}
@end
