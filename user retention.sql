---figure out the difference between each lauch channel and find the best user retention


select
	t3.day1,
	count(distinct case when diff=0 then t3.device_uuid else 0 end) as wake, ---daily users
	count(distinct case when diff=1 then t3.device_uuid else 0 end) as ciliu, ---day 1 user retention 
	count(distinct case when diff=1 and t3.bg='ug'then t3.device_uuid else 0 end) as ug,---day 1 user retention from ug
	count(distinct case when diff=1 and t3.bg='back'then t3.device_uuid else 0 end) as back,---day 1 user retention from back
	count(distinct case when diff=1 and t3.bg='app'then t3.device_uuid else 0 end) as app,---day 1 user retention from app
	count(distinct case when diff=1 and t3.bg='push'then t3.device_uuid else 0 end) as push---day 1 user retention from push
from
	(select
		t1.day1,
		t1.device_uuid,
		t2.bg,
		datediff(day2,day1) as diff
	from
		(select 
		 	qingtui.device_uuid,
		 	qingtui.day1
		 	
		from 
			(select 
			 	md5(imei) as imei_md5,
			 	device_uuid,
			 	day,
			 	concat(substr(day,1,4),'-',substr(day,5,2),'-',substr(day,7,2)) as day1
			 from 
			 	portal.edm_qingtui_wake_user_detail_day
			 where 
			 	app_id in ('2x1kfBk63z') 
			 	and day>='20190819' and day<='20190825'
			 	and qingtui_source like '%news_zhizi_android_01%'
			group by
				md5(imei),
				device_uuid,
			 	day	
			)qingtui -----daily waken users
		join 
			(select  
			 	didmd5,
			 	app_cat
			 from
			 	streams.dwd_streams_zhizi_second_bidresponse_simplified
			 where  
			 	dt>='2019-08-19' and dt<='2019-08-25'
			 	and render_name='gdt'  
			 	and app_cat='51807'
			 group by 
			 	app_cat,
			 	didmd5
			)res   ------users that we paid for on real time bidding system
		on 
			qingtui.imei_md5=res.didmd5
		group by
			qingtui.device_uuid,
		 	qingtui.day1
		)t1 -----daily users that open our app through our paid ads
	left join
		(select 
			day,
			concat(substr(day,1,4),'-',substr(day,5,2),'-',substr(day,7,2)) as day2,
			device_uuid,
			bg
			kv['source'] as source
		from 
			portal.edm_user_device_session_hour 
		where 	
		 	app_id in ('2x1kfBk63z','B6c7g2') 
		 	and day='20190826'
		 	and kv['source'] like '%news_zhizi_android_01%'
		group by 
			day,
			device_uuid,
			bg
			kv['source']
		)t2 -----how the users start our app(four ways: ug/back/app/push)
	on
		t1.device_uuid=t2.device_uuid
	group by
		t1.day1,
		t1.device_uuid,
		t2.bg,
		datediff(day2,day1)
	)t3 -----daily users information and their ways to start the app
group by
	t3.day1 




---留存分析
select 
	u.dayno 日期,
	count(distinct s.uid) '次日留存'
from userinfo u
left join userinfo s 
on u.uid = s.uid
AND DATEDIFF(s.dayno,u.dayno)=1
where u.app_name='相机'and s.app_name='相机'
group by u.dayno;


select
    a.dayno 日期,
    count(distinct a.uid) 活跃,
    count(distinct case when datediff(b.dayno,a.dayno)=1 then a.uid end) 次留,
    count(distinct case when datediff(b.dayno,a.dayno)=3 then a.uid end) 三留,
    count(distinct case when datediff(b.dayno,a.dayno)=7 then a.uid end) 七留,
    concat(count(distinct case when datediff(b.dayno,a.dayno)=1 then a.uid end)/count(distinct a.uid)*100,'%') 次日留存率,
    concat(count(distinct case when datediff(b.dayno,a.dayno)=3 then a.uid end)/count(distinct a.uid)*100,'%') 三日留存率,
    concat(count(distinct case when datediff(b.dayno,a.dayno)=7 then a.uid end)/count(distinct a.uid)*100,'%') 七日留存率
from userinfo a 
left join userinfo b
on a.uid=b.uid
where a.app_name='相机'and b.app_name='相机'
group by a.dayno;

