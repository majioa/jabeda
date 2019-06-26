drop table if exists `stats`;

CREATE TABLE `stats` (
      `time` datetime NOT NULL,
      `hostnode` text NOT NULL,
      `veid` int(20) NOT NULL,
      `parameter` text NOT NULL,
      `oldvalue` bigint(20) NOT NULL,
      `currentvalue` bigint(20) NOT NULL
);

drop table if exists `events`;

CREATE TABLE `events` (
      `monitoring_id` int(11) NOT NULL auto_increment,
      `hostname` varchar(255) NOT NULL default '',
      `ping_time` datetime default NULL,
      PRIMARY KEY  (`monitoring_id`)
);
