/* $Id$ */
/*
 * commands.dsc - Miscellaneous commands
 * Copyright (c) 2002 Brian Weiss (except where noted)
 * See the 'COPYRIGHT' file for more information.
 */

/*
 * Displays miscellaneous information about the operating system,
 * client, and DarkStar (including modules).
 */
alias dinfo (void)
{
	@:divider = repeat(${word(0 $geom()) - 8} -)
	echo $G $divider

	/* Display information about the operating system */
	xecho -b $uname(%s %r) \($uname(%m)\)
	xecho -b $pipe(uptime)
	echo $G $divider

	/* Display information about the client */
	xecho -b ircII $J \($V\) [$info(i)] "$info(r)"
	xecho -b Uptime: $tdiff2(${time() - F}) - PID: $pid(), PPID: $ppid()
	xecho -b $info(c)
	xecho -b Compile-time options: $info(o)
	echo $G $divider

	/* Display information about DarkStar */
	xecho -b DarkStar $DS.VERSION \($DS.INTERNAL_VERSION\) [$DS.CORE_ID]
	xecho -b Available modules: $numitems(modules), Loaded modules: $numitems(loaded_modules)
	xecho -b Current theme: $DS.THEME, Current statusbar: $DS.SBAR
	echo $G $divider

	/* Display module information */
	foreach MODINFO module {
		for var in ($aliasctl(assign match MODINFO.$module\.)) {
			@:modname = tolower($module)
			eval ^local iline \$$var
			eval xecho -b [\$[12]modname] $iline
		}
		@:pig_in_a_pen = 1
	}
	if (pig_in_a_pen) {
		echo $G $divider
	}
}


#
# A file pager.  A demonstration of how to do something useful in ircII.
# This cheesy rip-off was written by hop in 1996.
# My apologies in advance to archon.
# Modified on Jan 25, 1999 as an example of how to use arglists.
# Modified on Oct 17, 2001 by Brian Weiss for use with DarkStar/EPIC4
#

alias more less
alias less (file, void)
{
	@:winnum = winnum()
	if (file) {
		if (fexist($file) == 1) {
			_less $open($file R) ${winsize() - 1} $winnum
		} else {
			xecho -b -w $winnum $file\: no such file.
		}
	} else {
		xecho -b -w $winnum Usage: /LESS <filename>
	}
}

alias _less (fd, count, winnum default 0, void)
{
	@:line = 0

	while (!eof($fd) && (line++ < count)) {
		@:ugh = read($fd)
		if (!eof($fd)) {
			xecho -w $winnum $ugh
		}
	}

	if (!eof($fd)) {
		@ LESS.FD = fd
		@ LESS.NL = count
		@ LESS.W  = winnum
		input_char "Enter q to quit, or anything else to continue " {
			if ([$0] != [q]) {
				_less $LESS.FD $LESS.NL $LESS.W
			}
		}
	} else {
		@ close($fd)
		for var in ($aliasctl(assign match LESS.)) {
			^assign -$var
		}
	}
}

/*
 * Removes assign structures.
 */
alias purge (arg, void)
{
	foreach $arg _purge {
		purge $arg\[$_purge]
	}
	^assign -$arg
}

/*
 * Removes alias structures.
 */
alias purgealias (arg, void)
{
	foreach -$arg _purge {
		purgealias $arg\[$_purge]
	}
	^alias -$arg
}

/*
 * Reloads everything including the core scripts.
 */
alias reload (void)
{
	@ :home = DS.HOME
	timer -del all
	for cnt from 0 to ${numitems(loaded_modules) - 1} {
		queue -do cleanup.$getitem(loaded_modules $cnt)
	}
	^load $home/darkstar.irc
}

/*
 * Show your client version string.
 */
alias sv (whom default "$C", void)
{
	msg $whom ircII $J $uname() - $CLIENT_INFORMATION
}

/*
 * Display client uptime.
 */
alias uptime (void)
{
	xecho -b ircII $J $uname() - $CLIENT_INFORMATION
	xecho -b Client Uptime: $tdiff(${time() - F})
}


/* EOF */