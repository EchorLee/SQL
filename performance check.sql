---we released a new program--insert articles of high quality in the home page, so we want to see how this action will affect our users and the experience with our app.

select	
	wakeup.day,	
	count(distinct case when datediff(day2,day1)=0 then wakeup.device_uuid else null end) hx,		
	sum(case when tttime.device_uuid is not null then total_time else 0 end) as total_time,	---total time spent on the app
	sum(case when readtime.device_uuid is not null then wz_pv else 0 end) as wz_pv,		---total page views 
	sum(case when readtime.device_uuid is not null then wz_time else 0 end) as wz_time,		---total reading time spent on the news
	sum(case when refresh.device_uuid is not null then refresh_times else 0 end) as refresh_times, ---total refresh times
	sum(case when refresh.device_uuid is not null then adexposure_times else 0 end) as adexposure_times ---total advertisement exposure times
from 
	(select		
		day,		
		device_uuid,			
		concat(substr(day,1,4),'-',substr(day,5,2),'-',substr(day,7,2)) as day1	
	from 
		portal.edm_qingtui_wake_user_detail_day 	
	where 
		app_id in ('2x1kfBk63z')		
		and day>=20191018 and day<=20191111
	group by 
		day,
		device_uuid
	) wakeup 

left outer join

	(select		
		day,		
		device_uuid,		
		sum(dura) as total_time	
	from 
		portal.edm_galaxy_duration_day 	
	where 
		day>=20191018 and day<=20191111	
		and app_id='2x1kfBk63z'		
		and event_id='DU'	
	group by 
		day,
		device_uuid
	) tttime on wakeup.day=tttime.day and wakeup.device_uuid=tttime.device_uuid  ---total time spent on the app

left outer join

 	(select		
	 	day,		
	 	device_uuid,	
	 	count(distinct content_id) as wz_pv,		
	 	sum(dura) as wz_time	
	 from	
	 	portal.edm_galaxy_content_bros_day  	
	 where	
	 	day>=20191018 and day<=20191111	
		 and app_id='2x1kfBk63z'		
		 and event_id='_pvX'		
		 and dura<=600000 --limit reading time to 10mins	
	 group by 
	 	day,
	 	device_uuid
 	) readtime on wakeup.day=readtime.day and wakeup.device_uuid=readtime.device_uuid  ---total page views and reading time spent on the news

left outer join

	(select		
	 	day,		
	 	device_uuid,		
	 	count(1) as refresh_times	
 	from 
 		portal.edm_galaxy_refresh_day	
 	where	
	 	day>=20191018 and day<=20191111
	 	and column_name='头条'		
	 	and app_id='2x1kfBk63z'		
	 	and (   (event_id='REFRESH_CLICK' and kv['type'] in('下拉','历史分割线','底部TAB','刷新火箭')) or event_id in ('LISTRU')   )	
 	group by 
 		day,
 		device_uuid
 	) refresh on wakeup.day=refresh.day and wakeup.device_uuid=refresh.device_uuid ---total refresh times

left outer join

 	(select 		
	 	day,		
	 	device_uuid,		
	 	sum(adexposure_times) as adexposure_times	
 	from 	
 		(select 			
	 		day,			
	 		device_uuid,			
	 		session_id,			
	 		column_name,			
	 		pos,			
	 		count(distinct content_id, eid) as adexposure_times		
	 	from 
	 		portal.edm_user_exposure_detail_day		
	 	where 	
	 		app_id='2x1kfBk63z'			
	 		and day>=20191018 and day<=20191111		
	 		and column_name='头条'			
	 		and column_name in ('头条')			
	 		and pos in ('3','9','22','28','34','40','52','58','16')		
	 	group by day,device_uuid,column_name,session_id,pos	
	 	) tmp1	
 	group by 
 		day,
 		device_uuid			

 	union all		

 	select 		
	 	day,		
	 	device_uuid,		
	 	sum(adexposure_times) as adexposure_times	
 	from 	
 		(select 			
	 		day,			
	 		device_uuid,			
	 		session_id,			
	 		column_name,			
	 		pos,			
	 		count(distinct content_id, eid) as adexposure_times		
 		from 
 			portal.edm_user_exposure_detail_day		
 		where 	
	 		app_id='2x1kfBk63z'			
	 		and day>=20191018 and day<=20191111				
	 		and column_name in ('娱乐',	'体育',	'本地',	'新时代','视频',	'财经',	'视频::推荐','热点',	'要闻',	'要闻::要闻','直播::热门','科技',	'汽车',	'NBA','段子','网易号','军事','轻松一刻', '微资讯',	'房产','彩票','国际足球',	'薄荷','历史','手机',	'活力冬奥学院','时尚'	)			
	 		and pos in ('1','6','8','14','20','26','32','38','50','56')		
 		group by day,device_uuid,column_name,session_id,	pos	
 		) tmp2	
 	group by 
 		day,
 		device_uuid

	) ad on wakeup.day=ad.day and wakeup.device_uuid=ad.device_uuid ---total advertisement exposure times

 group by wakeup.day
