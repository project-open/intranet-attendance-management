// /intranet-attendance-management/www/store/AttendanceTypeStore.js
//
// Copyright (C) 2013 ]project-open[
//
// All rights reserved. Please see
// https://www.project-open.com/license/ for details.

Ext.define('AttendanceManagement.store.AttendanceTypeStore', {
    extend:         'PO.store.CategoryStore',
    model: 	    'PO.model.category.Category',
    storeId:	    'attendanceTypeStore',
    proxy: {
	type:       'rest',
	url:        '/intranet-rest/im_category',
	appendId:   true,
	extraParams: {
	    format: 'json',
	    // include_disabled_p: '1', // Make sure to include "Open" and "Closed" even if disabled
	    category_type: '\'Intranet Attendance Type\''
	},
	reader: { type: 'json', root: 'data' }
    }
});
