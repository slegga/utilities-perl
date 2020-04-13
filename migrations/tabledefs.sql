## sqllite migrations
-- 1 up
create table messages (message text);
insert into messages values ('I ♥ Mojolicious!');
-- 1 down
drop table messages;

-- 2 up (...you can comment freely here...)
create table stuff (whatever integer);
-- 2 down
drop table stuff;
