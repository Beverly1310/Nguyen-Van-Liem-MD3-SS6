# 1.	Lấy ra danh phòng có sắp xếp giảm dần theo Price gồm các cột sau: Id, Name, Price, SalePrice, Status, CategoryName, CreatedDate
select r.id, r.name, r.price, r.saleprice, r.status, c.name, r.createddate
from room r
         join btth2.category c on c.id = r.categoryid
order by price desc;
# 2.	Lấy ra danh sách Category gồm: Id, Name, TotalRoom, Status (Trong đó cột Status nếu = 0, Ẩn, = 1 là Hiển thị )
select c.id,
       c.name,
       count(c.id)                    Totalroom,
       case c.stautus
           when 0 then 'Ẩn'
           when 1 then 'Hiển thị' end Trang_Thai
from category c
         join btth2.room r on c.id = r.categoryid
group by c.id;
# 3.	Truy vấn danh sách Customer gồm: Id, Name, Email, Phone, Address, CreatedDate, Gender, BirthDay, Age (Age là cột suy ra từ BirthDay, Gender nếu = 0 là Nam, 1 là Nữ,2 là khác )
select Id,
       Name,
       Email,
       Phone,
       Address,
       CreatedDate,
       Gender,
       BirthDay,
       year(curdate()) - year(birthday) Age
from customer;
# 4.	Truy vấn xóa các sản phẩm chưa được bán
delete
from room
where room.id not in (select bookingdetail.roomid from bookingdetail);
# 5.	Cập nhật Cột SalePrice tăng thêm 10% cho tất cả các phòng có Price >= 250000
update room
set saleprice = price * 0.1
where price >= 250000;
# 1.	View v_getRoomInfo Lấy ra danh sách của 10 phòng có giá cao nhất
create view v_getRoomInfo as
select *
from room
order by price desc
limit 10;
select *
from v_getRoomInfo;
# 2.	View v_getBookingList hiển thị danh sách phiếu đặt hàng gồm: Id, BookingDate, Status, CusName, Email, Phone,TotalAmount ( Trong đó cột Status nếu = 0 Chưa duyệt, = 1  Đã duyệt, = 2 Đã thanh toán, = 3 Đã hủy )
create view v_getBookingList as
select b.Id, b.BookingDate, b.Status, c.name, c.Email, c.Phone, sum(b2.price) TotalAmount
from booking b
         join btth2.bookingdetail b2 on b.id = b2.bookingid
         join btth2.customer c on c.id = b.customerid
group by b.Id, b.BookingDate, b.Status, c.name, c.Email, c.Phone;
select *
from v_getBookingList;
# 1.	Thủ tục addRoomInfo thực hiện thêm mới Room, khi gọi thủ tục truyền đầy đủ các giá trị của bảng Room ( Trừ cột tự động tăng )
DELIMITER //
create procedure if not exists addRoomInfo(name_in varchar(150), status_in tinyint, price_in float, saleprice_in float,
                                           createddat_in date, categoryid_in int)
begin
    insert into room(name, status, price, saleprice, createddate, categoryid)
    values (name_in, status_in, price_in, saleprice_in, createddat_in, categoryid_in);
end //;
// DELIMITER ;
# 2.	Thủ tục getBookingByCustomerId hiển thị danh sách phieus đặt phòng của khách hàng theo Id khách hàng gồm: Id, BookingDate, Status, TotalAmount
# (Trong đó cột Status nếu = 0 Chưa duyệt, = 1  Đã duyệt,, = 2 Đã thanh toán, = 3 Đã hủy), Khi gọi thủ tục truyền vào id cảu khách hàng
DELIMITER //
create procedure if not exists getBookingByCustomerId(cusid int)
begin
    select b.id, b.bookingdate, b.status, sum(price) TotalAmount
    from customer c
             join btth2.booking b on c.id = b.customerid
             join btth2.bookingdetail b2 on b.id = b2.bookingid
    where c.id = cusid
    group by c.id, b.id, b.bookingdate, b.status;
end //;
// DELIMITER ;
call getBookingByCustomerId(1);
# 3.	Thủ tục getRoomPaginate lấy ra danh sách phòng có phân trang gồm: Id, Name, Price, SalePrice, Khi gọi thủ tuc truyền vào limit và page
DELIMITER //
create procedure if not exists getRoomPaginate(limit_value int, page_value int)
begin
    declare offset_value int;
    set offset_value = page_value * limit_value;
    select Id, Name, Price, SalePrice from room limit offset_value,limit_value;
end //;
// DELIMITER ;
call getRoomPaginate(5, 1);
# 1.	Tạo trigger tr_Check_Price_Value sao cho khi thêm hoặc sửa phòng Room nếu nếu giá trị của cột Price > 5000000 thì tự động chuyển về 5000000 và in ra thông báo ‘Giá phòng lớn nhất 5 triệu’
create trigger if not exists tr_Check_before_insert_Price_Value
    before insert
    on room
    for each row
begin
    if new.Price > 5000000 then
        signal sqlstate '45000'
            set message_text = 'Giá phòng lớn nhất 5 triệu';
    end if;
end;
create trigger if not exists tr_Check_before_update_Price_Value
    before update
    on room
    for each row
begin
    if new.Price > 5000000 then
        signal sqlstate '45000'
            set message_text = 'Giá phòng lớn nhất 5 triệu';
    end if;
end;
# 2.	Tạo trigger tr_check_Room_NotAllow khi thực hiện đặt pòng, nếu ngày đến (StartDate) và ngày đi (EndDate) của đơn hiện tại mà phòng đã có người đặt rồi thì báo lỗi “Phòng này đã có người đặt trong thời gian này, vui lòng chọn thời gian khác”
create trigger if not exists tr_check_Room_NotAllow
    before insert
    on bookingdetail
    for each row
begin
    declare count_record int;
    declare min_startdate datetime;
    declare max_enddate datetime;
    select min(stardate),max(enddate) into min_startdate,max_enddate from bookingdetail where roomid= new.roomid;
    select count(*)
    into count_record
    from bookingdetail
    where roomid = NEW.roomid
      and NEW.stardate between min_startdate and max_enddate
    or  new.enddate between min_startdate and max_enddate;
    if count_record > 0 then
        signal sqlstate '45000'
            set message_text = 'Phòng này đã có người đặt trong thời gian này, vui lòng chọn thời gian khác';
    end if;
end;



