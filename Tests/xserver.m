/* Run only on a free, isolated display: Tests/run-xserver.sh. */
#import "XServerManager.h"
#include <assert.h>
#include <unistd.h>
#include <sys/stat.h>

int main(void)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  XServerManager *manager = [XServerManager sharedXServerManager];
  NSString *authority;
  Display *connection;
  struct stat info;
  [manager setDisplayName: @":99"];
  assert(![manager hasUsableDisplay]);
  assert([manager startXServer]);
  authority = [NSString stringWithUTF8String: getenv("XAUTHORITY")];
  assert(stat([authority fileSystemRepresentation], &info) == 0);
  assert((info.st_mode & 0777) == 0600);
  connection = XOpenDisplay(":99");
  assert(connection != NULL);
  XCloseDisplay(connection);
  setenv("XAUTHORITY", "/nonexistent/loginpanel-authority", 1);
  connection = XOpenDisplay(":99");
  assert(connection == NULL);
  setenv("XAUTHORITY", [authority fileSystemRepresentation], 1);
  assert([manager stopXServer]);
  assert([manager serverPID] == 0);
  assert(access([authority fileSystemRepresentation], F_OK) != 0);
  assert([manager stopXServer]);
  RELEASE(pool);
  puts("xserver: PASS");
  return 0;
}

