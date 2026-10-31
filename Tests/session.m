/* Exercise the real session launcher with an isolated home and current UID. */
#import "LoginPanelController.h"
#import "Authenticator.h"
#include <assert.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>

static struct passwd account;
static int restored = 0;
static int failed = 0;

@interface SessionAuthenticator : Authenticator

@end

@implementation SessionAuthenticator

- (struct passwd *)getPasswordEntity
{
  return &account;
}

@end

@interface LoginPanelController (Testing)

- (void)pollSession: (NSTimer *)timer;

@end

@interface SessionController : LoginPanelController

@end

@implementation SessionController

- (void)initializeInterface
{
  restored++;
}

- (void)sessionFailed
{
  failed++;
}

@end

static void
WaitForSession(SessionController *controller)
{
  int tries;
  for (tries = 0; tries < 1000; tries++)
    {
      [controller pollSession: nil];
      if ([[controller valueForKey: @"sessionPID"] intValue] == 0)
        return;
      usleep(10000);
    }
  assert(0 && "Session did not finish");
}

int main(void)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  SessionController *controller = [[SessionController alloc] init];
  SessionAuthenticator *auth = [[SessionAuthenticator alloc] init];
  char directory[] = "/tmp/loginpanel-session-XXXXXX";
  NSString *home, *script, *output;
  pid_t child;
  assert(mkdtemp(directory) != NULL);
  account = *getpwuid(getuid());
  account.pw_dir = directory;
  home = [NSString stringWithUTF8String: directory];
  script = [home stringByAppendingPathComponent: @".xsession"];
  output = [home stringByAppendingPathComponent: @"result"];
  assert([@"test -z \"$LOGINPANEL_TEST_SECRET\" || exit 10\n"
            "test \"$HOME\" = \"$PWD\" || exit 11\n"
            "test -n \"$USER\" || exit 12\n"
            "test \"$DISPLAY\" = :98 || exit 13\n"
            "printf success > result\n"
    writeToFile: script atomically: YES]);
  setenv("LOGINPANEL_TEST_SECRET", "must-not-leak", 1);
  setenv("DISPLAY", ":98", 1);
  [controller setValue: auth forKey: @"authenticator"];
  [controller startSession];
  child = [[controller valueForKey: @"sessionPID"] intValue];
  assert(child > 0);
  WaitForSession(controller);
  assert(restored == 1 && failed == 0);
  assert([[NSString stringWithContentsOfFile: output] isEqualToString: @"success"]);
  account.pw_dir = "/nonexistent/loginpanel-test";
  [controller startSession];
  child = [[controller valueForKey: @"sessionPID"] intValue];
  assert(child > 0);
  WaitForSession(controller);
  assert(restored == 2 && failed == 1);
  [controller killProcessGroup: -1];
  [controller killProcessGroup: 0];
  [controller killProcessGroup: getpgrp()];
  unlink([script fileSystemRepresentation]);
  unlink([output fileSystemRepresentation]);
  rmdir(directory);
  RELEASE(auth);
  RELEASE(controller);
  RELEASE(pool);
  puts("session: PASS");
  return 0;
}

