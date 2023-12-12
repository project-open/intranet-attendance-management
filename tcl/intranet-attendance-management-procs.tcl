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

    set params [list \
		    [list height $height] \
		    [list width $width] \
		    [list ansi_date $ansi_date] \
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
    {-user_id 0}
} {
    Returns the number of hours a person should be present
    at any work day.
} {
    if {0 == $user_id} { set user_id [ad_conn user_id] }
    set default_hours_per_day [parameter::get_from_package_key -package_key "intranet-attendance-management" -parameter "DefaultAttendanceHoursPerDay" -default "8.0"]

    if {![db_0or1row attendance_user_info "
	select	*
	from	im_employees e
	where	employee_id = :user_id
    "]} {
	# User for some reason doesn't exit...
	ns_log Error "im_attendance_daily_attendance_hours: user_id=$user_id doesn't exist"
	return $default_hours_per_day
    }

    set hours_per_day $default_hours_per_day
    if {$availability != ""} {
	set hours_per_day [expr $default_hours_per_day * $availability]
    }
    return $hours_per_day
}


ad_proc -public im_attendance_check_consistency {
    -attendance_hashs:required
} {
    Checks a list of attendances for a given user and day for consistency.
    Returns and empty list when successful, or a list of error strings otherwise
} {
    # ns_log Notice "check_consistency: hash=$attendance_hashs"
    set errors [list]

    set last_att [list]
    foreach curr_att $attendance_hashs {
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
	ns_log Notice "check_consistency: last_start_date='$last_start_date', last_end_date='$last_end_date', last_start_time='$last_start_time', last_end_time='$last_end_time'"


	# ----------------------------------------------------------------------
	# Checks of a single attendance

	# The _date_ component of curr_attendance_start and curr_attendance_end should be the same (unless end_date is empty)
	if {"" ne $curr_end_date && $curr_start_date ne $curr_end_date} {
	    lappend errors "Attendance #$curr_hash(attendance_id) on $curr_start_date has different dates between start and end"
	}
	
	# The _date_ component of last_start_date and curr_start_date should be the same (unless last_start_date is empty (non existent))
	if {"" ne $last_start_date && $curr_start_date ne $last_start_date} {
	    lappend errors "Attendance #$curr_hash(attendance_id) on $curr_start_date has different date than it's predecessor. Internal error?"
	}
	
	# There should be no breaks shorter than min_break_time
	if {[im_attendance_type_break] eq $curr_hash(attendance_type_id)} {
	    set duration $curr_hash(attendance_duration_hours)
	    ns_log Notice "check_consistency: break: duration=$duration"
	    
	    if {$curr_hash(attendance_duration_hours) < 0.20} { 
		lappend errors "Break #$curr_hash(attendance_id) on $curr_start_date is shorter than 15 minutes"
	    }
	}

	# Check that the work attendance is (more or less...) the same as the timesheet timd
	if {0 && [im_attendance_type_work] eq $curr_hash(attendance_type_id)} {
	    set work_duration 0
	    if {"" ne $curr_hash(attendance_duration_hours)} { set work_duration $curr_hash(attendance_duration_hours) }
	    set work_duration [expr round(100.0 * $work_duration) / 100.0]
	    set ts_duration [expr round(100.0 * $curr_hash(ts_sum_per_user_day)) / 100.0]
	    
	    set absdiff [expr round(100.0 * abs($work_duration - $ts_duration)) / 100.0]
	    if {$absdiff > 0.1} {
		lappend errors "The difference between work attendances ($work_duration) and timesheet hours ($ts_duration) is more than 0.1 hours"
	    }
	}

	# ----------------------------------------------------------------------
	# Compare curr_hash with last_hash, if last_hash is defined
	if {"" ne $last_end_time} {

	    # Check that last attendance and current one don't overlap
	    if {$last_end_time > $curr_start_time} {
		lappend errors "Attendance #$curr_hash(attendance_id) on $curr_start_date overlaps with attendance #$last_hash(attendance_id)."
	    }

	    

	}


	# ----------------------------------------------------------------------
	# Finish

	# Copy the current attendance into the last attendance
	set last_att $curr_att
    }

    # ToDo Check:
    # if there is a timesheet entry, but no attendance
    # if deviation between timesheet and attendances is > ...


    return $errors
}
