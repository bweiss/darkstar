#
# $Id$
# commands.dsc - Miscellaneous commands
# Copyright (c) 2002, 2003 Brian Weiss (except where noted)
# See the 'COPYRIGHT' file for more information.
#

#
# Displays miscellaneous information about the operating system,
# client, and DarkStar (including modules).
#
alias dinfo (void)
{
	@ :divider = repeat(${word(0 $geom()) - 8} -);
	echo $G $divider;

	# Display information about the operating system
	xecho -b $uname(%s %r) \($uname(%m)\);
	xecho -b $pipe(uptime);
	echo $G $divider;

	# Display information about the client
	xecho -b ircII $J \($V\) [$info(i)] "$info(r)";
	xecho -b Uptime: $tdiff2(${time() - F}) - PID: $pid(), PPID: $ppid();
	xecho -b $info(c);
	xecho -b Compile-time options: $info(o);
	echo $G $divider;

	# Display information about DarkStar
	xecho -b DarkStar $DS.VERSION \($DS.INTERNAL_VERSION\) [$DS.CORE_ID];
	xecho -b Available modules: $numitems(_modules), Loaded modules: $numitems(_loaded_modules);
	xecho -b Current theme: $CONFIG.THEME;
	echo $G $divider;

	# Display module information
	foreach _MODINFO module
	{
		for var in ($aliasctl(assign match _MODINFO.$module\.))
		{
			@ :modname = tolower($module);
			eval ^local iline \$$var;
			eval xecho -b [\$[12]modname] $iline;
		};
		@ :pig_in_a_pen = 1;
	};
	if (pig_in_a_pen) {
		echo $G $divider;
	};
};

alias more (...) {
	less $*;
};

#
# Output the contents of files to the current window, pausing between
# each full screen of output, while taking into account linewrapping and
# /SET CONTINUED_LINE, INDENT.
#
alias less (file, void)
{
	if (!file) {
		xecho -b Usage: /LESS <file>;
		return;
	};

	# Dump the contents of the specified file into an array.
	if (fexist($file) == 1)
	{
		@ :fd = open($file R);
		if (fd != -1)
		{
			@ delarray(_less);
			for (@ :item = 0, !eof($fd), @ :item++) {
				@ setitem(_less $item $read($fd));
			};
			@ close($fd);
		}{
			xecho -b LESS: Could not open $file for reading;
		};
	}{
		xecho -b LESS: File not found: $file;
	};

	_less.split_array _less;
	_less.output _less;
};

alias _less.output (array_struct, void)
{
	if (!array_struct)
		return;

	stack push set OUTPUT_REWRITE;
	^set -OUTPUT_REWRITE;

	@ :ii = 0;
	@ :arrays = getarrays($array_struct\.*);
	while (:array = shift(arrays))
	{
		for ii from 1 to $numitems($array)
		{
			@ :line = getitem($array ${ii-1});
			unless (!arrays && ii == numitems($array) && line == []) {
				echo $line;
			};
		};

		unless (!arrays)
		{
			^local pause $'*** Hit any key for more, "q" to quit ***';
			if (pause == [q])
				break;
		};
	};

	stack pop set OUTPUT_REWRITE;
	purgearray $array_struct;
};

#
# Break up the contents of the specified array into multiple arrays,
# each with as many lines as can be displayed at one time in the current
# window.
#
alias _less.split_array (array, void)
{
	if (!array)
		return;

	@ :cnt = 1;
	@ :ii = :lines = 0;
	while (ii < numitems(_less))
	{
		@ :text = getitem(_less $ii);
		@ :numlines = numlines($word(0 $geom()) $text);
		@ :lines += numlines;

		# We don't want an infinite loop if the window is so small we can't
		# even display a single line, so we make sure lines > numlines.
		if (lines > numlines && lines > winsize())
		{
			@ :cnt++;
			@ :lines = 0;
		}{
			@ setitem($array\.$cnt $numitems($array\.$cnt) $text);
			@ :ii++;
		};
	};
};

alias purge (struct, void)
{
	foreach $struct _purge {
		purge $struct\[$_purge];
	};
	^assign -$struct;
};

alias purgealias (struct, void)
{
	foreach -$struct _purge {
		purgealias $struct\[$_purge];
	};
	^alias -$struct;
};

alias purgearray (struct, void)
{
	for array in ($getarrays($struct*)) {
		@ delarray($array);
	};
};

# Reloads everything including the core scripts.
alias reload (void)
{
	@ :home = DS.HOME;

	for ii from 1 to $numitems(_loaded_modules) {
		queue -do cleanup.$getitem(_loaded_modules ${ii-1});
	};

	dump all;
	timer -del all;
	for array in ($getarrays()) {
		@ delarray($array);
	};

	^load -pf $home/darkstar.irc;
};

alias sv (whom default "$C", void)
{
	msg $whom ircII $J $uname() - $CLIENT_INFORMATION;
};

alias uptime (void)
{
	xecho -b ircII $J $uname() - $CLIENT_INFORMATION;
	xecho -b Client Uptime: $tdiff(${time() - F});
};

#
# The following aliases all come from CrazyEddy's commandqueues script that
# is distributed with EPIC4. They have been slightly modified for use with
# DarkStar. -bmw
#
# Usage:
#  1cmd [time [command]]
#
# command will not be executed if the same command has been executed in
# the last time seconds.
#
# The time of the last execution of the command will be set to the current time
# if it was executed, or if the last execution was less than "reset" seconds
# ago.  This is useful for riding events which occur in waves.
#
alias 1cmd (sec,cmd) {
	@ :foo = encode($tolower($cmd));
	@ :time = time();
	@ :eserv = 0 > servernum() ? [] : servernum();
	@ :reset = split(, $sec);
	@ :sec = shift(reset);
	@ :reset = shift(reset);
	if (!sec) {
		$cmd;
		return;
	} elsif (time - onecmd[$eserv][$foo][t] <= reset) {
		@ _ONECMD[$eserv][$foo][e] = time + sec;
		@ _ONECMD[$eserv][$foo][t] = time;
	} elsif (time - onecmd[$eserv][$foo][t] >= sec) {
		@ _ONECMD[$eserv][$foo][e] = time + sec;
		@ _ONECMD[$eserv][$foo][t] = time;
		$cmd;
	};
	if (time != _ONECMD[$eserv][lp] && !(++_ONECMD[$eserv][cnt] % 10)) {
		@ _ONECMD[$eserv] = time;
		foreach _ONECMD[$eserv] bar {
			if (_ONECMD[$eserv][$bar][e] < time) {
				@ _ONECMD[$eserv][$bar][t] = [];
				@ _ONECMD[$eserv][$bar][e] = [];
			};
		};
	};
};

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
stack push alias alias.tt;
alias alias.tt (cmd,op,args) {
	@ sar(gr/\${cmd}/${cmd}/args);
	@ sar(gr/\${op}/${op}/args);
	alias $args;
};
fe (q push fq unshift) cmd op {
	alias.tt $cmd $op ${cmd}1cmd (qo,qc,args) {
		@ :sn = servernum();
		@ :sn = sn < 0 ? [_] : sn;
		@ :argz = args;
		@ sar(gr/\\/\\\\/argz);
		@ sar(gr/\"/\\\"/argz);
		@ :qc = split(, $qc);
		fe ($qc) qqcc {
			if (0 <= findw("$argz" $qcmd[$sn][$qqcc])) {
				return;
			};
		};
		1cmd $qo ${cmd}cmd $shift(qc) $args;
	};
	alias.tt $cmd $op ${cmd}cmd (...) {
		@ :sn = servernum();
		@ :sn = sn < 0 ? [_] : sn;
		if (1 < #) {
#			@ :bar = [$1-];
#			@ ${op}(_QCMD.${sn}.$0 \"$msar(gr/\\/\\\\/\"/\\\"/bar)\");
			@ :foo = [$1-];
			@ :foo = ${op}(_QCMD.${sn}.$0 \"$msar(gr/\\/\\\\/\"/\\\"/foo)\");
		} else {
			@ :foo = [];
			if (1 == #) {
				@ foo = [$0];
			} elsif (islagged()) {
				@ :bar = [ ];
				# Do nothing if we're lagged.
				# This is meant to be a link to a
				# fictitious lag measurement script.
			} elsif (0 == #) {
				foreach _QCMD[$sn] bar {
					@ foo = bar;
					break;
				};
			};
			@ :bar = shift(_QCMD[$sn][$foo])
		};
		if (functioncall()) {
			return $msar(gr/\\\\/\\/\\\"/\"/bar);
		} elsif (@bar) {
			$msar(gr/\\\\/\\/\\\"/\"/bar);
			^timer -ref _QCMD.$sn -update 5 qcmd;
		} elsif (@foo) {
			^timer -ref _QCMD.$sn 5 qcmd;
		};
	};
};
stack pop alias alias.tt;

