/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * COMMANDS.DSC - Some useful commands for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *
 * Last modified: 12/23/01 (bmw)
 *
 * If you have any aliases you feel are useful enough to be in this file,
 * feel free to email me.
 */


#
# A file pager.  A demonstration of how to do something useful in ircII.
# This cheesy rip-off was written by hop in 1996.
# My apologies in advance to archon.
# Modified on Jan 25, 1999 as an example of how to use arglists.
# Modified on Oct 17, 2001 by Brian Weiss for use with Darkstar/EPIC4
#

alias more less

alias less (file, void)
{
	@ :winnum = winnum()

	if (file)
	{
		if (fexist($file) == 1)
		{
			_less $open($file R) ${winsize() - 1} $winnum
		}{
			xecho -b -w $winnum $file\: no such file.
		}
	}{
		xecho -b -w $winnum Usage: /less <filename>
	}
}

alias _less (fd, count, winnum default 0, void)
{
	^local line 0
	^local ugh

	while (!eof($fd) && (line++ < count))
	{
		@ ugh = read($fd)
		if (!eof($fd))
		{
			xecho -w $winnum $ugh
		}
	}

	if (!eof($fd))
	{
		@ LESS.FD = fd
		@ LESS.NL = count
		@ LESS.W  = winnum

		input_char "Enter q to quit, or anything else to continue "
		{
			if ([$0] != [q]) {_less $LESS.FD $LESS.NL $LESS.W}
		}
	}{
		@ close($file)
		for var in ($aliasctl(assign match LESS.))
		{
			^assign -$var
		}
	}
}

/*
 * /PURGE
 * Requested by whitefang.
 */
alias purge
{
      foreach $0 _purge
	{
            purge $0.$_purge
      }
      ^assign -$0
}

alias reload (void)
{
	@ :home = DS.HOME
	
	timer -del all

	for cnt from 1 to $numitems(loaded_modules)
	{
		@ :itm = cnt - 1
		queue -flush cleanup.$getitem(loaded_modules $itm)
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


/* bmw '01 */