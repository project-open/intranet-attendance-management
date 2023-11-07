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




Known Bugs
==========

- Write out error message when end_time < start_time
- Handle error message if start=end, and object
  destroy() fails
- Creating a new entry, it's created at the top, not at
  the bottom of the list. -> Add attendance_start with date.

ToDo
====

- Allow uncompleted entry (no end date) to be saved to disk
- Create state engine and integrate Start Break and End Break
- Show new entry always at the bottom of the list
- Only allow one item to be "open" (no end time)

Neues Portlet Zeiterfassung:
- Add column with attendance type
- Spalte "Gehen" frei lassen, wenn nur kommen eingetragen wurde
- Buttons:
	- Kommen:
		- Neuer Eintrag mit aktueller Zeit
		- ohne gehen
		- Typ: Anwesenheit
		- Ignorieren, wenn der letzte Eintrag ein leeres Feld "Gehen" hatte.
	- Anfang Pause:
		- Wie "Kommen" nur Type: Pause
	- Gehen:
		- Letzter Eintrag muss Anwesenheit gewesen sein, mit "Gehen" leer,
		  sonst ignorieren
	- Ende Pause:
		- Ähnlich wie "Gehen"
- "Linke Seite" bleibt leer / weg
- Link zu Monatszeiterfassung
- Anzeige Gleitzeitkonto
- Anzeige Urlaubskonto
- Vorschlag: Wochenweise anzeigen, mit <- Woche -> Selector für Zeit
  (plus Calendar Select für Woche?)


Timesheet Monthly Calendar:
- Pro Tag zusätzlicher Eintrag: Anwesenheit
	- Farbe rot/grün in Abhängigkeit von 8h 
- Vergleich Anwesenheit vs. Soll Anwesenheit
	- Monatlich mit Berechnung der Soll-Anwesenheit
- Soll Anwesenheit = 8h/Tag * Verfügbarkeit
- Klick auf Anwesenheits-Link führt zu Widget, 
  mit der richtigen Woche "aufgeklappt"


Report Pausenzeiten:
- Filter:
	- User
	- Abteilung
	- Zeitraum
- Anzeige:
	- Pausenzeiten
	- Mindestens 15 pro Pause
	- Ab 6h verpflichtend 30min Pause
	- Ab 9h 45min Pause
	- Pro Monat (31 Spalten oben) und pro User (links)
	- Jede Zelle:
		- Gesamtzeit Pausen
		- Rot wenn Business-Regeln verletzt (oben)
		  mit Kommentar warum
		- 



Done
====


Neues Portlet Zeiterfassung:
- Auf der Homepage zeigen
- Ohne Bezug zu Projekt
- Spalte "Gehen" frei lassen, wenn nur kommen eingetragen wurde
- Buttons:
	- Kommen:
		- Neuer Eintrag mit aktueller Zeit
		- ohne gehen
		- Typ: Anwesenheit
	- Anfang Pause:
		- Wie "Kommen" nur Type: Pause
	- Gehen:
		- Letzter Eintrag muss Anwesenheit gewesen sein, mit "Gehen" leer,
		  sonst ignorieren
	- Ende Pause:
		- Ähnlich wie "Gehen"
- "Linke Seite" bleibt leer / weg

- Done: Format for GridPanel date column is different from renderer


