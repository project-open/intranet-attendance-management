# /packages/intranet-attendance-management/lib/attendance-management.tcl
#
# Copyright (C) 2012 ]project-open[
#
# All rights reserved. Please check
# https://www.project-open.com/license/ for details.

# ----------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

set current_user_id [ad_conn user_id]
set user_locale [lang::user::locale]

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

