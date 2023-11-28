/* 
 * /intranet-attendance-management/www/controller/AttendanceController.js
 *
 * Copyright (C) 2021-2023 ]project-open[
 * All rights reserved. Please see
 * https://www.project-open.com/license/sencha/ for details.
 *
 * Controller for interaction between buttons and grid
 */
Ext.define('AttendanceManagement.controller.AttendanceController', {
    extend: 'Ext.app.Controller',

    // Variables
    debug: true,

    // Parameters
    'renderDiv': null,
    'current_user_id': null,
    
    'attendanceStore': null,
    'attendanceButtonPanel': null,
    'attendanceController': null,
    'attendanceGrid': null,
    'attendanceGridRowEditing': null,
    'initial_date_ansi': null,                // ANSI date for initial load of store, from portlet params

    'attendanceWeekDate': null,               // Monday 00:00:00 of the current week

    // Setup the various listeners so that everything gets concentrated here on this controller.
    init: function() {
        var me = this;
        if (me.debug) { console.log('AttendanceController: init'); }
        
        this.control({
            '#buttonStartWork': { click: this.onButtonStartWork },
            '#buttonStartBreak': { click: this.onButtonStartBreak },
            '#buttonStop': { click: this.onButtonStop },
            '#buttonDelete': { click: this.onButtonDelete },
            '#buttonPreviousWeek': { click: this.onButtonPreviousWeek },
            '#buttonNextWeek': { click: this.onButtonNextWeek },
            scope: me.attendanceGrid
        });

        // Listen to a click into the empty space below the grid entries in order to start creating a new entry
        me.attendanceGrid.on('containerclick', this.onGridContainerClick, me);

        // Listen to changes in the selction model in order to enable/disable the start/stop buttons
        me.attendanceGrid.on('selectionchange', this.onGridSelectionChange, me);

        // Listen to the Grid Editor that allows to specify start- and end time
        me.attendanceGrid.on('edit', this.onGridEdit, me);

        // Catch a global key strokes. This is used to abort entry with Esc.
        // For some reaons this doesn't work on the level of the AttendancePanel, so we go for the global "window"
        Ext.EventManager.on(window, 'keydown', this.onWindowKeyDown, me);

        // Load the attendance store for the current/select week
        // me.loadCurrentWeekAttendanceStore(me.initial_date_ansi);
        var initialDate = new Date();
        if (me.initial_date_ansi && "" != me.initial_date_ansi) {
            initialDate = new Date(me.initial_date_ansi);
        }
        me.loadAttendanceStore(initialDate);

        return me;
    },


    /* *****************************************************************************************
       Common/Auxillary functions
    ***************************************************************************************** */

    /**
     * Return Monday 00:00:00 of the current week
     */  
    getMonday: function (d) {
        d = new Date(d);
        var day = d.getDay(),
        diff = d.getDate() - day + (day == 0 ? -6 : 1); // adjust when day is sunday

        var result = new Date(d.setDate(diff));
        result.setHours(0);
        result.setMinutes(0);
        result.setSeconds(0);

        return result;
    },


    /**
     * Set the current week and load attendance store
     */
    loadCurrentWeekAttendanceStore: function() {
        var me = this;
        console.log('AttendanceController.loadCurrentWeekAttendanceStore: ');

        var todayDate = new Date();
        var mondayDate = me.getMonday(todayDate);
        me.loadAttendanceStore(mondayDate);
    },

    /**
     * Load the store for a given week
     */
    loadAttendanceStore: function(date) {
        var me = this;
        console.log('AttendanceController.loadAttendanceStore: '+date.toISOString());

        // Get Monday and Sunday of the current week
        var mondayDate = me.getMonday(date);
        var sundayDate = new Date(mondayDate.getTime() + 1000.0 * 3600 * 24 * 7 - 1000.0 * 1);

        // Store the new Monday into the Controller
        me.attendanceWeekDate = mondayDate;

        var startISO = Ext.Date.format(me.attendanceWeekDate, 'Y-m-d');
        var endISO = Ext.Date.format(sundayDate, 'Y-m-d');
        var query = "attendance_start between '" + startISO + "' and '" + endISO + "'";
        me.attendanceStore.getProxy().extraParams = { 
            attendance_user_id: me.current_user_id,
            format: 'json',
            query: query
        };
        me.attendanceStore.load({
            callback: function() {
                console.log('AttendanceStore: callback: loaded');

                // Setup default buttons once store has been loaded
                me.enableDisableButtons();
                me.checkConsistency();
            }
        });

        // Set the date into the label
        var labelWeek = Ext.getCmp('labelWeek');
        labelWeek.setText(startISO + ' - ' + endISO);
    },

    /**
     * Used to stop the current logging 
     */  
    abortWork: function() {
        var me = this;
        console.log('AttendanceController.abortWork');

        // Delete the started line in the editor
        me.attendanceGridRowEditing.cancelEdit();
    },


    /**
     * How many entries are "open" (not finished) this week?
     * This would actually need to incorporate entries from
     * other weeks, but we'll skip this here, because it
     * is really just a convenience function.
     */  
    getOpenAttendanceEntriesCount: function() {
        var me = this;
        console.log('AttendanceController.getOpenAttendanceEntriesCount');

        var count = 0;
        me.attendanceStore.each(function(item) {

            var end = item.get('attendance_end');
            if ("" == end) { count++; }
        });

        return count;
    },

    /**
     * Check for consistency of the weeek and issue error message(s).
     */  
    checkConsistency: function() {
        var me = this;
        console.log('AttendanceController.checkConsistency');

        // Count the entries with no end time
        var openItemsCount = 0;

        // Count entries with end time before start time
        var endBeforeStartCount = 0;

        // Count breaks that are too short
        var breaksTooShort = 0;

        // Itervals of more than a day
        var intervalTooLong = 0;
        
        me.attendanceStore.each(function(item) {
            var endIso = item.get('attendance_end');
            var startIso = item.get('attendance_start');
            var type_id = item.get('attendance_type_id');

            if ("" == endIso) {
                openItemsCount++;
            } else {
                var startDate = new Date(startIso);
                var endDate = new Date(endIso);
                if (endDate.getTime() < startDate.getTime()) endBeforeStartCount++;

                var durationMs = endDate.getTime() - startDate.getTime();
                var durationMinutes = Math.round(10.0 * durationMs / 1000.0 / 60.0 ) / 10.0;

                if (durationMinutes > 12.0 * 60.0) intervalTooLong++
                
                switch (type_id) {
                case "92100": { break; }            // Work
                case "92110": {                            // Break
                    if (durationMinutes < 15) breaksTooShort++;
                    break;
                }
                default: {}
                }
                    
            }
        });

        var message = "";
        var issueCount = 0;
        
        // Is there more then one ongoing attendance?
        // There should be never more than one...
        if (openItemsCount > 1) {
            issueCount = issueCount + openItemsCount-1;
            message = message + '<li>Found ' + openItemsCount + ' attendance entríes without end-time.' +
                '<br>There should be at most one of them.'
        }

        // End time before start time?
        if (endBeforeStartCount > 0) {
            issueCount = issueCount + endBeforeStartCount;
            message = message + '<li>Found entries with end time before start time.'
        }

        // Breaks shorter than 15min
        if (breaksTooShort > 0) {
            issueCount = issueCount + breaksTooShort;
            message = message + '<li>Found '+breaksTooShort+' breaks shorter than 15 min.'
        }

        // Interval Too long
        if (intervalTooLong > 0) {
            issueCount = issueCount + intervalTooLong;
            message = message + '<li>Found ' + intervalTooLong + ' items with more than 12 hours.'
        }

        if ("" != message) {
            message = "<ul>" + message + "</ul>" + '<br>Please edit manually to resolve the ' + issueCount + ' issue(s).'
            var title = 'Inconsistent attendance data';
            var msgBox = Ext.create('Ext.window.MessageBox', {});
            msgBox.show({
                title: title,
                msg: message,
                minWidth: 500,
                minHeight: 150,
                buttonText: { yes: "OK" },
                icon: Ext.Msg.INFO
            });
        }
    },

    
    /**
     * Find the first "open" (no end time) item in the store from today.
     *
     * There should really be exactly one open item, but try to 
     * be robust and deal gracefully with inconsistent states.
     * Returns null if there is no open item.
     */  
    findFirstOpenAttendanceEntryToday: function() {
        var me = this;
        console.log('AttendanceController.getOpenAttendanceEntriesCount');

        var firstOpenItem = null;
        me.attendanceStore.each(function(item) {
            var end = item.get('attendance_end');
            if ("" == end) {                            // don't overwrite if already found
                if (null == firstOpenItem) firstOpenItem = item;
            }
        });

        return firstOpenItem;
    },


    /*
     * Start logging an attendance
     */
    createNewAttendance: function(attendance_type_id) {
        var me = this;
        console.log('AttendanceController.createNewAttendance: '+attendance_type_id);

        // ToDo: Check that there is no other line currently open with an empty end-date
                
        me.attendanceGridRowEditing.cancelEdit();

        // Start logging
        var now = new Date();
        var startTime = /\d\d:\d\d/.exec(""+now)[0];
        var startDateIso = now.toISOString().substring(0,10);

        // The Attendance object is a 1:1 reflection of what is in the DB,
        // so all attributes are strings.
        var attendance = new Ext.create('AttendanceManagement.model.Attendance', {
            attendance_user_id: ""+me.current_user_id,
            attendance_type_id: ""+attendance_type_id, // Attendance
            attendance_status_id: ""+92020, // Active
            attendance_date: startDateIso,
            attendance_start_time: startTime,
            attendance_start: startDateIso+' '+startTime, // no time zone -> current TZ
            attendance_note: ""
        });
        
        // Add to end of the store and sync
        var addResult = me.attendanceStore.add(attendance);

        me.enableDisableButtons();
    },
    
    
    /**
     * Set the enabled/disabled status of all buttons
     */  
    enableDisableButtons: function() {
        var me = this;
        console.log('AttendanceController.enableDisableButtons');

        var buttonStartWork = Ext.getCmp('buttonStartWork');
        var buttonStartBreak = Ext.getCmp('buttonStartBreak');
        var buttonDelete = Ext.getCmp('buttonDelete');
        var buttonStop = Ext.getCmp('buttonStop');

        // Check if we are showing the current week.
        // Otherwise just disable all buttons.
        var currentWeekMonday = me.getMonday(new Date());
        var currentWeekISO = Ext.Date.format(currentWeekMonday, 'Y-m-d')
        var controllerWeekISO = Ext.Date.format(me.attendanceWeekDate, 'Y-m-d')
        if (currentWeekISO != controllerWeekISO) {
            buttonStartWork.disable();
            buttonStartBreak.disable()
            buttonDelete.disable();
            buttonStop.disable();
            return;
        }
        
        // Get the number of selected entries
        var selection = me.attendanceGrid.getSelectionModel().getSelection();
        var selectionLen = selection.length;

        // Get the number of entries without end date
        var openItemsCount = me.getOpenAttendanceEntriesCount();

        // Delete is enabled if one item is selected, disabled otherwise.
        buttonDelete.setDisabled(1 != selectionLen);
        
        // Stop is enabled, if at least one item is "open"
        // Stop will handle the case of more than item being open.
        buttonStop.setDisabled(0 == openItemsCount);

        // StartWork is enabled if no item is open
        // StartBreak is enabled if no item is open
        buttonStartWork.setDisabled(0 != openItemsCount);
        buttonStartBreak.setDisabled(0 != openItemsCount);
    },

    
    /* *****************************************************************************************
       GUI Events: Grid and key events
    ***************************************************************************************** */

    /**
     * The user has edited some entry.
     * We now have to set attendance_start and attendance_end
     * (the actual fields stored in the DB) based on date, 
     * start_time and end_time.
     */
    onGridEdit: function(editor, context) {
        var me = this;
        console.log('AttendanceController.onGridEdit');
        var rec = context.record;
        
        var attendance_date = rec.get('attendance_date');
        var attendance_start = rec.get('attendance_start');
        var attendance_start_time = rec.get('attendance_start_time');
        var attendance_end = rec.get('attendance_end');
        var attendance_end_time = rec.get('attendance_end_time');
        if ("" == attendance_start_time) { attendance_start_time = null; }
        if ("" == attendance_end_time) { attendance_end_time = null; }

        // Datefield in column converts attendance_date to Date.
        if (typeof(attendance_date) == 'object') {
            attendance_date = attendance_date.toISOString().substring(0,10);
            rec.set('attendance_date', attendance_date);
        }

        // Calculate attendance_start and attendance_end based on time values
        if (attendance_date != null) {
            if (attendance_start_time != null) {
                rec.set('attendance_start', attendance_date + ' ' + attendance_start_time);
            } else {
                rec.set('attendance_start', "");
            }
            
            if (attendance_end_time != null) {
                rec.set('attendance_end', attendance_date + ' ' + attendance_end_time);
            } else {
                rec.set('attendance_end', "");
            }
        }

        rec.save();
        
        me.enableDisableButtons();
        me.checkConsistency();
    },

    // Esc (Escape) button pressed somewhere in the application window
    onWindowKeyDown: function(e) {
        var me = this;
        var keyCode = e.getKey();
        var keyCtrl = e.ctrlKey;
        console.log('AttendanceController.onWindowKeyDown: code='+keyCode+', ctrl='+keyCtrl);
        
        // Delete key has same function as Delete Button
        if (46 == keyCode) { me.onButtonDelete(); }

        // ToDo: Not clear how to handle "cancel" ESC key.
        // Cancel current logging? -> Delete last entry
        // if (27 == keyCode) { me.onButtonCancelWork(); }

        // Status engine handled in the CancelWork and Delete functions
    },

    /**
     * Handle various key actions
     */
    onCellKeyDown: function(table, htmlTd, cellIndex, record, htmlTr, rowIndex, e, eOpts) {
        var me = this;
        console.log('AttendanceController.onCellKeyDown');
        var keyCode = e.getKey();
        var keyCtrl = e.ctrlKey;

        me.enableDisableButtons();

        console.log('AttendanceController.onCellKeyDown: code='+keyCode+', ctrl='+keyCtrl);
    },
    
    // Click into the empty space below the grid entries in order to start creating a new entry
    onGridContainerClick: function() {
        var me = this;
        console.log('AttendanceController.onGridContainerClick');
        var buttonStartWork = Ext.getCmp('buttonStartWork');
        var disabled = buttonStartWork.disabled;
        if (!disabled) {
            me.onButtonStartWork();
        }

        me.enableDisableButtons();
        me.checkConsistency();
    },



    /* *****************************************************************************************
       Button events
    ***************************************************************************************** */
    
    /*
     * Start logging working time
     */
    onButtonStartWork: function() {
        var me = this;
        console.log('AttendanceController.onButtonStartWork');

        me.selectCurrentWeek();

        me.createNewAttendance(92100); // Work attendance
        me.checkConsistency();
    },

    /*
     * Start a break
     */
    onButtonStartBreak: function() {
        var me = this;
        console.log('AttendanceController.onButtonStartBreak');

        me.selectCurrentWeek();

        me.createNewAttendance(92110); // Break
        me.checkConsistency();
    },

    /**
     * Add end to the only (hopefully...) entry without end in this week.
     * We also have to deal with zero or multiple "open" entries.
     */
    onButtonStop: function() {
        var me = this;
        console.log('AttendanceController.onButtonStop');

        me.selectCurrentWeek();

        // Make sure no editing is in course
        me.attendanceGridRowEditing.cancelEdit();

        // Search for the first open item in the store this week
        var item = me.findFirstOpenAttendanceEntryToday();
        if (item) {
            // Complete the attendance and set end time and attendance_end
            var now = new Date();
            var nowTimeISO = /\d\d:\d\d/.exec(""+now)[0];
            var startDateISO = item.get('attendance_date');

            // Create attendance_end with date from start (<12h...)
            item.set('attendance_end_time', nowTimeISO);
            item.set('attendance_end', startDateISO + ' ' + nowTimeISO);
            item.save();
        }
        
        me.enableDisableButtons();
        me.checkConsistency();
    },

    
    onButtonDelete: function() {
        var me = this;
        console.log('AttendanceController.onButtonDelete');

        me.selectCurrentWeek();

        var selModel = me.attendanceGrid.getSelectionModel();
        var records = selModel.getSelection();

        // Not logging already - enable the "start" button
        if (1 == records.length) {                  // Exactly one record enabled

            // Select the next row
            selModel.selectPrevious(false);
            // selModel.selectNext(false);

            var record = records[0];
            me.attendanceStore.remove(record);
            record.destroy();
        }

        me.enableDisableButtons();
        me.checkConsistency();
    },

    /**
     * Clicking around in the grid part of the screen,
     * Enable or disable the "Delete" button
     */
    onGridSelectionChange: function(view, records) {
        var me = this;
        if (me.debug) { console.log('AttendanceController.onGridSelectionChange'); }

        me.enableDisableButtons();
    },

    /**
     * Executed before starting to log hours
     * to select the current week.
     */
    selectCurrentWeek: function() {
        var me = this;
        console.log('AttendanceController.selectCurrentWeek');

        var todayDate = new Date();
        var thisWeekMondayDate = me.getMonday(todayDate);

        if (Math.abs(me.attendanceWeekDate.getTime() - thisWeekMondayDate.getTime()) > 10000) {
            console.log('AttendanceController.selectCurrentWeek: Different week');
            this.loadCurrentWeekAttendanceStore();
        }
    },
    
    onButtonPreviousWeek: function() {
        var me = this;
        console.log('AttendanceController.onButtonPreviousWeek');

        // Forward to next week
        me.attendanceWeekDate = new Date(me.attendanceWeekDate.getTime() - 1000.0 * 3600 * 24 * (7-1));
        me.loadAttendanceStore(me.attendanceWeekDate);
    },

    onButtonNextWeek: function() {
        var me = this;
        console.log('AttendanceController.onButtonNextWeek');

        // Forward to next week
        me.attendanceWeekDate = new Date(me.attendanceWeekDate.getTime() + 1000.0 * 3600 * 24 * (7+1));
        me.loadAttendanceStore(me.attendanceWeekDate);
    }    
    
});

