<master>

<h2>README.md</h2>
<pre>
<%= [im_exec cat /web/cedis/packages/intranet-attendance-management/TODO.md] %>
</pre>

<h2>GIT Log Attendance Management</h2>
<pre>
<%= [im_exec bash -c "cd /web/cedis/packages/intranet-attendance-management/; git log --stat"] %>
</pre>

<h2>GIT Log Timesheet Management</h2>
<pre>
<%= [im_exec bash -c "cd /web/cedis/packages/intranet-timesheet2/; git log --stat --since=2023-11-01"] %>
</pre>
