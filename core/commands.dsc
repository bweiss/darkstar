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
alias dinfo (void) {
	@ :divider = repeat(${word(0 $geom()) - 8} -)
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
			@ :modname = tolower($module)
			eval ^local iline \$$var
			eval xecho -b [\$[12]modname] $iline
		}
		@ :pig_in_a_pen = 1
	}
	if (pig_in_a_pen) {
		echo $G $divider
	}
}

alias more less
alias less (files) {
	if (!files) {
		xecho -b Usage: /LESS <file> ...
		return
	}
	for file in ($files) {
		if (fexist($file) == 1) {
			@ :fd = open($file R)
			if (fd != -1) {
				while (!eof($fd)) {
					@ :line = 0
					while (line++ < winsize()) {
						@ :foo = read($fd)
						unless (eof($fd) && foo == []) {
							echo $foo
						}
					}
					if (!eof($fd)) {
						^local pause $'Hit q to quit, or anything else to continue.'
						if (tolower($pause) == [q]) { return; }
					}
				}
				@ close($fd)
			} else {
				echo Error: Could not open $file for reading
			}
		} else {
			echo $file\: File not found
		}
	}
}

/*
 * Removes assign structures.
 */
alias purge (arg, void) {
	foreach $arg _purge {
		purge $arg\[$_purge]
	}
	^assign -$arg
}

/*
 * Removes alias structures.
 */
alias purgealias (arg, void) {
	foreach -$arg _purge {
		purgealias $arg\[$_purge]
	}
	^alias -$arg
}

/*
 * Reloads everything including the core scripts.
 */
alias reload (void) {
	@ :home = DS.HOME
	timer -del all
	for cnt from 0 to ${numitems(loaded_modules) - 1} {
		queue -do cleanup.$getitem(loaded_modules $cnt)
	}
	^load $home/darkstar.irc
}

alias sv (whom default "$C", void) {
	msg $whom ircII $J $uname() - $CLIENT_INFORMATION
}

alias uptime (void) {
	xecho -b ircII $J $uname() - $CLIENT_INFORMATION
	xecho -b Client Uptime: $tdiff(${time() - F})
}


/* EOF */