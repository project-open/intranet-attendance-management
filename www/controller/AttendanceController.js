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
        me.attendanceGrid.on('beforeedit', this.onGridBeforeEdit, me);

        // Catch a global key strokes. This is used to abort entry with Esc.
        // For some reaons this doesn't work on the level of the AttendancePanel, so we go for the global "window"
        Ext.EventManager.on(window, 'keydown', this.onWindowKeyDown, me);

        // Setup default buttons
        this.enableDisableButtons();

        this.checkConsistency();
        
        return this;
    },


    /* *****************************************************************************************
       Common/Auxillary functions
    ***************************************************************************************** */

    /**
     * Used to stop the current logging 
     */  
    abortWork: function() {
        console.log('AttendanceController.abortWork');

        // Delete the started line in the editor
        this.attendanceGridRowEditing.cancelEdit();
    },


    /**
     * How many entries are "open" (not finished) this week?
     * This would actually need to incorporate entries from
     * other weeks, but we'll skip this here, because it
     * is really just a convenience function.
     */  
    getOpenAttendanceEntriesCount: function() {
        console.log('AttendanceController.getOpenAttendanceEntriesCount');

        var count = 0;
        this.attendanceStore.each(function(item) {

            var end = item.get('attendance_end');
            if ("" == end) { count++; }
        });

        return count;
    },

    /**
     * Check for consistency of the weeek and issue error message(s).
     */  
    checkConsistency: function() {
        console.log('AttendanceController.checkConsistency');

        // Count the entries with no end time
        var openItemsCount = 0;

        // Count entries with end time before start time
        var endBeforeStartCount = 0;

        // Count breaks that are too short
        var breaksTooShort = 0;

        // Itervals of more than a day
        var intervalTooLong = 0;
        
        this.attendanceStore.each(function(item) {
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
                case "92100": { break; }	    // Work
                case "92110": {	        	    // Break
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
        console.log('AttendanceController.getOpenAttendanceEntriesCount');

        var firstOpenItem = null;
        this.attendanceStore.each(function(item) {
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
        console.log('AttendanceController.createNewAttendance: '+attendance_type_id);

        // ToDo: Check that there is no other line currently open with an empty end-date
                
        this.attendanceGridRowEditing.cancelEdit();

        // Start logging
        var now = new Date();
        var startTime = /\d\d:\d\d/.exec(""+now)[0];
        var startDateIso = now.toISOString().substring(0,10);

        // The Attendance object is a 1:1 reflection of what is in the DB,
        // so all attributes are strings.
        var attendance = new Ext.create('AttendanceManagement.model.Attendance', {
            attendance_user_id: ""+this.current_user_id,
            attendance_type_id: ""+attendance_type_id, // Attendance
            attendance_status_id: ""+92020, // Active
            attendance_date: startDateIso,
            attendance_start_time: startTime,
            attendance_start: startDateIso+' '+startTime, // no time zone -> current TZ
            attendance_note: ""
        });
        
        // Add to end of the store and sync
        var addResult = this.attendanceStore.add(attendance);

        this.enableDisableButtons();
    },
    
    
    /**
     * Set the enabled/disabled status of all buttons
     */  
    enableDisableButtons: function() {
        console.log('AttendanceController.enableDisableButtons');

        var buttonStartWork = Ext.getCmp('buttonStartWork');
        var buttonStartBreak = Ext.getCmp('buttonStartBreak');
        var buttonDelete = Ext.getCmp('buttonDelete');
        var buttonStop = Ext.getCmp('buttonStop');

        // buttonStartWork.disable();
        // buttonStartWork.enable();
        
        var selection = this.attendanceGrid.getSelectionModel().getSelection();
        var selectionLen = selection.length;

        var openItemsCount = this.getOpenAttendanceEntriesCount();

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
     * The user has double-clicked on the row editor in order to
     * manually fill in the values. This procedure automatically
     * fills in the end_time.
     * ToDo: Remove? No need to click into the empty space?
     */
    onGridBeforeEdit: function(editor, context, eOpts) {
        console.log('AttendanceController.onGridBeforeEdit');
        console.log(context.record);

        var endTime = context.record.get('attendance_end_time');
        if (typeof endTime === 'undefined' || "" == endTime) {
            endTime = /\d\d:\d\d/.exec(""+new Date())[0];
            context.record.set('attendance_end_time', endTime);
        }
        // Return true to indicate to the editor that it's OK to edit
        return true;
    },

    /**
     * ToDo: Add comment, what is this for?
     */
    onGridEdit: function(editor, context) {
        console.log('AttendanceController.onGridEdit');
        var rec = context.record;
        
        var attendance_date = rec.get('attendance_date');
        var attendance_start = rec.get('attendance_start');
        var attendance_start_time = rec.get('attendance_start_time');
        var attendance_end = rec.get('attendance_end');
        var attendance_end_time = rec.get('attendance_end_time');
        if ("" == attendance_start_time) { attendance_start_time = null; }
        if ("" == attendance_end_time) { attendance_end_time = null; }

        // start == end => Delete the entry
        if (attendance_start_time != null && attendance_end_time != null) {
            if (attendance_start_time == attendance_end_time) {
                rec.destroy();
                return;
            }
        }

        if (attendance_date != null) {
            // The attendance_date has been overwritten by the editor with a Date
            var value = new Date(attendance_date);
            rec.set('attendance_date', Ext.Date.format(value, 'Y-m-d'));
        }

        if (attendance_date != null && attendance_start_time != null) {
            var value = new Date(attendance_date);
            value.setHours(attendance_start_time.substring(0,2));
            value.setMinutes(attendance_start_time.substring(3,5));
            rec.set('attendance_start', Ext.Date.format(value, 'Y-m-d H:i:s'));
        }

        if (attendance_date != null && attendance_end_time != null) {
            var value = new Date(attendance_date);
            value.setHours(attendance_end_time.substring(0,2));
            value.setMinutes(attendance_end_time.substring(3,5));
            rec.set('attendance_end', Ext.Date.format(value, 'Y-m-d H:i:s'));
        }

        rec.save();
        rec.commit();
        
        this.enableDisableButtons();
        this.checkConsistency();
    },

    // Esc (Escape) button pressed somewhere in the application window
    onWindowKeyDown: function(e) {
        var keyCode = e.getKey();
        var keyCtrl = e.ctrlKey;
        console.log('AttendanceController.onWindowKeyDown: code='+keyCode+', ctrl='+keyCtrl);
        
        // Delete key has same function as Delete Button
        if (46 == keyCode) { this.onButtonDelete(); }

        // ToDo: Not clear how to handle "cancel" ESC key.
        // Cancel current logging? -> Delete last entry
        // if (27 == keyCode) { this.onButtonCancelWork(); }

        // Status engine handled in the CancelWork and Delete functions
    },

    /**
     * Handle various key actions
     */
    onCellKeyDown: function(table, htmlTd, cellIndex, record, htmlTr, rowIndex, e, eOpts) {
        console.log('AttendanceController.onCellKeyDown');
        var keyCode = e.getKey();
        var keyCtrl = e.ctrlKey;

        this.enableDisableButtons();

        console.log('AttendanceController.onCellKeyDown: code='+keyCode+', ctrl='+keyCtrl);
    },
    
    // Click into the empty space below the grid entries in order to start creating a new entry
    onGridContainerClick: function() {
        console.log('AttendanceController.onGridContainerClick');
        var buttonStartWork = Ext.getCmp('buttonStartWork');
        var disabled = buttonStartWork.disabled;
        if (!disabled) {
            this.onButtonStartWork();
        }

        this.enableDisableButtons();
        this.checkConsistency();
    },



    /* *****************************************************************************************
       Button events
    ***************************************************************************************** */
    
    /*
     * Start logging working time
     */
    onButtonStartWork: function() {
        console.log('AttendanceController.onButtonStartWork');

        this.createNewAttendance(92100); // Work attendance
        this.checkConsistency();
    },

    /*
     * Start a break
     */
    onButtonStartBreak: function() {
        console.log('AttendanceController.onButtonStartBreak');

        this.createNewAttendance(92110); // Break
        this.checkConsistency();
    },

    /**
     * Add end to the only (hopefully...) entry without end in this week.
     * We also have to deal with zero or multiple "open" entries.
     */
    onButtonStop: function() {
        console.log('AttendanceController.onButtonStop');

        // Make sure no editing is in course
        this.attendanceGridRowEditing.cancelEdit();

        // Search for the first open item in the store this week
        var item = this.findFirstOpenAttendanceEntryToday();
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
        
        this.enableDisableButtons();
        this.checkConsistency();
    },

    
    onButtonDelete: function() {
        console.log('AttendanceController.onButtonDelete');
        var selModel = this.attendanceGrid.getSelectionModel();
        var records = selModel.getSelection();

        // Not logging already - enable the "start" button
        if (1 == records.length) {                  // Exactly one record enabled

            // Select the next row
            selModel.selectPrevious(false);
            // selModel.selectNext(false);

            var record = records[0];
            this.attendanceStore.remove(record);
            record.destroy();
        }

        this.enableDisableButtons();
        this.checkConsistency();
    },

    /**
     * Clicking around in the grid part of the screen,
     * Enable or disable the "Delete" button
     */
    onGridSelectionChange: function(view, records) {
        if (this.debug) { console.log('AttendanceController.onGridSelectionChange'); }

        this.enableDisableButtons();
    },


    /**
     * Executed before starting to log hours
     * to select the current week.
     */
    selectCurrentWeek: function() {
        console.log('AttendanceController.selectCurrentWeek');

    },
    
    onButtonPreviousWeek: function() {
        console.log('AttendanceController.onButtonPreviousWeek');

        // complete the current logging interval
        this.abortWork();
    },

    onButtonNextWeek: function() {
        console.log('AttendanceController.onButtonNextWeek');

        // complete the current logging interval
        this.abortWork();
    },
    

    
    /* *****************************************************************************************
       Resizing
    ***************************************************************************************** */
    
    /**
     * The windows as a whole was resized
     */
    onWindowsResize: function(width, height) {
        console.log('AttendanceController.onWindowResize');
        var me = this;
        var sideBar = Ext.get('sidebar');				// ]po[ left side bar component
        var sideBarSize = sideBar.getSize();
        me.onResize(sideBarSize.width);
    },

    /**
     * The ]po[ left sideBar was resized
     */
    onSideBarResize: function(event, el, config) {
        console.log('AttendanceController.onSideBarResize');
        var me = this;
        var sideBar = Ext.get('sidebar');				// ]po[ left side bar component
        var sideBarSize = sideBar.getSize();

        // We get the event _before_ the sideBar has changed it's size.
        // So we actually need to the the oposite of the sidebar size:
        if (sideBarSize.width > 100) {
            sideBarSize.width = -5;
        } else {
            sideBarSize.width = 245;
        }

        me.onResize(sideBarSize.width);
    },

    /**
     * Generic resizing function, called with the target width of the sideBar
     */
    onResize: function(sideBarWidth) {
        console.log('AttendanceController.onResize: '+sideBarWidth);
        var me = this;
        var screenSize = Ext.getBody().getViewSize();
        var height = me.attendanceButtonPanel.getSize().height;
        var width = screenSize.width - sideBarWidth - 75;
        me.attendanceButtonPanel.setSize(width, height);
    }
    
});

