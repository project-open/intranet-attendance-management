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
            '#buttonStartLogging': { click: this.onButtonStartLogging },
            '#buttonStopLogging': { click: this.onButtonStopLogging },
            '#buttonCancelLogging': { click: this.onButtonCancelLogging },
            '#buttonManualLogging': { click: this.onButtonManualLogging },
            '#buttonDeleteLogging': { click: this.onButtonDeleteLogging },
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
    
    /*
     * The user has double-clicked on the row editor in order to
     * manually fill in the values. This procedure automatically
     * fills in the end_time.
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

    // 
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

    },

    // Esc (Escape) button pressed somewhere in the application window
    onWindowKeyDown: function(e) {
        var keyCode = e.getKey();
        var keyCtrl = e.ctrlKey;
        console.log('AttendanceController.onWindowKeyDown: code='+keyCode+', ctrl='+keyCtrl);
        
        // cancel hour logging with Esc key
        if (27 == keyCode) { this.onButtonCancelLogging(); }
        if (46 == keyCode) { this.onButtonDeleteLogging(); }
    },

    // Click into the empty space below the grid entries in order to start creating a new entry
    onGridContainerClick: function() {
        console.log('AttendanceController.GridContainerClick');
        var buttonStartLogging = Ext.getCmp('buttonStartLogging');
        var disabled = buttonStartLogging.disabled;
        if (!disabled) {
            this.onButtonStartLogging();
        }
    },

    /*
     * Start logging the time.
     */
    onButtonStartLogging: function() {
        console.log('AttendanceController.ButtonStartLogging');

        var buttonStartLogging = Ext.getCmp('buttonStartLogging');
        var buttonStopLogging = Ext.getCmp('buttonStopLogging');
        var buttonCancelLogging = Ext.getCmp('buttonCancelLogging');
        var buttonManualLogging = Ext.getCmp('buttonManualLogging');
        var buttonDeleteLogging = Ext.getCmp('buttonDeleteLogging');
        buttonStartLogging.disable();
        buttonStopLogging.enable();
        buttonCancelLogging.enable();
        buttonManualLogging.disable();
        buttonDeleteLogging.disable();

        this.attendanceGridRowEditing.cancelEdit();

        // Start logging
        this.loggingStartDate = new Date();

        var attendance = new Ext.create('AttendanceManagement.model.Attendance', {
            attendance_user_id: this.current_user_id,
            attendance_type_id: 92100, // Attendance
            attendance_status_id: 92020, // Active
            attendance_date: this.loggingStartDate,
            attendance_start_time: /\d\d:\d\d/.exec(""+new Date())[0],
            attendance_note: 'asdf'
        });
        
        // Remember the new attendance, add to store and start editing
        this.loggingAttendance = attendance;
        this.attendanceStore.add(attendance);
        //var rowIndex = this.attendanceStore.count() -1;
        // this.attendanceGridRowEditing.startEdit(0, 0);
    },

    /**
     * Start logging the time, for entirely manual entries.
     */
    onButtonManualLogging: function() {
        console.log('AttendanceController.ButtonManualLogging');
        this.onButtonStartLogging();
        this.attendanceGridRowEditing.startEdit(this.loggingAttendance, 0);
    },

    onButtonStopLogging: function() {
        console.log('AttendanceController.ButtonStopLogging');
        var buttonStartLogging = Ext.getCmp('buttonStartLogging');
        var buttonStopLogging = Ext.getCmp('buttonStopLogging');
        var buttonCancelLogging = Ext.getCmp('buttonCancelLogging');
        var buttonManualLogging = Ext.getCmp('buttonManualLogging');
        buttonStartLogging.enable();
        buttonStopLogging.disable();
        buttonCancelLogging.disable();
        buttonManualLogging.enable();

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
    },

    onButtonCancelLogging: function() {
        console.log('AttendanceController.ButtonCancelLogging');
        var buttonStartLogging = Ext.getCmp('buttonStartLogging');
        var buttonStopLogging = Ext.getCmp('buttonStopLogging');
        var buttonCancelLogging = Ext.getCmp('buttonCancelLogging');
        var buttonManualLogging = Ext.getCmp('buttonManualLogging');

        buttonStartLogging.enable();
        buttonStopLogging.disable();
        buttonCancelLogging.disable();
        buttonManualLogging.enable();

        // Delete the started line
        this.attendanceGridRowEditing.cancelEdit();
        this.attendanceStore.remove(this.loggingAttendance);

        // Stop logging
        this.loggingStartDate = null;
    },

    onButtonDeleteLogging: function() {
        console.log('AttendanceController.ButtonDeleteLogging');
        var records = this.attendanceGrid.getSelectionModel().getSelection();
        // Not logging already - enable the "start" button
        if (1 == records.length) {                  // Exactly one record enabled
            var record = records[0];
            this.attendanceStore.remove(record);
            record.destroy();
        }

        // Stop logging
        this.loggingStartDate = null;
    },

    /**
     * Clicking around in the grid part of the screen,
     * Enable or disable the "Delete" button
     */
    onGridSelectionChange: function(view, records) {
        if (this.debug) { console.log('AttendanceController.onGridSelectionChange'); }
        var buttonDeleteLogging = Ext.getCmp('buttonDeleteLogging');
        buttonDeleteLogging.setDisabled(1 != records.length);
    },


    /**
     * Handle various key actions
     */
    onCellKeyDown: function(table, htmlTd, cellIndex, record, htmlTr, rowIndex, e, eOpts) {
        console.log('AttendanceController.onCellKeyDown');
        var keyCode = e.getKey();
        var keyCtrl = e.ctrlKey;
        console.log('AttendanceController.onCellKeyDown: code='+keyCode+', ctrl='+keyCtrl);
    },


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

