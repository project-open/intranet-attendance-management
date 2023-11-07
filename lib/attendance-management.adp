    <div id=@attendance_editor_id@>
    <script type='text/javascript' <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>


// Ext.Loader.setConfig({enabled: true});
Ext.Loader.setPath('PO.model', '/sencha-core/model');
Ext.Loader.setPath('PO.store', '/sencha-core/store');
Ext.Loader.setPath('PO.class', '/sencha-core/class');
Ext.Loader.setPath('PO.view', '/sencha-core/view');
Ext.Loader.setPath('PO.controller', '/sencha-core/controller');

Ext.require([
    'Ext.data.*',
    'Ext.grid.*',
    'PO.store.CategoryStore',
    'PO.controller.StoreLoadCoordinator'
]);


Ext.define('AttendanceManagement.model.Attendance', {
    extend: 'Ext.data.Model',
    fields: [
        'id',					// Same as attendance_id

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

        // Add-on fields for editing, but not for storage.
        // These fields are kept in sync using store events.
        'attendance_date',	     	     	// Date part of start- and end time
        'attendance_start_time',		// Time part of start date
        'attendance_end_time'			// Time part of end date
    ],
    proxy: {
        type:		'rest',
        url:		'/intranet-rest/im_attendance_interval',
        appendId:		true,		// Append the object_id: ../im_ticket/<object_id>
        timeout:		300000,
        extraParams: { format: 'json' },	// Tell the ]po[ REST to return JSON data.
        reader: { type: 'json', root: 'data' },	// Tell the Proxy Reader to parse JSON
        writer: { type: 'json' }		// Allow Sencha to write changes
    }
});


Ext.define('AttendanceManagement.store.AttendanceStore', {
    extend:         'Ext.data.Store',
    model: 	    'AttendanceManagement.model.Attendance',
    storeId:	    'attendanceStore',
    // autoDestroy:    true,
    // autoLoad:	    false,
    // autoSync:	    false,
    // remoteFilter:   true,
    // pageSize:	    1000,
    // sorters: [{property: 'attendance_start', direction: 'DESC' }],
    proxy: {
        type:       'rest',
        url:        '/intranet-rest/im_attendance_interval',
        appendId:   true,
        extraParams: {
            format: 'json',
            user_id: 0,				// Needs to be overwritten by controller
            project_id: 0			// Needs to be overwritten by controller
        },
        reader: { type: 'json', root: 'data' }
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
                var regArr = regexp.exec(end);
                rec.data['attendance_end_time'] = regArr[1];

                store.afterEdit(rec, ['attendance_date', 'attendance_start_time', 'attendance_end_time']);
            }

            var isLoading = store.isLoading();
            store.loading = true;
            store.loading = isLoading;
        }
    }
});


// -----------------------------------------------------------------------
// Button bar
//
Ext.define('AttendanceManagement.view.AttendanceButtonPanel', {
    extend: 'Ext.panel.Panel',
    alias: 'ganttButtonPanel',
    layout: 'border',
    defaults: {
        collapsible: true,
        split: true,
        bodyPadding: 0
    },
    tbar: [{
        icon: '/intranet/images/navbar_default/clock_go.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Start_logging "Start logging"] %>',
        id: 'buttonStartLogging',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/clock_stop.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Stop_logging "Stop logging and save"] %>',
        id: 'buttonStopLogging',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/clock_delete.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Cancel_logging "Cancel logging"] %>',
        id: 'buttonCancelLogging',
        disabled: true
    }, {
        icon: '/intranet/images/navbar_default/add.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Manual_logging "Manual logging"] %>',
        id: 'buttonManualLogging',
        disabled: false
    }, {
        icon: '/intranet/images/navbar_default/delete.png',
        tooltip: '<%= [lang::message::lookup "" intranet-attendance-management.Delete_logging "Delete entry"] %>',
        id: 'buttonDeleteLogging',
        disabled: false
    }]
});




// -----------------------------------------------------------------------
// Controller for interaction between buttons and grid
//
Ext.define('AttendanceManagement.controller.AttendanceManagementController', {
    extend: 'Ext.app.Controller',

    // Variables
    debug: true,

    'loggingStartDate': null,				// contains the time when "start" was pressed or null otherwise
    'loggingAttendance': null,				// the attendance object created when logging

    // Parameters
    'renderDiv': null,
    'attendanceStore': null,
    'attendanceButtonPanel': null,
    'attendanceController': null,
    'attendanceGrid': null,
    'attendanceGridRowEditing': null,
    
    // Setup the various listeners so that everything gets concentrated here on this controller.
    init: function() {
        var me = this;
        if (me.debug) { console.log('AttendanceManagementController: init'); }
        
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
        console.log('AttendanceManagementController.onGridBeforeEdit');
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
        console.log('AttendanceManagementController.onGridEdit');
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
        console.log('AttendanceManagementController.onWindowKeyDown: code='+keyCode+', ctrl='+keyCtrl);
        
        // cancel hour logging with Esc key
        if (27 == keyCode) { this.onButtonCancelLogging(); }
        if (46 == keyCode) { this.onButtonDeleteLogging(); }
    },

    // Click into the empty space below the grid entries in order to start creating a new entry
    onGridContainerClick: function() {
        console.log('AttendanceManagementController.GridContainerClick');
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
        console.log('AttendanceManagementController.ButtonStartLogging');

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
            attendance_user_id: @current_user_id@,
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
        console.log('AttendanceManagementController.ButtonManualLogging');
        this.onButtonStartLogging();
        this.attendanceGridRowEditing.startEdit(this.loggingAttendance, 0);
    },

    onButtonStopLogging: function() {
        console.log('AttendanceManagementController.ButtonStopLogging');
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
        console.log('AttendanceManagementController.ButtonCancelLogging');
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
        console.log('AttendanceManagementController.ButtonDeleteLogging');
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
        if (this.debug) { console.log('AttendanceManagementController.onGridSelectionChange'); }
        var buttonDeleteLogging = Ext.getCmp('buttonDeleteLogging');
        buttonDeleteLogging.setDisabled(1 != records.length);
    },


    /**
     * Handle various key actions
     */
    onCellKeyDown: function(table, htmlTd, cellIndex, record, htmlTr, rowIndex, e, eOpts) {
        console.log('AttendanceManagementController.onCellKeyDown');
        var keyCode = e.getKey();
        var keyCtrl = e.ctrlKey;
        console.log('AttendanceManagementController.onCellKeyDown: code='+keyCode+', ctrl='+keyCtrl);
    },


    /**
     * The windows as a whole was resized
     */
    onWindowsResize: function(width, height) {
        console.log('AttendanceManagementController.onWindowResize');
        var me = this;
        var sideBar = Ext.get('sidebar');				// ]po[ left side bar component
        var sideBarSize = sideBar.getSize();
        me.onResize(sideBarSize.width);
    },

    /**
     * The ]po[ left sideBar was resized
     */
    onSideBarResize: function(event, el, config) {
        console.log('AttendanceManagementController.onSideBarResize');
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
        console.log('AttendanceManagementController.onResize: '+sideBarWidth);
        var me = this;
        var screenSize = Ext.getBody().getViewSize();
        var height = me.attendanceButtonPanel.getSize().height;
        var width = screenSize.width - sideBarWidth - 75;
        me.attendanceButtonPanel.setSize(width, height);
    }
    
});





function launchTimesheetAttendanceLogging(){

    // -----------------------------------------------------------------------
    // Stores
    var attendanceStore = Ext.StoreManager.get('attendanceStore');

    // -----------------------------------------------------------------------
    // Store for time entries
    var timeEntryStore = [];
    for (var i = @start_hour@; i < @end_hour@; i++) {
        var ii = ""+i;
        if (ii.length == 1) { ii = "0"+i; }
        for (var m = 0; m < 60; m = m + 30 ) {
            var mm = ""+m;
            if (mm.length == 1) { mm = "0"+m; }
            timeEntryStore.push(ii + ':' + mm);
        }
    }

    // -----------------------------------------------------------------------
    // Row editor for attendance grid
    // Veto inconcistent entries 
    // 
    var rowEditing = Ext.create('Ext.grid.plugin.RowEditing', {
        clicksToMoveEditor: 2,
        listeners: {
            edit: function(editor, context, eOpts) {

                // Check that the endTime is later than startTime
                var startTime = context.record.get('attendance_start_time');
                var endTime = context.record.get('attendance_end_time');
                if (startTime > endTime) {
                    return false;                     // Just return false - no error message
                }

                context.record.save();
            }
        }
    });

    // -----------------------------------------------------------------------
    // The actual grid for attendance entries
    //    
    var attendanceGrid = Ext.create('Ext.grid.Panel', {
        store: attendanceStore,
        layout: 'fit',
        region: 'center',
        plugins: [rowEditing],
        columns: [
            {
                text: "Date",
                xtype: 'datecolumn',
                dataIndex: 'attendance_date', 
                renderer: Ext.util.Format.dateRenderer('Y-m-d'),
                editor: {
                    xtype: 'datefield',
                    allowBlank: true,
                    startDay: @week_start_day@
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


    // -----------------------------------------------------------------------
    // Main panel
    // 
    var screenSize = Ext.getBody().getViewSize();    // Size calculation based on specific ]po[ layout
    var sideBarSize = Ext.get('sidebar').getSize();
    var width = screenSize.width - sideBarSize.width - 95;
    var height = screenSize.height - 280;
    
    var attendanceButtonPanel = Ext.create('AttendanceManagement.view.AttendanceButtonPanel', {
        renderTo: '@attendance_editor_id@',
        width: width,
        height: height,
        resizable: true,					// Add handles to the panel, so the user can change size
        items: [
            attendanceGrid
        ]
    });

    // -----------------------------------------------------------------------
    // Main controller
    // 
    var attendanceController = Ext.create('AttendanceManagement.controller.AttendanceManagementController', {
        'attendanceStore': attendanceStore,
        'attendanceButtonPanel': attendanceButtonPanel,
        'attendanceController': attendanceController,
        'attendanceGrid': attendanceGrid,
        'attendanceGridRowEditing': rowEditing
    });
    attendanceController.init(this).onLaunch(this);

    
    // -----------------------------------------------------------------------
    // Handle collapsable side menu
    var sideBarTab = Ext.get('sideBarTab');
    sideBarTab.on('click', attendanceController.onSideBarResize, attendanceController);
    Ext.EventManager.onWindowResize(attendanceController.onWindowsResize, attendanceController);    // Deal with resizing the main window
};


// -----------------------------------------------------------------------
// Start the application after loading the necessary stores
//
Ext.onReady(function() {
    Ext.QuickTips.init();
    
    var attendanceStore = Ext.create('AttendanceManagement.store.AttendanceStore');
    
    // "Launch" only after "store coodinator" has loaded all stores
    var coordinator = Ext.create('PO.controller.StoreLoadCoordinator', {
        stores: [
            'attendanceStore'
        ],
        listeners: {
            load: function() {
                if ("boolean" == typeof this.loadedP) { return; }  // application was launched before?
                launchTimesheetAttendanceLogging();                  // Launch the actual application.
                this.loadedP = true;                               // Mark the application as launched
            }
        }
    });

    // Load stores that need parameters
    attendanceStore.getProxy().extraParams = { user_id: @current_user_id@, format: 'json' };
    attendanceStore.load({
        callback: function() {
            console.log('AttendanceStore: callback: loaded');
        }
    });

});
</script>
</div>
