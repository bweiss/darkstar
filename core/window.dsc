/* $Id$ */
/*
 * window.dsc - Window related features for the DarkStar core
 * Copyright (c) 2003 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 *
 * This script uses serial number 2 for all /ON hooks.
 */

addconfig -b DOUBLE_STATUS 0

bind ^[[5~ scroll_backward
bind ^[[6~ scroll_forward

alias _double_all_windows (void)
{
	if (CONFIG.DOUBLE_STATUS != []) {
		for wref in ($winrefs()) {
			if (!windowctl(GET $wref FIXED)) {
				^window $wref double $bool2word($CONFIG.DOUBLE_STATUS)
			}
		}
	}
}

on #-hook 2 "CONFIG DOUBLE_STATUS *"
{
	_double_all_windows
}

on #-window_create 2 "*"
{
	if (CONFIG.DOUBLE_STATUS != [] && !windowctl(GET $0 FIXED)) {
		^window $0 double on
	}
}

defer _double_all_windows


/* EOF */