Nach dem Ausführen des Scriptes und der Ersteinrichtung der Nextcloud, werden in der Verwaltungsübersicht der NExtcloud einige Fehler auftreten.
Einige davon werden mit einige zusätzlichen Einträgen in der Nextcloud config.php. Dazu öffnen wir im Terminal mittels z.B. Nano:

nano /mnt/docker/Nextcloud/config/www/nextcloud/config/config.php


und fügen folgendes am Ende aber vor der letzten Klammer  );  ein:

  'default_phone_region' => 'DE',
  'maintenance_window_start' => 1,
  'memcache.local' => '\OC\Memcache\APCu', 
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => array(
     'host' => 'localhost',
     'port' => 6379,
     'timeout' => 0.0,
     'password' => '',  'default_phone_region' => 'DE',
  'maintenance_window_start' => 1,
  'memcache.local' => '\OC\Memcache\APCu', 
  'memcache.locking' => '\OC\Memcache\Redis',
  'redis' => array(
     'host' => 'localhost',
     'port' => 6379,
     'timeout' => 0.0,
     'password' => '', 
      ),


Abspeichern und schließen mittels Strg+o und Strg+x


Jetzt werden wir noch zwei Befehel ausführen, um einige fehlende Einträge in der Nextcloud Datenbank anzulegen.
Dazu folgende zwei Befehle im Terminal ausführen.


docker exec -it Nextcloud occ maintenance:repair --include-expensive

docker exec -it occ db:add-missing-indices


Jetzt sollten die meisten Warnungen verschuwnden sein.
