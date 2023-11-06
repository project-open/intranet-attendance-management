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
# Portlets
# ---------------------------------------------------------------------


ad_proc -public im_attendance_management_portlet {
    { -height 600 }
    { -width 600 }
} {
    Returns a HTML code with a Sencha attendance entry portlet.
} {
    # Sencha check and permissions
    if {![im_sencha_extjs_installed_p]} { return "" }
    set current_user_id [ad_conn user_id]

    if {![im_permission $current_user_id add_hours]} { return "" }
    im_sencha_extjs_load_libraries

    set params [list \
		    [list height $height] \
		    [list width $width] \
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
    if {$current_user_id == $user_id} {
	set view 1
	set read 1
	set write 1
	set admin 1
    }
}
