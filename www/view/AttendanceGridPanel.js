/* 
 * /intranet-attendance-management/www/view/AttendanceButtonPanel.js
 *
 * Copyright (C) 2021-2023 ]project-open[
 * All rights reserved. Please see
 * https://www.project-open.com/license/sencha/ for details.
 *
 * Attendance interval is time that an employee is present
 * "at work".
 */

// Store for time entries
var timeEntryStore = [];
for (var i = start_hour; i < end_hour; i++) {
    var ii = ""+i;
    if (ii.length == 1) { ii = "0"+i; }
    for (var m = 0; m < 60; m = m + 30 ) {
        var mm = ""+m;
        if (mm.length == 1) { mm = "0"+m; }
        timeEntryStore.push(ii + ':' + mm);
    }
}

var attendanceTypeStore = Ext.StoreManager.get('attendanceTypeStore');

Ext.define('AttendanceManagement.view.AttendanceGridPanel', {
    extend: 'Ext.grid.Panel',
    layout: 'fit',
    region: 'center',
    columns: [
        {
            text: "Type",
            dataIndex: 'attendance_type_id',
	    renderer: function(value){
	        var model = attendanceTypeStore.getById(value);
                var result = model.get('category');
                return result;
            },
	    editor: {
                xtype:                  'combo',
	        store:                  attendanceTypeStore,
                displayField:           'category',
		valueField:             'category_id',
            }
        }, {
            text: "Date",
            xtype: 'datecolumn',
            dataIndex: 'attendance_date', 
            renderer: Ext.util.Format.dateRenderer('Y-m-d'),
            editor: {
                xtype: 'datefield',
                allowBlank: true,
                startDay: week_start_day,
		format: 'Y-m-d'
            }
        }, {
            text: "Start Time",
            xtype: 'templatecolumn',
            tpl: '{attendance_start_time}',
            dataIndex: 'attendance_start_time',
            editor: {
                xtype: 'combobox',
                triggerAction: 'all',
                selectOnTab: true,
                store: timeEntryStore
            }
        }, {
            text: "End Time", 
            dataIndex: 'attendance_end_time',
            editor: {
                xtype: 'combobox',
                triggerAction: 'all',
                selectOnTab: true,
                store: timeEntryStore
            }
        }, {
            text: "Name", flex: 1, dataIndex: 'object_name', hidden: true
        }, {
            text: "Att Start", flex: 1, dataIndex: 'attendance_start', hidden: true
        }, {
            text: "Note", flex: 1, dataIndex: 'attendance_note',
            editor: { allowBlank: true }
        }
    ],
    columnLines: true,
    enableLocking: true,
    collapsible: false,
    title: 'Expander Rows in a Collapsible Grid with lockable columns',
    header: false,
    emptyText: 'No data yet',
    iconCls: 'icon-grid',
    margin: '0 0 20 0'
});

