/* 
 * /intranet-attendance-management/www/store/AttendanceStore.js
 *
 * Copyright (C) 2021-2023 ]project-open[
 * All rights reserved. Please see
 * https://www.project-open.com/license/sencha/ for details.
 *
 */
Ext.define('AttendanceManagement.store.AttendanceStore', {
    extend:         'Ext.data.Store',
    model: 	    'AttendanceManagement.model.Attendance',
    storeId:	    'attendanceStore',
    autoLoad:	    false, // Load manually per week
    autoSync:	    true, // immediately write changes to backend
    pageSize:	    10000, // just load everything
    
    sorters: [
        {property: 'attendance_start', direction: 'ASC'}
    ],
    proxy: {
        type:       'rest',
        url:        '/intranet-rest/im_attendance_interval',
        appendId:   true,
        extraParams: {
            format: 'json'
        },
        reader: { 
	    type: 'json', 
	    root: 'data' 
	}
    },

    listeners: {
        // ToDo: Fraber 2023-11-06: Eliminate?
        update: function(store, record, operation, modifiedFields) { 
            console.log('AttendanceStore: operation: ' + operation + ',  update: '+record + ', modified='+modifiedFields);
            if ("commit" == operation) { return; }
            // if (store.isLoading()) { return; }
        },

        // Extract the editable fields attendance_date, start_time and end_time
        // from the data returned by the ]po[ REST interface.
        load: function(store, records, successful, eOpts) {
            if (null == records) { return; }
            console.log('AttendanceStore: load: ');

            var regexp = /(\d\d:\d\d)/;
            for (var i = 0; i < records.length; i++) {
                var rec = records[i];
                var start = rec.get('attendance_start');
                var end = rec.get('attendance_end');

                // Update the data WITHOUT using rec.set(...)
                rec.data['attendance_date'] = start.substring(0,10);
                var regArr = regexp.exec(start);
                rec.data['attendance_start_time'] = regArr[1];
                if ("" != end) {
                    var regArr = regexp.exec(end);
                    rec.data['attendance_end_time'] = regArr[1];
                }

                store.afterEdit(rec, ['attendance_date', 'attendance_start_time', 'attendance_end_time']);
            }

            // Not sure about this.
            var isLoading = store.isLoading();
            store.loading = true;
            store.loading = isLoading;
        }
    }
});

