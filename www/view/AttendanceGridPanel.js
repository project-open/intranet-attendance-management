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


Ext.define('AttendanceManagement.view.AttendanceGridPanel', {
    extend: 'Ext.grid.Panel',
    layout: 'fit',
    region: 'center',
    store: 'attendanceStore',
    
    attendanceController: null,        // Set during init
    // plugins: Set during launch: [rowEditing],

    features: [{
        id: 'dayGrouping',
        ftype: 'grouping',        // 'groupingsummary' or 'grouping'
        groupHeaderTpl: [
	    '{name:this.weekday}, ',
	    '{name} ',
            'mit',
	    ' {rows:this.hours} ',
	    'in',
            ' {rows:this.entries} ',
            ' <img class="groupAddButtonClass" src="/intranet/images/navbar_default/page_white_copy.png" title="Copy &amp; Paste">',
            {
                weekday: function(name) { 
                    var dayOfWeek = new Date(name).getDay();
                    if (dayOfWeek) return DAY_NAME_OF_WEEK_SHORT[dayOfWeek];
                    return 'Error';
                },
                hours: function(rows) {
		    var hours = 0.0;
		    rows.forEach(function(model) {
			var startIso = model.get('attendance_start');
			var endIso = model.get('attendance_end');
			if ("" == startIso || "" == endIso) return "";

			// Exclude breaks from the sum
			var attendance_type_id = model.get('attendance_type_id');
			if ("92110" == attendance_type_id) return "";
			
			var startDate = PO.Utilities.pgToDate(startIso);
			var endDate = PO.Utilities.pgToDate(endIso);
			var diffSeconds = (endDate.getTime() - startDate.getTime()) / 1000.0;
			var diffMinutes = diffSeconds / 60.0;
			var diffHours = Math.round(100.0 * diffMinutes / 60.0) / 100.0;
			
			hours = hours + diffHours;
		    });
                    return Ext.util.Format.number(hours, '0.00')+"h";
                },
		entries: function(rows) {
		    if (rows.length != 1) {
			return rows.length + ' Einträgen';
		    } else {
			return '1 Eintrag';
		    }
		}
            }
        ],
        hideGroupedHeader: false,
        startCollapsed: false,
        enableGroupingMenu: true,

        /**
         * Overwriting the onGroupClick function, because the groupclick
         * event doesn't work for some reason.
         */
        onGroupClick: function(view, rowElement, groupName, e) {
            var targetClassName = e.target.className;
            if ("groupAddButtonClass" == targetClassName) {
                // The user clicked on the (+)
                console.log('AttendanceGroupPanel.grouping.onGroupClick: About to copy values to new day');
                
                // attendanceController is global. A bit ugly...
                attendanceController.onGroupButtonCopy.apply(attendanceController, arguments);
            } else {
                var result = Ext.grid.feature.Grouping.prototype.onGroupClick.apply(this, arguments);
                return result;
            }
        },

	listeners: {
	    groupcollapse: function() { attendanceController.onGroupCollapse.apply(attendanceController, arguments); },
	    groupexpand: function() { attendanceController.onGroupExpand.apply(attendanceController, arguments); }
	}
    }],

    initComponent: function() {
        console.log('AttendanceGripPanel.initComponent: Starting');
        this.callParent();
        console.log('AttendanceGripPanel.initComponent: after callParent()');

        // this.groupingFeature = this.view.getFeature('dayGrouping');
    },

    columns: [
        {
            text: l10n.Heading_ID, width: 60, dataIndex: 'id', hidden: true
        }, {
            text: l10n.Heading_Type,
            dataIndex: 'attendance_type_id',
            renderer: function(value){
                var attendanceTypeStore = Ext.StoreManager.get('attendanceTypeStore');
                var model = attendanceTypeStore.getById(value);
                var result = model.get('category_translated');
                return result;
            },
            editor: {
                xtype:                  'combo',
                store:                  'attendanceTypeStore',
                displayField:           'category_translated',
                valueField:             'category_id',
            },

            summaryType: 'count',
            summaryRenderer: function(value, summaryData, dataIndex) {
                // return "<b>" + ((value === 0 || value > 1) ? '(' + value + ' Tasks)' : '(1 Task)') + "</b>";
            }
        }, {
            text: l10n.Heading_DayOfWeek,
            hidden: false,
            width: 50,
            // Don't put a dataIndex here, rowEditing editor will stop
            renderer: function(v, html, model) {
                var dateIso = model.get('attendance_start');
                var date = PO.Utilities.pgToDate(dateIso);
                var dayOfWeek = date.getDay();
                if (dayOfWeek) return DAY_NAME_OF_WEEK_SHORT[dayOfWeek];
                return "Err"
            },
        }, {
            text: l10n.Heading_Date,
            dataIndex: 'attendance_date', 
            renderer: function(v) {
                var t = typeof(v);
                if (t == "string") { return v; }
                return t;
            },
            editor: {
                xtype: 'podatefield',
                allowBlank: true,
                startDay: week_start_day,
                format: 'Y-m-d',
                allowBlank: false
            }
        }, {
            text: l10n.Heading_Start,
            xtype: 'templatecolumn',
            tpl: '{attendance_start_time}',
            dataIndex: 'attendance_start_time',
            editor: {
                xtype: 'combobox',
                triggerAction: 'all',
                selectOnTab: true,
                store: timeEntryStore
                // Validation in model
            }
        }, {
            text: l10n.Heading_End, 
            dataIndex: 'attendance_end_time',
            editor: {
                xtype: 'combobox',
                triggerAction: 'all',
                selectOnTab: true,
                store: timeEntryStore
                // Validation in model
            }
        }, {
            text: l10n.Heading_Duration,
            width: 70,
            editor: false,
            renderer: function(dunno, cell, model, pos) {
                var startIso = model.get('attendance_start');
                var endIso = model.get('attendance_end');
                if ("" == startIso || "" == endIso) return "";
                
                var startDate = PO.Utilities.pgToDate(startIso);
                var endDate = PO.Utilities.pgToDate(endIso);
                var diffSeconds = (endDate.getTime() - startDate.getTime()) / 1000.0;
                var diffMinutes = diffSeconds / 60.0;
                var diffHours = Math.round(100.0 * diffMinutes / 60.0) / 100.0;
                return ""+Ext.util.Format.number(diffHours, '0.00')+"h";
            },

            summaryType: function(modelArray, column) {
                console.log(modelArray);
                var diffHours = 0.0
                for (var i = 0; i < modelArray.length; i++) {
                    var model = modelArray[i];

                    var startIso = model.get('attendance_start');
                    var endIso = model.get('attendance_end');
                    if ("" == startIso || "" == endIso) 
                        continue;
                    
                    var startDate = PO.Utilities.pgToDate(startIso);
                    var endDate = PO.Utilities.pgToDate(endIso);
                    var diffSeconds = (endDate.getTime() - startDate.getTime()) / 1000.0;
                    var diffMinutes = diffSeconds / 60.0;
                    var diffHours = diffHours + diffMinutes / 60.0;
                }
                return diffHours;

            },
            summaryRenderer: function(value, summaryData, dataIndex) { 
                var roundedHours = Math.round(100.0 * value) / 100.0;
                return "<b>"+Ext.util.Format.number(roundedHours, '0.00')+"h</b>";
            }
        }, {
            text: l10n.Heading_Note, flex: 1, dataIndex: 'attendance_note',
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

