####    autopilot/BendixPB20.nas help-functions adapted for VC10                                ####
####    Author: Markus Bulik                                                                   ####
####    This file is licenced under the terms of the GNU General Public Licence V2 or later    ####
##############################################################################
##                                                                          ##
## AP - routines for 'Bendix PB 20' autopilot system                        ##
##                                                                          ##
##############################################################################


### Bendix PB 20 ###
# Knobs:
# /autopilot/Bendix-PB-20/controls/active : true/false
# VC10 These are the previous     /alt-active : true/false
# /autopilot/Bendix-PB-20/controls/ALT-active : true/false
# VC10 These are the previous     /mode-selector : 0: NAV, 1: HDG, 2: MAN, 3: LOC VOR, 4: GS AUTO, 5: GS MAN
# /autopilot/Bendix-PB-20/controls/mode-selector : 0: HDG, 1: MAN, 2: LOC VOR, 3: GS AUTO, 4: GS MAN 5:FLARE
# /autopilot/Bendix-PB-20/settings/pitch-wheel-deg : -30 .. 30
# /autopilot/Bendix-PB-20/settings/turn : -35 .. 35

# init
var listenerApPB20InitFunc = func {
	# do initializations of new properties
  setprop("autopilot/Bendix-PB-20/controls/active", 0);
	setprop("autopilot/Bendix-PB-20/controls/ALT-active", 0);
  setprop("autopilot/Bendix-PB-20/controls/mode-selector", 1);
	setprop("autopilot/Bendix-PB-20/settings/turn", 0);
	setprop("autopilot/Bendix-PB-20/settings/pitch-wheel-deg", 0);
	setprop("autopilot/Bendix-PB-20/mutex", "");
}
setlistener("sim/signals/fdm-initialized", listenerApPB20InitFunc);

# Mutex - for synchronization of the listener-events
var bendixPB20MutexSet = func(value) {
	setprop("autopilot/Bendix-PB-20/mutex", value);
}
var bendixPB20MutexReset = func {
	setprop("autopilot/Bendix-PB-20/mutex", "");
}
var bendixPB20MutexResetFunc = func {
	if (getprop("autopilot/Bendix-PB-20/mutex") != "") {
		settimer(bendixPB20MutexReset, 0.2);
	}
}
setlistener("autopilot/Bendix-PB-20/mutex", bendixPB20MutexResetFunc);

# Active-switch
var     bendixPB20ActivePrev = 0;
var listenerApPB20ActiveFunc = func {
	if (  bendixPB20ActivePrev == 0) {
	  if ( (getprop("autopilot/Bendix-PB-20/controls/AP-1active") == 1)
        or (getprop("autopilot/Bendix-PB-20/controls/AP-2active") == 1) ) {
      setprop("autopilot/Bendix-PB-20/controls/active", 1);
    }
    else { 
      setprop("autopilot/Bendix-PB-20/controls/active", 0);
    }    
		if (getprop("autopilot/Bendix-PB-20/controls/active") == 1) {
			if (getprop("autopilot/Bendix-PB-20/mutex") == "") {
				##bthp VC10 1 is the new MAN  ##setprop("autopilot/Bendix-PB-20/controls/mode-selector", 2);
				setprop("autopilot/Bendix-PB-20/controls/mode-selector", 1);
			}
		}
	}
	bendixPB20ActivePrev = getprop("autopilot/Bendix-PB-20/controls/active");
}
setlistener("autopilot/Bendix-PB-20/controls/active"    , listenerApPB20ActiveFunc);
setlistener("autopilot/Bendix-PB-20/controls/AP-1active", listenerApPB20ActiveFunc);
setlistener("autopilot/Bendix-PB-20/controls/AP-2active", listenerApPB20ActiveFunc);

# Mode-selector
#
# !!! FEHLER: bei zurückschalten von Mode 4,5 auf 3,2,1 bleibt GS eingeschaltet anstatt ALT (bei eingeschaltetem Alt-Switch) !!!
##GooTxlate ERROR: when switching back from Mode 4.5 to 3.2.1, GS remains switched on instead of ALT (with switched on Alt-Switch) 
## Means for VC10 the numbers for modes are different
#
var listenerApPB20ModeFunc = func {
  #bthp  print("listenerApPB20ModeFunc");

	if (	(getprop("autopilot/Bendix-PB-20/mutex") == "" )   or
    		(getprop("autopilot/Bendix-PB-20/mutex") == "MODE") ) {
		bendixPB20MutexSet("MODE");
	}
	else {
		return;
	}

  #bthp VC10 Gate either AP1 or Ap2 active to common prop
	if (   ((getprop("autopilot/Bendix-PB-20/controls/AP-1active") or 0) == 1)
      or ((getprop("autopilot/Bendix-PB-20/controls/AP-2active") or 0) == 1) ) {
    setprop("autopilot/Bendix-PB-20/controls/active", 1);
  }
  else {
    setprop("autopilot/Bendix-PB-20/controls/active", 0);
  }

	if (getprop("autopilot/Bendix-PB-20/controls/active") == 1) {
		#  print ("-> listenerApPB20ModeFunc -> Mode-selector=: ", 
    #        getprop("autopilot/Bendix-PB-20/controls/mode-selector"));

		if (	getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 0) {
			# HDG - Mode

			setprop("autopilot/locks/heading", "dg-heading-hold");

			# resets
			if (getprop("autopilot/Bendix-PB-20/controls/ALT-active") == 0) {
				setprop("autopilot/locks/altitude", "");
			}
			else {
				setprop("autopilot/locks/altitude", "altitude-hold");
			}
			setprop("autopilot/locks/passive-mode", 0);
			setprop("autopilot/locks/flare-mode", 0);
		}
		if (getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 1) {
			# MAN - Mode

			#var rollKnobDeg = getprop("instrumentation/turn-indicator/indicated-turn-rate") * 36.63;
			var rollKnobDeg = 0.0;
			setprop("autopilot/Bendix-PB-20/settings/turn", rollKnobDeg);
			listenerApPB20MANRollFunc();

			setprop("autopilot/locks/heading", "wing-leveler");

			if (getprop("autopilot/Bendix-PB-20/controls/ALT-active") == 0) {
				setprop("autopilot/Bendix-PB-20/settings/pitch-wheel-deg", getprop("orientation/pitch-deg"));
				listenerApPB20MANPitchFunc();

				setprop("autopilot/locks/altitude", "pitch-hold");
			}
			else {
				setprop("autopilot/locks/altitude", "altitude-hold");
			}

			# resets
			setprop("autopilot/locks/passive-mode", 0);
			setprop("autopilot/locks/flare-mode", 0);
		}
		if (getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 2) {
			# LOC VOR - Mode

			setprop("autopilot/locks/heading", "nav1-hold");

			# resets
			if (getprop("autopilot/Bendix-PB-20/controls/ALT-active") == 0) {
				setprop("autopilot/locks/altitude", "");
			}
			else {
				setprop("autopilot/locks/altitude", "altitude-hold");
			}
			setprop("autopilot/locks/passive-mode", 0);
			setprop("autopilot/locks/flare-mode", 0);
		}
		if (getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 3) {
			# GS AUTO - Mode

			setprop("autopilot/locks/heading", "nav1-hold");
			setprop("autopilot/locks/altitude", "gs1-hold");

			# resets
			setprop("autopilot/locks/passive-mode", 0);
			setprop("autopilot/Bendix-PB-20/controls/ALT-active", 0);
			setprop("autopilot/locks/flare-mode", 0);
		}
		if (getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 4) {
			# GS MAN - Mode

			setprop("autopilot/locks/heading", "nav1-hold");
			if (getprop("autopilot/Bendix-PB-20/controls/ALT-active") == 0) {
				setprop("autopilot/locks/altitude", "");
			}
			else {
				setprop("autopilot/locks/altitude", "altitude-hold");
			}

			gsMANAltControl();

			# resets
			setprop("autopilot/locks/passive-mode", 0);
			setprop("autopilot/locks/flare-mode", 0);
		}
    
    if (getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 5) {
			# FLARE  Mode
			setprop("autopilot/locks/flare-mode", 1);
		  # resets
			setprop("autopilot/locks/altitude", "");
			setprop("autopilot/locks/heading", "");
		}
    if (getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 6) {
      # GPS NAV - Mode

			if (  getprop("autopilot/route-manager/active") == 1 and 
           getprop("autopilot/route-manager/airborne") == 1) {
				setprop("autopilot/locks/passive-mode", 1);

				# resets
				setprop("autopilot/locks/altitude", "");
				setprop("autopilot/locks/heading", "");
			}
			else {
				gui.popupTip("Flare needs at least RM and Airborne ");
			}
		}
	}
  else {
		# switched off
		setprop("autopilot/locks/heading", "");
		setprop("autopilot/locks/altitude", "");
		setprop("autopilot/internal/wing-leveler-target-roll-deg", 0.0);
		setprop("autopilot/locks/passive-mode", 0);
		setprop("autopilot/locks/speed", "");	# for compatibility only (Bendix-PB-20 don't have speed-mode)
	}
}

##bthp VC10 setlistener("autopilot/Bendix-PB-20/controls/active", listenerApPB20ModeFunc, 1,0);
setlistener("autopilot/Bendix-PB-20/controls/AP-1active",         listenerApPB20ModeFunc, 1,0);
setlistener("autopilot/Bendix-PB-20/controls/AP-2active",         listenerApPB20ModeFunc, 1,0);
setlistener("autopilot/Bendix-PB-20/controls/mode-selector",      listenerApPB20ModeFunc, 1,0);

# switches off 'altitude-hold' if GS is in range and all other conditions are satisfied
var gsMANAltControl = func {
  if (	getprop("autopilot/Bendix-PB-20/controls/active") == 1
      and ( 	 getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 4) ) {
    if (getprop("instrumentation/nav[0]/gs-in-range") == 0) {
		 	settimer(gsMANAltControl, 0.2);
		}
    else {
		 	setprop("autopilot/locks/altitude", "");
    }
	}
}


# MAN - Mode - roll-selector
var listenerApPB20MANRollFunc = func {
  # if roll-knob-deg turn, the mode selector jump to mode 1 MAN
	setprop("autopilot/Bendix-PB-20/controls/mode-selector", 1);

	if (	getprop("autopilot/Bendix-PB-20/controls/active") == 1 and
       (getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 1) ) {
	  setprop("autopilot/internal/wing-leveler-target-roll-deg", getprop("autopilot/Bendix-PB-20/settings/turn"));
	}
}

setlistener("autopilot/Bendix-PB-20/settings/turn", listenerApPB20MANRollFunc);

# MAN - Mode - pitch-selector
var listenerApPB20MANPitchFunc = func {

	if (	getprop("autopilot/Bendix-PB-20/controls/active") == 1 and
     (getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 1) ) {
	  if (getprop("autopilot/Bendix-PB-20/controls/ALT-active") == 0) {
		   var pitchDeg = getprop("autopilot/Bendix-PB-20/settings/pitch-wheel-deg");
  	   pitchDeg = (pitchDeg > 30 ? 30 : pitchDeg);
	     pitchDeg = (pitchDeg < -30 ? -30 : pitchDeg);
	     setprop("autopilot/settings/target-pitch-deg", pitchDeg);
	  }
  }
}

setlistener("autopilot/Bendix-PB-20/settings/pitch-wheel-deg", listenerApPB20MANPitchFunc);

# ALT switch
var listenerApPB20AltFunc = func {

	if (getprop("autopilot/Bendix-PB-20/mutex") == "") {
		bendixPB20MutexSet("PB20-ALT");
	}
	else {
		return;
	}

	if (getprop("autopilot/Bendix-PB-20/controls/active") == 1) {
		if (getprop("autopilot/Bendix-PB-20/controls/ALT-active") == 1) {

			# set altitude-hold-value to the actual altitude plus an offset dependent on vspeed

			var vspeed = getprop("velocities/vertical-speed-fps");
			var altOffset = vspeed * 5;	# ft climed/falled in 5 seconds

			var altitudeFt = getprop("instrumentation/altimeter/indicated-altitude-ft") + altOffset;
			setprop("autopilot/settings/target-altitude-ft", altitudeFt);

			setprop("autopilot/locks/altitude", "altitude-hold");
		}
    else {
			if (getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 1) {
				setprop("autopilot/locks/altitude", "pitch-hold");
			}
			else {
				if (getprop("autopilot/locks/altitude") == "altitude-hold") {
					setprop("autopilot/locks/altitude", "");
				}
			}
		}
	}
  else {
		setprop("autopilot/locks/altitude", "");
	}
  #bthp print("exit listenerApPB20AltFunc ap/lcks/alti: ", getprop("autopilot/locks/altitude"),
   #          "  ALT-active: ", getprop("autopilot/Bendix-PB-20/controls/ALT-active") );
}

setlistener("autopilot/Bendix-PB-20/controls/ALT-active", listenerApPB20AltFunc);

# settings from FG-menu (F11)

listenerApPB20SetHeadingFunc = func {

	if (	getprop("autopilot/Bendix-PB-20/mutex") == "" or
		getprop("autopilot/Bendix-PB-20/mutex") == "PASSIVE") {
		bendixPB20MutexSet("HEADING");
	}
	else {
		return;
	}

	menuSwitchBendixPB20();
}
setlistener("autopilot/locks/heading", listenerApPB20SetHeadingFunc);

listenerApPB20SetPassiveModeFunc = func {

	# unfortunalety 'passive-mode' is triggered many times, we only need to act if it's wsitched to '1'
	if (	getprop("autopilot/Bendix-PB-20/mutex") == "" and
		getprop("autopilot/locks/passive-mode") == 1) {
		bendixPB20MutexSet("PASSIVE");
	}
	else {
		return;
	}

	if (getprop("autopilot/locks/passive-mode") == 1) {
		if (getprop("autopilot/route-manager/active") == 1 and getprop("autopilot/route-manager/airborne") == 1) {
			setprop("autopilot/Bendix-PB-20/controls/active", 1);
			setprop("autopilot/Bendix-PB-20/controls/mode-selector", 2);
		}
		else {
			gui.popupTip("Must be Airborne and a Route must be active for AP Passive mode");
			setprop("autopilot/locks/passive-mode", 0);
		}
	}
}
setlistener("autopilot/locks/passive-mode", listenerApPB20SetPassiveModeFunc);

listenerApPB20SetAltitudeFunc = func {

	if (	getprop("autopilot/Bendix-PB-20/mutex") == "" or
		getprop("autopilot/Bendix-PB-20/mutex") == "PASSIVE") {
		bendixPB20MutexSet("ALT");
	}
	else {
		return;
	}

	if (getprop("autopilot/locks/altitude") == "altitude-hold") {
		setprop("autopilot/Bendix-PB-20/controls/active", 1);
		setprop("autopilot/Bendix-PB-20/controls/ALT-active", 1);
		if (getprop("autopilot/Bendix-PB-20/controls/mode-selector") == 1) {
			setprop("autopilot/locks/heading", "wing-leveler");
		}
	}
	else {
		setprop("autopilot/Bendix-PB-20/controls/ALT-active", 0);
	}

	menuSwitchBendixPB20();
}

setlistener("autopilot/locks/altitude", listenerApPB20SetAltitudeFunc);

var menuSwitchBendixPB20 = func {

	if (getprop("autopilot/locks/heading") == "wing-leveler") {
		setprop("autopilot/Bendix-PB-20/controls/active", 1);
		##bthpsetprop("autopilot/Bendix-PB-20/controls/mode-selector", 2);
		setprop("autopilot/Bendix-PB-20/controls/mode-selector", 1);
	}
	elsif (getprop("autopilot/locks/heading") == "dg-heading-hold") {
		setprop("autopilot/Bendix-PB-20/controls/active", 1);
		##bthpsetprop("autopilot/Bendix-PB-20/controls/mode-selector", 1);
		setprop("autopilot/Bendix-PB-20/controls/mode-selector", 0);
	}
	elsif (	getprop("autopilot/locks/heading") == "nav1-hold") {
		if (getprop("autopilot/locks/altitude") == "gs1-hold") {
			setprop("autopilot/Bendix-PB-20/controls/active", 1);
			##bthpsetprop("autopilot/Bendix-PB-20/controls/mode-selector", 4);
			setprop("autopilot/Bendix-PB-20/controls/mode-selector", 3);
		}
		else {
			setprop("autopilot/Bendix-PB-20/controls/active", 1);
			##bthpsetprop("autopilot/Bendix-PB-20/controls/mode-selector", 3);
			setprop("autopilot/Bendix-PB-20/controls/mode-selector", 2);
		}
	}
	elsif (getprop("autopilot/locks/heading") == "") {
		if (getprop("autopilot/locks/altitude") == "") {
			setprop("autopilot/Bendix-PB-20/controls/active", 0);
			setprop("autopilot/Bendix-PB-20/controls/ALT-active", 0);
			##bthp setprop("autopilot/Bendix-PB-20/controls/mode-selector", 2);
			setprop("autopilot/Bendix-PB-20/controls/mode-selector", 1);
		}
	}
}

listenerApPB20SetPitchFunc = func {

	setprop("autopilot/Bendix-PB-20/settings/pitch-wheel-deg", getprop("autopilot/settings/target-pitch-deg"));
}
setlistener("autopilot/locks/altitude",      listenerApPB20SetPitchFunc);
setlistener("autopilot/settings/pitch-hold", listenerApPB20SetPitchFunc);

### Bendix PB 20 ###

setlistener("controls/special/yoke-switch1", func (s1){
    var s1 = s1.getBoolValue();
    if (s1 == 1){
      setprop("autopilot/Bendix-PB-20/controls/active"         , 0);
      setprop("autopilot/Bendix-PB-20/controls/ALT-active"     , 0);
		  setprop("autopilot/Bendix-PB-20/controls/mode-selector"  , 1);
      setprop("autopilot/Bendix-PB-20/settings/pitch-wheel-deg", 0);
			setprop("autopilot/settings/target-pitch-deg"            , 0);
			setprop("autopilot/locks/altitude"                       , "");
			setprop("autopilot/locks/speed"                          , "");
    }
  }
);
