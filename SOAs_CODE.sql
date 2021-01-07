use <<database>>
go

-------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- I. HLUTI UNDIRBÚNINGUR
-- 1. HREINSA GÖGNIN -- SLÁ SAMAN, FJARLÆGJA RUSL, SKIPTA UPP TLSV
--
-------------------------------------------------------------------------------------------------------------------------------------------------------

--Create table with source zones, including housing data:	Geo_Milureitir
--List neighbours of all source zones within SOA:			Geo_Milureitir_GR


--------------------------------------------------------------------------------------------------------------------------------------------
-- 
-- II. HLUTI
-- THE CODE
--
--------------------------------------------------------------------------------------------------------------------------------------------


--------------------------------------------------------------------------------------------------------------------------------------------
-- 
-- 1. Undirbúningur reiknirits
--
--------------------------------------------------------------------------------------------------------------------------------------------

go
if OBJECT_ID('tempdb..##tlsv')>0 drop table ##tlsv    --building blocks within a talningarsvæði
if OBJECT_ID('tempdb..##Z_gr')>0 drop table ##Z_gr    --neighbors of each building block within tlsv
if OBJECT_ID('tempdb..##hive')>0 drop table ##hive    --lokaniðurstaða
if OBJECT_ID('tempdb..##hg')>0 drop table ##hg        --lokaniðurstaða einfölduð á öðru formi
if OBJECT_ID('tempdb..##hgTst')>0 drop table ##hgTst  --mælingareintak
if OBJECT_ID('tempdb..##maps')>0 drop table ##maps    --(Skástu) Niðurstöður settar í kort
if object_id('tempdb..##data')>0 drop table ##data    --Heldur utan um tölfræðina
if OBJECT_ID('tempdb..#thive')>0 drop table #thive    --temporary tafla - vinnslutafla fyrir ##hive
if OBJECT_ID('tempdb..#tmpTFJ')>0 drop table #tmpTFJ  --temporary tafla
if OBJECT_ID('tempdb..#cand')>0 drop table #cand	  --temporary tafla. Heldur utan um nágranna og næstu nágranna etc þess reits sem er upphafsreitur hverju sinni
if OBJECT_ID('tempdb..#c')>0 drop table #c	          --temporary tafla. Til að stofna Cand án tvítekningar á tilvísun í NewID()
if OBJECT_ID('tempdb..#s')>0 drop table #s	          --temporary tafla. Heldur utan um fjölda íbúa og úrtaksstærðina úr hverju talningarsvæði, ásamt R og M gildum
if OBJECT_ID('tempdb..#t')>0 drop table #t	          --temporary tafla. Heldur utan um fastagildi, R, M, T og V 
if object_id('tempdb..#h')>0 drop table #h            --temporary tafla. Heldur utan um hid númerin sem standa að baki hverri lausn
if object_id('tempdb..#a')>0 drop table #a            --temporary tafla. prufutafla

if OBJECT_ID('tempdb..#g')>0 drop table #g
if OBJECT_ID('tempdb..#d')>0 drop table #d

go



create table ##tlsv (
	fID int identity(1,1) not null primary key, 
	tlsv varchar(20), 
	id varchar(5),
	Stadgr5 varchar(255), 
	fj int, 
	geom geometry, 
	shape_area numeric(38,11), 
	shape_len numeric(38,11),
	junik varchar(5),
	avgFJB float,
	avgFM float,
	avgBAr float,
	NDw int,
	NStf int
	)


create table ##Z_gr (
	tlsv varchar(20), 
	id varchar(5), 
	gr varchar(5), 
	Border_len numeric(38,11), 
	d int)

create table ##hive (
	hid int identity(1,1) not null, 
	hgID int, 
	run int, 
	tlsv varchar(20), 
	i int, 
	id varchar(5), 
	gr varchar(5) , 
	fj int , 
	tfj int, 
	d int,
	RowNr int)

create table #thive (
	hid int identity(1,1) not null, 
	run int, 
	tlsv varchar(20), 
	i int, 
	id varchar(5), 
	gr varchar(5) , 
	fj int , 
	tfj int, 
	d int,
	RowNr int)

create table ##maps (
	id int identity(1,1) not null primary key, 
	hgID int not null, 
	fID int, 
	rn1 int, rn2 int, 
	run int, i int, tlsv varchar(20), 
	geom geometry, 
	shape_area numeric(38,11), 
	shape_len numeric(38,11), 
	compact numeric(10,5), --as cast(4*pi()*shape_area/power(shape_len,2) as numeric(10,5)), 
	Fjoldi int,
	Ibudir numeric(38,11),
	Fermetrar numeric(38,11),
	Byggingarar numeric(38,11),
	FjIbuda int,
	FjStadfanga int
	)

create table ##hg (hgID int not null Primary key, run int, i int, tlsv varchar(20), smsv varchar(max), 
	fjoldi varchar(max), compact varchar(max),
	alls_fjoldi int,
	AVG_Fjoldi numeric(10,5),
	AVG_Wcompact numeric(38,11),
	AVG_Wibudir numeric(38,11),
	AVG_Wfermetrar numeric(38,11),
	AVG_Wbyggingarar numeric(38,11),
	SSB_compact numeric(38,11),
	SSB_fjoldi numeric(38,11),
	SSB_ibudir numeric(38,11),
	SSB_fermetrar numeric(38,11),
	SSB_byggingarar numeric(38,11),
	F int default(0) --Pareto frontier
)

create table ##hgTst (hgID int identity(1,1) not null Primary key, run int, i int, tlsv varchar(20), smsv varchar(max), 
	fjoldi varchar(max), compact varchar(max),
	alls_fjoldi int,
	AVG_Fjoldi numeric(10,5),
	AVG_Wcompact numeric(38,11),
	AVG_Wibudir numeric(38,11),
	AVG_Wfermetrar numeric(38,11),
	AVG_Wbyggingarar numeric(38,11),
	SSB_compact numeric(38,11),
	SSB_fjoldi numeric(38,11),
	SSB_ibudir numeric(38,11),
	SSB_fermetrar numeric(38,11),
	SSB_byggingarar numeric(38,11),
	F int default(0) --Pareto frontier
)

create table ##data (
  did int identity(1,1) not null primary key,
    run int
  , i int
  , tlsv varchar(20)
  , id varchar(5)
  , tag varchar(2) --ur upphafsreitur random, ud upphafsreitur ysta lag, d layer
  , rid int --fjöldi reita sem valdir eru úr ysta lagi
  , grp int --fjöldi sem valið er úr (ysta lagi eða þeim sem eftir eru)
  --, ath varchar(100)
  )

create table #tmpTFJ (run int, i int, tlsv varchar(20), id varchar(5), tFj int)
create table #cand (run int, i int, tlsv varchar(20), id varchar(5), gr varchar(5), fj int, d int, r int, hfj int)
create table #c (run int, i int, tlsv varchar(20), id varchar(5), gr varchar(5), fj int, d int, r int, hfj int)
create table #s (tlsv varchar(20) not null primary key, N int, S int, U int)
create table #t (r int, m int, t int, v int)
create table #h (hid int, hgID int)

go

CREATE NONCLUSTERED INDEX idx_hive_visar ON ##hive (run,tlsv,i,gr) INCLUDE (fj, id)

CREATE NONCLUSTERED INDEX idx_tlsv_tlsv_id ON ##tlsv ([tlsv]) INCLUDE ([id])

CREATE NONCLUSTERED INDEX idx_tmpTLSV_fj ON ##tlsv ([fj]) INCLUDE ([fID],[tlsv],[id])

CREATE NONCLUSTERED INDEX idx_d on #cand (d) include (run, i, tlsv, id, gr, fj)

CREATE NONCLUSTERED INDEX IDX_tmpHIVE_hgID ON ##hive ([hgID]) INCLUDE ([id],[gr])

CREATE NONCLUSTERED INDEX IDX_tmpHIVE_tFJ ON ##hive ([tfj]) INCLUDE ([run],[tlsv],[i],[id],[gr],[fj])

CREATE NONCLUSTERED INDEX IDX_tmpMaps_HgID_fID ON ##Maps ([hgID],[fID]) INCLUDE ([id])

CREATE NONCLUSTERED INDEX IDX_tmpHG_F ON ##hg ([F]) INCLUDE ([hgID],[tlsv])

CREATE NONCLUSTERED INDEX IDX_tmpMaps_Fjoldi ON ##Maps ([Fjoldi]) INCLUDE ([hgID])

CREATE NONCLUSTERED INDEX idx_z_gr_tlsv ON ##Z_gr ([tlsv]) INCLUDE ([id],[gr])
GO


--Lykilparametrar
insert into #t (r, m, t, v)
select R=20, M=1700, T=3000, V=200

--Fylkja (populera) grunntöflurnar

insert into ##tlsv (tlsv, id, Stadgr5, geom, shape_area, shape_len, fj, avgFJB, avgFM, avgBAr, NDw, NStf)
select tlsv, id, ogr_fid, geom, flatarmal, lengd, fjöldi, avgFJB, avgFM, avgBAr, NDw, NStf
from dbo.Geo_Milureitir 

update ##tlsv set junik=id


;with b  as (
select distinct a.tlsv, b.id, c.id gr, BorderLength
from dbo.Geo_Milureitir_GR a
join ##tlsv b on a.tlsv=b.tlsv and a.id=b.id
join ##tlsv c on a.tlsv=c.tlsv and a.gr=c.id
)
insert into ##Z_gr (tlsv, id, gr, border_len, d)
select tlsv, id, gr, sum(BorderLength), 9
from b
group by tlsv, id, gr


go
truncate table #s
insert into #s
select tlsv, N=sum(fj), S=cast(case when tlsv between '06' and '08' then count(distinct ID) * 1 else count(distinct ID) * 1 end as int), U=count(distinct ID)
from ##tlsv 
where fj>0
group by tlsv 

go
IF CURSOR_STATUS('global','crs') >= -1
 BEGIN
  IF CURSOR_STATUS('global','crs') > -1
   CLOSE crs
  DEALLOCATE crs
 END
IF CURSOR_STATUS('global','mcrs') >= -1
 BEGIN
  IF CURSOR_STATUS('global','mcrs') > -1
   CLOSE mcrs
  DEALLOCATE mcrs
 END
IF CURSOR_STATUS('global','tcrs') >= -1
 BEGIN
  IF CURSOR_STATUS('global','tcrs') > -1
   CLOSE tcrs
  DEALLOCATE tcrs
 END
IF CURSOR_STATUS('global','g') >= -1
 BEGIN
  IF CURSOR_STATUS('global','g') > -1
   CLOSE g
  DEALLOCATE g
 END
go


--------------------------------------------------------------------------------------------------------------------------------------------
-- 
-- 2. Smásvæðin búin til
--
--------------------------------------------------------------------------------------------------------------------------------------------



--1 tengja saman

set nocount on
truncate table ##hive
truncate table #thive
declare @hid int, @id varchar(5), @init varchar(5), @fj int, @gr varchar(5), @d int, @f int, @tfj int, @mFj int, @h int, @i int, @j int, @k int, @l int, @tlsv varchar(20)
declare @n int, @run int, @nst varchar(max), @M INT, @S int, @R int, @T int, @V int, @U int, @rid int, @td varchar(20)
--declare @ath varchar(100)

select top 1 @r=r, @m=m, @mfj=m, @T=t, @v=v from #t

BEGIN
	set @run=0
	while @run<@R
		begin
			set @run=@run + 1

			--Taka hvert talningarsvæði fyrir sig
			declare tcrs cursor for
			select tlsv, N, S, U
			from #s 
			--where tlsv<'02'
			order by tlsv

			open tcrs
			fetch next from tcrs into @tlsv, @n, @S, @U
			truncate table #thive

			while @@FETCH_STATUS=0
				begin
					--Innan hvers talningarsvæðis, leyfa öllum byggðum reitum að vera upphafsreitir
					declare mcrs cursor for
					with a (tlsv, id, init, h, rn) as (
					select distinct tlsv, id=id, init=id, h=0, ROW_NUMBER() OVER(ORDER BY id) --ef tekið úrtak úr þessu þá  OVER(ORDER BY NewID())
					from ##tlsv
					where tlsv=@tlsv
					and fj>0
					)
					select tlsv, id, init, h, @u
					from a
					where rn<=@S

					open mcrs
					fetch next from mcrs into @tlsv, @id, @init, @h, @u
					
					set @i=0

					while @@FETCH_STATUS=0 -- fyrir hvern júník reit (fj>0) innan talningarsvæðis,
						begin
							select @i=@i+1, @h=0

							insert into ##data (run, i, tlsv, id, tag, rid, grp)
							select @run, @i, @tlsv, @init, 'ur', 1, @U								

							--truncate table #tHive

							--halda áfram þar til búið er að úthluta öllum reitum innan talningarsvæðis
							WHILE @h=0
								begin
									truncate table #cand
									truncate table #c

									--declare @init varchar(5)='00010', @tlsv varchar(20)='01', @d int, @run int=1, @i int=1, @k int, @t int=3000, @l int, @fj int, @M int=1600
									set  @k=0 									
									insert into #c (tlsv, run, i, id, gr, fj, d, r)
									select tlsv, run=@run, i=@i, @init, @init, fj, d=0, r=1
									from ##tlsv a
									where id=@init and tlsv=@tlsv and not exists(select 1 from #tHive b where a.tlsv=b.tlsv and a.id=b.gr and b.run=@run and b.i=@i)
									
									--Hvaða nágrannahópar eru út frá @init og ekki hafa komið áður
									--declare @init varchar(5)='00010', @tlsv varchar(20)='01', @d int, @run int=1, @i int=1, @k int=0, @t int=3000, @l int, @fj int, @M int=1600
											
									WHILE @@ROWCOUNT>0
										begin
											set @k=@k+1
											;with z as (
											select distinct  a.tlsv, a.id, a.gr, fj 
											from ##Z_gr a join ##tlsv c on a.tlsv=c.tlsv and a.gr=c.id 
											where a.tlsv=@tlsv and 
											not exists(select 1 from #thive b where a.tlsv=b.tlsv and b.gr in (a.id,a.gr) and b.run=@run and b.i=@i)
											),
											b as (
											select distinct  run=@run, i=@i, z.tlsv, id= @init, z.gr, z.fj, d=@k
											from z join #c b on z.tlsv=b.tlsv and z.id=b.gr
											where not exists(select 1 from #c d where z.tlsv=d.tlsv and z.gr=d.gr)
											)
											insert into #c (run, i, tlsv, id, gr, fj, d, r)
											select run, i, tlsv, id, gr, fj, d, Row_NUmber() OVER(Order by case when fj=0 then 1 else d end, NewID()) as int
											from b
										end
										
									if exists(select 1 from #c)
										begin
											insert into #cand (run, i, tlsv, id, gr, fj, d, r, hfj)
											select a.run, a.i, a.tlsv, a.id, a.gr, a.fj, a.d, a.r, sum(b.fj)
											from #c a join #c b on a.d*100+a.r>=b.d*100+b.r
											group by a.run, a.i, a.tlsv, a.id, a.gr, a.fj, a.d, a.r
											having sum(b.fj)<@T
											order by a.d, a.r

											--Hér er sú staða af ef fyrsti reitur er >@T er ekkert valið og forritið fer í endalausa lúppu
											if @@ROWCOUNT=0
												insert into #cand (run, i, tlsv, id, gr, fj, d, r, hfj)
												select a.run, a.i, a.tlsv, a.id, a.gr, a.fj, a.d, a.r, fj
												from #c a
												where d=0

											--declare @k int, @l int, @fj int, @m int =1600, @t int=3000, @d int
											select @k=d, @l=r, @fj=hfj from #cand a where exists(select 1 from #cand b having abs(@M-a.Hfj)=min( abs(@M-b.Hfj)))

											--hvað eru margir í ysta laginu sem var tekið úr
											select @d=COUNT(*) from #cand where d=@k

											--select @d, @k, @l, @fj, * from #cand

											delete a
											output deleted.run, deleted.tlsv, deleted.id, deleted.gr, deleted.fj, deleted.hfj, deleted.d, deleted.i, deleted.r 
											into #thive (run, tlsv, id, gr, fj, tfj, d, i, RowNr)
											from #cand a
											where d*1000+r <= @k*1000+@l

											--líklega óþarft
											--delete #c where d*1000+r <= @k*1000+@l
											
											select @rid=count(*) from #thive where d=@k and run=@run and i=@i and tlsv=@tlsv
											select @d=@rid+count(*) from #cand where d=@k and run=@run and i=@i and tlsv=@tlsv

											insert into ##data (run, i, tlsv, id, tag, rid, grp)
											select @run, @i, @tlsv, @init, 'd', @rid, @d

											--Næsta init er fyrsti nágranni sem eftir er í #c ef hann er til
											select @init=null
											select top 1 @init=a.id, @k=d
											from #c a
											where (d*1000+r>@k*1000+@l)
											order by d, r

											if @init is not null
												begin
													select @u=count(distinct a.id)
													from #c a
													where d=@k
												end
											else -- ekki fleira á #c að græða
												begin
													select @init=null
													select top 1 @init=id
													from ##tlsv b
													where tlsv=@tlsv and not exists(select 1 from #thive c where b.tlsv=c.tlsv and b.id=c.gr and run=@run and i=@i )
													order by newid()

													select @u=count(distinct id)
													from ##tlsv b
													where tlsv=@tlsv and not exists(select 1 from #thive c where b.tlsv=c.tlsv and b.id=c.gr and run=@run and i=@i )
													
													if @init is null set @h=1
												end
																						
											insert into ##data (run, i, tlsv, id, tag, rid, grp)
											select @run, @i, @tlsv, @init, 'ud', 1, @u
										end	

	
									else -- ekki fleira á #c að græða
										begin
											select @init=null
											select top 1 @init=id
											from ##tlsv b
											where tlsv=@tlsv and not exists(select 1 from #thive c where b.tlsv=c.tlsv and b.id=c.gr and run=@run and i=@i )
											order by newid()

											select @u=count(distinct id)
											from ##tlsv b
											where tlsv=@tlsv and not exists(select 1 from #thive c where b.tlsv=c.tlsv and b.id=c.gr and run=@run and i=@i )
													
											if @init is null set @h=1
										end

									
								end


							fetch next from mcrs into @tlsv, @id, @init, @h, @u
							--set @h=1  --ef meiningin er að stoppa eftir fyrstu ítrun
						end

						close mcrs
						deallocate mcrs

						insert into ##hive (run, i, tlsv, id, gr, fj, tfj, d, RowNr)
						select run, i, tlsv, id, gr, fj, tfj, d, RowNr
						from #thive
						order by hid
						fetch next from tcrs into @tlsv, @n, @S, @U
						truncate table #thive

					end

			close tcrs
			deallocate tcrs
		end
END

set nocount off


go


set nocount on
declare  @r int, @i int, @mx int, @j int

select top 1 @r=r, @i=-1 from #t
select @j=1, @mx=max(s) from #s
declare @a table (i int)

while @j<=case when @r<@mx then @mx else @r end
	begin
		insert into @a (i) values(@j)
		set @j=@j+1
	end



print 'afgangs svæði'

set nocount on
while @@ROWCOUNT>0
	begin
		--Öll örsvæðin sem urðu afgangs eru sett inn
		;with 
		 t as (select * from #s),
		 y (run) as (select i from @a where i<=@R),
		 x (i) as (select i from @a where i<=@mx),
		 h (tlsv, gr, fj) as (select distinct tlsv, id, fj from ##tlsv),
		 z (run, tlsv, i, gr, fj) as (
			select distinct run, h.tlsv, i, gr, fj
			from y, x, h join t on h.tlsv=t.tlsv
			where t.s>=x.i
		   ),
		 w (run, tlsv, i, ID, fj) as (
			select distinct z.run, z.tlsv, z.i, ID=z.gr, z.fj
			from z
			where not exists( select 1 from ##hive b where z.run=b.run and z.tlsv=b.tlsv and z.i=b.i and z.gr=b.gr)
		   ),
		 a  (run, i, tlsv, id, gr, fj, r) as (
			Select w.run, w.i, w.tlsv, c.id, w.id, 0, ROW_NUMBER() OVER(PARTITION BY w.run, w.i, w.tlsv, w.id ORDER BY sum(border_len) DESC, c.id)
			from w 
			join ##Z_gr b on w.tlsv=b.tlsv and w.id=b.id
			join ##hive c on w.run=c.run and w.i=c.i and w.tlsv=c.tlsv and b.gr=c.gr
			where w.fj=0 
			group by  w.run, w.i, w.tlsv, c.id, w.id
			) 
		insert into ##hive (run, tlsv, i, id, gr, fj, tfj, d)
		select run, tlsv, i, id, gr, fj, null, @i
		from a 
		where r=1
		if @@rowcount>0 set @i=@i-1
	end

set nocount off

print 'Næst er +0 viðbót'
--Ekki má gleyma hinum svæðunum sem urðu afgangs, en hafa fleiri en 0 íbúa. Þau eru límd síðar í öðru ferli
;with 
 t as (select * from #s),
 y (run) as (select i from @a where i<=@R),
 x (i) as (select i from @a where i<=@mx),
 h (tlsv, gr, fj) as (select distinct tlsv, id, fj from ##tlsv),
 a (run, tlsv, i, gr, fj) as (
    select distinct run, h.tlsv, i, gr, fj
    from y, x, h join t on h.tlsv=t.tlsv
	where t.s>=x.i
   )
insert into ##hive (run, tlsv, i, id, gr, fj, tfj, d)
select distinct a.run, a.tlsv, a.i, a.gr, a.gr, a.fj, a.fj, 0
from a left join ##hive b on a.run=b.run and a.tlsv=b.tlsv and a.i=b.i and a.gr=b.gr
where b.gr is null



--Næst er að breyta tFj þannig að breytan verði ekki lengur kúmulatíf heldur sýni fyrir hvert örsvæði hversu fjölmennt smásvæðið er

;with b as (select run, tlsv, id, i, sum(fj) tfj from ##hive group by run, tlsv, id, i)
update a
set tFj=b.tFj
from ##hive a join b on a.tlsv=b.tlsv and a.id=b.id  and a.i=b.i and a.run=b.run

go

print 'Klippa og líma litlu svæðin'
--Loks skipta upp litlu svæðunum og líma þau við næstu nágranna (með lengstu landamærin), ef heildarfjöldinn verður ekki meir en 2500 
declare @i int, @h int, @t int
select top 1 @i=-101, @h=0, @t=T from #t
--select * from ##hive where tlsv='01'

while @@ROWCOUNT>0 and @h=0
	begin
--declare @i int, @h int, @t int
--select top 1 @i=-101, @h=0, @t=T from #t

		;with 
		 w (run, i, tlsv, oID, Id, fj, tfj) as (
			select distinct run, i, tlsv, ID, gr, fj, tfj
			from ##hive 
			where tfj<900 --and tlsv='01'
		   ),
		 bb  (run, i, tlsv, id, gr, fj, nTfj, r) as (
			Select w.run, w.i, w.tlsv, c.id, w.id, min(w.fj), c.tFj, ROW_NUMBER() OVER(PARTITION BY w.run, w.i, w.tlsv, w.id ORDER BY sum(border_len) DESC, c.Tfj) --finna lengstu landamærin
			from w 
			join ##Z_gr b on w.tlsv=b.tlsv and w.id=b.id
			join ##hive c on w.run=c.run and w.i=c.i and w.tlsv=c.tlsv and b.gr=c.gr
			where w.fj+c.tFj<@T and c.tfj>w.fj /*and w.fj+c.tfj>=900*/ and w.oid!=c.id --sameinast stærra svæði
			group by  w.run, w.i, w.tlsv, c.id, w.id, c.tFj
			) ,
		b (run, i, tlsv, id, gr, fj, nTfj, r) as (
		select run, i, tlsv, id, gr, fj, nTfj, ROW_NUMBER() OVER(PARTITION BY run, i, tlsv, id ORDER BY case when fj=0 then 1 else 2 end, Fj desc) -- þetta til að velja aðeins eitt svæði í einu sem sameinast X, fyrst hið stærsta
		from bb
		where r=1
		) 

		update a 
		set id=b.id,
			d=@i,
			tFJ=a.fj+nTfj
		--select *
		from ##hive a join b on a.run=b.run and a.i=b.i and a.tlsv=b.tlsv and a.gr=b.gr
		where r=1
		if @@rowcount>0 and  @i>-140
			begin
				set @i=@i-1
				;with b as (select run, tlsv, id, i, sum(fj) tfj from ##hive group by run, tlsv, id, i having sum(fj)!=min(tfj) or min(tfj)!=max(tfj))
				update a
				set tFj=b.tFj
				from ##hive a join b on a.tlsv=b.tlsv and a.id=b.id  and a.i=b.i and a.run=b.run
			end
		else
			set @h=1
	end
	go

set nocount off
go

;with b as (select run, tlsv, id, i, sum(fj) tfj from ##hive group by run, tlsv, id, i having sum(fj)!=min(tfj) or min(tfj)!=max(tfj))
update a
set tFj=b.tFj
from ##hive a join b on a.tlsv=b.tlsv and a.id=b.id  and a.i=b.i and a.run=b.run


--Fjarlægja eyjar sem ekki hafa mannfjölda
delete ##hive
where tfj=0

--laga ##hive, þannig að id númerið sé fitjunúmer frá 1 til k
--Nauðsynlegt til að finna unique lausnir


;with b as (select tlsv, run, i, id, new_id=Row_NUMBER() OVER(Partition by tlsv, run, i Order by Min(gr)) from ##hive group by tlsv, run, i, id)
update a
set id=new_id
from ##hive a join b on a.tlsv=b.tlsv and a.run=b.run and a.i=b.i and a.id=b.id

go

;with b as (select run, i, tlsv, hgID=min(Hid) from ##hive group by run, i, tlsv) 
update a 
set hgID=b.hgID
from ##hive a join b on a.run=b.run and a.i=b.i and a.tlsv=b.tlsv



--------------------------------------------------------------------------------------------------------------------------------------------
-- 
-- 3. Finna öll auðkenni pr svæði
--
--------------------------------------------------------------------------------------------------------------------------------------------


Print 'Populera HGTst og HG'
go


truncate table ##hg
truncate table ##hgTst
truncate table ##maps
;

set identity_insert ##hgTst on
;with b as (select  hgID=min(hID), tlsv, i, run from ##hive group by tlsv, i, run)
insert into ##hgTst (hgID, run, i, tlsv, SMSV)
SELECT hgID, run, i, tlsv
     , (STUFF((SELECT CAST(',' + cast(id as varchar(5)) + ',' + cast(gr as varchar(5)) AS VARCHAR(MAX)) 
         FROM ##hive a
         WHERE (hgID = b.hgID) 
		 ORDER BY ID, GR
         FOR XML PATH ('')), 1, 1, '')) AS smsv
FROM  b 
set identity_insert ##hgTst off


;with b as (select  min(hgID) hgID, smsv from ##hgTst group by smsv)
insert into ##hg (hgID, run, i, tlsv, smsv)
select a.hgID, a.run, a.i, a.tlsv, a.smsv 
from ##hgTst a
join b on a.hgID=b.hgID




--Svo má setja saman allar unique grúpperingar á talningarsvæði, ásamt fjölda á hverju smásvææði
go
PRINT 'Compactness'
go

;with 
a as (
select  a.hgID, b.run, b.i, b.id, b.tlsv, a.gr id_gr, sum(isnull(border_len,0)) bl
from ##hive a
join ##hive b on a.tlsv=b.tlsv and a.run=b.run and a.i=b.i and a.id=b.id --and a.gr!=b.gr
left join ##Z_gr c on a.tlsv=c.tlsv and c.id=a.gr and c.gr=b.gr
group by a.hgID, b.run, b.i, b.id, b.tlsv, a.gr
),
d as (
select a.*, shape_len-bl p, shape_area a, fj
from a
join ##tlsv c on a.tlsv=c.tlsv and a.id_gr=c.id
),
e as (
select hgid, id, run, i, tlsv, sum(a) flatarmál, sum(p) ummál, 4*pi()*sum(a)/power(sum(p),2) compact, sum(fj) fjoldi
from d
group by hgid, id, run, i, tlsv
)
insert into ##maps (hgID, fID, run, i, tlsv, shape_area, shape_len, compact, fjoldi)
select hgid, id, run, i, tlsv, flatarmál, ummál, compact, fjoldi
from e 
where exists(select 1 from ##hg f where e.hgID=f.hgID)



--bæta við upplýsingum úr ##Z í ##maps
print 'bæta við upplýsingum úr ##tlsv í ##maps'

;with b as (select a.hgID, fID=a.id, 
 Ibudir=sum(avgfjb*Nstf)/case when isnull(sum(nstf),0)=0 then 1 else sum(nstf) end, 
 Fermetrar=sum(avgFM*ndw)/case when isnull(sum(nstf),0)=0 then 1 else sum(nstf) end,  
 Byggingarar=sum(avgBAR*NStf)/case when isnull(sum(ndw),0)=0 then 1 else sum(ndw) end, 
 fjIbuda=sum(ndw), 
 fjStadfanga=sum(nstf)
from ##hive a join ##tlsv b on a.tlsv=b.tlsv and a.gr=b.id
group by a.hgID, a.ID
)
update a
set Ibudir=b.Ibudir,
	Fermetrar=b.fermetrar,
	Byggingarar=b.byggingarar,
	FjIbuda=b.fjIbuda,
	fjStadfanga=b.fjStadfanga
from ##maps a
join b on a.hgID=b.hgid and a.fid=b.fid


go

;with b as (Select HgID, avg_WCompact=SUM(fjoldi*Compact)/sum(fjoldi) from ##maps group by HgID)
update a
set avg_WCompact=b.avg_WCompact
from ##hg a join b on a.hgID=b.hgid


;with b as (Select HgID, Alls_fjoldi=sum(Fjoldi), avg_Fjoldi=SUM(cast(fjoldi as numeric(10,3)))/count(distinct id) from ##maps group by HgID)
update a
set avg_Fjoldi=b.avg_Fjoldi,
	Alls_fjoldi=b.Alls_fjoldi
from ##hg a join b on a.hgID=b.hgid

;with b as (Select hgID, avg_WIbudir=SUM(NStf*AvgFjB)/sum(NStf), Stadfong=sum(NStf) 
            from ##tlsv a join ##Hive b on a.tlsv=b.tlsv and a.id=b.gr where NStf>0 group by hgID)
update a
set avg_WIbudir=b.avg_WIbudir
from ##hg a join b on a.hgID=b.hgid


;with b as (Select hgID, avg_Wfermetrar=SUM(NDw*AvgFm)/sum(NDw), Ibudir=sum(NDw) from ##tlsv a join ##Hive b on a.tlsv=b.tlsv and a.id=b.gr where NDw>0 group by hgID)
update a
set avg_Wfermetrar=b.avg_Wfermetrar
from ##hg a join b on a.hgID=b.hgid


;with b as (Select hgID, avg_Wbyggingarar=SUM(NStf*AvgBar)/sum(NStf), Stadfong=sum(NStf) from ##tlsv a join ##Hive b on a.tlsv=b.tlsv and a.id=b.gr where NStf>0 group by hgID)
update a
set avg_Wbyggingarar=b.avg_Wbyggingarar
from ##hg a join b on a.hgID=b.hgid



;with b as (select hgID, fjoldi=avg_Fjoldi, Compact=AVG_Wcompact, Ibudir=AVG_Wibudir, fm=AVG_Wfermetrar, ByggAr=AVG_Wbyggingarar from ##hg),
c as (select b.hgID, SSB_Compact=sum(c.fjoldi*power(c.Compact-b.Compact,2))
from b 
join ##maps c on b.hgID=c.hgID
group by b.hgID
)
update a
set ssb_compact=c.SSB_compact
from ##hg a 
join c on a.hgID=c.hgID


;with b as (select hgID, fjoldi=avg_Fjoldi, Compact=AVG_Wcompact, Ibudir=AVG_Wibudir, fm=AVG_Wfermetrar, ByggAr=AVG_Wbyggingarar from ##hg),
c as (select b.hgID, ssb_fjoldi=sum(c.fjoldi*power(c.fjoldi-b.fjoldi,2))
from b 
join ##maps c on b.hgID=c.hgID
group by b.hgID
)
update a
set ssb_fjoldi=c.SSB_fjoldi
from ##hg a 
join c on a.hgID=c.hgID



;with b as (select hgID, fjoldi=avg_Fjoldi, Compact=AVG_Wcompact, Ibudir=AVG_Wibudir, fm=AVG_Wfermetrar, ByggAr=AVG_Wbyggingarar from ##hg),
c as (select b.hgID, SSB_Ibudir=sum(c.fjStadfanga*power(c.Ibudir-b.Ibudir,2))
from b 
join ##maps c on b.hgID=c.hgID
group by b.hgID
)
update a
set SSB_Ibudir=c.SSB_Ibudir
from ##hg a 
join c on a.hgID=c.hgID


;with b as (select hgID, fjoldi=avg_Fjoldi, Compact=AVG_Wcompact, Ibudir=AVG_Wibudir, fm=AVG_Wfermetrar, ByggAr=AVG_Wbyggingarar from ##hg),
c as (select b.hgID, SSB_byggingarar=sum(c.fjStadfanga*power(c.Byggingarar-b.ByggAr,2))
from b 
join ##maps c on b.hgID=c.hgID
group by b.hgID
)
update a
set SSB_byggingarar=c.SSB_byggingarar
from ##hg a 
join c on a.hgID=c.hgID


;with b as (select hgID, fjoldi=avg_Fjoldi, Compact=AVG_Wcompact, Ibudir=AVG_Wibudir, fm=AVG_Wfermetrar, ByggAr=AVG_Wfermetrar from ##hg),
c as (select b.hgID, SSB_fermetrar=sum(c.fjIbuda*power(c.fermetrar-b.FM,2))
from b 
join ##maps c on b.hgID=c.hgID
group by b.hgID
)
update a
set SSB_fermetrar=c.SSB_fermetrar
from ##hg a 
join c on a.hgID=c.hgID


--------------------------------------------------------------------------------------------------------------------------------------------
-- 
-- 4. Bestunin
--
--------------------------------------------------------------------------------------------------------------------------------------------


--Sjálf Bestunin

--Frontier
--Finna þá sem eru non-dominated (óvíkjanleg), þ.e. engin lausn finnst sem er betri á öllum markgildum.
--Hér eru fjöldatölurnar undanskildar, enda allar innan marka (900-3500) og það ætti að duga

declare @f int, @h int
select @f = 0, @h = 0

while exists(select 1 from ##hg where f=0) and @h=0
begin

	;with c as (
	select hgID, fr=@f+1 from ##hg a where f=@f and 
	 exists (
			select 1 from ##hg b 
			where a.hgID!=b.hgid and a.tlsv=b.tlsv and b.f=@f and  (
			a.avg_WCompact               >= b.avg_Wcompact and
			a.SSB_Compact                <= b.SSB_Compact and
			a.SSB_Ibudir                 >= b.SSB_Ibudir and
			--a.SSB_fermetrar              >= b.SSB_fermetrar and
			a.SSB_Byggingarar            >= b.SSB_Byggingarar  and
			( a.avg_WCompact             > b.avg_Wcompact or
			  a.SSB_Compact              < b.SSB_Compact or
			  a.SSB_Ibudir               > b.SSB_Ibudir or
			  --a.SSB_fermetrar            > b.SSB_fermetrar or
			  a.SSB_Byggingarar          > b.SSB_Byggingarar ))
	))

	update d
	set f=fr
	from ##hg d join c on d.hgID=c.hgID
	if @@ROWCOUNT=0 set @h=1
	set @f=@f+1
end

-- 0 eru þeir sem eru non-dominated
-- 1 eru þeir sem eru non-dominated í dominated hópnum etc.
;with b as (select tlsv, max(f)+1 mxF from ##hg group by tlsv)
update a
set f=mxf-f
from ##hg a join b on a.tlsv=b.tlsv
where a.f>0
go


--setja inn í test töfluna
update a
set f=b.f
from ##HGtst a join ##HG b on a.smsv=b.smsv

--Sortering á þeim sem eru non-dominated, þannig að þeir sem hafa minnstu fjarlægð frá markgildum þegar allt er sett saman komi fremst !
declare @M int
select top 1 @M=m from #t

;with w as (
  Select w1=3.0/7,  --Compact pr íbúa breytan hefur þrefalt vægi
         w2=0.0/7,  --Óþarfi að gera þessa oftast constant
		 w3=2.0/7,  --Compact SSB breytan hefur tvöfalt vægi
		 w4=1.0/7, 
		 w5=0.0/7,  --Mikil fylgni milli fjölda íbúða per staðfang og fermetrafjölda, setja teljara=0
		 w6=1.0/7),
markc     as (select tlsv, maxWCmp=max(avg_WCompact), minWCmp=min(avg_WCompact) from ##hg where f=0 group by tlsv),
markp     as (select tlsv, markFjoldi=cast(@M as numeric(38,11)), 
               maxd=case when abs(@M-min(avg_Fjoldi))>abs(max(avg_Fjoldi)-@M) then  abs(@M-min(avg_Fjoldi)) else abs(max(avg_Fjoldi)-@M) end
			  from ##hg where f=0 group by tlsv),
maxminFj  as (select tlsv, maxFj=max(SSB_fjoldi), minFj=min(SSB_fjoldi) from ##hg where f=0 group by tlsv),
maxminCp  as (select tlsv, maxCmp=max(SSB_Compact), minCmp=min(SSB_Compact) from ##hg where f=0 group by tlsv),
maxminIb  as (select tlsv, maxIb=max(SSB_Ibudir), minIb=min(SSB_Ibudir) from ##hg where f=0 group by tlsv),
maxminFM  as (select tlsv, maxFM=max(SSB_Fermetrar), minFM=min(SSB_Fermetrar) from ##hg where f=0 group by tlsv),
maxminBA  as (select tlsv, maxBA=max(SSB_Byggingarar), minBA=min(SSB_Byggingarar) from ##hg where f=0 group by tlsv),
a as (
select hgID, a.run, a.i, a.tlsv, a.F
	, MFjoldi=case when maxd=0 then 0 else (Markfjoldi-avg_Fjoldi)/maxD end                          --lágmarka fjarlægð frá 1750
	, MCompact=case when (maxWCmp=minWCmp) then 0 else (maxWCmp-avg_WCompact)/(maxWCmp-minWCmp) end  --lágmarka fjarlægð frá hámarkscompact gldi
	, SSBdFjoldi=case when (maxFj=minFj) then 0 else (minFj-SSB_Fjoldi)/(maxFj-minFj) end            --lágmarka SSB mannfjöldans
	, SSBdCompact=case when (maxCmp=minCmp) then 0 else (minCmp-SSB_Compact)/(maxCmp-minCmp) end     --lágmarka SSB samþjöppunarinnar
	, SSBdIbudir=case when (maxIb=minIb) then 0 else (MaxIb-SSB_Ibudir)/(maxIb-minIb) end            --hámarka SSB fjölda íbúða pr staðfang
	, SSBdFM=case when (maxFm=minFM) then 0 else (MaxFm-SSB_fermetrar)/(maxFm-minFM) end             --hámarka SSB fjölda fm pr íbúð
	, SSBdByggAr=case when (maxBA=minBA) then 0 else (maxBA-SSB_byggingarar)/(maxBA-minBA) end       --hámarka SSB byggingarársmeðaltala
from ##hg a 
join markc on a.tlsv=markc.tlsv 
join markp on a.tlsv=markp.tlsv
join maxminFj on a.tlsv=maxminFj.tlsv
join maxminCp on a.tlsv=maxminCp.tlsv
join maxminIb on a.tlsv=maxminIb.tlsv
join maxminFM on a.tlsv=maxminFM.tlsv
join maxminBA on a.tlsv=maxminBA.tlsv
where not exists (select 1 from ##maps m where a.hgID=m.hgID and (fjoldi<900 or fjoldi>3500)) --Fjöldi á svæði verður að vera innan marka, annars er ekki valið í samanburð
) ,
d as (
select hgID, run, i, tlsv, 
 dSUM= w1*abs(MCompact) + w2*abs(SSBdFjoldi) + w3*abs(SSBdCompact) + w4*abs(SSBdIbudir) + w5*abs(SSBdFM) + w6*abs(SSBdByggAr),
 tSUM=cast(cast(MCompact as numeric(38,11)) as varchar(50)) + ', ' + cast(cast(SSBdFjoldi as numeric(38,11))  as varchar(50))+ ', ' + cast(cast(SSBdCompact as numeric(38,11)) as varchar(50))+ ', ' + cast(cast(SSBdIbudir as numeric(38,11)) as varchar(50))+ ', ' + cast(cast(SSBdFM as numeric(38,11)) as varchar(50))+ ', ' + cast(cast(SSBdByggAr as numeric(38,11)) as varchar(50)),
 cvD = dbo.fnCV(cast(cast(MCompact as numeric(38,11)) as varchar(50)) + ', ' + cast(cast(SSBdFjoldi as numeric(38,11))  as varchar(50))+ ', ' + cast(cast(SSBdCompact as numeric(38,11)) as varchar(50))+ ', ' + cast(cast(SSBdIbudir as numeric(38,11)) as varchar(50))+ ', ' + cast(cast(SSBdFM as numeric(38,11)) as varchar(50))+ ', ' + cast(cast(SSBdByggAr as numeric(38,11)) as varchar(50))),
 rn1=Row_number() OVER (partition by tlsv order by w1*abs(MCompact) + w2*abs(SSBdFjoldi) + w3*abs(SSBdCompact) + w4*abs(SSBdIbudir) + w5*abs(SSBdFM) + w6*abs(SSBdByggAr)),
 rn2=Row_number() OVER (partition by tlsv order by sqrt(
       power(w1,2)*power(MCompact,2) + 
	   --power(dMannfj,2) +
	   power(w2,2)*power(SSBdFjoldi,2) + 
	   power(w3,2)*power(SSBdCompact,2) + 
	   power(w4,2)*power(SSBdIbudir,2) + 
	   power(w5,2)*power(SSBdFM,2) + 
	   power(w6,2)*power(SSBdByggAr,2))),
 MCompact, SSBdFjoldi, SSBdCompact, SSBdIbudir, SSBdFM, SSBdByggAr
from a, w
where F=0 -- aðeins mengi þeirra sem er Pareto non-dominated
)
update  a
set rn1=d.rn1,
	rn2=d.rn2
from ##maps a join d on a.hgid=d.hgid and a.tlsv=d.tlsv

go


--Nú má gera kort fyrir bestu lausn
declare @geom geometry, @g geometry, @hgid int, @run int, @i int, @fid int, @tlsv varchar(20), @id varchar(5), @oldtlsv varchar(20), @oldhgID int, @oldrun int, @oldi int, @oldfID int
declare @lausnir int = 1 --þetta haft ef menn vilja gera kort fyrir fleiri opsjónir en bara "skástu" lausn

declare g cursor for
select hgid, fid=b.id, gr, geom--a.tlsv, geom, run, i, fid=b.ID
from ##tlsv a join ##Hive b on a.tlsv=b.tlsv and a.id=b.gr
where exists(select 1 from ##maps c where b.tlsv=c.tlsv and b.run=c.run and b.i=c.i and rn2=1)--<=@lausnir)
union all
select max(hgid)+1, -1, '00000', null from ##hive--99, null, 0, 0, 0
order by hgid, fid

select  @oldHgID=0, @oldfID=0
open g
fetch next from g into  @hgid, @fid, @id, @g
while @@FETCH_STATUS=0
	begin
		if @oldhgid!=@hgid or @oldfID!=@fid	
			begin 
				if @oldfid=0
					set @geom=@g
				else
					begin
						update a
						set geom=@geom
						from ##maps a
						where hgID=@oldhgID and fid=@oldfid
						set @geom=@g
					end
			end
		else
			set @geom=@geom.STUnion(@g)


		select @oldHgID=@hgid, @oldfID=@fid
		fetch next from g into  @hgid, @fid, @id, @g
	end

close g
deallocate g

--------------------------------------------------------------------------------------------------------------------------------------------
-- 
-- 5. Vista niðurstöðurnar
--
--------------------------------------------------------------------------------------------------------------------------------------------


--Niðurstöður
select * from ##maps where rn2=1


go
--vista temptöflurnar
if object_id('dbo.tmpHIVE_20200707')>0 drop table dbo.tmpHIVE_20200707
if object_id('dbo.tmpHG_20200707')>0   drop table dbo.tmpHG_20200707
if object_id('dbo.tmpMAPS_20200707')>0 drop table dbo.tmpMAPS_20200707
if object_id('dbo.tmpDATA_20200707')>0 drop table dbo.tmpDATA_20200707

select *
into dbo.tmpHIVE_20200707
from ##hive

select *
into dbo.tmpHG_20200707
from ##hg

select *
into dbo.tmpMAPS_20200707
from ##maps

select *
into dbo.tmpDATA_20200707
from ##data
