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

    proxy: {
        type:       'rest',
        url:        '/intranet-rest/im_attendance_interval',
        appendId:   true,

        extraParams: {
            format: 'json',
            query: null,                         // attendance_date betweeen '<start>' and '<end>'
            attendance_user_id: 0,               // Show only for current user, set by controller
        },
        reader: { 
            type: 'json', 
            root: 'data' 
        }
    },

    fields: [
        'id',					// Same as attendance_id, but needed for Sencha magic
        'object_name',

        // Fields stored on the REST Back-end
        'attendance_id',			// Unique object ID 
        'attendance_user_id',			// Who logged the attendance?
        'attendance_status_id',			// Status is always "active"
        'attendance_type_id',			// Type is Work or Break
        'attendance_start',			// Start of time attendance (PostgreSQL timestamp format)
        'attendance_end',			// End od time attendance (PostgreSQL timestamp format)
        'attendance_note',			// Comment for the logged attendance
        'attendance_activity_id',		// Type of activity (meeting, work, ... (customer definable))
        'attendance_material_id',		// Type of service provided during attendance (rarely used)

        // Add-on fields only for editing, but not for storage.
        // These fields are kept in sync with the previous ones using store events.
        'attendance_date',			// Date part of start- and end time
        'attendance_start_time',		// Time part of start date
        'attendance_end_time'			// Time part of end date
    ],

    validations: [
        // {type: 'presence',  field: 'age'},
        // {type: 'length',    field: 'name',     min: 2},
        // {type: 'inclusion', field: 'gender',   list: ['Male', 'Female']},
        // {type: 'exclusion', field: 'username', list: ['Admin', 'Operator']},
        {type: 'format', field: 'attendance_date', matcher: /^\d{4}\-\d{2}\-\d{2}$/ },
        {type: 'format', field: 'attendance_start_time', matcher: /^\d{2}\:\d{2}$/ },
        {type: 'format', field: 'attendance_end_time', matcher: /^\d{2}\:\d{2}$/ }
    ]

});

