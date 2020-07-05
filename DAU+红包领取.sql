create table tmp_liujg_dau_based
(imp_date varchar(20) not null comment '日期',
qimei  varchar(20) not null comment '用户唯一标识',
is_new  varchar(10) comment '新用户表示，1表示新用户，0表示老用户',
primary key(imp_date,qimei)
);
ALTER TABLE tmp_liujg_dau_based COMMENT '用户活跃模型表';


create table tmp_liujg_packed_based  
(imp_date  varchar(20) comment '日期',
report_time   varchar(20) comment '领取时间戳',
qimei  varchar(20) not null comment '用户唯一标识',
add_money varchar(20) not null comment '领取金额，单位为分'
);
ALTER TABLE tmp_liujg_packed_based COMMENT '红包参与领取模型表';




--- 计算20190601至今，每日领取红包的新用户数，老用户数，及人均领取金额，人均领取次数
Select  
	aa.imp_date,
	aa.is_new,
	count(distinct aa.qimei) 领取红包人数,
	sum(aa.add_money)/count(distinct aa.qimei) 人均领取金额,
	count(aa.report_time)/count(distinct aa.qimei)  人均领取次数
from
	(Select   
		a.imp_date,
		a.qimei,
		a.add_money,
		a.report_time,
		Case when b.is_new  = 1 then  '新用户'  when b.is_new = 0 then '老用户'  else '领取红包但未登陆'end is_new 
	from tmp_liujg_packed_based   a
	Left join tmp_liujg_dau_based b 
	on a.imp_date = b.imp_date and a.qimei = b.qimei    
	where a.imp_date > '20190601'
)aa
Group by aa.imp_date,aa.is_new;




--计算2019年3月至今，每个月领过红包用户和未领红包用户的数量，平均月活跃天数（即本月平均活跃多少天）
--思路：先写出每个月领红包的用户 记为表1，将改表与活跃用户表右联结，根据表1空值与否来区分红包用户还是非红包用户。
Select 
	left(cc.imp_date,6) 月份,
	cc.is_packet_user 红包用户,
	Count(distinct cc.qimei)   用户数量,
	Count(is_packet_user)/Count(distinct cc.qimei)  月活跃天
from
	(Select 
		a.imp_date, 
		a.qimei,
		b.qimei hb_qimei,
		Case when b.qimei  is not null then '红包用户' else  '非红包用户' end is_packet_user,
		Case when b.qimei is not null then b.qimei else a.qimei end is_qimei
	from tmp_liujg_dau_based a
	Left join 
		(select  distinct  left(imp_date,6)imp_date, qimei from tmp_liujg_packed_based  where imp_date >= '20190301' )b
	On  left(a.imp_date,6) = b.imp_date and a.qimei = b.qimei
	)cc
Group by  left(cc.imp_date,6),cc.is_packet_user;



--计算2019年3月至今，每个月活跃用户的注册日期，2019年3月1日前注册的用户日期填空即可
--思路：先写出每个用户的注册日期，也就是每个新用户最小的日期，将改表和活跃用户表右联结。
select 
	left(a.imp_date,6) month,
	a.qimei,
	b.imp_date
from tmp_liujg_dau_based a
left join
	(select 
		qimei,
		min(imp_date) imp_date
	from tmp_liujg_dau_based
	where is_new=1
	group by qimei) b
on a.qimei=b.qimei
group by left(a.imp_date,6),a.qimei
order by left(a.imp_date,6);

？？为什么b表不能直接为结果呢？？？



--计算2019年3月至今，每日的用户活跃数，次日留存率，当日领取红包用户占比, 领取红包用户的次日留存
select 
	a.imp_date,
	count(a.qimei) dau,
	round(count(b.qimei)/count(a.qimei),2) '次日留存率',
	round(count(c.qimei)/count(a.qimei),2) '当日红包用户占比',
	round(count(d.qimei)/count(c.qimei),2) '当日领取红包用户留存率'
from tmp_liujg_dau_based a 
left join 
	tmp_liujg_dau_based b  ----'次日留存'
on a.qimei=b.qimei and DATEDIFF(b.imp_date,a.imp_date)=1
left join 
	(select 
		distinct imp_date,qimei 
	from tmp_liujg_packed_based )c  ----'当日红包用户占比'
on a.qimei=c.qimei and a.imp_date=c.imp_date
left join 
	(select 
		distinct imp_date,qimei 
	from tmp_liujg_packed_based )d ---'当日领取红包用户留存''
on c.qimei=d.qimei and datediff(d.imp_date,c.imp_date)=1 and b.qimei=d.qimei  --------？？bd相等
group by imp_date
order by imp_date;


--计算2019年6月1日至今，每日新用户领取得第一个红包的金额
select 
	a.imp_date,
	a.qimei,
	b.report_time,
	b.add_money
from tmp_liujg_dau_based a
left join
	(select 
		imp_date,qimei,report_time,add_money
	from tmp_liujg_packed_based 
	where (imp_date,qimei,report_time)
	in
		(select imp_date,qimei,min(report_time)
		from tmp_liujg_packed_based
		group by imp_date,qimei)
	)b
on a.qimei=b.qimei and a.imp_date=b.imp_date
where a.is_new=1;

？？？为什么不能直接取min 去join


--- 计算2019年3月1日至今，每个新用户领取的第一个红包和第二个红包的时间差
--（只计算注册当日有领取红包的用户，注册当日及以后的DAU表中新用户为1的用户）
--第一步:领取红包表，对用户进行分组，然后按照领取红包时间进行排序，取出排前两名的用户，注册日期，领取红包日期， 记为表1
--第二步:将表1自连接，条件是俩表的用户相等，并且 其中1个表的红包领取时间大于另一个表，这样就将红包用户，注册日期，第一次领取红包时间，第二次领取红包时间 取出来了 记为表2
--第三步:将表2和dau表自连接，联结条件是，用户相同，注册日期相同，筛选is_new=1，计算时间差。

select 
	a.qimei,
	a.imp_date '注册日期',
	b.time_min_1, ---首次领红包时间
	time_min_2, ----第二次领红包时间
	TIMESTAMPDIFF(minute,time_min_2,time_min_1) time_diff
from 
	tmp_liujg_dau_based a
join
	(select a.imp_date,a.qimei,a.report_time time_min_1,b.report_time time_min_2
	from 
		(select imp_date,qimei,report_time
		from
			(select imp_date,qimei,report_time,row_number() over (partition by qimei order by report_time) ranking
			from tmp_liujg_packed_based) a
		where ranking<=2
		) a
	join 
		(select imp_date,qimei,report_time
		from
			(select imp_date,qimei,report_time,row_number() over (partition by qimei order by report_time) ranking
			from tmp_liujg_packed_based) a
		where ranking<=2
		) b
	on a.qimei=b.qimei and a.report_time<b.report_time
	) b
on a.qimei=b.qimei and a.imp_date=b.imp_date
where a.is_new=1;




















