/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * STATBAR.DSC - Statbar manager for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 */

alias sbar status
alias statbar status

alias status (sbar, void)
{
	@ :status.files = glob($DS.STATUS_DIR\/\*))

	if (sbar && findw($sbar $status.files))
	{
		load $DS.STATUS_DIR/$sbar
		parsekey refresh_screen
		xecho -b Now using status [$sbar]
	}{
		xecho -b Available status bars:
		for status in ($status.files)
		{
			xecho -b  $after(-1 / $status)
		}
		xecho -b Usage: /statbar <sbar>
	}
}


/* bmw '01 */