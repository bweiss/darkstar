/*     _             _        _
 *  __| | __ _  _ _ | |__ ___| |_  __ _  _ _
 * / _` |/ _` || '_|| / /(_-<|  _|/ _` || '_|
 * \__,_|\__,_||_|  |_\_\/__/ \__|\__,_||_|
 *
 * HELP.DSC - Help system for Darkstar/EPIC4
 * Author: Brian Weiss <brian@got.net> - 2001
 *
 * Special thanks to WhiteDrgn for this code.
 */

alias dhelp (...)
{
	@ :old_path = HELP_PATH
	
	^set HELP_PATH $twiddle($DS.HELP_DIR)
	
	if (@ && HELP_PROMPT == [OFF])
	{
		timer 0
		{
			^on ^help ^"*"
			$(K)$(K)help
			^on ^help -"*"
		}
	}
			
	$(K)$(K)help $*
	$(K)$(K)help -wait
		
	^set HELP_PATH $old_path
}


/* bmw '01 */