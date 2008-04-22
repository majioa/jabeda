drop table if exists `stats`;

CREATE TABLE `stats` (
      `time` datetime NOT NULL,
      `hostnode` text NOT NULL,
      `veid` int(20) NOT NULL,
      `parameter` text NOT NULL,
      `oldvalue` bigint(20) NOT NULL,
      `currentvalue` bigint(20) NOT NULL
);

