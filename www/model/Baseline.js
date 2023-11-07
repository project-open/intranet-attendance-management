/* 
 * /sencha-core/www/model/project/Baseline.js
 *
 * Copyright (C) 2021 ]project-open[
 * All rights reserved. Please see
 * https://www.project-open.com/license/sencha/ for details.
 *
 * This is the default Sencha model for baselines and sub-
 * types including "im_profile" and "im_ticket_queue" with 
 * all important fields available from the ]po[ data-model.
 */

Ext.define('PO.model.project.Baseline', {
    extend: 'Ext.data.Model',
    fields: [
	'id',
	'object_type',				// Type of baseline: 'baseline', 'im_profile', ...

	// Basic Information
	'baseline_id',				// The primary key or object_id of the baseline
	'baseline_name',			// System name, frequently the Windows login of the baseline
	'baseline_project_id',			// baselines always belong to a project
	'baseline_type_id',			// Type
	'baseline_status_id',			// Status

	// Object metainformation
	'creation_date',			// 
	'creation_ip',				// 
	'creation_baseline',			// 
	'last_modified',			// 
	'modifying_ip',				// 
	'modifying_user'			// 
    ],

    proxy: {
	type:			'rest',				// Use the standard ]po[ REST interface for loading/saving
	url:			'/intranet-rest/im_baseline',	// Standard URL for baselines
	appendId:		true,				// Append the object_id: ../im_ticket/<object_id>
	timeout:		300000,
	
	extraParams: {
	    format:		'json',				// Tell the ]po[ REST to return JSON data.
	    deref_p:		'0'				// By default also load denormalized fields 
	},
	reader: {
	    type:		'json',				// Tell the Proxy Reader to parse JSON
	    root:		'data',				// Where do the data start in the JSON file?
	    totalProperty:	'total'				// Total number of tickets for pagination
	},
	writer: {
	    type:		'json'				// Allow Sencha to write ticket changes
	}
    }
});

