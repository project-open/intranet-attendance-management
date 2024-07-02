# /packages/intranet-attendance-management/tcl/intranet-attendance-management-procs.tcl
#
# Copyright (C) 2014 ]project-open[
# 
# All rights reserved. Please check
# https://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}

# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_attendance_status_approved {} { return 92000 }
ad_proc -public im_attendance_status_requested {} { return 92010 }
ad_proc -public im_attendance_status_active {} { return 92020 }
ad_proc -public im_attendance_status_closed {} { return 92090 }
ad_proc -public im_attendance_status_deleted {} { return 92099 }

ad_proc -public im_attendance_type_work {} { return 92100 }
ad_proc -public im_attendance_type_break {} { return 92110 }


# ----------------------------------------------------------------------
# Portlets
# ---------------------------------------------------------------------

ad_proc -public im_attendance_management_portlet {
    { -height 500 }
    { -width 600 }
} {
    Returns a HTML code with a Sencha ExtJS portlet
    to capture attendances.
} {
    # Sencha check and permissions
    if {![im_sencha_extjs_installed_p]} { return "" }
    set current_user_id [ad_conn user_id]

    # We are using add_hours privilege also for attendances.
    if {![im_permission $current_user_id add_hours]} { return "" }
    im_sencha_extjs_load_libraries

    # Check if calling page provided a "julian" parameter in the URL
    set julian [im_opt_val julian]
    set ansi_date ""
    if {"" != $julian && 0 != $julian} {
	set ansi_date [im_date_julian_to_ansi $julian]
    }

    # Check if the calling page has "user_id_from_search"
    set user_id_from_search [im_opt_val user_id_from_search]
    if {"" eq $user_id_from_search || ![string is integer $user_id_from_search]} { set user_id_from_search $current_user_id }

    set params [list \
		    [list height $height] \
		    [list width $width] \
		    [list ansi_date $ansi_date] \
		    [list user_id_from_search $user_id_from_search] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-attendance-management/lib/attendance-management"]
    return [string trim $result]
}


# ---------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------

ad_proc -public im_attendance_interval_permissions {user_id attendance_id view_var read_var write_var admin_var} {
    Fill the by-reference variables read, write and admin
    with the permissions of $user_id on attendance_id. 
    A user is allowed to see, modify and delete his own
    hour_managements.
} {
    upvar $view_var view
    upvar $read_var read
    upvar $write_var write
    upvar $admin_var admin

    set current_user_id $user_id
    set admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

    set view 0
    set read 0
    set write 0
    set admin 0

    # Empty or bad attendance_id
    if {"" == $attendance_id || ![string is integer $attendance_id]} { return }

    # Get cached hour_management info
    if {![db_0or1row attendance_management_info "
	select	*
	from	im_attendance_intervals i
	where	i.attendance_id = :attendance_id
    "]} {
	# Thic can happen if this procedure is called while the package hasn't yet been created
	ns_log Error "im_attendance_interval_permissions: user_id=$user_id, attendance_id=$attendance_id: attendance_id not found"
	return
    }

    # The owner and administrators can always read and write
    if {$admin_p || $current_user_id == $attendance_user_id} {
	set view 1
	set read 1
	set write 1
	set admin 1
    }
}



# ----------------------------------------------------------------------
# Nuke an attendance
# ---------------------------------------------------------------------

ad_proc -public im_attendance_interval_nuke {
    {-current_user_id 0}
    attendance_interval_id
} {
    Permanently deletes the Attendance Interval from the database.
} {
    db_dml nuke_context_id "update acs_objects set context_id = null where context_id = :attendance_interval_id"
    db_string nuke "select im_attendance_interval__delete(:attendance_interval_id)"
}



# ----------------------------------------------------------------------
# Business Logic
# ---------------------------------------------------------------------

ad_proc -public im_attendance_daily_attendance_hours {
    -user_id
    -date
} {
    Returns the number of hours a person should be present at the given date
} {
    #    return [util_memoize [list im_attendance_daily_attendance_hours_helper -user_id $user_id -date $date] 3600]
    return [im_attendance_daily_attendance_hours_helper -user_id $user_id -date $date]
}

ad_proc -public im_attendance_daily_attendance_hours_helper {
    -user_id
    -date
} {
    Returns the number of hours a person should be present at the given date
} {
    set default_hours_per_day [parameter::get_from_package_key -package_key "intranet-attendance-management" -parameter "DefaultAttendanceHoursPerDay" -default "8.0"]

    # --------------------------------------------------------------
    # Check HR for the number of hours to work
    set availability ""
    if {![db_0or1row attendance_user_info "
	select	*
	from	im_employees e
	where	employee_id = :user_id
    "]} {
	# User for some reason doesn't exit...
	ns_log Error "im_attendance_daily_attendance_hours: user_id=$user_id doesn't exist"
    }

    set hours_per_day $default_hours_per_day
    if {$availability != ""} {
	set hours_per_day [expr $default_hours_per_day * $availability / 100.0]
    }


    # --------------------------------------------------------------
    # Check Resource Management for work days and absences
    set workday_array [db_string work_day "select im_resource_mgmt_work_days (:user_id, :date, :date)"]
    set absence_array [db_string absence "select im_resource_mgmt_user_absence (:user_id, :date, :date)"]
    set workday_list [string map {"," " " "{" "" "}" ""} [lindex [split $workday_array "="] 1]]
    set absence_list [string map {"," " " "{" "" "}" ""} [lindex [split $absence_array "="] 1]]

    set hours [expr $hours_per_day * ($workday_list - $absence_list) / 100.0]

    ns_log Notice "im_attendance_daily_attendance_hours -user_id $user_id -date $date: hours_per_day=$hours_per_day, work=$workday_list, abs=$absence_list => hours=$hours"

    return $hours
}


ad_proc -public im_attendance_check_consistency_no_front_breaks {
    list_of_hash
} {
    Remove first item from list of hash, if it's a break
} {
    set pairs [lindex $list_of_hash 0]
    set rest [lrange $list_of_hash 1 end]

    array set hash $pairs
    set type_id 0
    if {[info exists hash(attendance_type_id)]} { set type_id $hash(attendance_type_id) }
    if {[im_attendance_type_break] == $type_id} {
	# First element is a break, repeat recursively
	return [im_attendance_check_consistency_no_front_breaks $rest]
    }

    # First element isn't a break, just return original list
    return $list_of_hash
}

ad_proc -public im_attendance_check_consistency_no_end_breaks {
    list_of_hash
} {
    Remove last item from list of hash, if it's a break
} {
    set pairs [lindex $list_of_hash end]
    set rest [lrange $list_of_hash 0 end-1]

    array set hash $pairs
    set type_id 0
    if {[info exists hash(attendance_type_id)]} { set type_id $hash(attendance_type_id) }
    if {[im_attendance_type_break] == $type_id} {
	# Last element is a break, repeat recursively
	return [im_attendance_check_consistency_no_end_breaks $rest]
    }

    # First element isn't a break, just return original list
    return $list_of_hash
}

ad_proc -public im_attendance_check_consistency {
    -user_id
    -date
    -attendance_hashs:required
} {
    Checks a list of attendances for a given user and day for consistency.
    The list needs to be for a single day and ordered by attendance_start in order to find overlaps/holes.
    Returns and empty list when successful, or a list of error strings otherwise.

    ToDo: Mark as an error to have breaks at the beginning or the end of the working day.
} {
    # ns_log Notice "check_consistency: hash=$attendance_hashs"
    set errors [list]
    set today [db_string today "select now()::date"]

    # No errors in the future...
    if {[string compare $date $today] > 0} { return $errors }

    # Remove leading or trailing breaks
    set hashs_no_front_breaks [im_attendance_check_consistency_no_front_breaks $attendance_hashs]
    if {$attendance_hashs != $hashs_no_front_breaks} {
	lappend errors [lang::message::lookup "" intranet-attendance-management.Found_a_break_as_first_attendance "Found a break as first attendance of the day, ignoring"]
    }

    set hashs_no_end_breaks [im_attendance_check_consistency_no_end_breaks $hashs_no_front_breaks]
    if {$hashs_no_end_breaks != $hashs_no_front_breaks} {
	lappend errors [lang::message::lookup "" intranet-attendance-management.Found_a_break_as_last_attendance "Found a break as last attendance of the day, ignoring"]
    }

    set last_att [list]
    set work_sum 0.0
    set break_sum 0.0
    set ts_sum 0.0
    foreach curr_att $hashs_no_end_breaks {
	array unset last_hash
	array unset curr_hash

	array set last_hash $last_att
	array set curr_hash $curr_att

	ns_log Notice "check_consistency: ----------------------------------------"
	ns_log Notice "check_consistency: last: $last_att"
	ns_log Notice "check_consistency: curr: $curr_att"
	# attendance_id attendance_type_id attendance_start_date attendance_start attendance_end attendance_duration_hours ts_sum_per_user_day

	# Exctract start/end date/time from current/last attendance. That's 8 variables in total (2^3)
	set curr_start_date [string range $curr_hash(attendance_start) 0 9]
	set curr_end_date [string range $curr_hash(attendance_end) 0 9]
	set curr_start_time [string range $curr_hash(attendance_start) 11 15]
	set curr_end_time [string range $curr_hash(attendance_end) 11 15]
	ns_log Notice "check_consistency: curr_hash=$curr_att"
	ns_log Notice "check_consistency: curr_start_date='$curr_start_date', curr_end_date='$curr_end_date', curr_start_time='$curr_start_time', curr_end_time='$curr_end_time'"

	if {$last_att ne ""} {
	    set last_start_date [string range $last_hash(attendance_start) 0 9]
	    set last_end_date [string range $last_hash(attendance_end) 0 9]
	    set last_start_time [string range $last_hash(attendance_start) 11 15]
	    set last_end_time [string range $last_hash(attendance_end) 11 15]
	} else {
	    set last_start_date ""
	    set last_end_date ""
	    set last_start_time ""
	    set last_end_time ""
	}

	switch $curr_hash(attendance_type_id) {
	    92100 { # Work
		set work_sum [expr round(100.0 * ($work_sum + $curr_hash(attendance_duration_hours)+0)) / 100.0]
	    }
	    92110 { # Break
		set break_sum [expr round(100.0 * ($break_sum + $curr_hash(attendance_duration_hours)+0)) / 100.0]
	    }
	    default {
		set err "im_attendance_check_consistency: Found invalid attendance_type_id in att: $curr_att"
	    }
	}

	set ts_sum $curr_hash(ts_sum_per_user_day)

	ns_log Notice "check_consistency: last_start_date='$last_start_date', last_end_date='$last_end_date', last_start_time='$last_start_time', last_end_time='$last_end_time', work_sum=$work_sum, break_sum=$break_sum"


	# ----------------------------------------------------------------------
	# Checks of a single attendance

	set attendance_id $curr_hash(attendance_id)

	# The _date_ component of curr_attendance_start and curr_attendance_end should be the same (unless end_date is empty)
	if {"" ne $curr_end_date && $curr_start_date ne $curr_end_date} {
	    lappend errors [lang::message::lookup "" intranet-attendance-management.Different_start_end_date "Attendance #%attendance_id% on %curr_start_date% has different dates between start and end"]
	}
	
	# The _date_ component of last_start_date and curr_start_date should be the same (unless last_start_date is empty (non existent))
	if {"" ne $last_start_date && $curr_start_date ne $last_start_date} {
	    lappend errors [lang::message::lookup "" intranet-attendance-management.Different_date_than_predecessor "Attendance #%attendance_id% on %curr_start_date% has a different date than it's predecessor. Internal error?"]
	}
	
	# There should be no breaks shorter than min_break_time
	if {[im_attendance_type_break] eq $curr_hash(attendance_type_id)} {
	    set duration $curr_hash(attendance_duration_hours)
	    ns_log Notice "check_consistency: break: duration=$duration"
	    
	    if {$curr_hash(attendance_duration_hours) < 0.20} { 
		lappend errors [lang::message::lookup "" intranet-attendance-management.Break_too_short "Break starting on %curr_start_date% %curr_start_time% is shorter than 15min"]
	    }
	}

	# ----------------------------------------------------------------------
	# Compare curr_hash with last_hash, if last_hash is defined
	if {"" ne $last_end_time} {

	    set diff_minutes [db_string diff_time "select extract(epoch from :last_end_time::time - :curr_start_time::time) / 60.0"]

	    # Check that last attendance and current one don't overlap
	    if {$diff_minutes >= 1.0} {
		lappend errors [lang::message::lookup "" intranet-attendance-management.Attendance_overlaps "Attendance starting %curr_start_date% %curr_start_time% overlaps with attendance starting %last_start_date% %last_start_time% by %diff_minutes%min"]
	    }

	    # Check for "holes"
	    if {$diff_minutes < -1.0} {
		set abs_diff_minutes [expr abs($diff_minutes)]
		# lappend errors [lang::message::lookup "" intranet-attendance-management.Attendance_gap "There is a gap of %abs_diff_minutes%min between attendance starting $last_start_date$ %last_start_time% and attendance starting %curr_start_date% %curr_start_time%"]
	    }
	}


	# ----------------------------------------------------------------------
	# Finish

	# Copy the current attendance into the last attendance
	set last_att $curr_att
    }

    # ad_return_complaint 1 "$break_sum $work_sum"

    # Check work vs. break times
    if {$work_sum > 9.0} {
	# At least 45min break after 9h of work
	if {$break_sum < 0.75} {
	    lappend errors [lang::message::lookup "" intranet-attendance-management.Break_after_long_period "After 9h of work (found: %work_sum%h) there should be at least 0.75h break (found: %break_sum%h)"]
	}
    } else {
	# At least 30min break after 6h of work
	if {$work_sum > 6.0} {
	    if {$break_sum < 0.5} {
		lappend errors [lang::message::lookup "" intranet-attendance-management.Break_after_middle_period "After 6h of work (found: %work_sum%h) there should be at least 0.5h break (found: %break_sum%h)"]
	    }
	}
    }

    # -------------------------------------------------------
    # These checks now work on the sums of work, break and timesheet

    set required_sum [im_attendance_daily_attendance_hours -user_id $user_id -date $date]    
    set required_margin 0.1

    # Check if there is work but no TS entry


    # If there is a timesheet entry
    # then check for a corresponding attendance time with 
    # if deviation between timesheet and attendances is > ...
    if {"" eq $ts_sum} { set ts_sum 0.0 }

    if {$ts_sum < [expr $required_sum - $required_margin]} {
	# lappend errors [lang::message::lookup "" intranet-attendance-management.Not_enough_time_logged "Not enough time (%ts_sum%h) logged on projects, expected %required_sum%h"]
    }

    if {$work_sum < [expr $required_sum - $required_margin]} {
	# lappend errors [lang::message::lookup "" intranet-attendance-management.Not_enough_work_logged "Not enough work attendance (%work_sum%h), expected %required_sum%h"]
    }

    if {$ts_sum < $work_sum} {
	lappend errors [lang::message::lookup "" intranet-attendance-management.Less_project_hours_than_work "Less hours (%ts_sum%h) logged on projects than on work attendances (%work_sum%h)"]
    }

    return $errors
}
