# ]po[ Attendance Management
This package is part of ]project-open[, an open-source enterprise project management system.

For more information about ]project-open[ please see:
* [Source](https://www.github.com/project-open/intranet-attendance-management)
* [Documentation Wiki](https://www.project-open.com/en/)
* [V5.1 Download](https://sourceforge.net/projects/project-open/files/project-open/V5.1/)
* [Installation Instructions](https://www.project-open.com/en/list-installers)

About ]po[ Attendance Management:

Employees need to log their time present at work,
according to laws in the European Union and other places.
This package allows to register attendance time and breaks.
It also allows to compare attendance with the time logged
on projects. These time can be different in certain
situations, but differences should be visible for HR
managers.



# Button Actions

- Start Work:
	- Ignorieren, wenn der letzte Eintrag ein leeres Feld "Gehen" hatte.
	- scrolls to current week, 
	- stops an ongoing attendance (work or break)
	  by adding end time of now()
	- starts a new work
	- adds the new entry to the end of the store
	- syncs with the database
	- Show new entries always at the bottom of the list

- Start Break:
  	- Equivalent to Start Work, just with type "Break"

- Stop:
	- Scrolls to current week, 
	- Stops an ongoing attendance (work or break) today
	  by adding end time of now()
	- Syncs with the database
	- "Gehen": Letzter Eintrag muss Anwesenheit gewesen sein,
	  mit "Gehen" leer, sonst ignorieren

- Delete:
	- Is only enabled if a row is selected
	- Deletes all type of entries
	- Syncs with the database immediately
	- Moves the "focus" (selection model) to the following
	  entry, or stays at the end of the list.
	  This is to allow to delete successive
	  entries by pressing Delete multiple times

- Next/Prev Week:
	- Just loads the store for the selected week
	- Vorschlag: Wochenweise anzeigen, mit
	  <- Woche -> Selector für Zeit (plus Calendar
	  Select for week?)



- Button Constraints:
	- There should in total be at most 1 open attendance
	- A week different from "current" should not have
	  ongoing attendances

- Button enable/disabled state:
	- Delete is enabled if one item is selected,
	  disabled otherwise.
	- Stop is enabled, if one item is "open"
	- StartWork is enabled if no item is open
	- StartBreak is enabled if no item is open
