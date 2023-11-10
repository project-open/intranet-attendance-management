<div id=@attendance_editor_id@>
<script type='text/javascript' <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>

Ext.Loader.setPath('PO', '/sencha-core');
Ext.Loader.setPath('AttendanceManagement', '/intranet-attendance-management');
// Ext.Loader.setConfig({disableCaching: false});

Ext.require([
    'Ext.data.*',
    'Ext.grid.*',
    'PO.model.category.Category',
    'PO.store.CategoryStore',
    'PO.controller.StoreLoadCoordinator',
    'AttendanceManagement.model.Attendance',
    'AttendanceManagement.store.AttendanceStore'
]);

// Expose TCL variables as JavaScript variables
var week_start_day = @week_start_day@;
var start_hour = @start_hour@;
var end_hour = @end_hour@;


function launchTimesheetAttendanceLogging(){
    // Stores
    var attendanceStore = Ext.StoreManager.get('attendanceStore');

    // Row editor for attendance grid, vetos inconcistent entries 
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

    // The actual grid for attendance entries
    var attendanceGrid = Ext.create('AttendanceManagement.view.AttendanceGridPanel', {
        store: attendanceStore,
        plugins: [rowEditing],
    });

    // Main panel
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

    // Main controller
    var attendanceController = Ext.create('AttendanceManagement.controller.AttendanceController', {
        'attendanceStore': attendanceStore,
        'attendanceButtonPanel': attendanceButtonPanel,
        'attendanceController': attendanceController,
        'attendanceGrid': attendanceGrid,
        'attendanceGridRowEditing': rowEditing,
	'current_user_id': @current_user_id@
    });
    attendanceController.init(this).onLaunch(this);

    
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
    var attendanceTypeStore = Ext.create('AttendanceManagement.store.AttendanceTypeStore');
    
    // "Launch" only after "store coodinator" has loaded all stores
    var coordinator = Ext.create('PO.controller.StoreLoadCoordinator', {
        stores: [
            'attendanceTypeStore',
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

    attendanceTypeStore.load();
    
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
