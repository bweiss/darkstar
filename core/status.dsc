/* $Id$ */
/*
 * status.dsc - Interface to change the status bar
 * Copyright (c) 2002 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 */

/****** USER ALIASES ******/

/*
 * /STATUS [-q] [statbarname]
 * Attempts to change the current status bar. If [statbarname] is not specified
 * the user will be prompted to choose one from a list. The 'q' option tells
 * /status to be silent about the change. This was mostly added so that themes
 * could change statbars quietly.
 */
alias sbar status
alias statbar status
alias status (args)
{
	/* Check for quiet option */
	if (left(1 $word(0 $args)) == [-]) {
		@:sbar = word(1 $args)
		if (word(0 $args) == [-q]) {
			@:quiet = 1
		}
	} else {
		@:sbar = args
	}

	status.buildlist

	if (!sbar) {
		status.buildlist
		status.display
		^assign sbar $"Which status bar would you like to use? "
		if (!sbar) {
			return
		}
	}

	if (isnumber($sbar) && sbar > 0 && sbar <= numitems(status)) {
		@:item = sbar - 1
		@:sbar = getitem(status $item)
	}

	if (quiet) {
		@ status.change($sbar)
	} else {
		switch ($status.change($sbar)) {
			(0) {xecho -b Now using status: $sbar}
			(1) {xecho -b Error: status.change\(\): Status bar not found: $sbar}
			(*) {xecho -b Error: status.change\(\): Unknown}
		}
	}
}


/****** INTERNAL ALIASES ******/

/*
 * Scans the status directories and dumps all available statbars into an array
 * containing the name (status) and the complete filename (status_files).
 */
alias status.buildlist (void)
{
	@ delarray(status)
	@ delarray(status_files)

	for dir in ($DS.STATUS_DIR) {
		@:dir = twiddle($dir)
		if (fexist($dir) == 1) {
			for file in ($glob($dir\/\*)) {
				@:lastc = mid(${strlen($file) - 1} 1 $file)
				unless (lastc == [/]) {
					@:name = after(-1 / $file)
					@ setitem(status $numitems(status) $name)
					@ setitem(status_files $numitems(status_files) $file)
				}
			}
		}
	}
}

/*
 * Everything involved with actually changing the status.
 * Returns 0 on success and > 0 on failure.
 */
alias status.change (sbar, void)
{
	@:file = getitem(status_files $finditem(status $sbar))
	if (fexist($file) == 1)
	{
		load $file

		/*
		 * Turn on/off the double status bar according to
		 * STATUS.DOUBLE. Any windows in the single_status
		 * array are exempt from being double.
		 */
		for refnum in ($winrefs()) {
			@:name = winnam($refnum)
			if (STATUS.DOUBLE) {
				unless (matchitem(single_status $name) > -1) {
					^window $refnum double on
				}
			} else {
				^window $refnum double off
			}
		}

		parsekey refresh_screen
		@ DS.SBAR = after(-1 / $file)
		return 0
	}

	return 1
}

alias status.display (void)
{
	xecho -b Available status bars:
	for cnt from 0 to ${numitems(status) - 1} {
		@:name = getitem(status $cnt)
		@:num = cnt + 1
		echo $[3]num $name
	}
}


/* EOF */