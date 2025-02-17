# $Id$
#	Copyright (c) 2007 BlackJac@EFNet
#
#	Version: 1.2.2007.09.28.1
#
#	This script simulates the history feature of epic4 for epic5. The
#	behavior and key bindings should be nearly identical to the original.
#	Several significant improvements have been made over the original epic4
#	implementation.
#
#	Settings:
#		set history [0|<positive integer>]
#			Controls the maximum number of entries to be stored in
#			the client's history buffer. Setting it to 0 purges the
#			history buffer and disables command history.
#		set history_circleq [on|off|toggle]
#			Controls the behavior of history browsing when you reach
#			the beginning or end of the buffer. If set to on, when
#			you reach the beginning of the buffer and press the
#			backward_history keybinding (defaulted to the up arrow)
#			again, the history will circle back to the end of the
#			buffer. In addition, when you reach the end of the
#			buffer and press the forward_history keybinding
#			(defaulted to the down arrow) again, the history will
#			circle back to the beginning of the buffer.
#		set history_persistent [on|off|toggle]
#			Controls whether the current session's history buffer
#			will be saved on exit and read back into memory the next
#			time the script is loaded.
#		set history_remove_dupes [on|off|toggle]
#			Controls whether history buffer entries that are exact
#			duplicates of the most recent entry are removed from the
#			buffer.
#		set history_save_file <filename>
#			Default filename to use when saving the current history
#			buffer or reading a previous buffer and adding it to the
#			current buffer.
#		set history_save_position [on|off|toggle]
#			Controls whether the backward_history or forward_history
#			keybindings will start scrolling through the history
#			buffer from the spot where a previous
#			/!<indexnum|pattern> match was found, or from the most
#			recent history buffer entry.
#		set history_timestamp [on|off|toggle]
#			Controls whether /history displays the timestamp of each
#			command.
#
#	Commands:
#		/history [<indexnum>]
#			Returns a list of all commands in the history buffer, or
#			all commands up to <indexnum>.
#		/!<indexnum|pattern>
#			Retrieves history buffer entries and outputs them to the
#			input line. Use /!<indexnum> to retrieve <indexnum> or
#			/!<pattern> to retrieve the most recent entry matching
#			<pattern>.
#
#	Functions:
#		$historyctl(add <text>)
#			Adds <text> to the next available index number in the
#			history buffer. 
#			Returns 0 if the history buffer is disabled.
#			Returns 1 if successful.
#		$historyctl(delete <indexnum>)
#			Removes <indexnum> from the history buffer.
#			Returns -2 if the history buffer is disabled.
#			Returns -1 if <indexnum> does not exist.
#			Returns 0 if successful.
#		$historyctl(get <indexnum>)
#			Returns the history buffer item <indexnum> if it exists,
#			or nothing.
#		$historyctl(index <indexnum>)
#			Moves the history buffer scrollback pointer to item
#			<indexnum>.
#			Returns 0 if <indexnum> does not exist.
#			Returns 1 if successful.
#		$historyctl(read [<filename>])
#			Reads into the history buffer the contents of <file> or
#			HISTORY_SAVE_FILE if none is specified.
#			Returns nothing if the read failed.
#			Returns > 0 if the read succeeds.
#		$historyctl(reset)
#			Clears the entire history buffer.
#			Returns -1 if the history buffer does not exist.
#			Returns 0 if successful.
#		$historyctl(save [<filename>])
#			Writes the current history buffer to <file> or
#			HISTORY_SAVE_FILE if none is specified.
#			Returns nothing if the write failed.
#			Returns > 0 if the write succeeds.
#		$historyctl(set <buffer size>)
#			Sets the size of the history buffer. Setting it to 0
#			purges the history buffer and disables command history.

#package history;

alias history (index, void) {
	xecho -b -c Command History:;
	if (index > (:numitems = numitems(array.history)) || !index) {
		@ index = numitems;
	};
	if (index > 0) {
		fe ($jot(0 ${index - 1} 1)) hh {
			@ :item = getitem(array.history $hh);
			xecho -c $hh${getset(history_timestamp) == 'on' ? "  \[$word(3 $stime($word(0 $item)))\]  " : "\: "}$restw(1 $item);
		};
	};
};

alias history.add (...) {
	if (@) {
		if (getset(history_remove_dupes) == 'on') {
			@ delitems(array.history $getmatches(array.history % $*));
			@ delitems(array.history $getmatches(array.history % $* ));
		};
		if (numitems(array.history) == history) {
			@ delitem(array.history 0);
		};
		@ setitem(array.history $numitems(array.history) $time() $*);
		@ history.index = '';
	};
};

alias history.erase (void) {
	@ history.index = '';
	parsekey reset_line;
};

alias history.get (direction, void) {
	if (direction == 1) {
		if (@L && @history.index == 0) {
			history.add $L;
		};
		if ((history.index == (:numitems = numitems(array.history) - 1) || @history.index == 0)) {
			if (getset(history_circleq) == 'on') {
				history.show 0;
			} else {
				history.erase;
			};
		} else if (history.index < numitems && @history.index) {
			history.show ${history.index + 1};
		};
	} else if (direction == -1) {
		if (@L && @history.index == 0) {
			history.add $L;
			@ history.index = numitems(array.history) - 1;
		};
		if ((history.index == 0 && getset(history_circleq) == 'on') || @history.index == 0) {
			history.show ${numitems(array.history) - 1};
		} else if (history.index > 0) {
			history.show ${history.index - 1};
		};
	};
};

alias history.shove (void) {
	history.add $L;
	parsekey reset_line;
};

alias history.show (index, void) {
	if (@index) {
		@ history.index = index;
		parsekey reset_line $restw(1 $getitem(array.history $history.index));
	};
};

alias historyctl (action, ...) {
	switch ($action) {
		(add) {
			if (history) {
				history.add $*;
				return 1;
			};
			return 0;
		};
		(delete) {
			@ delitem(array.history $0);
		};
		(get) {
			return $restw(1 $getitem(array.history $0));
		};
		(index) {
			if (strlen($getitem(array.history $0))) {
				@ history.index = *0;
				return 1;
			};
			return 0;
		};
		(read) {
			if ((:fd = open("${*0 ? *0 : getset(history_save_file)}" R)) > -1) {
				while (:line = read($fd)) {
					if (numitems(array.history) == history) {
						@ delitem(array.history 0);
					};
					@ setitem(array.history $numitems(array.history) $line);
				};
				@ close($fd);
				return $fd;
			};
		};
		(reset) {
			@ history.index = '';
			@ delarray(array.history);
		};
		(save) {
			if ((:fd = open("${*0 ? *0 : getset(history_save_file)}" W)) > -1) {
				fe ($jot(0 ${numitems(array.history) - 1} 1)) hh {
					@ write($fd $getitem(array.history $hh));
				};
				@ close($fd);
				return $fd;
			};
		};
		(set) {
			^set history $0;
			return 1;
		};
	};
};

alias sendline (...) {
	if (@) {
		history.add $*;
		//sendline $*;
	};
};

@ bindctl(function BACKWARD_HISTORY create "history.get -1");

@ bindctl(function ERASE_HISTORY create history.erase);

@ bindctl(function FORWARD_HISTORY create "history.get 1");

@ bindctl(function SHOVE_TO_HISTORY create history.shove);

fe (N [OB [[B) hh {
	@ bindctl(sequence ^$hh set forward_history);
};

fe (P [OA [[A) hh {
	@ bindctl(sequence ^$hh set backward_history);
};
                
@ bindctl(sequence ^U set erase_history);

^on ^input "/!*" {
	@ :find = after(! $0);
	if (isnumber($find)) {
		if (:found = getitem(array.history $find)) {
			xtype -l $restw(1 $found)${*1 ? "$1-" : ""};
		} else {
			xecho -b -c No such history entry: $find;
		};
	} else if (:found = getmatches(array.history % /$find*) ## ' ' ## getmatches(array.history % $find*)) {
		@ :index = rightw(1 $numsort($found));
		if (getset(history_save_position) == 'on') {
			@ history.index = index;
		};
		xtype -l $restw(1 $getitem(array.history $index))${*1 ? " $1-" : ""};
	} else {
		xecho -b -c No match;
	};
};

addset history int {
	if (*0 == 0) {
		@ delarray(array.history);
		@ history.index = '';
		^bind ^] nothing;
		^on #input 2 -"*";
		^on #input 2 -"/!*";
	} else if (@) {
		if (numitems(array.history) > history) {
			until (numitems(array.history) == history) {
				@ delitem(array.history 0);
			};
		};
		^bind ^] shove_to_history;
		^on #-input 2 "*" {
			history.add $*;
		};
		^on #-input 2 "/!*" #;
	};
};

set history 150;

addset history_circleq bool;

set history_circleq on;

addset history_persistent bool {
	if (*0 == 'on') {
		^on #-exit 2 "*" {
			@ historyctl(save $getset(history_save_file));
		};
	} else if (@) {
		^on #exit 2 -"*";
	};
};

set history_persistent off;

addset history_save_file str;

set history_save_file ~/.epic_history;

addset history_remove_dupes bool;

set history_remove_dupes off;

addset history_save_position bool;

set history_save_position on;

addset history_timestamp bool;

set history_timestamp off;

if (getset(history_persistent) == 'on' && fexist("$getset(history_save_file)") == 1) {
	@ historyctl(read $getset(history_save_file));
};
