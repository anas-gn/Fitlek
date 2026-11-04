#!/bin/bash
echo -e '[mysqld]\nskip-grant-tables' | sudo tee /etc/my.cnf.d/skip-grant.cnf
sudo systemctl restart mysqld
sleep 3

sudo mysql -e "INSERT IGNORE INTO mysql.tables_priv (Host, Db, User, Table_name, Grantor, Timestamp, Table_priv, Column_priv) VALUES ('localhost', 'sirvya', 'sirvya_runtime', 'coach_packages', 'root@localhost', CURRENT_TIMESTAMP, 'Select,Insert,Update,Delete,Create,Drop,References,Index,Alter,Create View,Show view,Trigger', '');"

sudo rm -f /etc/my.cnf.d/skip-grant.cnf
sudo systemctl restart mysqld
