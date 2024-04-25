create schema btth2;
use btth2;
create table if not exists category
(
    id      int primary key auto_increment,
    name    varchar(100) not null unique,
    stautus tinyint default 1 check (stautus in (0, 1))

);
create table if not exists room
(
    id          int primary key auto_increment,
    name        varchar(150) not null,
    status      tinyint default 1 check ( status in (0, 1)),
    price       float        not null check ( price >= 100000 ),
    saleprice   float   default 0,
    createddate date    default (curdate()),
    categoryid  int          not null,
    foreign key (categoryid) references category (id)
);
create index room_index on room (name, price, createddate);
create trigger if not exists tg_before_insert_room_saleprice
    before insert
    on room
    for each row
    if new.saleprice > NEW.price then
        signal sqlstate '45000'
            set message_text = 'Gia sale phai nho hon hoac bang gia ban';
    end if;
create table if not exists customer
(
    id          int primary key auto_increment,
    name        varchar(150) not null,
    email       varchar(150) not null unique check ( email like '%@%.%'),
    address     varchar(255),
    createddate date default (curdate()),
    gender      tinyint      not null,
    check ( gender in (0, 1, 2) ),
    birthday    date         not null
);
create trigger if not exists tg_before_insert_customer_createddate
    before insert
    on customer
    for each row
    if new.createddate < curdate() then
        signal sqlstate '45000'
            set message_text = 'Ngay tao phai lon hon hoac bang ngay hien tai';
    end if;
create table if not exists booking
(
    id          int primary key auto_increment,
    customerid  int not null,
    foreign key (customerid) references customer (id),
    status      tinyint  default 1 check ( status in (0, 1, 2, 3)),
    bookingdate datetime default (now())
);
create table if not exists bookingdetail
(
    bookingid int      not null,
    foreign key (bookingid) references booking (id),
    roomid    int      not null,
    foreign key (roomid) references room (id),
    price     float    not null,
    stardate  datetime not null,
    enddate   datetime not null,
    primary key (bookingid, roomid)
);
create trigger if not exists tg_before_insert_bookingdetail_enddate
    before insert
    on bookingdetail
    for each row
    if NEW.enddate <= NEW.stardate then
        signal sqlstate '45000'
            set message_text = 'Ngay ket thuc phai sau nay bat dau';
    end if;
INSERT INTO category (name)
VALUES ('Standard'),
       ('Deluxe'),
       ('Suite'),
       ('Family Room'),
       ('VIP');
INSERT INTO room (name, price, categoryid)
VALUES ('Standard Room 1', 150000, 1),
       ('Standard Room 2', 150000, 1),
       ('Deluxe Room 1', 250000, 2),
       ('Deluxe Room 2', 250000, 2),
       ('Suite 1', 350000, 3),
       ('Suite 2', 350000, 3),
       ('Family Room 1', 400000, 4),
       ('Family Room 2', 400000, 4),
       ('VIP Room 1', 500000, 5),
       ('VIP Room 2', 500000, 5),
       ('VIP Room 3', 500000, 5),
       ('VIP Room 4', 500000, 5),
       ('VIP Room 5', 500000, 5),
       ('VIP Room 6', 500000, 5),
       ('VIP Room 7', 500000, 5);
alter table customer
    add phone varchar(50) not null;
alter table customer
    add constraint customer_pk
        unique (phone);
INSERT INTO customer (name, email, phone, address, gender, birthday)
VALUES ('John Doe', 'john@example.com', '123456789', '123 Main St, City', 1, '1990-05-15'),
       ('Alice Smith', 'alice@example.com', '987654321', '456 Elm St, Town', 0, '1985-10-25'),
       ('Bob Johnson', 'bob@example.com', '147852369', '789 Oak St, Village', 1, '1988-12-03');
-- Tạo các hóa đơn đặt phòng cho khách hàng đã thêm ở trên
INSERT INTO booking (customerid)
VALUES (1),
       (2),
       (3);
-- Thêm chi tiết đặt phòng cho các hóa đơn đã tạo
INSERT INTO bookingdetail (bookingid, roomid, price, stardate, enddate)
VALUES (1, 1, 150000, '2024-04-25 12:00:00', '2024-04-27 12:00:00'),
       (1, 2, 150000, '2024-04-25 12:00:00', '2024-04-27 12:00:00'),
       (2, 3, 250000, '2024-05-01 12:00:00', '2024-05-03 12:00:00'),
       (2, 4, 250000, '2024-05-01 12:00:00', '2024-05-03 12:00:00'),
       (3, 5, 350000, '2024-05-10 12:00:00', '2024-05-12 12:00:00'),
       (3, 6, 350000, '2024-05-10 12:00:00', '2024-05-12 12:00:00');
