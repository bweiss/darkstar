/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * HELP.DSC - Help system for Darkstar/EPIC4
 * Author: Brian Weiss <brian@epicsol.org> - 2001
 *         whitefang <thall@epicsol.org>
 *
 * Last modified: 10/11/01 (bmw)
 *
 * This was originally written by whitefang. He deserves all the credit.
 */

alias dhelp (...)
{
	@ :old_path = HELP_PATH
	
	^set HELP_PATH $twiddle($DS.HELP)
	
	if (@ && HELP_PROMPT == [OFF])
	{
		timer 0
		{
			^on ^help ^"*"
			//help
			^on ^help -"*"
		}
	}
			
	//help $*
	//help -wait
		
	^set HELP_PATH $old_path
}


/* bmw '01 */