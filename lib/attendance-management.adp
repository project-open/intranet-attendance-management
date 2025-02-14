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
    'PO.view.menu.HelpMenu',
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
var gifPath = "/intranet/images/navbar_default/";

// A localized array of shortened days of the week
const DAY_NAME_OF_WEEK_SHORT = [
    '<%= [_ intranet-timesheet2.Day_of_week_Sun] %>', 
    '<%= [_ intranet-timesheet2.Day_of_week_Mon] %>', 
    '<%= [_ intranet-timesheet2.Day_of_week_Tue] %>', 
    '<%= [_ intranet-timesheet2.Day_of_week_Wed] %>', 
    '<%= [_ intranet-timesheet2.Day_of_week_Thu] %>', 
    '<%= [_ intranet-timesheet2.Day_of_week_Fri] %>', 
    '<%= [_ intranet-timesheet2.Day_of_week_Sat] %>'
];

// Localization: Start with English and overwrite with locale specific translation from database
var l10n = { Button_text_To: 'to' };
var l10n_english = {<multiple name="english_messages">@english_messages.message_key@: "@english_messages.message@",
</multiple>};
Object.keys(l10n_english).forEach(key => { var val = l10n_english[key]; l10n[key] = val; });
var l10n_locale = {<multiple name="locale_messages">@locale_messages.message_key@: "@locale_messages.message@",
</multiple>};
Object.keys(l10n_locale).forEach(key => { var val = l10n_locale[key]; l10n[key] = val; });

var attendanceController = null; // Global scope, so we can address it from the panel

function launchTimesheetAttendanceLogging(){
    // Stores
    var attendanceStore = Ext.StoreManager.get('attendanceStore');

    /* ***********************************************************************
     * Grid Gui
     *********************************************************************** */
    
    // Row editor for attendance grid
    // The controller registers validateedit and edit events
    var rowEditing = Ext.create('Ext.grid.plugin.RowEditing', {
        clicksToMoveEditor: 2
    });

    // The actual grid for attendance entries
    var attendanceGrid = Ext.create('AttendanceManagement.view.AttendanceGridPanel', {
        plugins: [rowEditing],
    });

    // Main panel
    var attendanceButtonPanel = Ext.create('AttendanceManagement.view.AttendanceButtonPanel', {
        renderTo: '@attendance_editor_id@',
        width: @portlet_width@,
        height: @portlet_height@,
        current_user_id: @user_id_from_search@,
	current_user_name: '@user_name_from_search@',
        resizable: false,			// Add handles to the panel, so the user can change size
        items: [
            attendanceGrid
        ]
    });

    // Global main controller
    attendanceController = Ext.create('AttendanceManagement.controller.AttendanceController', {
        attendanceStore: attendanceStore,
        attendanceButtonPanel: attendanceButtonPanel,
        attendanceController: attendanceController,
        attendanceGrid: attendanceGrid,
        attendanceGridRowEditing: rowEditing,
        current_user_id: @user_id_from_search@,
        current_user_name: '@user_name_from_search@',
        initial_date_ansi: '@ansi_date@'
    });
    attendanceController.init(this).onLaunch(this);
    attendanceGrid.attendanceController = attendanceController;
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
            // 'attendanceStore' // is loaded in attendanceController, not required to start app
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
    
    // attendanceStore is loaded in 
    // attendanceController.loadAttendanceStore()

});
</script>
</div>

@audit_html;noquote@
