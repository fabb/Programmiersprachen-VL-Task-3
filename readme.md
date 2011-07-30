What's this?
============

This is one of three tasks to be completed in the proceedings of the course "Programming Languages" at the University of Technology Vienna. I solved these together with lewurm.

In this task, I did the implementation together with lewurm reviewed it.

Below you can find the original task description in German.


3\. Übungsaufgabe
===============

Überblick:
----------
Entwickeln Sie ein Workflow-Werkzeug zur Bearbeitung von Dateien nach einem festlegbaren Schema in einer dynamisch typisierten Scripting-Sprache wie Perl, PHP, Ruby, ...

Workflow-Werkzeug:
------------------
Das Werkzeug soll einen in einer Konfigurationsdatei festgelegten Workflow abarbeiten und dabei vorgegebene Programme auf Dateien anwenden, die einem vorgegebenen Muster entsprechen.

Folgende Aktionen sollen in der Konfigurationsdatei festlegbar sein:

* Eine *primitive Aktion* ruft ein Programm auf bzw. setzt ein (Unix-)Kommando ab, möglicherweise mit Argumenten, die auch benannte Teile eines Musters enthalten. Die Ausführung einer primitiven Aktion ist erfolgreich, wenn der Programmaufruf mit dem Wert 0 terminiert, sonst ist sie gescheitert. Alle anderen (nicht-primitiven) Aktionen erweitern oder kombinieren einfachere Aktionen.

* Eine *Sequenz* besteht aus mehreren Aktionen, die in der gegebenen Reihenfolge hintereinander ausgeführt werden. Wenn eine Ausführung einer Aktion scheitert, werden die weiteren Aktionen nicht mehr ausgeführt, und die Ausführung der Sequenz gilt als gescheitert, sonst als erfolgreich.

* Eine *Mengen-Aktion* besteht aus einem Muster und einer Aktion. Das Muster spezifiziert eine Menge von Dateien (siehe unten), und die Aktion wird für jede Datei in der Menge in beliebiger Reihenfolge einmal ausgeführt. Falls eine Ausführung der Aktion scheitert, wird die Aktion auf keine weitere Dateien mehr angewandt, und die Ausführung der Mengen-Aktion gilt als gescheitert.

* Eine *Schleife* beinhaltet eine Aktion, die ständig wiederholt ausgeführt wird, solange die Ausführung der Aktion erfolgreich ist und dabei zumindest eine primitive Aktion ausgeführt wird. Die Ausführung einer Schleife terminiert nur dann erfolgreich, wenn die Aktion nur aus Mengen-Aktionen besteht, deren Muster in einem Durchlauf keine Dateien spezifizieren.

* Eine *Fehlerbehandlung* kombiniert zwei Aktionen A und B. Falls die Ausführung von A erfolgreich ist, ist auch die Ausführung der ganzen Fehlerbehandlung erfolgreich, und B wird nicht ausgeführt. Falls aber die Ausführung von A scheitert, wird B ausgeführt, und die Fehlerbehandlung ist genau dann erfolgreich, wenn die Ausführung von B erfolgreich ist.

Muster in Mengen-Aktionen sollen Pfade im Dateisystem darstellen, die benannte Wildcards enthalten können. Beispielsweise könnte `Bilder/2011-04-[tag]/[name].jpg` für alle Dateien entsprechend dem Unix-Pfad `Bilder/2011-04-*/*.jpg` stehen, wobei `[[tag]]` und `[[name]]` im Argument einer primitiven Aktion oder im Muster einer anderen enthaltenen Mengen-Aktion für die beiden Zeichenketten stehen, die im Unix-Pfad durch die beiden Wildcards (`*`) dargestellt werden. Die genaue Syntax und Semantik für Muster (so wie in diesem Beispiel oder anders) sollen Sie selbst festlegen, genauso wie die Syntax zur Festlegung von Workflows in der Konfigurationsdatei.

Ein Workflow ist in gewisser Weise ein einfaches Programm mit bedingten Anweisungen und Schleifen. Ihre Aufgabe besteht also darin, die Syntax und einige semantische Details der Sprache festzulegen und einen einfachen Interpreter dafür zu implementieren. Bitte halten Sie die Syntax so einfach, dass die Aufgabe leicht ohne spezielle Compilerbau-Werkzeuge lösbar ist.

Anwendungsbeispiele:
-------------------
Obige Beschreibung des Werkzeugs ist abstrakt gehalten. Hier werden einige Anwendungsbeispiele angerissen, die den Zweck klarer umschreiben und als Testfälle dienen können.

* Das Werkzeug überprüft, ob neue Dateien in einem Eingangs-Ordner erstellt wurden, verschiebt Dateien mit bestimmten Endungen im Namen in andere Ordner, und führt ein Protokoll über verschobene Dateien.

* Angenommen, Sie wollen mehrere Texte, die Sie per Mail bekommen und in einem Verzeichnis abgelegt haben, zu einer Einheit zusammenfügen. Das Werkzeug kann Sie dabei unterstützen, indem es aus jeder Datei mit Hilfe eines Skripts den Header entfernt, die geänderten Dateien zu einer großen Datei zusammenfasst und diese Datei in einem Editor für weitere Korrekturen öffnet.

* Das Werkzeug erstellt für alle Bilder in einem Ordner je zwei Kopien in unterschiedlichen Größen in anderen Ordnern und fügt für jedes Bild eine passende Zeile in eine bestehende HTML-Datei ein, sodass die Bilder in einer Übersichtstabelle und im Detail auf einem Web-Browser betrachtet werden können.
