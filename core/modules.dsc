#
# $Id$ */
# modules.dsc - DarkStar module system
# Copyright (c) 2002-2004 Brian Weiss
# See the 'COPYRIGHT' file for more information.
#

addconfig    AUTO_LOAD_MODULES away channel dcc formats misc newnick nickmgr nickcomp relay tabkey theme window;
addconfig -b SAVE_ON_UNLOAD 0;
addconfig -b LOAD_PROMPT 0;

addformat MODLIST_FOOTER -------------------------------------------------------;
addformat MODLIST_FOOTER1 $$G Available modules: $$numitems(_modules), Loaded modules: $$numitems(_loaded_modules);
addformat MODLIST_FOOTER2;
addformat MODLIST_HEADER #   Module           Version    Size  Loaded Auto-Load;
addformat MODLIST_HEADER1 -------------------------------------------------------;
addformat MODLIST_HEADER2;
addformat MODLIST_MODULE  $$[3]1 $$[16]2 $$[7]3 $$[-7]4    $${[$5] ? [\[*\]] : [\[\ \]]}     $${[$6] ? [\[*\]] : [\[ \]]};

#
# /AUTOLOAD [[-a|-d] <module> ...] ...
#
# Interface to /DSET AUTO_LOAD_MODULES. The -a and -d options specify which
# action to perform (add/delete). If neither is present then -a will be
# assumed.
#
alias autoload (args)
{
	^local action add;
	^local modlist $CONFIG.AUTO_LOAD_MODULES;

	if (!args) {
		dset AUTO_LOAD_MODULES;
		return;
	}

	while (:arg = shift(args))
	{
		switch ($arg)
		{
			(-a) {@ :action = [add]};
			(-d) {@ :action = [delete]};
			(\\*) {
				if (action == [add]) {
					for ii from 1 to $numitems(_modules) {
						@ push(:foo $getitem(_modules ${ii-1}));
					};
					for bar in ($foo) {
						if (findw($bar $modlist) == -1) {
							@ push(:modlist $bar);
						};
					};
				} else if (action == [delete]) {
					dset -AUTO_LOAD_MODULES;
					@ :modlist = [];
				};
			};
			(*) {
				if (action == [add] && findw($arg $modlist) == -1) {
					@ push(:modlist $arg);
				} else if (action == [delete]) {
					@ :modlist = remw($arg $modlist);
				};
			};
		};
	};

	if (modlist != CONFIG.AUTO_LOAD_MODULES) {
		dset AUTO_LOAD_MODULES $modlist;
	} else {
		dset AUTO_LOAD_MODULES;
	};
};

alias loadmod (modules)
{
	stack push set INPUT_PROMPT;

	if (!modules)
	{
		modlist;
		^local modules $"Enter modules to load: ";
		if (modules == [])
			return;
	}{
		# modlist takes care of this if there are no modules
		_build_modlist;
	};

	if (modules == [*])
	{
		@ :modules = [];
		for ii from 1 to $numitems(_modules) {
			@ push(:modules $getitem(_modules ${ii-1}));
		};
	}{
		@ :modules = getitems(_modules -1 $modules);
	};

	for module in ($modules)
	{
		^local modver $modinfo($module v);

		if (#modules > 1) {
			^set INPUT_PROMPT Loading modules [$pad($#modules . $progress)] \($module $modver\);
		};

		if (!(:retcode = _load_module($module)))
		{
			# Module loaded successfully
			@ :progress #= [*];
			@ push(:pass $module);
		}{
			# Module failed to load
			@ :progress #= [x];
			switch ($retcode)
			{
				(1) {xecho -c Error: _load_module: Not enough arguments};
				(2) {xecho -b -c Module is already loaded: $module};
				(3) {xecho -b -c Module not found: $module};
			};
		};

		if (#modules > 1) {
			^set INPUT_PROMPT Loading modules [$pad($#modules . $progress)] \($module $modver\);
		};
	};

	if (#pass == 1) {
		xecho -b -c Loaded module: $pass $modinfo($pass v);
	} else if (pass) {
		xecho -b -c Loaded $#pass modules: $pass;
	};

	stack pop set INPUT_PROMPT;
};

alias listmods (...)
{
	modlist $*;
};

alias modules (...)
{
	modlist;
};

alias modlist (void)
{
	_build_modlist;

	for var in (MODLIST_HEADER MODLIST_HEADER1 MODLIST_HEADER2) {
		if (FORMAT[$var]) {
			echo $fparse($var);
		};
	};

	for ii from 1 to $numitems(_modules)
	{
		@ :module = getitem(_modules ${ii-1});
		@ :file = _MODULE.$module;
		@ :version = _MODULE[$module][VERSION] ? _MODULE[$module][VERSION] : [-];
		@ :auto_load = match($module $CONFIG.AUTO_LOAD_MODULES) ? 1 : 0;
		@ :loaded = finditem(_loaded_modules $module) > -1 ? 1 : 0;
		if (FORMAT.MODLIST_MODULE) {
			echo $fparse(MODLIST_MODULE $ii $module $version $fsize($file) $loaded $auto_load);
		};
	};

	for var in (MODLIST_FOOTER MODLIST_FOOTER1 MODLIST_FOOTER2) {
		if (FORMAT[$var]) {
			echo $fparse($var);
		};
	};

	# Attempt to purge the auto-load list of modules that don't exist.
	for mod in ($CONFIG.AUTO_LOAD_MODULES)
	{
		if (mod != [*] && finditem(_modules $mod) < 0)
		{
			^local ask $'Remove unknown module "$mod" from the auto-load list? ';
			if (ask == [y])
			{
				@ CONFIG.AUTO_LOAD_MODULES = remw($mod $CONFIG.AUTO_LOAD_MODULES);
				xecho -b Removed $mod from the auto-load list;
			};
		};
	};
};

alias reloadmod (modules)
{
	if (!modules)
	{
		xecho -b Usage: /RELOADMOD <module> ...;
		return;
	};

	unloadmod $modules;
	loadmod $modules;
};

alias unloadmod (modules)
{
	stack push set INPUT_PROMPT;

	if (!modules)
	{
		echo #   Module;
		for ii from 1 to $numitems(_loaded_modules) {
			echo $[3]ii $getitem(_loaded_modules ${ii-1});
		};
		^local modules $"Enter modules to unload: ";
		if (modules == [])
			return;
	};

	if (modules == [*])
	{
		@ :modules = [];
		for ii from 1 to $numitems(_loaded_modules) {
			@ push(:modules $getitem(_loaded_modules ${ii-1}));
		};
	}{
		@ :modules = getitems(_loaded_modules -1 $modules);
	};

	for module in ($modules)
	{
		if (#modules > 1) {
			^set INPUT_PROMPT Unloading modules [$pad($#modules . $progress)] \($module\);
		};

		if (CONFIG.SAVE_ON_UNLOAD) {
			^save $module;
		};

		if (!(:retcode = _unload_module($module)))
		{
			# Module unloaded successfully
			@ :progress #= [*];
			@ push(:pass $module);
		}{
			# Module could not be unloaded
			@ :progress #= [x];
			switch ($retcode)
			{
				(1) {xecho -c Error: _unload_module: Not enough arguments};
				(2) {xecho -b -c Module is not loaded: $module};
			};
		};

		if (#modules > 1) {
			^set INPUT_PROMPT Unloading modules [$pad($#modules . $progress)] \($module\);
		};
	};

	if (#pass == 1) {
		xecho -b -c Unloaded module: $pass;
	} else {
		xecho -b -c Unloaded $#pass modules: $pass;
	};

	stack pop set INPUT_PROMPT;
};


alias _build_modlist (void)
{
	for dir in ($DS.MODULE_DIRS) {
		_scan_module_dir $dir;
	};
};

#
# Loads a module and its save file.
# Returns 0 on success and > 0 on failure.
#
alias _load_module (module, void)
{
	if (!module)
		return 1;

	if (finditem(_loaded_modules $module) > -1) {
		# Module is already loaded
		return 2;
	}

	if (finditem(_modules $module) < 0) {
		# Module not found
		return 3;
	};

	^assign MODULE.LOADING $module;

	if (_MODULE[$module][LOADER] == [pf]) {
		load -pf $_MODULE[$module];
	} else {
		load $_MODULE[$module];
	};

	if (fexist($DS.SAVE_DIR/$module) == 1) {
		^load $DS.SAVE_DIR/$module;
	};

	@ setitem(_loaded_modules $numitems(_loaded_modules) $module);

	# Hook the event so other modules can act on it
	hook LOADMOD $module;

	^assign -MODULE.LOADING;
	return 0;
};

#
# Scans a directory for modules and stores information about each one
# in the _MODULE structure and adds the name of the module to the _modules
# array. The top line of the file will be read and parsed for header tags.
# The currently supported tags are "version" and "loader" and should be in
# the form "<tag>:<value>". There are two possible values for the loader
# tag: "std" and "pf".
#
alias _scan_module_dir (dir, void)
{
	if (!dir) {
		echo Error: _scan_module_dir: Not enough arguments;
		return;
	};

	@ :dir = twiddle($dir);
	for file in ($glob($dir\/\*.dsm))
	{
		@ :name = before(-1 . $after(-1 / $file));

		# Restrict module names.
		@ :pass  = chr($jot($ascii(AZ)));
		@ :pass #= chr($jot($ascii(az)));
		@ :pass #= chr($jot($ascii(09)));
		if (strip($pass $name)) {
			echo Error: _scan_module_dir: Illegal module name: $name;
			return;
		};
		if (rmatch($name _* core ds module config format)) {
			echo Error: _scan_module_dir: The module name '$name' is reserved;
			return;
		};

		if ((:item = finditem(_modules $name)) > -1) {
			@ delitem(_modules $item);
			purge _MODULE.$name;
		};

		# Grab the module's header from the top of the file and parse it.
		if ((:fd = open($file R)) != -1)
		{
			@ :header = read($fd);
			@ close($fd);
			while (:tag = shift(header))
			{
				switch ($tag)
				{
					(version:*) {
						^assign _MODULE[$name][VERSION] $after(1 : $tag);
					};
					(loader:*) {
						@ :loader = after(1 : $tag);
						switch ($loader)
						{
							(std) (pf) {
								^assign _MODULE[$name][LOADER] $loader;
							}
							(*) {
								echo Warning: _scan_module_dir: Invalid loader tag: $loader;
							};
						};
					};
				};
			};
		};

		^assign _MODULE.$name $file;
		@ setitem(_modules $numitems(_modules) $name);
	};
};

#
# Unloads a module and cleans up after it.
# Returns 0 on success and > 0 on failure.
#
alias _unload_module (module, void)
{
	if (!module)
		return 1;

	@ :item = finditem(_loaded_modules $module);
	if (item < 0) {
		# Module is not loaded
		return 2;
	};

	^assign MODULE.UNLOADING $module;

	# Execute module's cleanup queue and purge all assign,
	# alias, and array structures that belong to this module.
	queue -do cleanup.$module;
	purge $module;
	purgealias $module;
	for array in ($getarrays($module\.*)) {
		@ delarray($array);
	};

	# Remove all metadata for this module.
	for ii from 0 to ${numitems(_DSET.$module) - 1}
	{
		@ :var = getitem(_DSET.$module $ii);
		^assign -CONFIG.$var;
		^assign -_DSET.$var;
	};
	for ii from 0 to ${numitems(_FSET.$module) - 1}
	{
		@ :var = getitem(_FSET.$module $ii);
		^assign -FORMAT.$var;
		^assign -_FSET.$var;
	};
	@ delarray(_DSET.$module);
	@ delarray(_FSET.$module);
	purge _MODINFO.$module;
	@ delitem(_loaded_modules $item);

	hook UNLOADMOD $module;

	^assign -MODULE.UNLOADING;
	return 0;
};

