/* $Id$ */
/*
 * commands.dsc - Miscellaneous commands
 * Copyright (c) 2002, 2003 Brian Weiss (except where noted)
 * See the 'COPYRIGHT' file for more information.
 */

/*
 * Displays miscellaneous information about the operating system,
 * client, and DarkStar (including modules).
 */
alias dinfo (void)
{
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
	xecho -b Available modules: $numitems(_modules), Loaded modules: $numitems(_loaded_modules)
	xecho -b Current theme: $CONFIG.THEME
	echo $G $divider

	/* Display module information */
	foreach _MODINFO module
	{
		for var in ($aliasctl(assign match _MODINFO.$module\.))
		{
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

/*
 * Output the contents of files to the current window, pausing between
 * each full screen of output, while taking into account linewrapping and
 * /SET {CONTINUED_LINE|SET INDENT}. It's not terribly efficient but
 * it sure beats the hell out of the old /LESS. :-)
 */
alias less (file, void)
{
	if (!file) {
		xecho -b Usage: /LESS <file>
		return
	}

	/*
	 * Dump the contents of the specified file into an array.
	 */
	if (fexist($file) == 1)
	{
		@ :fd = open($file R)
		if (fd != -1)
		{
			@ delarray(_less)
			for (@ :item = 0, !eof($fd), @ :item++) {
				@ setitem(_less $item $read($fd))
			}
			@ close($fd)
		}{
			xecho -b LESS: Could not open $file for reading
		}
	}{
		xecho -b LESS: File not found: $file
	}

	_less.split_array _less
	_less.output _less
}

alias _less.output (array_struct, void)
{
	if (!array_struct) \
		return

	@ :ii = 0
	@ :arrays = getarrays($array_struct\.*)
	while (:array = shift(arrays))
	{
		for ii from 1 to $numitems($array) {
			echo $getitem($array ${ii-1})
		}

		unless (!arrays)
		{
			^local pause $'Hit q to quit, or anything else to continue.'
			if (pause == [q]) \
				break
		}
	}

	purgearray _less
}

/*
 * Break up the contents of the specified array into multiple arrays,
 * each with as many lines as can be displayed at one time in the current
 * window.
 */
alias _less.split_array (array, void)
{
	if (!array) \
		return

	@ :cnt = 1
	@ :ii = :lines = 0
	while (ii < numitems(_less))
	{
		@ :text = getitem(_less $ii)
		@ :numlines = numlines($text)
		@ :lines += numlines

		/*
		 * We don't want an infinite loop if the window is so small we can't
		 * even display a single line, so we make sure lines > numlines.
		 */
		if (lines > numlines && lines > winsize())
		{
			@ :cnt++
			@ :lines = 0
		}{
			@ setitem($array\.$cnt $numitems($array\.$cnt) $text)
			@ :ii++
		}
	}
}

alias purge (struct, void)
{
	foreach $struct _purge {
		purge $struct\[$_purge]
	}
	^assign -$struct
}

alias purgealias (struct, void)
{
	foreach -$struct _purge {
		purgealias $struct\[$_purge]
	}
	^alias -$struct
}

alias purgearray (struct, void)
{
	for array in ($getarrays($struct*)) {
		@ delarray($array)
	}
}

/*
 * Reloads everything including the core scripts.
 */
alias reload (void)
{
	@ :home = DS.HOME
	timer -del all
	for cnt from 0 to ${numitems(_loaded_modules) - 1} {
		queue -do cleanup.$getitem(_loaded_modules $cnt)
	}
	^load $home/darkstar.irc
}

alias sv (whom default "$C", void)
{
	msg $whom ircII $J $uname() - $CLIENT_INFORMATION
}

alias uptime (void)
{
	xecho -b ircII $J $uname() - $CLIENT_INFORMATION
	xecho -b Client Uptime: $tdiff(${time() - F})
}


/*
 * The *cmd aliases all come from CrazyEddy's commandqueues script that is
 * distributed with EPIC4. They have been slightly modified for use with
 * DarkStar. -bmw
 */

#
# Usage:
#  1cmd [time [command]]
#
# command will not be executed if the same command has been executed in
# the last time seconds.
#
alias 1cmd {
	@ :foo = encode($tolower($1-))
	@ :eserv = 0 > servernum() ? [] : servernum()
	if (time() - _ONECMD[$eserv][$foo] >= [$0]) {
		@ _ONECMD[$eserv][$foo] = time()
		$1-
	}
	if (time() != _ONECMD[$eserv] && (!rand(100))) {
		@ _ONECMD[$eserv] = time()
		foreach _ONECMD[$eserv] bar {
			if (_ONECMD[$eserv][$bar] < time()) {
				@ _ONECMD[$eserv][$bar] = []
			}
		}
	}
}

#
# Usage:
#  qcmd [queue [command]]
#  fqcmd [queue [command]]
#
# Queue command, and schedule a timer for later execution.  Prevents flooding.
# fqcmd adds the command to the beginning of the queue instead of the end.
#
#  q1cmd [time [queue [command]]]
#  fq1cmd [time [queue [command]]]
#
# The same as "1cmd {time} qcmd {queue} {command}", only, the command also
# won't be scheduled if the same command is already scheduled.
#
# Also, with [f]q1cmd, you can specify a coma separated list of queues for
# the second argument.  All these queues will be searched for duplicates but
# the first will be the queue given to qcmd.
#
stack push alias alias.tt
alias alias.tt (cmd,op,args) {
	@ sar(gr/\${cmd}/${cmd}/args)
	@ sar(gr/\${op}/${op}/args)
	alias $args
}
fe (q push fq unshift) cmd op {
	alias.tt $cmd $op ${cmd}1cmd (qo,qc,args) {
		@ :argz = args
		@ sar(gr/\\/\\\\/argz)
		@ sar(gr/\"/\\\"/argz)
		@ :qc = split(, $qc)
		fe ($qc) qqcc {
			if (0 <= findw("$argz" $_QCMD[$servernum()][$qqcc])) {
				return
			}
		}
		1cmd $qo ${cmd}cmd $shift(qc) $args
	}
	alias.tt $cmd $op ${cmd}cmd {
		@ :sn = servernum()
		@ :sn = sn < 0 ? [_] : sn
		if (1 < #) {
			@ :bar = [$1-]
			@ ${op}(_QCMD.${sn}.$0 \"$msar(gr/\\/\\\\/\"/\\\"/bar)\")
		} else {
			@ :foo = []
			if (1 == #) {
				@ foo = [$0]
			} elsif (islagged()) {
				@ :bar = [ ]
				# Do nothing if we're lagged.
				# This is meant to be a link to a
				# fictitious lag measurement script.
			} elsif (0 == #) {
				foreach _QCMD[$sn] bar {
					@ foo = bar
					break
				}
			}
			if (@foo) {
				@ :bar = shift(_QCMD[$sn][$foo])
				$msar(gr/\\\\/\\/\\\"/\"/bar)
			}
		}
		if (@bar) ^timer -ref _qcmd.$sn 5 qcmd
	}
}
stack pop alias alias.tt

