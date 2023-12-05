<div id=@attendance_editor_id@>
<script type='text/javascript' <if @::__csp_nonce@ not nil>nonce="@::__csp_nonce;literal@"</if>>

Ext.Loader.setPath('PO', '/sencha-core');
Ext.Loader.setPath('AttendanceManagement', '/intranet-attendance-management');
Ext.Loader.setConfig({disableCaching: false});

Ext.require([
    'Ext.data.*',
    'Ext.grid.*',
    'PO.Utilities',
    'PO.model.category.Category',
    'PO.store.CategoryStore',
    'PO.controller.StoreLoadCoordinator',
    'PO.view.field.PODateField',
    'AttendanceManagement.model.Attendance',
    'AttendanceManagement.store.AttendanceStore',
    'AttendanceManagement.store.AttendanceTypeStore',
    'AttendanceManagement.controller.AttendanceController',
    'AttendanceManagement.view.AttendanceButtonPanel',
    'AttendanceManagement.view.AttendanceGridPanel'
]);

/*
*/

// Expose TCL variables as JavaScript variables
var week_start_day = @week_start_day@;
var start_hour = @start_hour@;
var end_hour = @end_hour@;
// var user_locale = '@user_locale@';
var user_locale = 'en-US';

// A localized array of shortened days of the week
const DAY_NAME_OF_WEEK_SHORT = [
    "<%= [_ intranet-timesheet2.Day_of_week_Sun] %>", 
    "<%= [_ intranet-timesheet2.Day_of_week_Mon] %>", 
    "<%= [_ intranet-timesheet2.Day_of_week_Tue] %>", 
    "<%= [_ intranet-timesheet2.Day_of_week_Wed] %>", 
    "<%= [_ intranet-timesheet2.Day_of_week_Thu] %>", 
    "<%= [_ intranet-timesheet2.Day_of_week_Fri] %>", 
    "<%= [_ intranet-timesheet2.Day_of_week_Sat] %>"
];

// Localization: Start with English and overwrite with locale specific translation from database
const l10n = {<multiple name="english_messages">@english_messages.message_key@: "@english_messages.message@",
</multiple>};
const l10n_locale = {<multiple name="locale_messages">@locale_messages.message_key@: "@locale_messages.message@",
</multiple>};
Object.keys(l10n_locale).forEach(key => {var val = l10n_locale[key]; l10n[key] = val;});

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
    var attendanceButtonPanel = Ext.create('AttendanceManagement.view.AttendanceButtonPanel', {
        renderTo: '@attendance_editor_id@',
        width: @portlet_width@,
        height: @portlet_height@,
        resizable: false,			// Add handles to the panel, so the user can change size
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
        'current_user_id': @current_user_id@,
	'initial_date_ansi': '@ansi_date@'
    });
    attendanceController.init(this).onLaunch(this);

};


// -----------------------------------------------------------------------
// Start the application after loading the necessary stores
//
Ext.onReady(function() {
    Ext.QuickTips.init();

    // -----------------------------------------------------------------------
    // Define stores and add to "coordinator" 
    var attendanceStore = Ext.create('AttendanceManagement.store.AttendanceStore');
    var attendanceTypeStore = Ext.create('AttendanceManagement.store.AttendanceTypeStore');
    
    // "Launch" only after "store coodinator" has loaded all stores
    var coordinator = Ext.create('PO.controller.StoreLoadCoordinator', {
        stores: [
            'attendanceTypeStore',
            // 'attendanceStore'
        ],
        listeners: {
            load: function() {
                if ("boolean" == typeof this.loadedP) { return; }  // application was launched before?
                launchTimesheetAttendanceLogging();                // Launch the actual application.
                this.loadedP = true;                               // Mark the application as launched
            }
        }
    });

    // -----------------------------------------------------------------------
    // Load stores (with custom args)

    // This should only be "Work" and "Break"...
    attendanceTypeStore.load();
    
});
</script>
</div>
