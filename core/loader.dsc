/* $Id$ */
/*
 * loader.dsc - DarkStar module loader
 * Copyright (c) 2002, 2003 Brian Weiss
 * See the 'COPYRIGHT' file for more information.
 */

/****** USER ALIASES ******/

alias loadmod (modules)
{
	^local pass
	^local progress
	@ :oldprompt = INPUT_PROMPT
	@ :verbose = CONFIG.LOADMODULE_VERBOSE
	loader.build_modlist
	if (!modules) {
		modlist
		^local modules $"Modules to load? (1 2-4 ...) "
		if (modules == []) {
			return
		}
	}
	@ :modules = loader.which_mods(modules $modules)
	for module in ($modules) {
		if (!(:retcode = loader.load_module($module))) {
			/* Module loaded successfully */
			if (verbose) {
				@ :modver = modinfo($module v)
				xecho -b Loaded module: $module ${modver != [-] ? modver : []}
			} else {
				@ :progress = progress ## [.]
				push pass $module
				^set INPUT_PROMPT Loading modules [$[$#modules]progress] \($module $modinfo($module v)\)
			}
		} else {
			/* Module failed to load */
			@ :progress = progress ## [x]
			switch ($retcode) {
				(1) { echo Error: No modules found; }
				(2) { echo Error: Module is already loaded \($module\); }
				(3) { echo Error: Module not found: $module; }
				(*) { echo Error: Unknown \(module: $module\); }
			}
		}
	}
	if (!verbose) {
		if (oldprompt == []) {
			^set -INPUT_PROMPT
		} else {
			^set INPUT_PROMPT $oldprompt
		}
		xecho -b Loaded $#pass module${#pass == 1 ? [] : [s]}${#pass > 0 ? [ \($pass\)] : []}
	}
}

alias listmods modlist
alias modules modlist
alias modlist (void) {
	loader.build_modlist
	for var in (MODLIST_HEADER MODLIST_HEADER1 MODLIST_HEADER2) {
		if (FORMAT[$var]) {
			echo $fparse($var)
		}
	}
	for cnt from 0 to ${numitems(modules) - 1} {
		@ :num = cnt + 1
		@ :file = getitem(module_files $cnt)
		@ :module = getitem(modules $cnt)
		@ :version = getitem(module_versions $cnt)
		@ :auto_load = match($module $CONFIG.AUTO_LOAD_MODULES) ? 1 : 0
		@ :loaded = finditem(loaded_modules $module) > -1 ? 1 : 0
		if (FORMAT.MODLIST_MODULE) {
			echo $fparse(MODLIST_MODULE $num $module $version $fsize($file) $loaded $auto_load)
		}
	}
	for var in (MODLIST_FOOTER MODLIST_FOOTER1 MODLIST_FOOTER2) {
		if (FORMAT[$var]) {
			echo $fparse($var)
		}
	}
}

alias reloadmod (modules) {
	if (!modules) {
		xecho -b Usage: /RELOADMOD <module> ...
		return
	}
	unloadmod $modules
	loadmod $modules
}

alias unloadmod (modules) {
	^local pass
	^local progress
	@ :oldprompt = INPUT_PROMPT
	@ :verbose = CONFIG.LOADMODULE_VERBOSE
	if (!modules) {
		echo #   Module
		for cnt from 0 to ${numitems(loaded_modules) - 1} {
			@ :num = cnt + 1
			echo $[3]num $getitem(loaded_modules $cnt)
		}
		^local modules $"Modules to unload? (1 2-4 ...) "
		if (modules == []) {
			return
		}
	}
	@ :modules = loader.which_mods(loaded_modules $modules)
	for module in ($modules) {
		if (CONFIG.AUTO_SAVE_ON_UNLOAD) {
			^save $module
		}
		if (!(:retcode = loader.unload_module($module))) {
			/* Module unloaded successfully */
			if (verbose) {
				xecho -b Unloaded module: $module
			} else {
				@ :progress = progress ## [.]
				push pass $module
				^set INPUT_PROMPT Unloading modules [$[$#modules]progress] \($module $modinfo($module v)\)
			}
		} else {
			/* Module could not be unloaded */
			@ :progress = progress ## [x]
			switch ($retcode) {
				(1) { echo Error: No modules are currently loaded; }
				(2) { echo Error: Module is not loaded \($module\); }
				(*) { echo Error: Unknown \(module: $module\); }
			}
		}
	}
	if (!verbose) {
		if (oldprompt == []) {
			^set -INPUT_PROMPT
		} else {
			^set INPUT_PROMPT $oldprompt
		}
		xecho -b Unloaded $#pass module${#pass == 1 ? [] : [s]}${#pass > 0 ? [ \($pass\)] : []}
	}
}


/****** MODULE ALIASES ******/

/*
 * Handles module dependencies.
 * This is meant to be called by a module at load time.
 */
alias module.dep (depmods) {
	if (!(:module = after(-1 / $before(-1 . $word(1 $loadinfo()))))) {
		echo Error: module.dep: This command must be called at load time
		return
	}
	if (!depmods) {
		echo Error: module.dep: Not enough arguments \(module: $module\)
		return
	}
	for depmod in ($depmods) {
		if (finditem(loaded_modules $depmod) < 0) {
			if (finditem(modules $depmod) > -1) {
				if (CONFIG.AUTO_LOAD_DEPENDENCIES) {
					xecho -b Module $module depends on $depmod - Auto-loading...
					loadmod $depmod
				} else {
					^local tmp $'Module $module depends on $depmod - Load it now? [Yn] '
					if (tmp == []) {
						^local tmp Y
					}
					switch ($toupper($left(1 $tmp))) {
						(Y) { loadmod $depmod; }
						(*) { xecho -b Skipping dependency $depmod - Module may not work properly; }
					}
				}
			} else {
				xecho -b Warning: Unable to load dependency: Module not found: $depmod
			}
		}
	}
}

/*
 * This allows modules to force saved settings to be loaded before the module
 * is finished loading. Very useful for events happening at module load time
 * that depend on certain config settings. This should not be used until
 * after adding your config and format variables via {config|format}.add.
 */
alias module.load_saved_settings (void) {
	if (:module = after(-1 / $before(-1 . $word(1 $loadinfo())))) {
		^local save_file $DS.SAVE_DIR\/$module\.sav
		if (fexist($save_file) == 1) {
			^load $save_file
		}
	}
}


/****** INTERNAL ALIASES ******/

/*
 * This scans the module directories and compiles a list of modules.
 * Data about each module is stored in the three arrays: modules,
 * module_files, and module_versions. The module's version is grabbed
 * from the top line of the file and must be in the form of
 * "#version <versionstr>". If no version is specified, '-' will be used.
 */
alias loader.build_modlist (void) {
	@ delarray(modules)
	@ delarray(module_files)
	@ delarray(module_versions)
	for dir in ($DS.MODULE_DIR) {
		^local dir $twiddle($dir)
		for file in ($glob($dir\/\*.dsm)) {
			^local name $before(-1 . $after(-1 / $file))
			if (name == [core]) {
				echo Error: loader.build_modlist: The name "core" is reserved
				return
			}
			/* Get the module's version */
			^local fd $open($file R)
			^local line $read($fd)
			@ close($fd)
			^local ver ${match(#version $line) ? word(1 $line) : [-]}
			/* If a module with the same name already exists, remove it
			   so that the new module overrides the old. */
			if ((:item = matchitem(modules $name)) > -1) {
				@ delitem(modules $item)
				@ delitem(module_files $item)
				@ delitem(module_versions $item)
			}
			@ setitem(modules $numitems(modules) $name)
			@ setitem(module_files $numitems(module_files) $file)
			@ setitem(module_versions $numitems(module_versions) $ver)
		}
	}
}

/*
 * Loads a module including theme and saved settings.
 * Returns 0 on success and > 0 on failure.
 */
alias loader.load_module (module, void) {
	if (!numitems(modules)) {
		/* No modules found */
		return 1
	}
	if (match(%.% $module)) {
		^local module $before(-1 . $module)
	}
	if (finditem(loaded_modules $module) > -1) {
		/* Module already loaded */
		return 2
	}
	if ((:item = finditem(modules $module)) > -1) {
		^local file $getitem(module_files $item)
		^local save_file $DS.SAVE_DIR\/$module\.sav
		^local theme_file $getitem(theme_dirs $finditem(themes $DS.THEME))$module
		load $file
		if (fexist($save_file) == 1) {
			^load $save_file
		}
		if (fexist($theme_file) == 1) {
			^load $theme_file
		}
		@ setitem(loaded_modules $numitems(loaded_modules) $module)
		/* Hook the event so other modules can act on it */
		hook LOADMOD $module
		return 0
	}
	/* No such module */
	return 3
}

/*
 * Unloads a module and cleans up after it.
 * Returns 0 on success and > 0 on failure.
 */
alias loader.unload_module (module, void) {
	if (!numitems(loaded_modules)) {
		/* No modules are loaded */
		return 1
	}
	if (match(%.% $module)) {
		^local module $before(-1 . $module)
	}
	if ((:item = finditem(loaded_modules $module)) > -1) {
		queue -do cleanup.$module
		purge $module
		purgealias $module
		for array in ($getarrays($module\.*)) {
			@ delarray($array)
		}
		for var in ($DSET.MODULES[$module]) {
			^assign -CONFIG.$var
			^assign -DSET.CONFIG.$var
			^assign -DSET.BOOL.$var
		}
		for var in ($FSET.MODULES[$module]) {
			^assign -FORMAT.$var
			^assign -FSET.FORMAT.$var
		}
		^assign -DSET.MODULES.$module
		^assign -FSET.MODULES.$module
		purge MODINFO[$module]
		@ delitem(loaded_modules $item)
		hook UNLOADMOD $module
		return 0
	}
	/* Module is not loaded */
	return 2
}

/*
 * Converts any number, or range of numbers, to its module equivalent. It can
 * be passed any combination of module names, numbers, and ranges of numbers.
 * Returns only module names.
 */
alias loader.which_mods (array, args) {
	^local modules
	for tmp in ($args) {
		if (isnumber($strip(- $tmp))) {
			if (match(%-% $tmp)) {
				^local start $before(- $tmp)
				^local end $after(- $tmp)
				if (start < end && start < numitems($array) && end <= numitems($array)) {
					for cnt from $start to $end {
						push modules $getitem($array ${cnt - 1})
					}
				} else {
					echo Error: loader.which_mods\(\): Illegal range specified
				}
			} else {
				if (:mod = getitem($array ${tmp - 1})) {
					push modules $mod
				} else {
					echo Error: loader.which_mods\(\): Module not found: $tmp
				}
			}
		} else {
			push modules $tmp
		}
	}
	return $modules
}


/****** STARTUP ******/

if (CONFIG.AUTO_LOAD_PROMPT) {
	^local modules
	/* Keep things quiet while we list available modules */
	for hook in (250 251 252 254 255 265 266) {
		^on ^$hook ^"*"
	}
	^stack push set SUPPRESS_SERVER_MOTD
	^set SUPPRESS_SERVER_MOTD ON
	modlist
	^local mods $"Modules to load? ([A]uto / [N]one / 1 2-4 ...) [A] "
	switch ($toupper($mods)) {
		() (A) { ^local modules $CONFIG.AUTO_LOAD_MODULES; }
		(N)    {#}
		(*)    { ^local modules $loader.which_mods(modules $mods); }
	}	
	wait -cmd for hook in (250 251 252 254 255 265 266) {
		^on ^$hook -"*"
	}
	^stack pop set SUPPRESS_SERVER_MOTD
	if (modules) {
		loadmod $modules
	}
} else if (CONFIG.AUTO_LOAD_MODULES) {
	loadmod $CONFIG.AUTO_LOAD_MODULES
}


/* EOF */