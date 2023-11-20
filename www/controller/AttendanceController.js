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

    'loggingStartDate': null,				// contains the time when "start" was pressed or null otherwise
    'loggingAttendance': null,				// the attendance object created when logging

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
     * Set the enabled/disabled status of all buttons
     * Stop is enabled, if one item is "open"
     * StartWork is enabled if no item is open
     * StartBreak is enabled if no item is open
     */  
    enableDisableButtons: function() {
        console.log('AttendanceController.enableDisableButtons');

        var selection = this.attendanceGrid.getSelectionModel().getSelection();
	var selectionLen = selection.length;

        var buttonStartWork = Ext.getCmp('buttonStartWork');
        var buttonStartBreak = Ext.getCmp('buttonStartBreak');
	var buttonDelete = Ext.getCmp('buttonDelete');
	var buttonStop = Ext.getCmp('buttonStop');

	// Delete is enabled if one item is selected, disabled otherwise.
        buttonDelete.setDisabled(1 != selectionLen);

        // buttonStop.setDisabled(1 != selectionLen);

        // buttonStartWork.disable();
        // buttonStartWork.enable();
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
    },

    // Esc (Escape) button pressed somewhere in the application window
    onWindowKeyDown: function(e) {
        var keyCode = e.getKey();
        var keyCtrl = e.ctrlKey;
        console.log('AttendanceController.onWindowKeyDown: code='+keyCode+', ctrl='+keyCtrl);
        
        // cancel hour logging with Esc key
        if (27 == keyCode) { this.onButtonCancelWork(); }
        if (46 == keyCode) { this.onButtonDelete(); }

	this.enableDisableButtons();
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
    },



    /* *****************************************************************************************
       Button events
    ***************************************************************************************** */
    
    /*
     * Start logging the time.
     */
    onButtonStartWork: function() {
        console.log('AttendanceController.onButtonStartWork');

        // ToDo: Check that there is no other line currently open with an empty end-date
                
        this.attendanceGridRowEditing.cancelEdit();

        // Start logging
        this.loggingStartDate = new Date();
        var startTime = /\d\d:\d\d/.exec(""+this.loggingStartDate)[0];
        var startDateIso = this.loggingStartDate.toISOString().substring(0,10);

        // The Attendance object is a 1:1 reflection of what is in the DB,
        // so all attributes are strings.
        var attendance = new Ext.create('AttendanceManagement.model.Attendance', {
            attendance_user_id: ""+this.current_user_id,
            attendance_type_id: ""+92100, // Attendance
            attendance_status_id: ""+92020, // Active
            attendance_date: startDateIso,
            attendance_start_time: startTime,
            attendance_start: startDateIso,
            attendance_note: ""
        });
        
        // Remember the new attendance, add to store and start editing
        this.loggingAttendance = attendance;
        this.attendanceStore.add(attendance);
        this.attendanceStore.sync();

	this.enableDisableButtons();
    },

    onButtonStop: function() {
        console.log('AttendanceController.onButtonStop');

        // Complete the attendance created when starting to log
        this.loggingAttendance.set('attendance_end_time', /\d\d:\d\d/.exec(""+new Date())[0]);

        // Not necesary anymore because the store is set to autosync?
        this.loggingAttendance.save();
        this.attendanceGridRowEditing.cancelEdit();

        // Stop logging
        this.loggingStartDate = null;

        // Continue editing
        var rowIndex = this.attendanceStore.count() -1;
        this.attendanceGridRowEditing.startEdit(rowIndex, 3);

	this.enableDisableButtons();
    },

    
    onButtonDelete: function() {
        console.log('AttendanceController.onButtonDelete');
        var records = this.attendanceGrid.getSelectionModel().getSelection();
        // Not logging already - enable the "start" button
        if (1 == records.length) {                  // Exactly one record enabled
            var record = records[0];
            this.attendanceStore.remove(record);
            record.destroy();
        }

        // Stop logging
        this.loggingStartDate = null;

	this.enableDisableButtons();
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

