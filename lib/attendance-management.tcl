# /packages/intranet-attendance-management/lib/attendance-management.tcl
#
# Copyright (C) 2012 ]project-open[
#
# All rights reserved. Please check
# https://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# Variables expected to be set by calling procedure:
# height, width, ansi_date and user_id_from_search
# ---------------------------------------------------------------------

set current_user_id [ad_conn user_id]
set admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set user_locale [lang::user::locale]
set user_name_from_search [im_name_from_user_id $user_id_from_search]

set data_list {}
if {[info exists height]} { set portlet_height $height } else { set portlet_height 400 }
if {[info exists width]} { set portlet_width $width } else { set portlet_width 600 }

# Create a random ID for the attendance_editor
set attendance_editor_rand [expr round(rand() * 100000000.0)]
set attendance_editor_id "attendance_editor_$attendance_editor_rand"

# Start and end time for default combo box with time entry options
set start_hour [parameter::get_from_package_key -package_key "intranet-attendance-management" -parameter "AttendanceStartHour" -default "7"]
set end_hour [parameter::get_from_package_key -package_key "intranet-attendance-management" -parameter "AttendanceEndHour" -default "22"]
set week_start_day [parameter::get_from_package_key -package_key "intranet-timesheet2" -parameter WeekStartDay -default 1]

# Default material and Unit of Measure: "Default" and "Hour"
set default_material_id [im_material_default_material_id]

# Create a debug JSON object that controls logging verbosity
set debug_default "default 0"
set debug_list [parameter::get_from_package_key -package_key "intranet-gantt-editor" -parameter DebugHash -default $debug_default]
array set debug_hash $debug_list
set debug_json_list {}
foreach id [array names debug_hash] { lappend debug_json_list "'$id': $debug_hash($id)" }
set debug_json "{\n\t[join $debug_json_list ",\n\t"]\n}"


set english_message_sql "select	message_key, replace(replace(message, E'\n', '\\n'), E'\r', '') as message from lang_messages where locale = 'en_US' and package_key = 'intranet-attendance-management'"
db_multirow english_messages english_messages $english_message_sql

set locale_message_sql "select message_key, replace(replace(message, E'\n', '\\n' ), E'\r', '') as message from lang_messages where locale = :user_locale and package_key = 'intranet-attendance-management'"
db_multirow locale_messages locale_messages $locale_message_sql


# ----------------------------------------------------------------------
# Create a report for admins to show all changes in attendances this week
# including deletes
# ---------------------------------------------------------------------

set audit_html ""
if {$admin_p && $current_user_id != $user_id_from_search} {
    set monday_iso [db_string monday_iso "select date_trunc('week', :ansi_date::date)"]
    set object_ids [db_list attendance_ids "
	select	*
	from	im_attendance_intervals a
	where	a.attendance_user_id = :user_id_from_search and
		a.attendance_start >= :monday_iso::date and
		a.attendance_end <= :monday_iso::date + 7
    "]
    # ad_return_complaint 1 $object_ids
    set audit_html [im_audit_component -object_id $object_ids]
}
