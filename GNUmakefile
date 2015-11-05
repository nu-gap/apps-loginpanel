#
#  This file is part of the GNUstep Application Project
#
#  This library is free software; you can redistribute it and/or
#  modify it under the terms of the GNU Library General Public
#  License as published by the Free Software Foundation; either
#  version 2 of the License, or (at your option) any later version.
#
#  This library is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.	 See the GNU
#  Library General Public License for more details.
#
#  If you are interested in a warranty or support for this source code,
#  contact Scott Christley at scottc@net-community.com
#
#  You should have received a copy of the GNU General Public
#  License along with this library; see the file COPYING.
#  If not, write to the Free Software Foundation,
#  59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

ifeq ($(GNUSTEP_MAKEFILES),)
 GNUSTEP_MAKEFILES := $(shell gnustep-config --variable=GNUSTEP_MAKEFILES 2>/dev/null)
  ifeq ($(GNUSTEP_MAKEFILES),)
    $(warning )
    $(warning Unable to obtain GNUSTEP_MAKEFILES setting from gnustep-config!)
    $(warning Perhaps gnustep-make is not properly installed,)
    $(warning so gnustep-config is not in your PATH.)
    $(warning )
    $(warning Your PATH is currently $(PATH))
    $(warning )
  endif
endif

ifeq ($(GNUSTEP_MAKEFILES),)
  $(error You need to set GNUSTEP_MAKEFILES before compiling!)
endif

loginpanel_MAIN_MODEL_FILE = loginwindow.gorm

include $(GNUSTEP_MAKEFILES)/common.make

# The application to be compiled
APP_NAME = loginpanel

loginpanel_PRINCIPAL_CLASS = LoginApplication

# The Objective-C source files to be compiled
loginpanel_OBJC_FILES = Authenticator.m \
          loginpanel_main.m LoginImageView.m \
	  LoginPanelController.m LoginWindow.m\
          LoginTheme.m LoginApplication.m XServerManager.m

# The Resource files to be copied into the app's resources directory
loginpanel_RESOURCE_FILES = gnustep.tiff\
                   loginicon.tiff \
                   loginPanel.tiff \
                   loginPanelBlank.tiff \
                   power.tiff \
                   restart.tiff \
                   power_invert.tiff \
                   restart_invert.tiff 

loginpanel_LOCALIZED_RESOURCE_FILES = \
                   loginwindow.gorm \
                   InfoPanel.gorm

loginpanel_LANGUAGES = English


include GNUmakefile.preamble
include $(GNUSTEP_MAKEFILES)/tool.make
include $(GNUSTEP_MAKEFILES)/application.make
-include GNUmakefile.postamble

