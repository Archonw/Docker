Mit diesen Scripts kann unter Debian-basierten Distributionen eine Nextcloud-Docker Installation ausgeführt werden.

Vorgehensweise:

1.
Ausführen von: nextcloud_stack_installer.sh

Es wird das erste Script ausgeführt. Dabei werden Eingaben für die MariaDB Datenbank abgefragt,
und es muss der Linux-User angegeben werden, der die Docker Container verwalten soll.

Ist dieses erfolgreich durchgelaufen kommt am Ende eine Zusammenfassung mit den nötigen Daten, die im nächsten Schritt in Nextcloud-Web Oberfläche bei der Erst-Einrichtung eingegeben werden müssen.
Nachdem die Erst-Einrichtung erfolgt ist, und man erfolgreich mit seinem ersten Konto in der Nextcloud angemeldet ist, kann jetzt das zweite Script ausgeführt werden. 



2. 
Bitte einmal am Linux-Rechner ab- und wieder anmelden, damit der User den Docker-Zugriff erhält, dann

Ausführen von: after-first-setup.sh

Das zweite Script sorgt für ein paar wichtige Einstellungen, die noch in der Nextcloud vorgenommen werden müssen.
Navigiert man im Anschluss in seinem Nextcloud-Konto zu der Administrationseinstellungen und dort zur üBersicht, so sollten nur noch wenige Fehlermeldungen zu sehene sein.

Die Meldung zur E-Mail-Serverkonfiguration lässt sich beheben, in dem in in den Administrationseinstellungen unter Grundeinstellungen den E-Mail-Server einstellt.


Optional:

- nginx-proxy-manager-installer.sh 
Damit kann der Nginx-Proxy-Manager installiert werden. Ein einfach zu bedienender Proxy Manager danke WebGUI.

- vaultwarden-installer.sh
Das ist installiert den Vaultwalden Passwortmanager.
