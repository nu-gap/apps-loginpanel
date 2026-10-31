/* 
   Authenticator.m

   Class to allow loginpanel to authenticate users

   Copyright (C) 2000-2013 GNUstep Application Project

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
   31 Milk Street #960789 Boston, MA 02196 USA.
*/

/* Authenticator.m created by me on Wed 17-Nov-1999 */

#import "Authenticator.h"
#include <unistd.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>
#ifdef __linux__
#include <shadow.h>
#include <crypt.h>
#endif
#if HAVE_OPENBSD_AUTH
#include <login_cap.h>
#include <bsd_auth.h>
#endif

#ifdef HAVE_PAM
static int
LoginConversation(int count, const struct pam_message **messages,
                  struct pam_response **responses, void *context)
{
  Authenticator *auth = (Authenticator *)context;
  struct pam_response *reply;
  int i;

  if (count <= 0 || count > PAM_MAX_NUM_MSG)
    return PAM_CONV_ERR;
  reply = calloc(count, sizeof(*reply));
  if (reply == NULL)
    return PAM_BUF_ERR;
  for (i = 0; i < count; i++)
    {
      switch (messages[i]->msg_style)
        {
          case PAM_PROMPT_ECHO_ON:
            reply[i].resp = [auth username] != nil ? strdup([[auth username] UTF8String]) : NULL;
            break;
          case PAM_PROMPT_ECHO_OFF:
            reply[i].resp = [auth password] != nil ? strdup([[auth password] UTF8String]) : NULL;
            break;
          case PAM_TEXT_INFO:
          case PAM_ERROR_MSG:
            continue;
          default:
            goto failure;
        }
      if (reply[i].resp == NULL)
        goto failure;
    }
  *responses = reply;
  return PAM_SUCCESS;

failure:
  for (i = 0; i < count; i++)
    {
      if (reply[i].resp != NULL)
        {
          memset(reply[i].resp, 0, strlen(reply[i].resp));
          free(reply[i].resp);
        }
    }
  free(reply);
  return PAM_CONV_ERR;
}
#endif

static void
FreeAccount(struct passwd *account)
{
  if (account != NULL)
    {
      free(account->pw_name);
      free(account->pw_dir);
      free(account->pw_shell);
      free(account);
    }
}

@implementation Authenticator

- (id)initWithUsername: (NSString *)user password: (NSString *)pass
{
  self = [super init];
  if (self != nil)
    {
      [self setUsername: user];
      [self setPassword: pass];
    }
  return self;
}

- (void)dealloc
{
  [self closeSession];
  FreeAccount(pw);
  DESTROY(username);
  DESTROY(password);
  DEALLOC;
}

- (void)setUsername: (NSString *)user
{
  ASSIGNCOPY(username, user);
}

- (void)setPassword: (NSString *)pass
{
  ASSIGNCOPY(password, pass);
}

- (NSString *)username
{
  return username;
}

- (NSString *)password
{
  return password;
}

- (struct passwd *)getPasswordEntity
{
  return pw;
}

- (BOOL)isPasswordCorrect
{
  BOOL valid = NO;
  [self closeSession];
  FreeAccount(pw);
  pw = NULL;
  if ([username length] == 0 || [password length] == 0
      || strlen([username UTF8String]) != [username lengthOfBytesUsingEncoding: NSUTF8StringEncoding]
      || strlen([password UTF8String]) != [password lengthOfBytesUsingEncoding: NSUTF8StringEncoding])
    return NO;
#ifdef HAVE_PAM
  {
    struct pam_conv conversation = { LoginConversation, self };
    const void *canonicalUser = NULL;
    int result = pam_start("loginpanel", [username UTF8String], &conversation, &handle);
    if (result == PAM_SUCCESS && getenv("DISPLAY") != NULL)
      result = pam_set_item(handle, PAM_TTY, getenv("DISPLAY"));
    if (result == PAM_SUCCESS)
      result = pam_authenticate(handle, PAM_DISALLOW_NULL_AUTHTOK);
    if (result == PAM_SUCCESS)
      result = pam_acct_mgmt(handle, 0);
    if (result == PAM_SUCCESS)
      result = pam_get_item(handle, PAM_USER, &canonicalUser);
    if (result == PAM_SUCCESS && canonicalUser != NULL)
      {
        [self setUsername: [NSString stringWithUTF8String: canonicalUser]];
        valid = YES;
      }
  }
#elif HAVE_OPENBSD_AUTH
  valid = auth_userokay((char *)[username UTF8String], NULL, NULL,
                       (char *)[password UTF8String]);
#else
  {
    const char *hash = NULL;
    char *candidate;
    struct passwd *record = getpwnam([username UTF8String]);
    if (record != NULL)
      hash = record->pw_passwd;
#ifdef __linux__
    if (hash != NULL && strcmp(hash, "x") == 0)
      {
        struct spwd *shadow = getspnam([username UTF8String]);
        long today = time(NULL) / 86400;
        if (shadow == NULL || shadow->sp_lstchg == 0
            || (shadow->sp_expire >= 0 && today >= shadow->sp_expire)
            || (shadow->sp_max >= 0 && shadow->sp_lstchg >= 0
                && today >= shadow->sp_lstchg + shadow->sp_max))
          hash = NULL;
        else
          hash = shadow->sp_pwdp;
      }
#endif
    if (hash != NULL && hash[0] != '\0' && hash[0] != '!' && hash[0] != '*')
      {
        candidate = crypt([password UTF8String], hash);
        valid = candidate != NULL && strcmp(candidate, hash) == 0;
      }
  }
#endif
  if (valid)
    {
      struct passwd *record = getpwnam([username UTF8String]);
      valid = record != NULL && record->pw_shell != NULL
        && strcmp(record->pw_shell, "/usr/sbin/nologin") != 0
        && strcmp(record->pw_shell, "/sbin/nologin") != 0
        && strcmp(record->pw_shell, "/bin/false") != 0;
      if (valid)
        {
          pw = calloc(1, sizeof(*pw));
          if (pw != NULL)
            {
              pw->pw_uid = record->pw_uid;
              pw->pw_gid = record->pw_gid;
              pw->pw_name = strdup(record->pw_name);
              pw->pw_dir = strdup(record->pw_dir);
              pw->pw_shell = strdup(record->pw_shell);
              valid = pw->pw_name != NULL && pw->pw_dir != NULL && pw->pw_shell != NULL;
            }
          else
            valid = NO;
        }
    }
  if (!valid)
    {
      FreeAccount(pw);
      pw = NULL;
      [self closeSession];
    }
  return valid;
}

- (BOOL)openSession
{
  if (pw == NULL)
    return NO;
#ifdef HAVE_PAM
  if (handle == NULL || pam_setcred(handle, PAM_ESTABLISH_CRED) != PAM_SUCCESS)
    return NO;
  credentialsEstablished = YES;
  if (pam_open_session(handle, 0) != PAM_SUCCESS)
    {
      [self closeSession];
      return NO;
    }
  sessionOpen = YES;
#endif
  return YES;
}

- (void)closeSession
{
#ifdef HAVE_PAM
  if (handle != NULL)
    {
      if (sessionOpen)
        pam_close_session(handle, 0);
      if (credentialsEstablished)
        pam_setcred(handle, PAM_DELETE_CRED);
      pam_end(handle, PAM_SUCCESS);
      handle = NULL;
    }
  sessionOpen = NO;
  credentialsEstablished = NO;
#endif
}

- (void)setEnvironment
{
#ifdef HAVE_PAM
  char **environment = pam_getenvlist(handle);
  char **entry;
  if (environment != NULL)
    {
      for (entry = environment; *entry != NULL; entry++)
        {
          char *separator = strchr(*entry, '=');
          if (separator != NULL)
            {
              *separator = '\0';
              setenv(*entry, separator + 1, 1);
            }
          free(*entry);
        }
      free(environment);
    }
#endif
}

@end
