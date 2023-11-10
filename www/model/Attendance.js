/* 
 * /intranet-attendance-management/www/model/Attendance.js
 *
 * Copyright (C) 2021-2023 ]project-open[
 * All rights reserved. Please see
 * https://www.project-open.com/license/sencha/ for details.
 *
 * Attendance interval is time that an employee is present
 * "at work".
 */
Ext.define('AttendanceManagement.model.Attendance', {
    extend: 'Ext.data.Model',
    fields: [
        'id',					// Same as attendance_id, but needed for Sencha magic
	'object_name',
	'creation_user',
	'creation_date',	

        // Fields stored on the REST Back-end
        'attendance_id',			// Unique object ID 
        'attendance_user_id',			// Who logged the attendance?
        'attendance_status_id',			// 
        'attendance_type_id',			// 
        {name: 'attendance_start', convert: null}, // Start of time attendance (PostgreSQL timestamp format)
        'attendance_end',			// End od time attendance (PostgreSQL timestamp format)
        'attendance_note',			// Comment for the logged attendance
        'attendance_activity_id',		// Type of activity (meeting, work, ... (customer definable))
        'attendance_material_id',		// Type of service provided during attendance (rarely used)

        // Add-on fields only for editing, but not for storage.
        // These fields are kept in sync with the previous ones using store events.
        'attendance_date',	     	     	// Date part of start- and end time
        'attendance_start_time',		// Time part of start date
        'attendance_end_time'			// Time part of end date
    ],

    // Not sure this is actually used.
    // The proxy of the store is more important.
    proxy: {
        type:		'rest',
        url:		'/intranet-rest/im_attendance_interval',
        appendId:	true,			// Append the object_id: ../im_ticket/<object_id>
        timeout:	300000,
        extraParams: { format: 'json' },	// Tell the ]po[ REST to return JSON data.
        reader: { type: 'json', root: 'data' },	// Tell the Proxy Reader to parse JSON
        writer: { type: 'json' }		// Allow Sencha to write changes
    }
});

