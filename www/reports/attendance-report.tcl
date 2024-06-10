# /packages/intranet-attendance-management/www/attendance-report.tcl
#
# Copyright (c) 2003-2013 ]project-open[
#
# All rights reserved.
# Please see https://www.project-open.com/ for licensing.

ad_page_contract {
    Lists attendances (work and break) dependent on interval, time, user and department.
    Checks business rules for attendances:
    - min_break, max_break, min_work, max_work
    - min_work_break 6 0.5: At least 0.5 hours break after 6 hours of work
    - min_work_break 9 0.75: At least 0.75 hours break after 9 hours of work
    Used to manually calculate working time per month.
} {
    { report_start_date "" }
    { report_end_date "" }
    { report_department_id "" }
    { report_user_id "" }
    { report_attendance_type_id "" }
    { report_attendance_status_id "" }
    { level_of_detail:integer 2 }
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

if {"t" ne $read_p } {
    ad_return_complaint 1 [lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]
    ad_script_abort
}


# ------------------------------------------------------------
# Check Parameters
#

# Maxlevel is 3.
if {$level_of_detail > 3} { set level_of_detail 3 }

# Deactivate department filter if user filter was set (more specific)
if {"" ne $report_user_id && 0 ne $report_user_id} {
    set report_department_id ""
}

# Default is user locale
if {"" == $number_locale} { set number_locale [lang::user::locale] }

set days_in_past 3
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

if {"" == $report_end_date} { 
    set report_end_date "$end_year-$end_month-01"
}



# ------------------------------------------------------------
# Page Title, Bread Crums and Help
#
set page_title [lang::message::lookup "" intranet-attendance-management.Attendance_Report "Attendance Report"]
set context_bar [im_context_bar $page_title]
set help_text "
	<strong>$page_title:</strong><br>
	[lang::message::lookup "" intranet-attendance-management.Attendance_Report_help "
	This report returns a list of attendances grouped per user and date.
        Start date is inclusive, end date is exclusive (2023-11-01 - 2023-12-01 shows November).
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
set base_url "/intranet-attendance-management/reports/attendance-report"
set this_url "[export_vars -base $base_url {report_start_date report_end_date level_of_detail} ]?"
set base_url_date "[export_vars -base $base_url {report_start_date report_end_date}]"

# Level of Details
# Determines the LoD of the grouping to be displayed
#
set levels [list \
    1 [lang::message::lookup "" intranet-attendance-management.Attendances_per_User "Attendances per User"] \
    2 [lang::message::lookup "" intranet-attendance-management.Attendances_per_User_Date "Attendances per User and Date"] \
    3 [lang::message::lookup "" intranet-attendance-management.All_Details "All Details"] \
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

if {"" ne $report_user_id && 0 ne $report_user_id} {
    lappend criteria "e.employee_id = :report_user_id"
}

set where_clause [join $criteria " and\n\t"]
if { $where_clause ne "" } { set where_clause " and $where_clause" }


# Previous version of the report_sql, preserved for clarity of documentation.
# The only problem with this version is that it doesn't show all timesheet
# hours (im_hours), if the user didn't log an attendance on that day.
# We could have preserved this SQL and instead created a fake attendance for
# all days with im_hours, but that would have been ugly as well.
set simplified_report_sql "
	select	a.*,
		im_cost_center_name_from_id(e.department_id) as user_department,
		to_char(a.attendance_start, 'YYYY-MM-DD') as attendance_start_date,
		to_char(a.attendance_start + '1 day'::interval, 'YYYY-MM-DD') as attendance_start_date_next,
		to_char(a.attendance_start, 'HH24:MI') as attendance_start_time,
		to_char(a.attendance_end, 'HH24:MI') as attendance_end_time,
		im_name_from_user_id(a.attendance_user_id) as user_name,
		coalesce(EXTRACT(EPOCH FROM attendance_end - attendance_start) / 3600, 0) as attendance_duration_hours,
		CASE when a.attendance_type_id = [im_attendance_type_work] THEN coalesce(EXTRACT(EPOCH FROM attendance_end - attendance_start) / 3600, 0) END as attendance_work,
		CASE when a.attendance_type_id = [im_attendance_type_break] THEN coalesce(EXTRACT(EPOCH FROM attendance_end - attendance_start) / 3600, 0) END as attendance_break
	from	im_attendance_intervals a,
		im_employees e
	where	a.attendance_user_id = e.employee_id and
		a.attendance_start >= :report_start_date and
		a.attendance_start < :report_end_date
		$where_clause
	order by user_name, attendance_start
"

# This 
set report_sql "
select	a.attendance_id,
	t.user_id as attendance_user_id,
	a.attendance_start,
	a.attendance_end,
	a.attendance_type_id,
	a.attendance_status_id,
	a.attendance_note,
	im_cost_center_name_from_id(e.department_id) as user_department,
	to_char(t.date, 'YYYY-MM-DD') as attendance_start_date,
	to_char(t.date, 'J') as attendance_start_julian,
	to_char(t.date + '1 day'::interval, 'YYYY-MM-DD') as attendance_start_date_next,
	to_char(a.attendance_start, 'HH24:MI') as attendance_start_time,
	to_char(a.attendance_end, 'HH24:MI') as attendance_end_time,
	im_name_from_user_id(t.user_id) as user_name,
	coalesce(EXTRACT(EPOCH FROM attendance_end - attendance_start) / 3600, 0) as attendance_duration_hours,
	CASE when a.attendance_type_id = [im_attendance_type_work] THEN round(coalesce(EXTRACT(EPOCH FROM attendance_end - attendance_start) / 3600, 0)::numeric, 2) END as attendance_work,
	CASE when a.attendance_type_id = [im_attendance_type_break] THEN round(coalesce(EXTRACT(EPOCH FROM attendance_end - attendance_start) / 3600, 0)::numeric, 2) END as attendance_break
from
	-- Create a list of all (date, user_id) tuples with either attenances or im_hours
	(select distinct date, user_id
	from
		(select	aa.attendance_start::date as date,
			aa.attendance_user_id as user_id
		from	im_attendance_intervals aa,
			im_employees e
		where	aa.attendance_user_id = e.employee_id and
			aa.attendance_start >= :report_start_date and
			aa.attendance_start < :report_end_date
	UNION
		select	h.day::date as date,
			h.user_id as user_id
		from	im_hours h
		where	h.day >= :report_start_date and
			h.day < :report_end_date
		) tt
	) t
	-- Join the list
	LEFT OUTER JOIN im_attendance_intervals a ON (t.date = a.attendance_start::date and t.user_id = a.attendance_user_id)
	LEFT OUTER JOIN im_employees e ON (t.user_id = e.employee_id)
where	
	t.date >= :report_start_date and
	t.date < :report_end_date
	$where_clause
order by
	user_name,
	t.date,
	attendance_start
	
"
# ad_return_complaint 1 [im_ad_hoc_query -format html $report_sql]

# ------------------------------------------------------------
# Timesheet Data
#

set ts_criteria [list]
if {"" ne $report_department_id && 0 ne $report_department_id} {
    lappend ts_criteria "e.department_id in ([join [im_sub_cost_center_ids $report_department_id] ", "])\n"
}

if {"" ne $report_user_id && 0 ne $report_user_id} {
    lappend ts_criteria "e.employee_id = :report_user_id"
}

set ts_where_clause [join $ts_criteria " and\n\t"]
if { $ts_where_clause ne "" } { set ts_where_clause " and $ts_where_clause" }



# ad_return_complaint 1 "<pre>$ts_where_clause</pre>"
set timesheet_sql "
	select	sum(h.hours) as hours,
		h.user_id,
		h.day::date as day_date
	from	im_hours h,
		im_employees e
	where	h.user_id = e.employee_id and
		h.day >= :report_start_date and
		h.day < :report_end_date
		$ts_where_clause
	group by
		h.user_id,
		h.day::date
"
set ts_sum_total 0.0
db_foreach timesheet_info $timesheet_sql {
    # timesheet sum per user and date
    set ts_key "$user_id-$day_date"
    set ts_hash($ts_key) $hours

    # timesheet sum per user
    set ts_key "$user_id"
    set v 0.0
    if {[info exists ts_user_hash($ts_key)]} { set v $ts_user_hash($ts_key) }
    set v [expr $v + $hours]
    set ts_user_hash($ts_key) $v

    # timesheet total
    set ts_sum_total [expr $ts_sum_total + $hours]
}

set ts_sum_total [expr round(100.0 * $ts_sum_total) / 100.0]
set ts_sum_total_pretty [im_report_format_number [expr round(100.0 * $ts_sum_total) / 100.0] $output_format $number_locale]





# ------------------------------------------------------------
# Report Definition
#

# Global Header
set header0 [list \
		 [lang::message::lookup "" intranet-attendance-management.Heading_User "User"] \
		 [lang::message::lookup "" intranet-attendance-management.Heading_Date "Date"] \
		 [lang::message::lookup "" intranet-attendance-management.Heading_Type "Type"] \
		 [lang::message::lookup "" intranet-attendance-management.Heading_Start "Start"] \
		 [lang::message::lookup "" intranet-attendance-management.Heading_End "End"] \
		 [lang::message::lookup "" intranet-attendance-management.Heading_Work "Work"] \
		 [lang::message::lookup "" intranet-attendance-management.Heading_Break "Break"] \
		 [lang::message::lookup "" intranet-attendance-management.Heading_Timesheet "Timesheet"] \
		 [lang::message::lookup "" intranet-attendance-management.Heading_note "Note"] \
]

# The entries in this list include <a HREF=...> tags
# in order to link the entries to the rest of the system (New!)
set report_def [list \
		    group_by attendance_user_id \
		    header {
			"#colspan=9 
                        <a href=$user_url$attendance_user_id target=_>$user_name</a> ($user_department)"
		    } \
		    content [list \
				 group_by attendance_start_date \
				 header {
				 } \
				 content [list \
					      group_by attendance_id \
					      header {
						  ""
						  "<nobr>$attendance_start_date</nobr>"
						  "$attendance_type"
						  "$attendance_start_time"
						  "$attendance_end_time"
						  "#align=right $attendance_work_pretty"
						  "#align=right $attendance_break_pretty"
						  ""
						  "$attendance_note"
					      } \
					      content {} \
					      footer {} \
				 ] \
				 footer {
				     ""
				     "#colspan=2 <nobr><a href=$base_url?report_user_id=$attendance_user_id&level_of_detail=3&report_start_date=$attendance_start_date&report_end_date=$attendance_start_date_next target=_blank><img src=/intranet/images/plus_9.gif border=0></a>
                                     <i>$attendance_start_date</i></nobr>"
				     ""
				     ""
				     "#align=right <i>$attendance_date_work_pretty</i>"
				     "#align=right <i>$attendance_date_break_pretty</i>"
				     "#align=right $ts_sum_per_user_day_pretty"
				     "$errors_formatted_for_note_column"
				 } \
				] \
		    footer {
			"#colspan=5 <a href=$base_url_date&report_user_id=$attendance_user_id&level_of_detail=3 
                        target=_blank><img src=/intranet/images/plus_9.gif border=0></a>
                        <b><a href=$user_url$attendance_user_id target=_>$user_name</a> ($user_department) </b>"
			"#align=right <b>$attendance_user_work_pretty</b>"
			"#align=right <b>$attendance_user_break_pretty</b>"
			"#align=right <b>$ts_sum_per_user_pretty</b>"
			""
		    } \
		   ]


# Global Footer Line
set footer0 [list \
		 "[lang::message::lookup "" intranet-attendance-management.Total "Total"]" \
		 "" \
		 "" \
		 "" \
		 "" \
		 "#align=right \$attendance_work_total_pretty" \
		 "#align=right \$attendance_break_total_pretty" \
		 "#align=right \$ts_sum_total_pretty" \
		 "" \
]


# ------------------------------------------------------------
# Counters
#

set user_attendance_date_work_counter   [list pretty_name "Attendance Work"        var attendance_date_work reset \$attendance_start_julian  expr "\$attendance_work+0"]
set user_attendance_user_work_counter   [list pretty_name "Attendance User Work"   var attendance_user_work reset \$attendance_user_id     expr "\$attendance_work+0"]
set user_attendance_work_total_counter  [list pretty_name "Attendance Work Total"  var attendance_work_total reset 0                       expr "\$attendance_work+0"]

set user_attendance_date_break_counter  [list pretty_name "Attendance Break"       var attendance_date_break reset \$attendance_start_julian expr "\$attendance_break+0"]
set user_attendance_user_break_counter  [list pretty_name "Attendance User Break"  var attendance_user_break reset \$attendance_user_id    expr "\$attendance_break+0"]
set user_attendance_break_total_counter [list pretty_name "Attendance Break Total" var attendance_break_total reset 0                      expr "\$attendance_break+0"]

set counters [list \
	$user_attendance_date_work_counter \
	$user_attendance_user_work_counter \
	$user_attendance_work_total_counter \
	$user_attendance_date_break_counter \
	$user_attendance_user_break_counter \
	$user_attendance_break_total_counter \
]

# Set the values to 0 as default (New!)
set attendance_user_work 0
set attendance_date_work 0
set attendance_work_total 0
set attendance_work_total_pretty 0

set attendance_user_break 0
set attendance_date_break 0
set attendance_break_total 0
set attendance_break_total_pretty 0

set ts_sum_per_user_day 0

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
		  <td class=rowtitle colspan=2 align=center>[lang::message::lookup "" intranet-core.Filter "Filter"]</td>
		</tr>
		<tr>
		  <td>[lang::message::lookup "" intranet-reporting.LevelOfDetails "Level of Details"]:</td>
		  <td>
		    [im_select -translate_p 0 level_of_detail $levels $level_of_detail]
		  </td>
		</tr>

		<tr>
		  <td class=form-label>[lang::message::lookup "" intranet-core.Start_Date "Start Date"]:</td>
		  <td class=form-widget>
		    <input type=textfield name=report_start_date value=$report_start_date>
		  </td>
		</tr>
		<tr>
		  <td class=form-label>[lang::message::lookup "" intranet-core.End_Date "End Date"]:</td>
		  <td class=form-widget>
		    <input type=textfield name=report_end_date value=$report_end_date>
		  </td>
		</tr>

		<tr>
		  <td>[lang::message::lookup "" intranet-attendance-management.User_Department "User Department"]:</td>
		  <td>[im_cost_center_select -include_empty 1 -include_empty_name [_ intranet-core.All] report_department_id $report_department_id]</td>
		</tr>

		<tr>
		  <td class=form-label>[lang::message::lookup "" intranet-core.User "User"]</td>
		  <td class=form-widget>
		    [im_user_select -include_empty_p 1 -group_id [list [im_employee_group_id] [im_freelance_group_id]] -include_empty_name [lang::message::lookup "" intranet-core.All "All"] report_user_id $report_user_id] 
		</td>

		<tr>
		  <td>[lang::message::lookup "" intranet-attendance-management.Attendance_Type "Attendance Type"]:</td>
		  <td>[im_category_select -translate_p 1 -include_empty_p 1 "Intranet Attendance Type" report_attendance_type_id $report_attendance_type_id]</td>
		</tr>

		<tr>
		  <td>[lang::message::lookup "" intranet-attendance-management.Attendance_Status "Attendance Status"]:</td>
		  <td>[im_category_select -include_empty_p 1 "Intranet Attendance Status" report_attendance_status_id $report_attendance_status_id]</td>
		</tr>

		<tr>
		  <td class=form-label>[lang::message::lookup "" intranet-reporting.Output_Format Format]:</td>
		  <td class=form-widget>
		    [im_report_output_format_select output_format "" $output_format]
		  </td>
		</tr>
		<tr>
		  <td class=form-label><nobr>[lang::message::lookup "" intranet-reporting.Number_Format "Number Format"]:</td>
		  <td class=form-widget>
		    [im_report_number_locale_select number_locale $number_locale]
		  </td>
		</tr>
		<tr>
		  <td</td>
		  <td><input type=submit value='[_ intranet-core.Submit]'></td>
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

    set attendance_type [im_category_from_id -translate_p 1 $attendance_type_id]
    set attendance_status [im_category_from_id -translate_p 1 $attendance_status_id]

    # -------------------------------------------------------
    # Mix-in the timesheet information
    set ts_sum_per_user_day 0
    set ts_sum_per_user_day_pretty ""
    set ts_key "$attendance_user_id-$attendance_start_date"
    if {[info exists ts_hash($ts_key)]} { 
	set ts_sum_per_user_day $ts_hash($ts_key) 
	set ts_sum_per_user_day_pretty [im_report_format_number [expr round(100.0 * $ts_sum_per_user_day) / 100.0] $output_format $number_locale]
    }

    # Sum of hours per user
    set ts_sum_per_user 0.0
    if {[info exists ts_user_hash($attendance_user_id)]} { set ts_sum_per_user $ts_user_hash($attendance_user_id) }
    set ts_sum_per_user_pretty [im_report_format_number [expr round(100.0 * $ts_sum_per_user) / 100.0] $output_format $number_locale]


    # -------------------------------------------------------
    # Check for consistency and return a list of issues
    # Takes as input a list of hashes of attendances (list representation)

    # Aggregate attendance data per day and user
    set key "$attendance_user_id-$attendance_start_date"
    set v [list]
    if {[info exists cell_hash($key)]} { set v $cell_hash($key) }

    # Write attendance data into hash-list
    set list [list]
    set vars {attendance_id attendance_type_id attendance_start_date attendance_start attendance_end attendance_duration_hours ts_sum_per_user_day}
    foreach var $vars { lappend list $var [set $var] }
    lappend v $list
    set cell_hash($key) $v

    # Call consistency checker
    set errors [im_attendance_check_consistency -user_id $attendance_user_id -date $attendance_start_date -attendance_hashs $v]

    # Format the cell "notes" for debugging
    set errors_formatted_for_note_column ""
    if {[llength $errors] > 0} {
	set errors_formatted_for_note_column "<font color=red><ul><li>[join $errors "<br>\n<li>"]</ul></font>"
    }

    # -------------------------------------------------------
    # Format the report footer
    im_report_display_footer \
	-output_format $output_format \
	-group_def $report_def \
	-footer_array_list $footer_array_list \
	-last_value_array_list $last_value_list \
	-level_of_detail $level_of_detail \
	-row_class $class \
	-cell_class $class

    im_report_update_counters -counters $counters


    # Restrict the length of the attendance_note to 40 characters.
    set attendance_note_pretty [string_truncate -len 40 $attendance_note]

    # Format work+break, also for counters
    set attendance_work_pretty ""
    set attendance_break_pretty ""
    if {"" ne $attendance_work} { 
	set attendance_work_pretty [im_report_format_number [expr round(100.0 * $attendance_work) / 100.0] $output_format $number_locale]
    }
    if {"" ne $attendance_break} { 
	set attendance_break_pretty [im_report_format_number [expr round(100.0 * $attendance_break ) / 100.0] $output_format $number_locale] 
    }

    set attendance_date_work_pretty   [im_report_format_number [expr round(100.0 * $attendance_date_work)   / 100.0] $output_format $number_locale]
    set attendance_user_work_pretty   [im_report_format_number [expr round(100.0 * $attendance_user_work)   / 100.0] $output_format $number_locale]
    set attendance_work_total_pretty  [im_report_format_number [expr round(100.0 * $attendance_work_total)  / 100.0] $output_format $number_locale]

    set attendance_date_break_pretty  [im_report_format_number [expr round(100.0 * $attendance_date_break)  / 100.0] $output_format $number_locale]
    set attendance_user_break_pretty  [im_report_format_number [expr round(100.0 * $attendance_user_break)  / 100.0] $output_format $number_locale]
    set attendance_break_total_pretty [im_report_format_number [expr round(100.0 * $attendance_break_total) / 100.0] $output_format $number_locale]

    set vars {
	attendance_user_work_pretty attendance_date_work_pretty attendance_work_total_pretty 
	attendance_date_break_pretty attendance_user_break_pretty attendance_break_total_pretty
    }
    foreach var $vars {
	if {"0.00" eq [set $var]} { set $var "" }
    }


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

