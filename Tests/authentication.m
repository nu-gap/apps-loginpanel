/* Regression tests for local authentication; no system accounts are changed. */
#import "Authenticator.h"
#include <shadow.h>
#include <crypt.h>
#include <assert.h>
#include <string.h>
#include <time.h>

static struct passwd account;
static struct spwd shadow;
static char hash[512];

struct passwd *getpwnam(const char *name)
{
  return strcmp(name, "loginpanel-test") == 0 ? &account : NULL;
}

struct spwd *getspnam(const char *name)
{
  return strcmp(name, "loginpanel-test") == 0 ? &shadow : NULL;
}

int main(void)
{
  NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
  Authenticator *auth = [[Authenticator alloc] init];
  strcpy(hash, crypt("correct-password", "$6$rounds=1000$testsalt$"));
  account.pw_name = "loginpanel-test";
  account.pw_passwd = "x";
  account.pw_dir = "/tmp";
  account.pw_shell = "/bin/sh";
  shadow.sp_pwdp = hash;
  shadow.sp_lstchg = time(NULL) / 86400 - 1;
  shadow.sp_max = 30;
  shadow.sp_expire = -1;
  [auth setUsername: @"loginpanel-test"];
  [auth setPassword: @"correct-password"];
  assert([auth isPasswordCorrect]);
  assert([auth getPasswordEntity] != NULL);
  [auth setPassword: @"wrong-password"];
  assert(![auth isPasswordCorrect]);
  assert([auth getPasswordEntity] == NULL);
  [auth setPassword: @""];
  assert(![auth isPasswordCorrect]);
  [auth setPassword: @"correct-password"];
  shadow.sp_pwdp = "!locked";
  assert(![auth isPasswordCorrect]);
  shadow.sp_pwdp = hash;
  shadow.sp_expire = time(NULL) / 86400;
  assert(![auth isPasswordCorrect]);
  shadow.sp_expire = -1;
  shadow.sp_lstchg = 0;
  assert(![auth isPasswordCorrect]);
  shadow.sp_lstchg = time(NULL) / 86400 - 31;
  assert(![auth isPasswordCorrect]);
  shadow.sp_lstchg = time(NULL) / 86400 - 1;
  account.pw_shell = "/usr/sbin/nologin";
  assert(![auth isPasswordCorrect]);
  account.pw_shell = "/bin/sh";
  [auth setUsername: @"unknown-account"];
  assert(![auth isPasswordCorrect]);
  [auth setUsername: @"loginpanel-test"];
  [auth setPassword: [NSString stringWithFormat: @"correct-password%Cignored", 0]];
  assert(![auth isPasswordCorrect]);
  RELEASE(auth);
  RELEASE(pool);
  puts("authentication: PASS");
  return 0;
}

