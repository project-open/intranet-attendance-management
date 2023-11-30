# /packages/intranet-attendance-management/www/attendance-report.tcl
#
# Copyright (c) 2003-2013 ]project-open[
#
# All rights reserved.
# Please see https://www.project-open.com/ for licensing.

ad_page_contract {
    Lists attendances dependent on interval, time, user and department.
    - Anzeige:
	- Pausenzeiten
	- Anwesenheitszeiten
	- Mindestens 15 pro Pause
	- Ab 6h verpflichtend 30min Pause
	- Ab 9h 45min Pause
	- Pro Monat (31 Spalten oben) und pro User (links)
	- Jede Zelle:
		- Gesamtzeit Pausen
		- Rot wenn Business-Regeln verletzt (oben)
		  mit Kommentar warum
	- Used to manually calculate working time per month
} {
    { report_start_date "" }
    { report_end_date "" }
    { report_department_id "" }
    { report_user_id "" }
    { report_attendance_type_id "" }
    { report_attendance_status_id "" }
    { level_of_detail:integer 3 }
    { output_format "html" }
    { number_locale "" }
}

# ------------------------------------------------------------
# Security
#
set menu_label "reporting-attendances"
set current_user_id [auth::require_login]
set read_p [db_string report_perms "
	select	im_object_permission_p(m.menu_id, :current_user_id, 'read')
	from	im_menus m
	where	m.label = :menu_label
" -default 'f']

# For testing - set manually
set read_p "t"

if {"t" ne $read_p } {
    set message "You don't have the necessary permissions to view this page"
    ad_return_complaint 1 "<li>$message"
    ad_script_abort
}


# ------------------------------------------------------------
# Check Parameters
#

# Maxlevel is 3.
if {$level_of_detail > 3} { set level_of_detail 3 }

# Default is user locale
if {"" == $number_locale} { set number_locale [lang::user::locale] }

set days_in_past 7
db_1row todays_date "
select
        to_char(sysdate::date - :days_in_past::integer, 'YYYY') as todays_year,
        to_char(sysdate::date - :days_in_past::integer, 'MM') as todays_month,
        to_char(sysdate::date - :days_in_past::integer, 'DD') as todays_day
from dual
"

# Check that Start & End-Date have correct format
if {"" != $report_start_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $report_start_date]} {
    ad_return_complaint 1 "Start Date doesn't have the right format.<br>
    Current value: '$report_start_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" != $report_end_date && ![regexp {^[0-9][0-9][0-9][0-9]\-[0-9][0-9]\-[0-9][0-9]$} $report_end_date]} {
    ad_return_complaint 1 "End Date doesn't have the right format.<br>
    Current value: '$report_end_date'<br>
    Expected format: 'YYYY-MM-DD'"
}

if {"" == $report_start_date} {
    set report_start_date "$todays_year-$todays_month-01"
}

db_1row report_end_date "
select
 to_char(to_date(:report_start_date, 'YYYY-MM-DD') + 31::integer, 'YYYY') as end_year,
 to_char(to_date(:report_start_date, 'YYYY-MM-DD') + 31::integer, 'MM') as end_month,
 to_char(to_date(:report_start_date, 'YYYY-MM-DD') + 31::integer, 'DD') as end_day
from dual
"



# ------------------------------------------------------------
# Page Title, Bread Crums and Help
#
set page_title [lang::message::lookup "" intranet-attendance-management.Attendance_Report "Attendance Report"]
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>$page_title:</strong><br>
	[lang::message::lookup "" intranet-attendance-management.Attendance_Report_help "
	This report returns a list of attendances grouped per user.
"]"


# ------------------------------------------------------------
# Default Values and Constants
#
set rowclass(0) "roweven"
set rowclass(1) "rowodd"

# Variable formatting - Default formatting is quite ugly
# normally. In the future we will include locale specific
# formatting.
#
set currency_format "999,999,999.09"
set percentage_format "90.9"
set date_format "YYYY-MM-DD"

# Set URLs on how to get to other parts of the system for convenience.
set user_url "/intranet/users/view?user_id="
set this_url "[export_vars -base "/intranet-attendance-management/reports/attendance-report" {} ]?"

# Level of Details
# Determines the LoD of the grouping to be displayed
#
set levels [list \
    1 [lang::message::lookup "" intranet-attendance-management.Attendances_per_User "Attendances per User"] \
    2 [lang::message::lookup "" intranet-attendance-management.All_Details "All Details"] \
]


# ------------------------------------------------------------
# Report SQL
#

# Get dynamic attendance fields
#
set deref_list [im_dynfield::object_attributes_derefs -object_type "im_attendance"]
set deref_extra_select [join $deref_list ",\n\t"]
if {"" != $deref_extra_select} { set deref_extra_select ",\n\t$deref_extra_select" }

set criteria [list]
if {"" ne $report_attendance_status_id && 0 ne $report_attendance_status_id} {
    lappend criteria "a.attendance_status_id in ([join [im_sub_categories $report_attendance_status_id] ", "])"
}

if {"" ne $report_attendance_type_id && 0 ne $report_attendance_type_id} {
    lappend criteria "a.attendance_type_id in ([join [im_sub_categories $report_attendance_type_id] ", "])"
}

if {"" ne $report_department_id && 0 ne $report_department_id} {
    lappend criteria "e.department_id in ([join [im_sub_cost_center_ids $report_department_id] ", "])\n"
}

set where_clause [join $criteria " and\n\t"]
if { $where_clause ne "" } { set where_clause " and $where_clause" }


set report_sql "
	select
		a.*,
		im_cost_center_name_from_id(e.department_id) as user_department,
		to_char(a.attendance_start, 'YYYY-MM-DD') as attendance_start_date,
		to_char(a.attendance_start, 'HH24:MI') as attendance_start_time,
		to_char(a.attendance_end, 'HH24:MI') as attendance_end_time,
		im_name_from_user_id(a.attendance_user_id) as user_name,
		CASE when a.attendance_type_id = [im_attendance_type_work] THEN attendance_end - attendance_start END as attendance_work,
		CASE when a.attendance_type_id = [im_attendance_type_break] THEN attendance_end - attendance_start END as attendance_break
	from
		im_attendance_intervals a,
		im_employees e
	where
		a.attendance_user_id = e.employee_id
		$where_clause
	order by
		user_name,
		a.attendance_start
"


# ------------------------------------------------------------
# Report Definition
#

# Global Header
set header0 {
    "User"
    "Dept"
    "Date"
    "Type"
    "Start"
    "End"
    "Work"
    "Break"
    "Note"
}

# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
#
set report_def [list \
    group_by attendance_user_id \
		    header {
			"#colspan=1 <a href=$user_url$attendance_user_id target=_>$user_name</a>"
			"#colspan=8 $user_department"
			} \
    content [list \
	group_by attendance_id \
		 header {
		     ""
		     ""
		     "$attendance_start_date"
		     "$attendance_type"
		     "$attendance_start_time"
		     "$attendance_end_time"
		     "$attendance_work"
		     "$attendance_break"
		     "$attendance_note"
		 } \
	content {} \
    ] \
    footer {} \
]


# Global Footer Line
set footer0 {}


# ------------------------------------------------------------
# Counters
#

#
# Subtotal Counters (per user)
#
set user_attendance_work_counter [list \
	pretty_name "Attendance Value" \
	var attendance_value \
	reset \$attendance_user_id \
	expr "\$attendance_value+0" \
]

set user_attendance_work_total_counter [list \
	pretty_name "Attendance Value Total" \
	var attendance_value_total \
	reset 0 \
	expr "\$attendance_value+0" \
]


set counters [list \
	$user_attendance_work_counter \
	$user_attendance_work_total_counter \
]

# Set the values to 0 as default (New!)
set attendance_value 0
set attendance_value_total 0

# ------------------------------------------------------------
# Start Formatting the HTML Page Contents
#

im_report_write_http_headers -report_name $menu_label -output_format $output_format

switch $output_format {
    html {
	ns_write "
	[im_header]
	[im_navbar reporting]
	<table cellspacing=0 cellpadding=0 border=0>
	<tr valign=top>
	  <td width='30%'>
		<!-- 'Filters' - Show the Report parameters -->
		<form>
		<table cellspacing=2>
		<tr class=rowtitle>
		  <td class=rowtitle colspan=2 align=center>Filters</td>
		</tr>
		<tr>
		  <td>Level of<br>Details</td>
		  <td>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>

		<tr>
		  <td>[lang::message::lookup "" intranet-attendance-management.User_Department "User Department"]:</td>
		  <td>[im_cost_center_select -include_empty 1 -include_empty_name "All" report_department_id $report_department_id]</td>
		</tr>

		<tr>
		  <td>[lang::message::lookup "" intranet-attendance-management.Attendance_Type "Attendance Type"]:</td>
		  <td>[im_category_select -include_empty_p 1 "Intranet Attendance Type" report_attendance_type_id $report_attendance_type_id]</td>
		</tr>

		<tr>
		  <td>[lang::message::lookup "" intranet-attendance-management.Attendance_Status "Attendance Status"]:</td>
		  <td>[im_category_select -include_empty_p 1 "Intranet Attendance Status" report_attendance_status_id $report_attendance_status_id]</td>
		</tr>

		<tr>
		  <td class=form-label>[lang::message::lookup "" intranet-reporting.Output_Format Format]</td>
		  <td class=form-widget>
		    [im_report_output_format_select output_format "" $output_format]
		  </td>
		</tr>
		<tr>
		  <td class=form-label><nobr>[lang::message::lookup "" intranet-reporting.Number_Format "Number Format"]</nobr></td>
		  <td class=form-widget>
		    [im_report_number_locale_select number_locale $number_locale]
		  </td>
		</tr>
		<tr>
		  <td</td>
		  <td><input type=submit value='Submit'></td>
		</tr>
		</table>
		</form>
	  </td>
	  <td align=center>
		<table cellspacing=2 width='90%'>
		<tr>
		  <td>$help_text</td>
		</tr>
		</table>
	  </td>
	</tr>
	</table>
	
	<!-- Here starts the main report table -->
	<table border=0 cellspacing=1 cellpadding=1>
    "
    }
}

set footer_array_list [list]
set last_value_list [list]

im_report_render_row \
    -output_format $output_format \
    -row $header0 \
    -row_class "rowtitle" \
    -cell_class "rowtitle"

set counter 0
set class ""
db_foreach sql $report_sql {
    set class $rowclass([expr {$counter % 2}])

    set attendance_work_pretty [im_report_format_number $attendance_work $output_format $number_locale]
    set attendance_break_pretty [im_report_format_number $attendance_break $output_format $number_locale]
    set attendance_type [im_category_from_id -translate_p 1 $attendance_type_id]
    set attendance_status [im_category_from_id -translate_p 1 $attendance_status_id]

    # Restrict the length of the attendance_note to 40 characters.
    set attendance_note_pretty [string_truncate -len 40 $attendance_note]

    im_report_display_footer \
        -output_format $output_format \
        -group_def $report_def \
        -footer_array_list $footer_array_list \
        -last_value_array_list $last_value_list \
        -level_of_detail $level_of_detail \
        -row_class $class \
        -cell_class $class

    im_report_update_counters -counters $counters

    set last_value_list [im_report_render_header \
        -output_format $output_format \
        -group_def $report_def \
        -last_value_array_list $last_value_list \
        -level_of_detail $level_of_detail \
        -row_class $class \
        -cell_class $class
    ]

    set footer_array_list [im_report_render_footer \
        -output_format $output_format \
        -group_def $report_def \
        -last_value_array_list $last_value_list \
        -level_of_detail $level_of_detail \
        -row_class $class \
        -cell_class $class
    ]

    incr counter
}

im_report_display_footer \
    -output_format $output_format \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -level_of_detail $level_of_detail \
    -display_all_footers_p 1 \
    -row_class $class \
    -cell_class $class

im_report_render_row \
    -output_format $output_format \
    -row $footer0 \
    -row_class $class \
    -cell_class $class \
    -upvar_level 1


# Write out the HTMl to close the main report table
#
switch $output_format {
    html {
    ns_write "</table>\n"
    ns_write "<br>&nbsp;<br>"
    ns_write [im_footer]
    }
}

