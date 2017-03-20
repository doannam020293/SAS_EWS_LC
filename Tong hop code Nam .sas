/*********************************************************/
/****************DANH SACH KHACH HANG*********************/
/*********************************************************/

libname MISDB OLEDB USER=msb_qlrr PASS=msb@qlrr datasource='10.1.17.222\mssqlserver_2008' 
provider=sqloledb schema=dbo; 
%macro DSKH(output1, date1, date2);
libname MISDB OLEDB USER=msb_qlrr PASS=msb@qlrr datasource='10.1.17.222\mssqlserver_2008' 
provider=sqloledb schema=dbo; 


/*Lay indicator cho rieng khach hang LC*/
proc sql;
create table ews_lc.dskh2 as select
cif_number,
indicator
from misdb.customer
where indicator = 'L';
quit;


proc sql;
create table ews_lc.dskh1 as select
cif_number,
indicator
from misdb.customer
where cif_number in (106429,
129771,
132797,
134800,
136951,
139758,
140275,
3543,
3888,
9734,
110405,
885332,
4050,
133475,
404605,
3254,
13844,
108666,
118470,
130054,
135460,
135833,
139489,
139763,
162599,
164620,
172290,
183448,
188236,
199960,
242052,
242115,
243037,
277020,
347183,
347875,
380098,
386131,
408913,
413443,
438982,
586580,
716490,
883476,
936466,
1002379,
1004237,
1057117,
1085612,
1150063,
1371095,
1382692,
1400878,
1436945,
1455225,
161992,
168374,
1390908,
1410234,
2772,
129978,
8524,
108391,
121094,
132373,
188645,
230346,
435605,
600700,
780171,
1016349,
1029952,
1035200,
1043896,
1123901,
1169372,
1173979,
1174347,
1390185,
1398555,
1404724,
1409204,
1410025,
1419918,
1431435,
1431522,
1431611,
1434361,
1447275,
1453631,
1460269,
109290,
125174,
129257,
130196,
137599,
253669,
1384825,
102809,
251952,
1157764,
1383772,
1443766,
1460091,
1471222,
3157,
225296,
311963,
318314,
390856,
892229,
1414553,
1452347,
992774,
1475309,
1478797,
123156,
145376,
173366,
1503024,
1509287,
1497023,
101111,
1493901,
160753,
1463376,
1493710,
1496978,
1504956,
1512237,
1513536,
198450,
1016781,
1428456,
1536184,
582866,
1529521,
180368,
479679,
715482,
1414372,
1539760,
122081,
124029,
752074,
1516636,
167757,
238510,
192895,
192746,
337647,
1562986,
425960,
940632,
175110,
381292,
395633,
508590,
999644,
1138593,
1153147,
1431655,
1481087,
1528241,
1528486,
1542415,
1551757,
106206,
187730,
314485,
1110908,
1126541,
1165593,
1402346,
1429736,
1469390,
1549594,
1575738,
1578714,
1580457,
119422,
132786,
1099802,
1555425,
153341,
197571,
932573,
236095,
1418984,
1571105,
1576121,
1583045,
1593404
);
quit;


 
 
data ews_lc.ews_dskh_lc;
set ews_lc.dskh2 ews_lc.dskh1;
run;

proc sql;
create table ews_lc.ews_dskh_lc as select distinct
cif_number,
indicator
from ews_lc.ews_dskh_lc;quit;

/*Lay bang ty gia tren may 66*/
proc sql;
create table ews_lc.ssfxrt as select
import_date,
currency_code,
mid_rate
from misdb.ssfxrt
where import_date = &date1;
quit;

/*Lay du lieu lnmast tren may 66*/
proc sql;
create table ews_lc.lnmast as select 
cif_number,
INPUT(import_date, yymmdd10.) AS import_date FORMAT DATE9.,
account,
current_balance,
currency_type,
overdue_indicator,
status,
participation_code
from misdb.lnmast
where import_date = &date1
AND CIF_NUMBER IN (select cif_number from ews_lc.ews_dskh_lc);
quit;

/*Xu ly cac account la C va S*/
/*Xoa cac account co status la 2,8,9 la TK tat toan, TK xoa no, Tk khong su dung*/
data ews_lc.lnmast;
set ews_lc.lnmast;
if participation_code = 'C' or participation_code = 'S' then check = -1;
else check = 1;
if status in (2, 8, 9) then delete;
run;

/*Tinh qd du no*/
proc sql;
create table ews_lc.lnmast_lc_qd as select
a.*,
b.mid_rate,
c.indicator,
a.current_balance*b.mid_rate*a.check as current_balance_qd_cs,
a.current_balance*b.mid_rate as current_balance_qd
from ews_lc.lnmast a left join ews_lc.ews_dskh_lc c
on a.cif_number = c.cif_number
left join ews_lc.ssfxrt b
on a.currency_type = b.currency_code;
quit;

/*Sum cbal quy doi va max nhom no theo cif_number va sau do sort theo cif_number*/
proc sql;
create table ews_lc.lnmast_lc_qd_cif as select distinct
cif_number,
sum(current_balance_qd_cs) as sum_balance_xulycs,
sum(current_balance_qd) as sum_balance_koxuly,
max(overdue_indicator) as max_overdue_indicator
from ews_lc.lnmast_lc_qd
group by cif_number
order by cif_number;
quit;

/*Lay so du TF cuar khacsh hang theo nguyen tac loai cac san pham nho thu, bao lanh,theo cac ma san pham sau*/
proc sql;
create table ews_lc.tfmast as select
cif_number,
INPUT(import_date, yymmdd10.) AS import_date FORMAT DATE9.,
reference,
bill_outstanding,
currency_type
from misdb.tfmast 
where import_date = &date1 
and product_type not in ('AG', 'IC', 'IL', 'OC', 'CT')
AND CIF_NUMBER IN (select cif_number from ews_lc.ews_dskh_lc) ;
quit;

/*Join bang Trade Finance voi ty gia va bang du lieu customer*/
proc sql;
create table ews_lc.tfmast_lc_qd as select
a.*,
b.mid_rate,
c.indicator,
a.bill_outstanding*b.mid_rate as bill_outstanding_qd
from ews_lc.tfmast a left join ews_lc.ews_dskh_lc c
on a.cif_number = c.cif_number
left join ews_lc.ssfxrt b
on a.currency_type = b.currency_code;
quit;


/*Sum total bill_outstanding*/
proc sql;
create table ews_lc.tfmast_lc_qd_cif as select distinct
cif_number,
sum(bill_outstanding_qd) as sum_bill_outstanding_qd
from ews_lc.tfmast_lc_qd
group by cif_number
order by cif_number;
quit;

/*Lay han muc cua khach hang*/
/*Chiet xuat du lieu tu lnappf*/
proc sql;
create table ews_lc.lnappf as select
applicationnumber,
CPNO,
facilityname,
sequencenumber,
currencytype,
cifno,
mainfacility,
facilityaano,
facilitycode,
facilityseq,
facilitylimit,
dateapproved,
facilityexpirydate,
date
from misdb.lnappf_all where date = &date1 
AND CIFNO IN (select cif_number from ews_lc.ews_dskh_lc);
quit;

/*Xu ly du lieu trong lnappf*/
data ews_lc.lnappf;
set ews_lc.lnappf;
dateapproved=datepart(dateapproved)	;
format dateapproved date9. 	;
FacilityExpiryDate=datepart(FacilityExpiryDate)	;
format FacilityExpiryDate date9.;
run;

/*Quy doi han muc cua khach hang*/
proc sql;
create table ews_lc.lnappf_lc_qd as select
a.*,
b.mid_rate,
c.indicator,
a.facilitylimit*b.mid_rate as facilitylimit_qd
from ews_lc.lnappf a left join ews_lc.ews_dskh_lc c
on a.cifno = c.cif_number
left join ews_lc.ssfxrt b
on a.currencytype = b.currency_code;
quit;

/*Giu lai cac khoan co han muc cap 0 con hieu luc tu ngay bao cao tro di*/
data ews_lc.lnappf_lc_qd;
set ews_lc.lnappf_lc_qd;
if facilityaano = 0 and FacilityExpiryDate >= &date2 and DateApproved <>.;
run;

/*Tinh tong han muc cap 0 va max ngay het han theo cif va order lai theo cif*/
proc sql;
create table ews_lc.lnappf_lc_qd_cif as select distinct
cifno as cif_number,
sum(facilitylimit_qd) as sum_facilitylimit,
max(FacilityExpiryDate) as max_FacilityExpiryDate
from ews_lc.lnappf_lc_qd
group by cifno
order by cifno;
quit;
/*GHEP 3 BANG */
data ews_lc.Listofcustomer_ews_lc;
merge 
ews_lc.lnmast_lc_qd_cif
ews_lc.tfmast_lc_qd_cif
ews_lc.lnappf_lc_qd_cif
;
by CIF_number;
format max_FacilityExpiryDate date9.;
if sum_balance_xulycs = "." then sum_balance_xulycs = 0;
if sum_balance_koxuly = "." then sum_balance_koxuly = 0;
if sum_bill_outstanding_qd = "." then sum_bill_outstanding_qd = 0;
if sum_facilitylimit = "." then sum_facilitylimit = 0;

/*Sum cua lnmast va TF*/
sum_LN_TF = sum_balance_koxuly + sum_bill_outstanding_qd;

/*Sum facility + lnmast + TF*/
sum_Fac_LN_TF = sum_LN_TF + sum_facilitylimit;
run;

data &output1;
set ews_lc.Listofcustomer_ews_lc;
if sum_balance_xulycs = sum_balance_koxuly = 0 then max_overdue_indicator = "";
if max_overdue_indicator = 'A' or max_overdue_indicator = '' ;
if sum_Fac_LN_TF = 0 then delete; 
End_date=&date1;
run;






%mend DSKH;



/**********************************************************/
/********************TINH DONG TIEN VAO*******************/
/**********************************************************/

%MACRO THRUPUT(STARTDATE,ENDDATE,masterfile,OUT);
/*TAO LIBNAME*/

libname MISDB OLEDB USER=msb_qlrr PASS=msb@qlrr datasource='10.1.17.222\mssqlserver_2008' 
provider=sqloledb schema=dbo;

/*lAY DU LIEU DDMAST NHUNG DA LOAI DI CAC SP KY QUY*/
/*CIF KHACH HANG NAM TRONG TRONG DANH SACH KHACH HANG EWS (DANH SACH DUOC TAO THEO TUNG YEU CAU)*/

PROC SQL;
CREATE TABLE ews_lc.DDMAST AS SELECT DISTINCT
CIF_NUMBER,
ACCOUNT
FROM MISDB.DDMAST WHERE IMPORT_DATE >=&startdate and IMPORT_DATE <=&enddate AND ACCOUNT_TYPE NOT IN (
'CA11B',     
'CA11FB',    
'CA11I',     
'CA11ODPFI', 
'CA11SD',
'CA11STAFF',
'CA11TCTD',
'CA12CP',
'CA12GT',
'CA12LC',
'CA12LS',
'CA12NV',
'CA12OP',
'CA12OPI',
'CA131',
'CA22ODP',
'CAFCB',
'CAGOPVON',
'CAM1',
'CAM1FC',
'CAMBASIC',
'CAMBASICFC',
'CAMCOM',
'CAMFAMILY',
'CA-RM',
'F-CA12GT',
'F-CA12LC',
'F-CA12NV',
'F-CA12OP',
'KYQUYT',
'L-CA12GT',
'L-CA12LC',
'L-CA12OP',
'MC-ADVANCE',
'MC-FREE100',
'MCPLUS',
'M-INVEST01',
'R-CA11IUL',
'R-CA12OP',
'S-CA11B',
'SLC01',
'SV11',
'SVVIP'
)  
AND CIF_NUMBER IN (select cif_number from &masterfile);
QUIT;

/*LAY DU LIEU BANG TY GIA*/

PROC SQL;
CREATE TABLE ews_lc.SSFXRT AS SELECT DISTINCT
MID_RATE,
INPUT(import_date, yymmdd10.) AS import_date FORMAT DATE9.,
CURRENCY_CODE
FROM MISDB.SSFXRT 
WHERE IMPORT_DATE >= &STARTDATE AND IMPORT_DATE <= &ENDDATE;
QUIT;

/*LAY DU LIEU DDHIST*/
/*LAY SO DU CUA KHACH HANG DUOC GHI CO (CREDIT)HAY C TREN DDHIST*/
/*KHI TAI KHAON CUA KHACH HANG DUOC GHI C CO = DONG TIEN VAO*/

PROC SQL;
CREATE TABLE ews_lc.DDHIST AS SELECT 
ACCOUNT,
TRANSACTION_AMOUNT,
CURRENCY_TYPE,
DEBIT_CREDIT_CODE,
INPUT(POSTED_DATE, yymmdd10.) AS POSTED_DATE FORMAT DATE9.,
USER_ID,
SEQUENCE_NUMBER,
AUX_TRANSACTION_CODE,
AFFECTS_CODE
FROM MISDB.DDHIST 
WHERE POSTED_DATE >= &STARTDATE  AND POSTED_DATE <=&ENDDATE AND DEBIT_CREDIT_CODE ="C" 
AND ACCOUNT IN (SELECT ACCOUNT FROM ews_lc.DDMAST) ;
QUIT;


/*QUY DOI TRANSACTION_AMOUNT TRONG DDHIST SAU KHI MAPPING LOAI DONG TIEN*/

PROC SQL;
CREATE TABLE ews_lc.DDHIST_1 AS SELECT 
A.ACCOUNT,
A.TRANSACTION_AMOUNT,
A.TRANSACTION_AMOUNT*C.MID_RATE AS TRANSACTION_AMOUNT_QD,
A.CURRENCY_TYPE,
A.DEBIT_CREDIT_CODE ,
A.POSTED_DATE,
A.USER_ID,
A.SEQUENCE_NUMBER,
A.AFFECTS_CODE,
A.AUX_TRANSACTION_CODE,
B.CIF_NUMBER,
C.MID_RATE
FROM ews_lc.DDHIST A 
LEFT JOIN ews_lc.DDMAST B 
ON A.ACCOUNT=B.ACCOUNT
LEFT JOIN ews_lc.SSFXRT C ON A.CURRENCY_TYPE = C.CURRENCY_CODE AND A.POSTED_DATE =C.IMPORT_DATE
ORDER BY B.CIF_NUMBER, A.ACCOUNT, A.POSTED_DATE;QUIT;

/*TINH TONG SO TIEN TRANSACTION_AMOUNT SAU KHI QUY DOI*/

PROC SQL;
CREATE TABLE ews_lc.DDHIST_SUM AS SELECT DISTINCT
CIF_NUMBER,
SUM(TRANSACTION_AMOUNT_QD) AS SUM_TRANSACTION
FROM ews_lc.DDHIST_1
GROUP BY CIF_NUMBER;
QUIT;

/*LAY DU LIEU CAC KHOAN GIAI NGAN LOAN TREN DD*/
/*TRUOC TIEN LAY CAC KHOAN DA GIAI NGAN TREN LNMAST*/
/* CHI LAY CIF_NUMBER VA ACCOUNT*/

PROC SQL;
CREATE TABLE ews_lc.LNMAST AS SELECT DISTINCT
CIF_NUMBER,
ACCOUNT
FROM MISDB.LNMAST WHERE IMPORT_DATE >=&STARTDATE and import_date <=&enddate AND CIF_NUMBER IN (select CIF_NUMBER from &masterfile);
QUIT;

/*TAI DU LIEU LNHIST  
CHI LAY NHUNG KHOAN GIAI NGAN BANG TIEN MAT, CHUYEN KHOAN TRONG CHI NHANH/TRONG HE THONG/NGOAI HE THONG (4320,4360)
NGOAI RA DAY LA NHUNG GIAO DICH ANH HUONG DEN GOC(P)*/

PROC SQL;
CREATE TABLE ews_lc.LNHIST AS SELECT 
ACCOUNT,
TRANSACTION_AMOUNT,
CURRENCY_TYPE,
DEBIT_CREDIT_CODE,
INPUT(POSTING_DATE, yymmdd10.) AS POSTING_DATE FORMAT DATE9.,
USER_ID,
SEQUENCE_NUMBER,
LHAXTC, 
TRANSACTION_CODE,
AFFECTS_CODE
from misdb.lnhist
where posting_date >= &startdate and posting_date <= &enddate AND LHAXTC IN ( '4320', '4360', '4364') AND AFFECTS_CODE = 'P'
AND ACCOUNT IN (SELECT ACCOUNT FROM ews_lc.LNMAST) ;
QUIT;

/*JOIN LNHIST VOI LNAMST DE LAY CIF_NUMBER CHO NHUNG KHOAN GIAI NGAN*/

proc sql;
create table ews_lc.LNHIST_1 as select 
a.cif_number,
b.*
from ews_lc.LNMAST a right join ews_lc.LNHIST b
on a.account = b.account;
quit;

/*JOIN DDHIT VOI LNHIST DE TIM RA CAC KHOAN GIAI NGAN*/

PROC SQL;
CREATE TABLE ews_lc.DDHIST_TRU_QD_LN AS SELECT distinct
a.*,
b.account as account_ln,
b.posting_date as posting_date_ln,
b.TRANSACTION_AMOUNT as TRANSACTION_AMOUNT_ln,
b.cif_number as cifno
FROM ews_lc.DDHIST_1 A 
left JOIN ews_lc.LNHIST_1 b 
ON b.POSTING_DATE =a.POSTED_DATE
and b.user_id = a.user_id
and b.SEQUENCE_NUMBER = a.SEQUENCE_NUMBER
and b.cif_number = a.cif_number;
QUIT; 


/*TNH TONG CAC KHOAN DA GIAI NGAN DA CHUYEN VAO DD THEO CIF*/

PROC SQL;
CREATE TABLE ews_lc.DDHIST_TRU_LN AS SELECT DISTINCT
CIFNO,
SUM(TRANSACTION_AMOUNT_QD) AS SUM_TRANSACTION
FROM ews_lc.DDHIST_TRU_QD_LN
GROUP BY CIFno;
QUIT;

/*LOAI CAC GIAO DICH CUA CUNG KHACH HANG CHUYEN VAO DD TRONG NOI BO MSB*/
/*LAY CAC TRANSACTION NOI BO CUA CIF HOAC THEO DANH SACH KHACH HANG*/
data ews_lc.ddhist_1_c;
set ews_lc.DDHIST_1;
if AUX_TRANSACTION_CODE in (
'BP1321',    
'EB1321',    
'EB2320',    
'EB2321',    
'IB1321',    
'IB2321',    
'SMS1321',   
'V1321',     
'1320',
'1321',
'2320',
'2321',
'9614',
'9615'
);
if AFFECTS_CODE = "B";
if DEBIT_CREDIT_CODE ="C";
run;


PROC SQL;
CREATE TABLE ews_lc.DDMAST_D AS SELECT DISTINCT
CIF_NUMBER,
ACCOUNT
FROM MISDB.DDMAST WHERE IMPORT_DATE >=&startdate and IMPORT_DATE <=&enddate  
AND CIF_NUMBER IN (select cif_number from &masterfile);
QUIT;

PROC SQL;
CREATE TABLE ews_lc.DDHIST_D AS SELECT 
ACCOUNT,
TRANSACTION_AMOUNT,
CURRENCY_TYPE,
DEBIT_CREDIT_CODE,
INPUT(POSTED_DATE, yymmdd10.) AS POSTED_DATE FORMAT DATE9.,
USER_ID,
SEQUENCE_NUMBER,
AUX_TRANSACTION_CODE,
AFFECTS_CODE
FROM MISDB.DDHIST 
WHERE POSTED_DATE >= &STARTDATE  AND POSTED_DATE <=&ENDDATE AND DEBIT_CREDIT_CODE ="D" 
AND ACCOUNT IN (SELECT ACCOUNT FROM ews_lc.DDMAST_D) and AFFECTS_CODE = "B" 
and AUX_TRANSACTION_CODE in ('BP1321',    
'EB1321',    
'EB2320',    
'EB2321',    
'IB1321',    
'IB2321',    
'SMS1321',   
'V1321',     
'1320',
'1321',
'2320',
'2321',
'9614',
'9615');
QUIT;


PROC SQL;
CREATE TABLE ews_lc.DDHIST_1_D AS SELECT distinct
A.ACCOUNT,
A.TRANSACTION_AMOUNT,
A.TRANSACTION_AMOUNT*C.MID_RATE AS TRANSACTION_AMOUNT_QD,
A.CURRENCY_TYPE,
A.DEBIT_CREDIT_CODE ,
A.POSTED_DATE,
A.USER_ID,
A.SEQUENCE_NUMBER,
A.AFFECTS_CODE,
B.CIF_NUMBER, 
C.MID_RATE

FROM ews_lc.DDHIST_D A LEFT JOIN ews_lc.DDMAST_D B 
ON A.ACCOUNT = B.ACCOUNT
LEFT JOIN ews_lc.SSFXRT C ON A.CURRENCY_TYPE = C.CURRENCY_CODE AND A.POSTED_DATE =C.IMPORT_DATE
ORDER BY B.CIF_NUMBER, A.ACCOUNT, A.POSTED_DATE;
QUIT;


proc sql;
create table ews_lc.DD_DD_TRU as select distinct
a1.*, 
b1.account as account_dd,
b1.posted_date as posted_date_tkgui,
b1.cif_number as cifno
from ews_lc.ddhist_1_c a1 left join ews_lc.ddhist_1_d b1
on a1.USER_ID = b1.user_id
and a1.SEQUENCE_NUMBER = b1.Sequence_Number
and a1.posted_date = b1.posted_date
and a1.cif_number = b1.CIF_NUMBER;
quit;


PROC SQL;
CREATE TABLE ews_lc.DDHIST_TRU_DD AS SELECT DISTINCT
CIFno,
SUM(TRANSACTION_AMOUNT_QD) AS SUM_TRANSACTION
FROM ews_lc.DD_DD_TRU
GROUP BY Cifno;
QUIT;


proc sql;
create table &out as select distinct
a.cif_number,
a.SUM_TRANSACTION,
b.SUM_TRANSACTION as SUM_TRANSACTION_tru_ln,
c.SUM_TRANSACTION as SUM_TRANSACTION_tru_dd
from ews_lc.DDHIST_SUM a left join ews_lc.DDHIST_TRU_ln b
on a.cif_number = b.cifno
left join ews_lc.DDHIST_TRU_DD c
on a.cif_number = c.cifno;
quit;


data &out;
set &out;
if SUM_TRANSACTION_tru_ln = '.' then SUM_TRANSACTION_tru_ln = 0;
if SUM_TRANSACTION_tru_dd = '.' then SUM_TRANSACTION_tru_dd = 0;
diff = SUM_TRANSACTION - SUM_TRANSACTION_tru_ln - SUM_TRANSACTION_tru_dd;
run;
/*
proc sql;
create table &out as select
a.cif_number,
b.sum_transaction,
b.sum_transaction_tru_ln,
b.sum_transaction_tru_dd,
b.diff
from
ews_lc.DDMAST a
left join &out b on a.cif_number = b.cif_number;
quit;

data &out;
set &out;
if diff =.then diff =0;
run;
*/

/*dm 'output;clear;log;clear;'*/
%MEND;
/**********************************************************/
/********************TINH DONG TIEN RA*******************/
/**********************************************************/
%MACRO OUTPUT(STARTDATE,ENDDATE,masterfile,OUT);

libname MISDB OLEDB USER=msb_qlrr PASS=msb@qlrr datasource='10.1.17.222\mssqlserver_2008' 
provider=sqloledb schema=dbo; 

PROC SQL;
CREATE TABLE ews_lc.DDMAST AS SELECT DISTINCT
CIF_NUMBER,
ACCOUNT
FROM MISDB.DDMAST WHERE IMPORT_DATE >=&startdate and IMPORT_DATE <=&enddate AND ACCOUNT_TYPE NOT IN (
'CA11B',     
'CA11FB',    
'CA11I',     
'CA11ODPFI', 
'CA11SD',
'CA11STAFF',
'CA11TCTD',
'CA12CP',
'CA12GT',
'CA12LC',
'CA12LS',
'CA12NV',
'CA12OP',
'CA12OPI',
'CA131',
'CA22ODP',
'CAFCB',
'CAGOPVON',
'CAM1',
'CAM1FC',
'CAMBASIC',
'CAMBASICFC',
'CAMCOM',
'CAMFAMILY',
'CA-RM',
'F-CA12GT',
'F-CA12LC',
'F-CA12NV',
'F-CA12OP',
'KYQUYT',
'L-CA12GT',
'L-CA12LC',
'L-CA12OP',
'MC-ADVANCE',
'MC-FREE100',
'MCPLUS',
'M-INVEST01',
'R-CA11IUL',
'R-CA12OP',
'S-CA11B',
'SLC01',
'SV11',
'SVVIP'
)  
AND CIF_NUMBER IN (select cif_number from &masterfile);
QUIT;


PROC SQL;
CREATE TABLE ews_lc.SSFXRT AS SELECT DISTINCT
MID_RATE,
INPUT(import_date, yymmdd10.) AS import_date FORMAT DATE9.,
CURRENCY_CODE
FROM MISDB.SSFXRT 
WHERE IMPORT_DATE >= &STARTDATE AND IMPORT_DATE <= &ENDDATE;
QUIT;

PROC SQL;
CREATE TABLE ews_lc.DDHIST AS SELECT 
ACCOUNT,
TRANSACTION_AMOUNT,
CURRENCY_TYPE,
DEBIT_CREDIT_CODE,
INPUT(POSTED_DATE, yymmdd10.) AS POSTED_DATE FORMAT DATE9.,
USER_ID,
SEQUENCE_NUMBER,
AUX_TRANSACTION_CODE,
AFFECTS_CODE
FROM MISDB.DDHIST 
WHERE POSTED_DATE >= &STARTDATE  AND POSTED_DATE <=&ENDDATE AND DEBIT_CREDIT_CODE ="D" 
AND ACCOUNT IN (SELECT ACCOUNT FROM ews_lc.DDMAST) ;
QUIT;



PROC SQL;
CREATE TABLE ews_lc.DDHIST_1 AS SELECT 
A.ACCOUNT,
A.TRANSACTION_AMOUNT,
A.TRANSACTION_AMOUNT*C.MID_RATE AS TRANSACTION_AMOUNT_QD,
A.CURRENCY_TYPE,
A.DEBIT_CREDIT_CODE ,
A.POSTED_DATE,
A.USER_ID,
A.SEQUENCE_NUMBER,
A.AFFECTS_CODE,
A.AUX_TRANSACTION_CODE,
B.CIF_NUMBER,
C.MID_RATE

FROM ews_lc.DDHIST A 
LEFT JOIN ews_lc.DDMAST B 
ON A.ACCOUNT=B.ACCOUNT
LEFT JOIN ews_lc.SSFXRT C ON A.CURRENCY_TYPE = C.CURRENCY_CODE AND A.POSTED_DATE =C.IMPORT_DATE
ORDER BY B.CIF_NUMBER, A.ACCOUNT, A.POSTED_DATE;
QUIT;


PROC SQL;
CREATE TABLE ews_lc.DDHIST_SUM AS SELECT DISTINCT
CIF_NUMBER,
SUM(TRANSACTION_AMOUNT_QD) AS SUM_TRANSACTION
FROM ews_lc.DDHIST_1
GROUP BY CIF_NUMBER;
QUIT;


/*Keo cac khoan GN loan tren dd*/

PROC SQL;
CREATE TABLE ews_lc.LNMAST AS SELECT DISTINCT
CIF_NUMBER,
ACCOUNT
FROM MISDB.LNMAST WHERE IMPORT_DATE >=&STARTDATE and import_date <=&enddate AND CIF_NUMBER IN (select CIF_NUMBER from &masterfile);
QUIT;

/* TRICH NO THU CONG*/
PROC SQL;
CREATE TABLE ews_lc.LNHIST_MANUAL AS SELECT 
ACCOUNT,
TRANSACTION_AMOUNT,
CURRENCY_TYPE,
DEBIT_CREDIT_CODE,
INPUT(POSTING_DATE, yymmdd10.) AS POSTING_DATE FORMAT DATE9.,
USER_ID,
SEQUENCE_NUMBER,
LHAXTC, 
TRANSACTION_CODE,
AFFECTS_CODE
from misdb.lnhist
where posting_date >= &startdate and posting_date <= &enddate AND LHAXTC IN ( '4121','4920','4930','')
AND AFFECTS_CODE in( 'P','I') AND DEBIT_CREDIT_CODE ="D" 
AND ACCOUNT IN (SELECT ACCOUNT FROM ews_lc.LNMAST) ;
QUIT;

/*TRICH NO TU DONG*/
PROC SQL;
CREATE TABLE ews_lc.LNHIST_AUTO AS SELECT 
ACCOUNT,
TRANSACTION_AMOUNT,
CURRENCY_TYPE,
DEBIT_CREDIT_CODE,
INPUT(POSTING_DATE, yymmdd10.) AS POSTING_DATE FORMAT DATE9.,
USER_ID,
SEQUENCE_NUMBER,
LHAXTC, 
TRANSACTION_CODE,
AFFECTS_CODE
from misdb.lnhist
where posting_date >= &startdate and posting_date <= &enddate AND TRANSACTION_CODE in(146)
AND AFFECTS_CODE in( 'P','I')AND DEBIT_CREDIT_CODE ="D" 
AND ACCOUNT IN (SELECT ACCOUNT FROM ews_lc.LNMAST) ;
QUIT;

DATA EWS_LC.LNHIST;
SET ews_lc.LNHIST_MANUAL ews_lc.LNHIST_AUTO;RUN;

proc sql;
create table ews_lc.LNHIST_1 as select 
a.cif_number,
b.*
from ews_lc.LNMAST a right join ews_lc.LNHIST b
on a.account = b.account
;
quit;

PROC SQL;
CREATE TABLE ews_lc.DDHIST_TRU_QD_LN AS SELECT distinct
a.*,
b.account as account_ln,
b.posting_date as posting_date_ln,
b.TRANSACTION_AMOUNT as TRANSACTION_AMOUNT_ln,
b.cif_number as cifno
FROM ews_lc.DDHIST_1 A 
left JOIN ews_lc.LNHIST_1 b 
ON b.POSTING_DATE =a.POSTED_DATE
and b.user_id = a.user_id
and b.SEQUENCE_NUMBER = a.SEQUENCE_NUMBER
and b.cif_number = a.cif_number;
QUIT; 



PROC SQL;
CREATE TABLE ews_lc.DDHIST_TRU_LN AS SELECT DISTINCT
CIFNO,
SUM(TRANSACTION_AMOUNT_QD) AS SUM_TRANSACTION
FROM ews_lc.DDHIST_TRU_QD_LN
GROUP BY CIFno;
QUIT;



/*LOAI CAC KHOAN CHUYEN RA DD TRONG NOI BO MSB*/

data ews_lc.ddhist_1_D;
set ews_lc.DDHIST_1;
if AUX_TRANSACTION_CODE in (
'BP1321',    
'EB1321',    
'EB2320',    
'EB2321',    
'IB1321',    
'IB2321',    
'SMS1321',   
'V1321',     
'1320',
'1321',
'2320',
'2321',
'9614',
'9615'
);
if AFFECTS_CODE = "B";
if DEBIT_CREDIT_CODE ="D";
run;


PROC SQL;
CREATE TABLE ews_lc.DDMAST_C AS SELECT DISTINCT
CIF_NUMBER,
ACCOUNT
FROM MISDB.DDMAST WHERE IMPORT_DATE >=&startdate and IMPORT_DATE <=&enddate  
AND CIF_NUMBER IN (select cif_number from &masterfile);
QUIT;

PROC SQL;
CREATE TABLE ews_lc.DDHIST_C AS SELECT 
ACCOUNT,
TRANSACTION_AMOUNT,
CURRENCY_TYPE,
DEBIT_CREDIT_CODE,
INPUT(POSTED_DATE, yymmdd10.) AS POSTED_DATE FORMAT DATE9.,
USER_ID,
SEQUENCE_NUMBER,
AUX_TRANSACTION_CODE,
AFFECTS_CODE
FROM MISDB.DDHIST 
WHERE POSTED_DATE >= &STARTDATE  AND POSTED_DATE <=&ENDDATE AND DEBIT_CREDIT_CODE ="C" 
AND ACCOUNT IN (SELECT ACCOUNT FROM ews_lc.DDMAST_C) and AFFECTS_CODE = "B" 
and AUX_TRANSACTION_CODE in ('BP1321',    
'EB1321',    
'EB2320',    
'EB2321',    
'IB1321',    
'IB2321',    
'SMS1321',   
'V1321',     
'1320',
'1321',
'2320',
'2321',
'9614',
'9615');
QUIT;


PROC SQL;
CREATE TABLE ews_lc.DDHIST_1_C AS SELECT distinct
A.ACCOUNT,
A.TRANSACTION_AMOUNT,
A.TRANSACTION_AMOUNT*C.MID_RATE AS TRANSACTION_AMOUNT_QD,
A.CURRENCY_TYPE,
A.DEBIT_CREDIT_CODE ,
A.POSTED_DATE,
A.USER_ID,
A.SEQUENCE_NUMBER,
A.AFFECTS_CODE,
B.CIF_NUMBER, 
C.MID_RATE

FROM ews_lc.DDHIST_C A LEFT JOIN ews_lc.DDMAST_C B 
ON A.ACCOUNT = B.ACCOUNT
LEFT JOIN ews_lc.SSFXRT C ON A.CURRENCY_TYPE = C.CURRENCY_CODE AND A.POSTED_DATE =C.IMPORT_DATE
ORDER BY B.CIF_NUMBER, A.ACCOUNT, A.POSTED_DATE;

QUIT;




proc sql;
create table ews_lc.DD_DD_TRU as select distinct
a1.*, 
b1.account as account_dd,
b1.posted_date as posted_date_tkgui,
b1.cif_number as cifno
from ews_lc.ddhist_1_D a1 left join ews_lc.ddhist_1_C b1
on a1.USER_ID = b1.user_id
and a1.SEQUENCE_NUMBER = b1.Sequence_Number
and a1.posted_date = b1.posted_date
and a1.cif_number = b1.CIF_NUMBER
;
quit;



  
PROC SQL;
CREATE TABLE ews_lc.DDHIST_TRU_DD AS SELECT DISTINCT
CIFNO,
SUM(TRANSACTION_AMOUNT_QD) AS SUM_TRANSACTION
FROM ews_lc.DD_DD_TRU
GROUP BY CIFNO;
QUIT;


proc sql;
create table &out as select distinct
a.cif_number,
a.SUM_TRANSACTION,
b.SUM_TRANSACTION as SUM_TRANSACTION_tru_ln,
c.SUM_TRANSACTION as SUM_TRANSACTION_tru_dd
from ews_lc.DDHIST_SUM a left join ews_lc.DDHIST_TRU_ln b
on a.cif_number = b.cifno
left join ews_lc.DDHIST_TRU_DD c
on a.cif_number = c.cifno;
quit;


data &out;
set &out;
if SUM_TRANSACTION_tru_ln = '.' then SUM_TRANSACTION_tru_ln = 0;
if SUM_TRANSACTION_tru_dd = '.' then SUM_TRANSACTION_tru_dd = 0;
diff = SUM_TRANSACTION - SUM_TRANSACTION_tru_ln - SUM_TRANSACTION_tru_dd;
run;

dm log 'clear' ;
%MEND;


/*********************************************************/
/****************HAN MUC SU DUNG*********************/
/*********************************************************/
%macro export_lnappf(lnappf_month,date,listofname);

proc sql;
create table &lnappf_month as select distinct
ApplicationNumber,
CPNo,
FacilityName,
SequenceNumber,
CurrencyType,
CIFNo,
FacilityAAno,
FacilityCode,
FacilitySeq,
FacilityLimit,
dateapproved,
FacilityExpiryDate,
INPUT(Date, yymmdd10.) AS Date FORMAT DATE9.,
AFREVL
from misdb.lnappf_all
where date=&date AND CIFNo IN (SELECT CIF_NUMBER FROM &listofname);
quit;

data &lnappf_month;
set &lnappf_month;
dateapproved=datepart(dateapproved)	;
format dateapproved date9. 	;
FacilityExpiryDate=datepart(FacilityExpiryDate)	;
format FacilityExpiryDate date9.;
run;
	
%mend;
%macro export_lnmast(lnmast_year,date1,date2,listofname);
proc sql;
create table &lnmast_year as select distinct
INPUT(IMPORT_DATE, yymmdd10.) AS IMPORT_DATE FORMAT DATE9.,
ACCOUNT,
CIF_NUMBER,
AA_NUMBER,
CURRENCY_TYPE,
CURRENT_BALANCE,
INPUT(OPEN_DATE, yymmdd10.) AS OPEN_DATE FORMAT DATE9.,
PARTICIPATION_CODE,
FACILITY_CODE,
SEQUENCE_NUMBER
from misdb.lnmast
where &date1 <= import_date and  import_date <= &date2
AND CIF_NUMBER IN (SELECT CIF_NUMBER FROM &listofname); 
quit;
%mend;
%macro export_ssfxrt(ssfxrt,date1,date2);
proc sql;
create table &ssfxrt as select distinct
CURRENCY_CODE ,
INPUT(import_date, yymmdd10.) AS import_date FORMAT DATE9.,
MID_RATE 
from misdb.ssfxrt
where &date1 <= import_date and  import_date <= &date2; 
quit;
%mend;
%macro get_var(input);
	proc contents data=&input out=cont (keep = name) noprint;
	run;

	proc sql noprint;
		select distinct  name into : CMU1_03_var separated by ','
		from cont;
	quit;

	data cont;
	set cont;
	name1 = cat("in1.", name);
	run;

	proc sql noprint;
		select distinct  name1 into : CMD_VAR separated by ','
		from cont;
	quit;
%mend get_var;

/*MACRO TINH DU NO TRUNG BINH*/

%macro avgbalance(input1, input2,input3, day1, output, output1,avg_month);

libname MISDB OLEDB USER=msb_qlrr PASS=msb@qlrr datasource='10.1.17.222\mssqlserver_2008' 
provider=sqloledb schema=dbo;

/*	LAY DU NO TRUNG BINH TRONG THOI GIAN BAO CAO*/
/*DOI DAU NHUNG KHOAN CO C&S TRONG LNMAST DA DOWNLOAD VE*/

		data ews_lc.lnmast_h1_q;
		set &input1;
			if CURRENT_BALANCE ne 0;
			if PARTICIPATION_CODE = "C" or PARTICIPATION_CODE = "S" 
				then CURRENT_BALANCE1 = -1 * CURRENT_BALANCE;
				else CURRENT_BALANCE1 = CURRENT_BALANCE;
		run;

	%get_var(ews_lc.Lnmast_H1_q);
	PROC SQL NOPRINT;
		SELECT DISTINCT name1 into : CMD_VAR separated by ','
		FROM cont;
	QUIT;

/*MAPPING TY GIA*/
	PROC SQL;
		CREATE TABLE ews_lc.Lnmast_h2_q
		AS SELECT DISTINCT
		&CMD_VAR,
		IN2.MID_RATE
		FROM ews_lc.LNMAST_H1_q AS IN1 LEFT JOIN ews_lc.ssfxrt AS IN2
		ON IN1.CURRENCY_TYPE = IN2.CURRENCY_CODE
		and in1.import_date = in2.import_date;
	QUIT;


/*QUY DOI CBAL*/
	DATA ews_lc.lnmast_h2_q;
	SET ews_lc.lnmast_h2_q;
	CURRENT_BALANCE_QD = CURRENT_BALANCE1 * MID_RATE;
	RUN;
	
/* MAP LNMAST LAY RA TRUONG REVOL */

	PROC SQL;
		CREATE TABLE ews_lc.LNMAST_LNAPPF_q AS SELECT 
			in1.CIF_NUMBER,
			in1.IMPORT_DATE,
			in1.ACCOUNT,
			in1.CURRENT_BALANCE_QD,
			in1.AA_number,
			in1.FACILITY_CODE,
			in1.SEQUENCE_NUMBER,
			in2.*
		from ews_lc.lnmast_h2_q as in1 left join &input3 as in2
		on in1.AA_Number = in2.ApplicationNumber
		and in1.FACILITY_CODE = in2.FacilityName
		and in1.SEQUENCE_NUMBER = in2.SequenceNumber
		;
	QUIT;

/*DANH DAU CAC KHOAN REVOL*/
	data &output;
	set ews_lc.LNMAST_LNAPPF_q;
	if FACILITY_CODE in (001,004,005,006,007,211,180,181,902,828,900,182) and AFREVL = 'R';
	run;

		
	%get_var(&output);
	PROC SQL NOPRINT;
		SELECT DISTINCT name1 into : CMD_VAR separated by ','
		from cont;
	QUIT;

/*JOIN LNMAST VOI LNAPPF*/

	PROC SQL;
		CREATE TABLE ews_lc.LNMAST_LNAPPF1_q AS SELECT DISTINCT
			&CMD_VAR,
			in2.cif_number as cifno
		from &output as in1 right join &input2 as in2
		on in1.CIF_NUMBER = in2.CIF_number;
	QUIT;
		
/*LAY SO DU TB*/

	PROC SQL;
		CREATE TABLE &output1 AS SELECT distinct
		CIFNO,
/*		SUM(CURRENT_BALANCE_QD) AS SUM_CURRENT_BALANCE_QD,*/
		SUM(CURRENT_BALANCE_QD)/&day1 as &avg_month
				FROM ews_lc.Lnmast_lnappf1_q
				GROUP BY CIFNO;
	QUIT;

data &output1;
set &output1;
if cifno="." then delete;run;

proc sort data=&output1;
By Cifno;run;


%mend avgbalance;


/* ======================================================================================*/
/* ======================================================================================*/
/* ======================================================================================*/


/*============================================================*/
/*============================ macro NAY DUNG TRONG MACRO TINH HM================================*/
/*============================ macro add colum level to lnappf table================================*/

%macro recusive_add_level_HM(IN_lnappf,OUT_lnappf_with_level);
  %local level nlevel;
  %let   level = 1; 

  proc sql; 

 /* Get first level as table level_1. */

    CREATE table Level_1 as

    SELECT 
		cpno_parent, 
		cpno,
		1 as level, 
		Facilityname, 
		facilityLimit, 
		Cifno, 
		FacilityExpiryDate,
		CurrencyType, 
		DateApproved,
		Date

    FROM &IN_lnappf

    WHERE &IN_lnappf..cpno_parent in ('.','');

 /* Recursively get successive levels. */

  %do %while(&SQLOBS > 0); /* biáº¿n SQLOBS nÃ y lÃ  biáº¿n tá»± sinh sau má»—i cÃ¢u lá»‡nh query trong sql = number of columns in query results*/
		
       %let nlevel = %eval(&level + 1);

      CREATE table Level_&nlevel as
      SELECT 
			&IN_lnappf..cpno_parent,
			&IN_lnappf..cpno, 
			&nlevel as level,
			&IN_lnappf..Facilityname,
			&IN_lnappf..facilityLimit, 
			&IN_lnappf..Cifno,
			&IN_lnappf..FacilityExpiryDate, 
			&IN_lnappf..CurrencyType, 
			&IN_lnappf..DateApproved,  
			&IN_lnappf..Date /* have colum similar with level 1*/

      FROM &IN_lnappf as child INNER JOIN Level_&level as parent
	/* trong bang tong  lnappf, lay ra nhung ban ghi co cpno_parent == cpno trong bang level 1 thi nhung ban ghi do la level 2 */
      ON child.cpno_parent=parent.cpno;

      %let level = &nlevel;

      %end;

 /* Concatenate all levels together */

  data &OUT_lnappf_with_level;

    set %do ii = 1 %to %eval(&level);

          Level_&ii

          %end;

        ;

  run; 

%mend recusive_add_level_HM;

/*============================================================*/
/*============================ macro NAY DUNG TRONG MACRO TINH HM================================*/
/*============================ macro update han muc theo min (sum_han_muc_con, han_muc_cha) ================================*/

%macro recusive_sum_HM(IN_lnappf_leave, IN_lnappf_with_level,OUT_lnappf_level1_final);
 %local level low_level ;
/* create 5 table with level respectively */
%let i=1;
%do i=1 %to 5;
	data lnappf_leave_&i;
	set &IN_lnappf_leave;
	if level = &i;
	run;
%end;


%do i=1 %to 5;
	%let level =  %eval(6 -&i ); /*  coi nhu vong lap giam dan tu 5 -> 0 */
	%let low_level = %eval(&level - 1 );
	proc sql;
	create table lnappf_leave_sum_&low_level as select 
			parent.CPNo_parent,
			parent.CPNO,parent.level,
			parent.Facilityname,
			parent.facilityLimit ,  
			parent.FacilityExpiryDate, 
			parent.cifno, 
			parent.CurrencyType , 
			parent.DateApproved,
			parent.Date,
			sum(child.facilityLimit) as sum_limit_child
	from &IN_lnappf_with_level as parent join lnappf_leave_&level as child
	on parent.CPNo = child.CPNo_parent 
	group by parent.CPNo_parent,
			parent.CPNO,
			parent.level,
			parent.Facilityname, 
			parent.facilityLimit ,  
			parent.FacilityExpiryDate, 
			parent.cifno, 
			parent.CurrencyType,
			parent.DateApproved,
			parent.Date
			;
	quit;
	/* l?y min (sum (h?n m?c con), h?n m?c cha)*/
	data lnappf_leave_sum_&low_level;
	set lnappf_leave_sum_&low_level;
	facilityLimit = min (sum_limit_child,facilityLimit);
	drop sum_limit_child;
	run;
	/* t?ng h?p 2 h?n m?c c?p th?p hon*/
	data lnappf_leave_&low_level;
	set lnappf_leave_&low_level lnappf_leave_sum_&low_level;
	run;
	
%end;

data &OUT_lnappf_level1_final ;
set lnappf_leave_1 ;
run;


%mend recusive_sum_HM;





/*============================================================*/
/*============================ TINH HM================================*/

/*TINH HAN MUC CHO VAY DC CAP*/
/*LAY HAM MUC MOI CON HIEU LUC*/

%macro HM(IN_lnappf,IN_lnmast_lnappf,IN_day1,IN_name_of_Tong_HM_quydoi,Out_HMSD_01);
/************************INPUT:input1: lnappf_01: lnappf of month report           ********************** */
/************************INPUT:input2: lnmast_lnappf_01: lnmast gÃ¡n vá»›i lnappf of month report vá»›i nhá»¯ng háº¡n má»©c náº±m trong cÃ¢y HM            ********************** */
/************************INPUT: day1: date end of month report           ********************** */
/************************INPUT: &IN_Name_of_Tong_HM_quydoi: name of column Tong_HM_qui_doi           ********************** */
/************************OUTPUT:            ********************** */
/************************OUTPUT:            ********************** */

/* filter table Input acorrding to facility_code, and revol = R (ews_lc.lnappf_01,ews_lc.LNMAST_LNAPPF_q_211R_01,MDY(1,31,2017)*/



data  LNMAST_LNAPPF_q_211R_01;
set &IN_lnmast_lnappf ;
if FACILITY_CODE in (001,004,005,006,007,211,180,181,902,828,900,182) and AFREVL = 'R';
run; 

data lnappf_01;
set &IN_lnappf;
if FACILITYNAME in (001,004,005,006,007,211,180,181,902,828,900,182) and AFREVL = 'R';
run;
/* create column cpno_parent in table Lnappf */

proc sql;
create table lnappf_with_cpno_parent as SELECT
			in1.*,
			in2.cpno as cpno_parent
FROM lnappf_01 in1 /* as child table*/
LEFT JOIN ews_lc.lnappf_01 in2 /* as parent table*/
ON in1.FacilityAAno = in2.ApplicationNumber 
AND in1.FacilityCode = in2.FacilityName 
AND in1.FacilitySeq = in2.SequenceNumber;
quit;






/* create column level of facility by recusive query */

%recusive_add_level_HM(lnappf_with_cpno_parent,lnappf_with_level);


/* lay ra nhung han muc cuoi cung, gan lien voi khoan vay, va con hieu luc */
proc sql;
create table lnappf_leave_efective as SELECT *
FROM lnappf_with_level 
WHERE cpno not in (select cpno_parent from lnappf_with_level) and  FacilityExpiryDate >= &IN_day1 ;
quit;
/* lay ra nhung han muc gan voi khoan vay*/
proc sql;
create table lnappf_leave_with_lnmast as select * 
from lnappf_with_level where cpno in  (select distinct cpno from LNMAST_LNAPPF_q_211R_01)  ;
quit;
/*consolidate two table lnapp_leave( it will remove duplicate) */
data lnappf_leave;
set lnappf_leave_efective lnappf_leave_with_lnmast;
run;
/*remove duplicate row*/
proc sort data=lnappf_leave noduprecs;
      by _all_ ; 
Run;

/* create table lnappf_level1_final, with facilitylimit is updated = min(....)*/
%recusive_sum_HM(lnappf_leave, lnappf_with_level,lnappf_level1_final);
/* map exchange*/
PROC SQL;
	CREATE TABLE lnappf_level1_final_map_exchange
	AS SELECT 
	IN1.*,
	IN2.MID_RATE as mid_rate_appf
	FROM lnappf_level1_final AS IN1 LEFT JOIN ews_lc.ssfxrt AS IN2
	ON IN1.CurrencyType = IN2.CURRENCY_CODE
	where  in2.import_date = in1.Date
	;
QUIT;

data lnappf_level1_final_map_exchange;
set lnappf_level1_final_map_exchange;
HM_quydoi = mid_rate_appf*FacilityLimit;
if DateApproved = "." then delete;
run;



proc sql;
create table &Out_HMSD_01 as select 
cifno,
sum(HM_quydoi) as &IN_name_of_Tong_HM_quydoi
from lnappf_level1_final_map_exchange
group by cifno;
quit;
data &Out_HMSD_01;
set &Out_HMSD_01;
if cifno = '.' then delete; run;
proc sort data= &Out_HMSD_01;
By Cifno;run;

%mend HM;



/*********************************************************/
/****************LICH SU QUA HAN*********************/
/*********************************************************/
%macro dpd_ip(input1,output1, output2, day1, day2); 
libname MISDB OLEDB USER=msb_qlrr PASS=msb@qlrr datasource='10.1.17.222\mssqlserver_2008' 
provider=sqloledb schema=dbo;

/*Keo du lieu goc*/
proc sql;
create table &output1 as select distinct			
INPUT(NPDT, yymmdd10.) AS duedate FORMAT DATE9.,
cifno,		
IMPORT_DATE,
max(pddays) as max_dpday		
from misdb.lnpdue a 			
where a.cifno in (select cif_number from &input1) 			
and a.IMPORT_DATE between &day1 and &day2 AND PDDAYS > 0 
group by cifno,NPDT;	
quit;

/*Keo du lieu lai*/
proc sql;
create table 
&output2 
as select distinct			
INPUT(NIPDT7, yymmdd10.) AS duedate FORMAT DATE9.,
cifno,	
IMPORT_DATE,	
max(ipdday) as max_dpday			
from misdb.lnpdue a 			
where a.cifno in (select cif_number from &input1) 			
and a.IMPORT_DATE between &day1 and &day2 AND IPDDAY > 0 
group by cifno, NIPDT7;	
quit;

proc sql;
create table ews_lc.dunokhac0 as select distinct
cif_number as CIFNO from &input1;quit

%mend dpd_ip;
%macro input2(input1, input2, out);
DATA &out;
MERGE &input1 &input2;
BY  duedate CIFNO;
RUN;
%mend;
%macro process_dpd (input1,output1,output2);
/* Lay so ngay qua han max theo duedate*/
proc sql;
create table ews_lc.max_duedate as select distinct
cifno,
duedate,
max(max_dpday) as max_dpd_duedate
from &input1
group by cifno, duedate;
quit;

proc sql;
create table ews_lc.cif1 as select distinct
cifno
from ews_lc.max_duedate
group by cifno;quit;

data ews_lc.mastercif;
set ews_lc.cif1 ews_lc.dunokhac0;run;

proc sql;
create table ews_lc.mastercifdistinct as select distinct
cifno
from ews_lc.mastercif
group by cifno;quit;

/*Dem so ngay qua han theo due date*/
/* Khoan vay qua han tu 2-6 ngay*/
proc sql;
create table &output1 as select distinct
cifno,
duedate
from ews_lc.max_duedate
where (max_dpd_duedate >=2 and max_dpd_duedate<=6) ;
quit;

proc sql;
create table &output1 as select distinct
cifno,
count(duedate) as count_duedate
from &output1
group by cifno;
quit;

proc sql;
create table ews_lc.dunokhac0_1 as select distinct
cifno from ews_lc.mastercifdistinct
where cifno not in (select cifno from &output1);quit;

data &output1;
merge &output1 ews_lc.dunokhac0_1;by cifno;run;

data &output1;
set &output1;
if count_duedate="." then count_duedate=0;run;

/* Khoan vay qua han >7 ngay*/

proc sql;
create table &output2 as select distinct
cifno,
duedate
from ews_lc.max_duedate
where (max_dpd_duedate >=7) ;
quit;

proc sql;
create table &output2 as select distinct
cifno,
count(duedate) as count_duedate
from &output2
group by cifno;
quit;

proc sql;
create table ews_lc.dunokhac0_1 as select distinct
cifno from ews_lc.mastercifdistinct
where cifno not in (select cifno from &output2);quit;

data &output2;
merge &output2 ews_lc.dunokhac0_1;by cifno;run;

data &output2;
set &output2;
if count_duedate="." then count_duedate=0;run;

%mend;
/*********************************************************/
/****************SO TIEN GOC PHAI TRA*********************/
/*********************************************************/
%macro cum_gocphaitra(STARTDATE,ENDDATE,months,masterfile,out);
libname MISDB OLEDB USER=msb_qlrr PASS=msb@qlrr datasource='10.1.17.222\mssqlserver_2008' 
provider=sqloledb schema=dbo;

PROC SQL;
CREATE TABLE ews_lc.LNMAST AS SELECT DISTINCT
INPUT(import_date, yymmdd10.) AS import_date FORMAT DATE9.,
CIF_NUMBER,
ACCOUNT,
ORIGINAL_BALANCE,
CURRENCY_TYPE,
TERM,
TERM_CODE,
STATUS,
PARTICIPATION_CODE,
OVERDUE_INDICATOR
FROM MISDB.LNMAST 
WHERE IMPORT_DATE >= &STARTDATE and import_date <= &enddate 
AND CIF_NUMBER IN (select CIF_NUMBER from &masterfile);
QUIT;

PROC SQL;
CREATE TABLE ews_lc.SSFXRT AS SELECT DISTINCT
MID_RATE,
INPUT(import_date, yymmdd10.) AS import_date FORMAT DATE9.,
CURRENCY_CODE
FROM MISDB.SSFXRT 
WHERE IMPORT_DATE >= &STARTDATE AND IMPORT_DATE <= &ENDDATE;
QUIT;

PROC SQL;
CREATE TABLE ews_lc.lnmast_QD AS SELECT 
a.*,
b.MID_RATE
FROM ews_lc.lnmast A 
LEFT JOIN ews_lc.ssfxrt B 
ON  a.CURRENCY_TYPE = b.CURRENCY_CODE and a.IMPORT_DATE = b.IMPORT_DATE;
QUIT;

data ews_lc.lnmast_QD;
set ews_lc.lnmast_QD;
If ORIGINAL_BALANCE ne 0;
If PARTICIPATION_CODE="C" or PARTICIPATION_CODE="S" then
ORIGINAL_BALANCE1=-1*ORIGINAL_BALANCE;else ORIGINAL_BALANCE1=ORIGINAL_BALANCE;
ORIGINAL_BALANCE_QD=ORIGINAL_BALANCE1*MID_RATE;
run;

proc sql;
create table ews_lc.lnmast_QD_sum as select distinct
cif_number,
account,
term,
term_code,
sum (ORIGINAL_BALANCE_QD) as sum_ORIGINAL_BALANCE_QD,
count(cif_number) as count
from ews_lc.lnmast_QD 
group by cif_number,account ;quit;

data ews_lc.lnmast_QD_sum;
set ews_lc.lnmast_QD_sum;
if TERM_CODE="M" then cum_gocphaitra=(sum_ORIGINAL_BALANCE_QD/count/TERM*30)*count;
if TERM_CODE="D" then cum_gocphaitra=(sum_ORIGINAL_BALANCE_QD/count/TERM)*count;
run;

proc sql;
create table &out as select distinct
cif_number,
sum (cum_gocphaitra) as luykegocphaitra
from ews_lc.lnmast_QD_sum 
group by cif_number ;quit;
%mend;

%macro tonghop_cbal(input);
proc sort data=&input; by cifno;run;

DATA ews_lc.Averagebalance;
MERGE ews_lc.Averagebalance &input;
BY CIFNO;
RUN;
%mend;

%macro tonghop_HM(input);
proc sort data=&input; by cifno;run;
DATA ews_lc.HM;
MERGE ews_lc.HM &input;
BY CIFNO;
RUN;
%mend;

%macro xulyfile(in,out,date);
data &out;
set &in;
drop SUM_TRANSACTION SUM_TRANSACTION_tru_ln SUM_TRANSACTION_tru_dd;
Date=&date;run;
%mend;

%macro cashflow_in(in);
data ews_lc.cashflow_in;
set ews_lc.cashflow_in &in;run;
proc delete data=&in;run;
%mend;



%macro cashflow_out(in);
data ews_lc.cashflow_out;
set ews_lc.cashflow_out &in;run;
proc delete data=&in;run;
%mend;

/*****************************************/
/*LAY THONG TIN CHUNG CUA KHACH HANG*/

%macro tong_hop_cau_hoi(dskh_lc);

libname MISDB OLEDB USER=msb_qlrr PASS=msb@qlrr datasource='10.1.17.222\mssqlserver_2008' 
provider=sqloledb schema=dbo;

proc sql;
create table LC_Cust_inf as select
cif_number,
CUSTOMER_NAME,
OFFICE_ID,
BRANCH_ID
from misdb.customer
where cif_number in (select cif_number from &dskh_lc);
quit;

proc sql;
create table LC_Cust_inf as select 
in1.*,
in2.sum_balance_xulycs as Current_Balance,
in2.Max_overdue_indicator,
in2.sum_bill_outstanding_qd as Sum_bill_outstanding,
in2.Sum_facilitylimit ,
in2.Max_FacilityExpiryDate,
in2.sum_LN_TF,
in2.sum_Fac_LN_TF
from LC_Cust_inf as in1 left join &dskh_lc as in2 on
in1.cif_number=in2.cif_number ;quit;
/*******************************/
/*XU LY DU LIEU DONG TIEN*/
proc delete data =cashflow;run;

proc sql;
create table cashflow as select distinct
in1.cif_number,
in2.diff as Cash_in_thismonth,
in3.diff as Cash_in_lastmonth,
in4.diff as Cash_in_thisquarter,
in5.diff as Cash_in_lastquarter,
in6.diff as Cash_in_thisquarterlastyear,
in7.diff as Cash_in_6month,
in8.diff as Cash_out_thismonth,
in9.diff as Cash_out_lastmonth,
in10.diff as Cash_out_thisquarter,
in11.diff as Cash_out_lastquarter,
in12.diff as Cash_out_thisquarterlastyear,
in13.luykegocphaitra as Cum_principle_3m,
in14.luykegocphaitra as Cum_principle_6m
from &dskh_lc as in1 left join ews_lc.Ddmast_inthism as in2 on
in1.cif_number=in2.cif_number 
left join ews_lc.Ddmast_inlastm as in3 on
in1.cif_number=in3.cif_number
left join ews_lc.Ddmast_inthisq as in4 on
in1.cif_number=in4.cif_number
left join ews_lc.Ddmast_inlastq as in5 on
in1.cif_number=in5.cif_number
left join ews_lc.Ddmast_inthisq_lasty as in6 on
in1.cif_number=in6.cif_number
left join ews_lc.Ddmast_in6months as in7 on
in1.cif_number=in7.cif_number
left join ews_lc.Ddmast_outthism as in8 on
in1.cif_number=in8.cif_number
left join ews_lc.Ddmast_outlastm as in9 on
in1.cif_number=in9.cif_number
left join ews_lc.Ddmast_outthisq as in10 on
in1.cif_number=in10.cif_number
left join ews_lc.Ddmast_outlastq as in11 on
in1.cif_number=in11.cif_number
left join ews_lc.Ddmast_outthisq_lasty as in12 on
in1.cif_number=in12.cif_number
left join ews_lc.Gocphaitra_3months as in13 on
in1.cif_number=in13.cif_number
left join ews_lc.Gocphaitra_6months as in14 on
in1.cif_number=in14.cif_number;quit;

data cashflow;
set cashflow;
if Cash_in_thismonth=0 then Cash_in_thismonth=".";
if Cash_in_lastmonth=0 then Cash_in_lastmonth=".";
if Cash_in_thisquarter=0 then Cash_in_thisquarter=".";
if Cash_in_thisquarterlastyear=0 then Cash_in_thisquarterlastyear=".";
if Cash_in_6month=0 then Cash_in_6month=".";
if Cash_out_thismonth=0 then Cash_out_thismonth=".";
if Cash_out_lastmonth=0 then Cash_out_lastmonth=".";
if Cash_out_thisquarter=0 then Cash_out_thisquarter=".";
if Cash_out_lastquarter=0 then Cash_out_lastquarter=".";
if Cash_out_thisquarterlastyear=0 then Cash_out_thisquarterlastyear=".";run;

proc delete data =cashflow_question;run; 

data cashflow_question;
set cashflow;
if (Cash_in_thismonth NE "." and Cash_in_thismonth NE 0 and Cash_in_lastmonth EQ ".") then Thruput_1=1;
else Thruput_1=(Cash_in_thismonth-Cash_in_lastmonth)/Cash_in_lastmonth;
if (Cash_in_thisquarter NE "." and Cash_in_thisquarter NE 0 and Cash_in_lastquarter EQ ".") then Thruput_2=1;
else Thruput_2=(Cash_in_thisquarter-Cash_in_lastquarter)/Cash_in_lastquarter;
if (Cash_in_thisquarter NE "." and Cash_in_thisquarter NE 0 and Cash_in_thisquarterlastyear EQ ".") then Thruput_3=1;
else Thruput_3=(Cash_in_thisquarter-Cash_in_thisquarterlastyear)/Cash_in_thisquarterlastyear;
if (Cash_in_thisquarter NE "." and Cash_in_thisquarter NE 0 and Cum_principle_3m EQ ".") then Thruput_4=9999;
else Thruput_4=Cash_in_thisquarter/Cum_principle_3m;
if (Cash_in_6month NE "." and Cash_in_6month NE 0 and Cum_principle_6m EQ ".") then Thruput_5=9999;
else Thruput_5=Cash_in_6month/Cum_principle_6m;
run;
/**********************************/
/*DU LIEU HAN MUC SU DUNG*/
proc delete data =Utilization;run; 

proc sql;
create table Utilization as select distinct
in1.cif_number,
in2.Tong_HM_quydoi12,
in2.Tong_HM_quydoi11,
in2.Tong_HM_quydoi10,
in2.Tong_HM_quydoi09,
in2.Tong_HM_quydoi08,
in2.Tong_HM_quydoi07,
in2.Tong_HM_quydoi06,
in2.Tong_HM_quydoi05,
in2.Tong_HM_quydoi04,
in2.Tong_HM_quydoi03,
in2.Tong_HM_quydoi02,
in2.Tong_HM_quydoi01,
in3.avg_month12,
in3.avg_month11,
in3.avg_month10,
in3.avg_month09,
in3.avg_month08,
in3.avg_month07,
in3.avg_month06,
in3.avg_month05,
in3.avg_month04,
in3.avg_month03,
in3.avg_month02,
in3.avg_month01
from &dskh_lc as in1 left join ews_lc.HM as in2 on
in1.cif_number=in2.cifno 
left join ews_lc.Averagebalance as in3 on
in1.cif_number=in3.cifno;quit;

proc delete data =Utilization_question;run; 

data Utilization_question;
set Utilization;
if (Tong_HM_quydoi01 NE "." and Tong_HM_quydoi01 NE 0 and avg_month01 EQ 0)then Utliz_01=0;
else Utliz_01=avg_month01/Tong_HM_quydoi01;
if (Tong_HM_quydoi02 NE "." and Tong_HM_quydoi02 NE 0 and avg_month02 EQ 0)then Utliz_02=0;
else Utliz_02=avg_month02/Tong_HM_quydoi02;
if (Tong_HM_quydoi03 NE "." and Tong_HM_quydoi03 NE 0 and avg_month03 EQ 0)then Utliz_03=0;
else Utliz_03=avg_month03/Tong_HM_quydoi03;
if (Tong_HM_quydoi04 NE "." and Tong_HM_quydoi04 NE 0 and avg_month04 EQ 0)then Utliz_04=0;
else Utliz_04=avg_month04/Tong_HM_quydoi04;
if (Tong_HM_quydoi05 NE "." and Tong_HM_quydoi05 NE 0 and avg_month05 EQ 0)then Utliz_05=0;
else Utliz_05=avg_month05/Tong_HM_quydoi05;
if (Tong_HM_quydoi06 NE "." and Tong_HM_quydoi06 NE 0 and avg_month06 EQ 0)then Utliz_06=0;
else Utliz_06=avg_month06/Tong_HM_quydoi06;
if (Tong_HM_quydoi07 NE "." and Tong_HM_quydoi07 NE 0 and avg_month07 EQ 0)then Utliz_07=0;
else Utliz_07=avg_month07/Tong_HM_quydoi07;
if (Tong_HM_quydoi08 NE "." and Tong_HM_quydoi08 NE 0 and avg_month08 EQ 0)then Utliz_08=0;
else Utliz_08=avg_month08/Tong_HM_quydoi08;
if (Tong_HM_quydoi09 NE "." and Tong_HM_quydoi09 NE 0 and avg_month09 EQ 0)then Utliz_09=0;
else Utliz_09=avg_month09/Tong_HM_quydoi09;
if (Tong_HM_quydoi10 NE "." and Tong_HM_quydoi10 NE 0 and avg_month10 EQ 0)then Utliz_10=0;
else Utliz_10=avg_month10/Tong_HM_quydoi10;
if (Tong_HM_quydoi11 NE "." and Tong_HM_quydoi11 NE 0 and avg_month11 EQ 0)then Utliz_11=0;
else Utliz_11=avg_month11/Tong_HM_quydoi11;
if (Tong_HM_quydoi12 NE "." and Tong_HM_quydoi12 NE 0 and avg_month12 EQ 0)then Utliz_12=0;
else Utliz_12=avg_month12/Tong_HM_quydoi12;

if UtliZ_01="." then UtliZ_01=0;else UtliZ_01=UtliZ_01;
if UtliZ_02="." then UtliZ_02=0;else UtliZ_02=UtliZ_02;
if UtliZ_03="." then UtliZ_03=0;else UtliZ_03=UtliZ_03;
if UtliZ_04="." then UtliZ_04=0;else UtliZ_04=UtliZ_04;
if UtliZ_05="." then UtliZ_05=0;else UtliZ_05=UtliZ_05;
if UtliZ_06="." then UtliZ_06=0;else UtliZ_06=UtliZ_06;
if UtliZ_07="." then UtliZ_07=0;else UtliZ_07=UtliZ_07;
if UtliZ_08="." then UtliZ_08=0;else UtliZ_08=UtliZ_08;
if UtliZ_09="." then UtliZ_09=0;else UtliZ_09=UtliZ_09;
if UtliZ_10="." then UtliZ_10=0;else UtliZ_10=UtliZ_10;
if UtliZ_11="." then UtliZ_11=0;else UtliZ_11=UtliZ_11;
if UtliZ_12="." then UtliZ_12=0;else UtliZ_12=UtliZ_12;

if UtliZ_12 =0 then Utliz_12_id=0; else Utliz_12_id=1;
if UtliZ_11 =0 then Utliz_11_id=0; else Utliz_11_id=1;
if UtliZ_10 =0 then Utliz_10_id=0; else Utliz_10_id=1;
if UtliZ_09 =0 then Utliz_09_id=0; else Utliz_09_id=1;
if UtliZ_08 =0 then Utliz_08_id=0; else Utliz_08_id=1;
if UtliZ_07 =0 then Utliz_07_id=0; else Utliz_07_id=1;
if UtliZ_06 =0 then Utliz_06_id=0; else Utliz_06_id=1;
if UtliZ_05 =0 then Utliz_05_id=0; else Utliz_05_id=1;
if UtliZ_04 =0 then Utliz_04_id=0; else Utliz_04_id=1;
if UtliZ_03 =0 then Utliz_03_id=0; else Utliz_03_id=1;
if UtliZ_02 =0 then Utliz_02_id=0; else Utliz_02_id=1;
if UtliZ_01 =0 then Utliz_01_id=0; else Utliz_01_id=1;

if UtliZ_12 >=0.65 then Utliz_12_09=1; else Utliz_12_09=0;
if UtliZ_11 >=0.65 then Utliz_11_09=1; else Utliz_11_09=0;
if UtliZ_10 >=0.65 then Utliz_10_09=1; else Utliz_10_09=0;
if UtliZ_09 >=0.65 then Utliz_09_09=1; else Utliz_09_09=0;
if UtliZ_08 >=0.65 then Utliz_08_09=1; else Utliz_08_09=0;
if UtliZ_07 >=0.65 then Utliz_07_09=1; else Utliz_07_09=0;
if UtliZ_06 >=0.65 then Utliz_06_09=1; else Utliz_06_09=0;
if UtliZ_05 >=0.65 then Utliz_05_09=1; else Utliz_05_09=0;
if UtliZ_04 >=0.65 then Utliz_04_09=1; else Utliz_04_09=0;
if UtliZ_03 >=0.65 then Utliz_03_09=1; else Utliz_03_09=0;
if UtliZ_02 >=0.65 then Utliz_02_09=1; else Utliz_02_09=0;
if UtliZ_01 >=0.65 then Utliz_01_09=1; else Utliz_01_09=0;

if Utliz_02 <= 0.4 then Utiliz_1=(Utliz_01-Utliz_02)/Utliz_02;else Utiliz_1=".";
if Utliz_02 >= 0.6 then Utiliz_2=(Utliz_01-Utliz_02)/Utliz_02;else Utiliz_2=".";

Check1=Utliz_01_id+Utliz_02_id+Utliz_03_id;
Check2=Utliz_04_id+Utliz_05_id+Utliz_06_id;
Check3=(Utliz_01+ Utliz_02+ Utliz_03)/check1;
Check4=(Utliz_04+ Utliz_05+ Utliz_06)/check2;

if (check4<=0.4 and check1=0 and check2>0)then Utiliz3_1=-1;else Utiliz3_1=0;
if (check4<=0.4  and check2>0) then Utiliz3_2=(check3-check4)/check4;else Utiliz3_2=".";
if Utiliz3_1=-1 then Utiliz_3=-1; else Utiliz_3=Utiliz3_2;

if (check4>=0.6 and check1=0 and check2>0)then Utiliz3_1=-1;else Utiliz3_1=0;
if (check4>=0.6  and check2>0) then Utiliz3_2=(check3-check4)/check4;else Utiliz3_2=".";
if Utiliz4_1=-1 then Utiliz_4=-1; else Utiliz_4=Utiliz4_2;

Utiliz_5=sum(Utliz_01_09,Utliz_02_09,Utliz_03_09);
Utiliz_6=sum(Utliz_01_09,Utliz_02_09,Utliz_03_09,Utliz_04_09,Utliz_05_09,Utliz_06_09);
Utiliz_7=sum(Utliz_01_09,Utliz_02_09,Utliz_03_09,Utliz_04_09,Utliz_05_09,Utliz_06_09,Utliz_07_09,Utliz_08_09,Utliz_09_09,Utliz_10_09,Utliz_11_09,Utliz_12_09);
run;
/*******************************/
/*DU LIEU QUAN HAN PDP*/
/*proc delete data =Historical_dpd;run; */

proc sql;
create table Historical_dpd as select distinct
in1.cif_number,
in2.count_duedate as dpd_1m_26days,
in3.count_duedate as dpd_1m_7days,
in4.count_duedate as dpd_3m_26days,
in5.count_duedate as dpd_3m_7days,
in6.count_duedate as dpd_6m_26days,
in7.count_duedate as dpd_6m_7days,
in8.count_duedate as dpd_9m_26days,
in9.count_duedate as dpd_9m_7days,
in10.count_duedate as dpd_12m_26days,
in11.count_duedate as dpd_12m_7days
from &dskh_lc as in1 left join ews_lc.Quahan_1m_26 as in2 on
in1.cif_number=in2.cifno 
left join ews_lc.Quahan_1m_7 as in3 on
in1.cif_number=in3.cifno
left join ews_lc.Quahan_3m_26 as in4 on
in1.cif_number=in4.cifno
left join ews_lc.Quahan_3m_7 as in5 on
in1.cif_number=in5.cifno
left join ews_lc.Quahan_6m_26 as in6 on
in1.cif_number=in6.cifno
left join ews_lc.Quahan_6m_7 as in7 on
in1.cif_number=in7.cifno
left join ews_lc.Quahan_9m_26 as in8 on
in1.cif_number=in8.cifno
left join ews_lc.Quahan_9m_7 as in9 on
in1.cif_number=in9.cifno
left join ews_lc.Quahan_12m_26 as in10 on
in1.cif_number=in10.cifno
left join ews_lc.Quahan_12m_7 as in11 on
in1.cif_number=in11.cifno;quit;
/***************************************/
/*DU LIEU CAU 21 THEO 3 CACH*/
data ews_lc.cashflow_in;
set ews_lc.cashflow_in;
rename diff=cashflow_in;
if cashflow_in =0 then cashflow_in=".";run;

proc sort data=ews_lc.cashflow_in;
by cif_number date;run;

data ews_lc.cashflow_out;
set ews_lc.cashflow_out;
rename diff=cashflow_out;
if cashflow_out=0 then cashflow_out=".";run;

proc sort data=ews_lc.cashflow_out;
by cif_number date;run;

data cash_in_out_day_1;
merge ews_lc.cashflow_in ews_lc.cashflow_out;
by cif_number date;run;

data cash_in_out_day_1;
set cash_in_out_day_1;
if (cashflow_in EQ "." and cashflow_out EQ".") then delete;run;

data cash_in_out_day_1;
set cash_in_out_day_1;
if(cashflow_in EQ "." and Cashflow_out >0)then ratio_daily=1; 
else if( cashflow_in >0 and cashflow_out EQ ".")then ratio_daily=0;
else if (cashflow_in>0 and cashflow_out<0 )then ratio_daily=0; 
else if (cashflow_in >0 and cashflow_out >0) then ratio_daily=cashflow_out/cashflow_in;
if ratio_daily>=0.9 then ratio_daily_id=1; else ratio_daily_id=0;run;

proc delete data=ews_lc.cash_in_out_day;run;

proc sql;
create table ews_lc.cash_in_out_day as select distinct
cif_number,
mean(ratio_daily) as ratio_out_in_daily,
sum(ratio_daily_id) as sum,
count(cif_number) as total
from cash_in_out_day_1
group by cif_number;quit;

data ews_lc.cash_in_out_day;set ews_lc.cash_in_out_day;
num_pass_09=sum/total;run;

proc delete data=ews_lc.cash_in_out_month;run;

data ews_lc.cash_in_out_month;
set cashflow;
keep cif_number Cash_in_thismonth Cash_out_thismonth;

data ews_lc.cash_in_out_month;set ews_lc.cash_in_out_month;
if(Cash_in_thismonth EQ "." and Cash_out_thismonth>0)then ratio_out_in_month=1; 
else if( Cash_in_thismonth >0 and Cash_out_thismonth EQ ".")then ratio_out_in_month=0;
else if (Cash_in_thismonth>0 and Cash_out_thismonth<0 )then ratio_out_in_month=0; 
else if (Cash_in_thismonth >0 and Cash_out_thismonth>0) then ratio_out_in_month=Cash_out_thismonth/Cash_in_thismonth;
run;

/********************************************/
/*************TONG KET***********************/
/********************************************/
proc delete data=ews_lc.LC_tonghop;run;

proc sql;
create table ews_lc.LC_tonghop as select distinct
in1.*,
in2.Thruput_1,
in2.Thruput_2,
in2.Thruput_3,
in2.Thruput_4,
in2.Thruput_5,
in3.Utiliz_1,
in3.Utiliz_2,
in3.Utiliz_3,
in3.Utiliz_4,
in3.Utiliz_5,
in3.Utiliz_6,
in3.Utiliz_7,
in4.dpd_1m_26days as Hist_1,
in4.dpd_1m_7days as Hist_2,
in4.dpd_3m_26days as Hist_3,
in4.dpd_3m_7days as Hist_4,
in4.dpd_6m_26days as Hist_5,
in4.dpd_6m_7days as Hist_6,
in4.dpd_12m_26days as Hist_7,
in4.dpd_12m_7days as Hist_8,
in5.ratio_out_in_daily,
in5.num_pass_09,
in6.ratio_out_in_month
from Lc_cust_inf as in1 left join Cashflow_question as in2 on
in1.cif_number=in2.cif_number
left join utilization_question as in3 on
in1.cif_number=in3.cif_number
left join Historical_dpd as in4 on
in1.cif_number=in4.cif_number
left join ews_lc.cash_in_out_day as in5 on
in1.cif_number=in5.cif_number
left join ews_lc.cash_in_out_month as in6 on
in1.cif_number=in6.cif_number;quit;

%mend;




/* ===================================================================================================================*/
/* ===================================================================================================================*/
/* ===================================================================================================================*/
/**************** DANH SACH KHACH HANG******************/


%DSKH(ews_lc.DSKH_lc_28022017,'2017-02-28',MDY(02,28,2017));
 
%THRUPUT('2017-02-01','2017-02-28',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_INTHISM );
%THRUPUT('2017-01-01','2017-01-31',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_INLASTM );
%THRUPUT('2016-12-01','2017-02-28',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_INTHISQ );
%THRUPUT('2016-09-01','2016-11-30',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_INLASTQ );
%THRUPUT('2015-12-01','2016-02-28',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_INTHISQ_LASTY );
%THRUPUT('2016-09-01','2017-02-28',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_IN6months);
 
%OUTPUT('2017-02-01','2017-02-28',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_OUTTHISM );
%OUTPUT('2017-01-01','2017-01-31',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_OUTLASTM );
%OUTPUT('2016-12-01','2017-02-28',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_OUTTHISQ );
%OUTPUT('2016-09-01','2016-11-30',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_OUTLASTQ );
%OUTPUT('2015-12-01','2016-02-28',ews_lc.DSKH_lc_28022017, ews_lc.DDMAST_OUTTHISQ_LASTY );
 
%export_ssfxrt(ews_lc.ssfxrt,'2016-02-28' , '2017-02-28');

%export_lnmast(ews_lc.lnmast_01, '2017-02-01', '2017-02-28', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_02, '2017-01-01', '2017-01-31', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_03, '2016-12-01', '2016-12-31', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_04, '2016-11-01', '2016-11-30', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_05, '2016-10-01', '2016-10-31', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_06, '2016-09-01', '2016-09-30', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_07, '2016-08-01', '2016-08-31', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_08, '2016-07-01', '2016-07-31', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_09, '2016-06-01', '2016-06-30', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_10, '2016-05-01', '2016-05-31', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_11, '2016-04-01', '2016-04-30', ews_lc.DSKH_lc_28022017);
%export_lnmast(ews_lc.lnmast_12, '2016-03-01', '2016-03-31', ews_lc.DSKH_lc_28022017);

%export_lnappf(ews_lc.lnappf_01,  '2017-02-28', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_02,  '2017-01-31', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_03,  '2016-12-31', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_04,  '2016-11-30', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_05,  '2016-10-31', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_06,  '2016-09-30', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_07,  '2016-08-31', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_08,  '2016-07-31', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_09,  '2016-06-30', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_10,  '2016-05-31', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_11,  '2016-04-30', ews_lc.DSKH_lc_28022017);
%export_lnappf(ews_lc.lnappf_12,  '2016-03-31', ews_lc.DSKH_lc_28022017);

%avgbalance(ews_lc.lnmast_01,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_01,28,ews_lc.LNMAST_LNAPPF_q_211R_01,ews_lc.Lnmast_avg_01,avg_month01);
%avgbalance(ews_lc.lnmast_02,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_02,31,ews_lc.LNMAST_LNAPPF_q_211R_02,ews_lc.Lnmast_avg_02,avg_month02);
%avgbalance(ews_lc.lnmast_03,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_03,31,ews_lc.LNMAST_LNAPPF_q_211R_03,ews_lc.Lnmast_avg_03,avg_month03);
%avgbalance(ews_lc.lnmast_04,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_04,30,ews_lc.LNMAST_LNAPPF_q_211R_04,ews_lc.Lnmast_avg_04,avg_month04);
%avgbalance(ews_lc.lnmast_05,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_05,31,ews_lc.LNMAST_LNAPPF_q_211R_05,ews_lc.Lnmast_avg_05,avg_month05);
%avgbalance(ews_lc.lnmast_06,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_06,30,ews_lc.LNMAST_LNAPPF_q_211R_06,ews_lc.Lnmast_avg_06,avg_month06);
%avgbalance(ews_lc.lnmast_07,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_07,31,ews_lc.LNMAST_LNAPPF_q_211R_07,ews_lc.Lnmast_avg_07,avg_month07);
%avgbalance(ews_lc.lnmast_08,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_08,31,ews_lc.LNMAST_LNAPPF_q_211R_08,ews_lc.Lnmast_avg_08,avg_month08);
%avgbalance(ews_lc.lnmast_09,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_09,30,ews_lc.LNMAST_LNAPPF_q_211R_09,ews_lc.Lnmast_avg_09,avg_month09);
%avgbalance(ews_lc.lnmast_10,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_10,31,ews_lc.LNMAST_LNAPPF_q_211R_10,ews_lc.Lnmast_avg_10,avg_month10);
%avgbalance(ews_lc.lnmast_11,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_11,30,ews_lc.LNMAST_LNAPPF_q_211R_11,ews_lc.Lnmast_avg_11,avg_month11);
%avgbalance(ews_lc.lnmast_12,ews_lc.DSKH_lc_28022017,ews_lc.lnappf_12,31,ews_lc.LNMAST_LNAPPF_q_211R_12,ews_lc.Lnmast_avg_12,avg_month12);

%HM(ews_lc.lnappf_01,ews_lc.LNMAST_LNAPPF_q_211R_01,MDY(2,28,2017), Tong_HM_quydoi01,ews_lc.HMSD_01);
%HM(ews_lc.lnappf_02,ews_lc.LNMAST_LNAPPF_q_211R_02,MDY(1,31,2017), Tong_HM_quydoi02,ews_lc.HMSD_02);
%HM(ews_lc.lnappf_03,ews_lc.LNMAST_LNAPPF_q_211R_03,MDY(12,31,2016), Tong_HM_quydoi03,ews_lc.HMSD_03);
%HM(ews_lc.lnappf_04,ews_lc.LNMAST_LNAPPF_q_211R_04,MDY(11,30,2016), Tong_HM_quydoi04,ews_lc.HMSD_04);
%HM(ews_lc.lnappf_05,ews_lc.LNMAST_LNAPPF_q_211R_05,MDY(10,31,2016), Tong_HM_quydoi05,ews_lc.HMSD_05);
%HM(ews_lc.lnappf_06,ews_lc.LNMAST_LNAPPF_q_211R_06,MDY(9,30,2016), Tong_HM_quydoi06,ews_lc.HMSD_06);
%HM(ews_lc.lnappf_07,ews_lc.LNMAST_LNAPPF_q_211R_07,MDY(8,31,2016), Tong_HM_quydoi07,ews_lc.HMSD_07);
%HM(ews_lc.lnappf_08,ews_lc.LNMAST_LNAPPF_q_211R_08,MDY(7,31,2016), Tong_HM_quydoi08,ews_lc.HMSD_08);
%HM(ews_lc.lnappf_09,ews_lc.LNMAST_LNAPPF_q_211R_09,MDY(6,30,2016), Tong_HM_quydoi09,ews_lc.HMSD_09);
%HM(ews_lc.lnappf_10,ews_lc.LNMAST_LNAPPF_q_211R_10,MDY(5,31,2016), Tong_HM_quydoi10,ews_lc.HMSD_10);
%HM(ews_lc.lnappf_11,ews_lc.LNMAST_LNAPPF_q_211R_11,MDY(4,30,2016), Tong_HM_quydoi11,ews_lc.HMSD_11);
%HM(ews_lc.lnappf_12,ews_lc.LNMAST_LNAPPF_q_211R_12,MDY(3,31,2016), Tong_HM_quydoi12,ews_lc.HMSD_12);

proc delete data = ews_lc.Averagebalance; run;
Data ews_lc.Averagebalance;
set ews_lc.Lnmast_avg_01;run;

%tonghop_cbal(ews_lc.lnmast_avg_01);
%tonghop_cbal(ews_lc.lnmast_avg_02);
%tonghop_cbal(ews_lc.lnmast_avg_03);
%tonghop_cbal(ews_lc.lnmast_avg_04);
%tonghop_cbal(ews_lc.lnmast_avg_05);
%tonghop_cbal(ews_lc.lnmast_avg_06);
%tonghop_cbal(ews_lc.lnmast_avg_07);
%tonghop_cbal(ews_lc.lnmast_avg_08);
%tonghop_cbal(ews_lc.lnmast_avg_09);
%tonghop_cbal(ews_lc.lnmast_avg_10);
%tonghop_cbal(ews_lc.lnmast_avg_11);
%tonghop_cbal(ews_lc.lnmast_avg_12);

proc delete data=ews_lc.HM;run;
Data ews_lc.HM;
set ews_lc.HMSD_01;run;

%tonghop_HM(ews_lc.HMSD_01);
%tonghop_HM(ews_lc.HMSD_02);
%tonghop_HM(ews_lc.HMSD_03);
%tonghop_HM(ews_lc.HMSD_04);
%tonghop_HM(ews_lc.HMSD_05);
%tonghop_HM(ews_lc.HMSD_06);
%tonghop_HM(ews_lc.HMSD_07);
%tonghop_HM(ews_lc.HMSD_08);
%tonghop_HM(ews_lc.HMSD_09);
%tonghop_HM(ews_lc.HMSD_10);
%tonghop_HM(ews_lc.HMSD_11);
%tonghop_HM(ews_lc.HMSD_12);

%dpd_ip(ews_lc.DSKH_lc_28022017, ews_lc.quahangoc_28022017_1M,ews_lc.quahanlai_28022017_1M,'2017-02-01','2017-02-28');
%dpd_ip(ews_lc.DSKH_lc_28022017, ews_lc.quahangoc_28022017_3M,ews_lc.quahanlai_28022017_1M,'2016-12-01','2017-02-28');
%dpd_ip(ews_lc.DSKH_lc_28022017, ews_lc.quahangoc_28022017_6M,ews_lc.quahanlai_28022017_1M,'2016-09-01','2017-02-28');
%dpd_ip(ews_lc.DSKH_lc_28022017, ews_lc.quahangoc_28022017_9M,ews_lc.quahanlai_28022017_1M,'2016-06-01','2017-02-28');
%dpd_ip(ews_lc.DSKH_lc_28022017, ews_lc.quahangoc_28022017_12M,ews_lc.quahanlai_28022017_1M,'2016-03-01','2017-02-28');

%input2(ews_lc.quahangoc_28022017_1M,ews_lc.quahanlai_28022017_1M,ews_lc.quahan_28022017_1M);
%input2(ews_lc.quahangoc_28022017_3M,ews_lc.quahanlai_28022017_3M,ews_lc.quahan_28022017_3M);
%input2(ews_lc.quahangoc_28022017_6M,ews_lc.quahanlai_28022017_6M,ews_lc.quahan_28022017_6M);
%input2(ews_lc.quahangoc_28022017_9M,ews_lc.quahanlai_28022017_9M,ews_lc.quahan_28022017_9M);
%input2(ews_lc.quahangoc_28022017_12M,ews_lc.quahanlai_28022017_12M,ews_lc.quahan_28022017_12M);

%process_dpd(ews_lc.quahan_28022017_1M,ews_lc.quahan_1M_26,ews_lc.quahan_1M_7);
%process_dpd(ews_lc.quahan_28022017_3M,ews_lc.quahan_3M_26,ews_lc.quahan_3M_7);
%process_dpd(ews_lc.quahan_28022017_6M,ews_lc.quahan_6M_26,ews_lc.quahan_6M_7);
%process_dpd(ews_lc.quahan_28022017_9M,ews_lc.quahan_9M_26,ews_lc.quahan_9M_7);
%process_dpd(ews_lc.quahan_28022017_12M,ews_lc.quahan_12M_26,ews_lc.quahan_12M_7);

%cum_gocphaitra('2016-12-01','2017-02-28',3,ews_lc.DSKH_lc_28022017,ews_lc.gocphaitra_3months);
%cum_gocphaitra('2016-09-01','2017-02-28',6,ews_lc.DSKH_lc_28022017,ews_lc.gocphaitra_6months);

%THRUPUT('2017-02-28','2017-02-28', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_28);
%THRUPUT('2017-02-27','2017-02-27', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_27);
%THRUPUT('2017-02-26','2017-02-26', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_26);
%THRUPUT('2017-02-25','2017-02-25', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_25);
%THRUPUT('2017-02-24','2017-02-24', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_24);
%THRUPUT('2017-02-23','2017-02-23', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_23);
%THRUPUT('2017-02-22','2017-02-22', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_22);
%THRUPUT('2017-02-21','2017-02-21', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_21);
%THRUPUT('2017-02-20','2017-02-20', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_20);
%THRUPUT('2017-02-19','2017-02-19', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_19);
%THRUPUT('2017-02-18','2017-02-18', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_18);
%THRUPUT('2017-02-17','2017-02-17', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_17);
%THRUPUT('2017-02-16','2017-02-16', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_16);
%THRUPUT('2017-02-15','2017-02-15', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_15);
%THRUPUT('2017-02-14','2017-02-14', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_14);
%THRUPUT('2017-02-13','2017-02-13', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_13);
%THRUPUT('2017-02-12','2017-02-12', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_12);
%THRUPUT('2017-02-11','2017-02-11', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_11);
%THRUPUT('2017-02-10','2017-02-10', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_10);
%THRUPUT('2017-02-09','2017-02-09', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_09);
%THRUPUT('2017-02-08','2017-02-08', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_08);
%THRUPUT('2017-02-07','2017-02-07', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_07);
%THRUPUT('2017-02-06','2017-02-06', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_06);
%THRUPUT('2017-02-05','2017-02-05', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_05);
%THRUPUT('2017-02-04','2017-02-04', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_04);
%THRUPUT('2017-02-03','2017-02-03', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_03);
%THRUPUT('2017-02-02','2017-02-02', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_02);
%THRUPUT('2017-02-01','2017-02-01', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_02_01);
%THRUPUT('2017-01-31','2017-01-31', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_01_31);
%THRUPUT('2017-01-30','2017-01-30', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_01_30);
%THRUPUT('2017-01-29','2017-01-29', ews_lc.DSKH_lc_28022017,ews_lc.cfin_2017_01_29);

%xulyfile( ews_lc.cfin_2017_02_28,ews_lc.cfin_2017_02_28_1, '2017-02-28');
%xulyfile( ews_lc.cfin_2017_02_27,ews_lc.cfin_2017_02_27_1, '2017-02-27');
%xulyfile( ews_lc.cfin_2017_02_26,ews_lc.cfin_2017_02_26_1, '2017-02-26');
%xulyfile( ews_lc.cfin_2017_02_25,ews_lc.cfin_2017_02_25_1, '2017-02-25');
%xulyfile( ews_lc.cfin_2017_02_24,ews_lc.cfin_2017_02_24_1, '2017-02-24');
%xulyfile( ews_lc.cfin_2017_02_23,ews_lc.cfin_2017_02_23_1, '2017-02-23');
%xulyfile( ews_lc.cfin_2017_02_22,ews_lc.cfin_2017_02_22_1, '2017-02-22');
%xulyfile( ews_lc.cfin_2017_02_21,ews_lc.cfin_2017_02_21_1, '2017-02-21');
%xulyfile( ews_lc.cfin_2017_02_20,ews_lc.cfin_2017_02_20_1, '2017-02-20');
%xulyfile( ews_lc.cfin_2017_02_19,ews_lc.cfin_2017_02_19_1, '2017-02-19');
%xulyfile( ews_lc.cfin_2017_02_18,ews_lc.cfin_2017_02_18_1, '2017-02-18');
%xulyfile( ews_lc.cfin_2017_02_17,ews_lc.cfin_2017_02_17_1, '2017-02-17');
%xulyfile( ews_lc.cfin_2017_02_16,ews_lc.cfin_2017_02_16_1, '2017-02-16');
%xulyfile( ews_lc.cfin_2017_02_15,ews_lc.cfin_2017_02_15_1, '2017-02-15');
%xulyfile( ews_lc.cfin_2017_02_14,ews_lc.cfin_2017_02_14_1, '2017-02-14');
%xulyfile( ews_lc.cfin_2017_02_13,ews_lc.cfin_2017_02_13_1, '2017-02-13');
%xulyfile( ews_lc.cfin_2017_02_12,ews_lc.cfin_2017_02_12_1, '2017-02-12');
%xulyfile( ews_lc.cfin_2017_02_11,ews_lc.cfin_2017_02_11_1, '2017-02-11');
%xulyfile( ews_lc.cfin_2017_02_10,ews_lc.cfin_2017_02_10_1, '2017-02-10');
%xulyfile( ews_lc.cfin_2017_02_09,ews_lc.cfin_2017_02_09_1, '2017-02-09');
%xulyfile( ews_lc.cfin_2017_02_08,ews_lc.cfin_2017_02_08_1, '2017-02-08');
%xulyfile( ews_lc.cfin_2017_02_07,ews_lc.cfin_2017_02_07_1, '2017-02-07');
%xulyfile( ews_lc.cfin_2017_02_06,ews_lc.cfin_2017_02_06_1, '2017-02-06');
%xulyfile( ews_lc.cfin_2017_02_05,ews_lc.cfin_2017_02_05_1, '2017-02-05');
%xulyfile( ews_lc.cfin_2017_02_04,ews_lc.cfin_2017_02_04_1, '2017-02-04');
%xulyfile( ews_lc.cfin_2017_02_03,ews_lc.cfin_2017_02_03_1, '2017-02-03');
%xulyfile( ews_lc.cfin_2017_02_02,ews_lc.cfin_2017_02_02_1, '2017-02-02');
%xulyfile( ews_lc.cfin_2017_02_01,ews_lc.cfin_2017_02_01_1, '2017-02-01');
%xulyfile( ews_lc.cfin_2017_01_31,ews_lc.cfin_2017_01_31_1, '2017-01-31');
%xulyfile( ews_lc.cfin_2017_01_30,ews_lc.cfin_2017_01_30_1, '2017-01-30');
%xulyfile( ews_lc.cfin_2017_01_29,ews_lc.cfin_2017_01_29_1, '2017-01-29');

proc delete data=ews_lc.cashflow_in;run;
data ews_lc.cashflow_in;
set ews_lc.cfin_2014_09_01_1;run;
proc delete data=ews_lc.cfin_2014_09_01_1;run;

%cashflow_in(ews_lc.cfin_2017_02_28_1);
%cashflow_in(ews_lc.cfin_2017_02_27_1);
%cashflow_in(ews_lc.cfin_2017_02_26_1);
%cashflow_in(ews_lc.cfin_2017_02_25_1);
%cashflow_in(ews_lc.cfin_2017_02_24_1);
%cashflow_in(ews_lc.cfin_2017_02_23_1);
%cashflow_in(ews_lc.cfin_2017_02_22_1);
%cashflow_in(ews_lc.cfin_2017_02_21_1);
%cashflow_in(ews_lc.cfin_2017_02_20_1);
%cashflow_in(ews_lc.cfin_2017_02_19_1);
%cashflow_in(ews_lc.cfin_2017_02_18_1);
%cashflow_in(ews_lc.cfin_2017_02_17_1);
%cashflow_in(ews_lc.cfin_2017_02_16_1);
%cashflow_in(ews_lc.cfin_2017_02_15_1);
%cashflow_in(ews_lc.cfin_2017_02_14_1);
%cashflow_in(ews_lc.cfin_2017_02_13_1);
%cashflow_in(ews_lc.cfin_2017_02_12_1);
%cashflow_in(ews_lc.cfin_2017_02_11_1);
%cashflow_in(ews_lc.cfin_2017_02_10_1);
%cashflow_in(ews_lc.cfin_2017_02_09_1);
%cashflow_in(ews_lc.cfin_2017_02_08_1);
%cashflow_in(ews_lc.cfin_2017_02_07_1);
%cashflow_in(ews_lc.cfin_2017_02_06_1);
%cashflow_in(ews_lc.cfin_2017_02_05_1);
%cashflow_in(ews_lc.cfin_2017_02_04_1);
%cashflow_in(ews_lc.cfin_2017_02_03_1);
%cashflow_in(ews_lc.cfin_2017_02_02_1);
%cashflow_in(ews_lc.cfin_2017_02_01_1);
%cashflow_in(ews_lc.cfin_2017_01_31_1);
%cashflow_in(ews_lc.cfin_2017_01_30_1);
%cashflow_in(ews_lc.cfin_2017_01_29_1);

%OUTPUT('2017-02-28','2017-02-28', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_28);
%OUTPUT('2017-02-27','2017-02-27', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_27);
%OUTPUT('2017-02-26','2017-02-26', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_26);
%OUTPUT('2017-02-25','2017-02-25', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_25);
%OUTPUT('2017-02-24','2017-02-24', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_24);
%OUTPUT('2017-02-23','2017-02-23', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_23);
%OUTPUT('2017-02-22','2017-02-22', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_22);
%OUTPUT('2017-02-21','2017-02-21', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_21);
%OUTPUT('2017-02-20','2017-02-20', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_20);
%OUTPUT('2017-02-19','2017-02-19', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_19);
%OUTPUT('2017-02-18','2017-02-18', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_18);
%OUTPUT('2017-02-17','2017-02-17', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_17);
%OUTPUT('2017-02-16','2017-02-16', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_16);
%OUTPUT('2017-02-15','2017-02-15', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_15);
%OUTPUT('2017-02-14','2017-02-14', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_14);
%OUTPUT('2017-02-13','2017-02-13', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_13);
%OUTPUT('2017-02-12','2017-02-12', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_12);
%OUTPUT('2017-02-11','2017-02-11', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_11);
%OUTPUT('2017-02-10','2017-02-10', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_10);
%OUTPUT('2017-02-09','2017-02-09', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_09);
%OUTPUT('2017-02-08','2017-02-08', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_08);
%OUTPUT('2017-02-07','2017-02-07', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_07);
%OUTPUT('2017-02-06','2017-02-06', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_06);
%OUTPUT('2017-02-05','2017-02-05', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_05);
%OUTPUT('2017-02-04','2017-02-04', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_04);
%OUTPUT('2017-02-03','2017-02-03', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_03);
%OUTPUT('2017-02-02','2017-02-02', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_02);
%OUTPUT('2017-02-01','2017-02-01', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_02_01);
%OUTPUT('2017-01-31','2017-01-31', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_01_31);
%OUTPUT('2017-01-30','2017-01-30', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_01_30);
%OUTPUT('2017-01-29','2017-01-29', ews_lc.DSKH_lc_28022017,ews_lc.cfout_2017_01_29);

%xulyfile( ews_lc.cfout_2017_02_28,ews_lc.cfout_2017_02_28_1, '2017-02-28');
%xulyfile( ews_lc.cfout_2017_02_27,ews_lc.cfout_2017_02_27_1, '2017-02-27');
%xulyfile( ews_lc.cfout_2017_02_26,ews_lc.cfout_2017_02_26_1, '2017-02-26');
%xulyfile( ews_lc.cfout_2017_02_25,ews_lc.cfout_2017_02_25_1, '2017-02-25');
%xulyfile( ews_lc.cfout_2017_02_24,ews_lc.cfout_2017_02_24_1, '2017-02-24');
%xulyfile( ews_lc.cfout_2017_02_23,ews_lc.cfout_2017_02_23_1, '2017-02-23');
%xulyfile( ews_lc.cfout_2017_02_22,ews_lc.cfout_2017_02_22_1, '2017-02-22');
%xulyfile( ews_lc.cfout_2017_02_21,ews_lc.cfout_2017_02_21_1, '2017-02-21');
%xulyfile( ews_lc.cfout_2017_02_20,ews_lc.cfout_2017_02_20_1, '2017-02-20');
%xulyfile( ews_lc.cfout_2017_02_19,ews_lc.cfout_2017_02_19_1, '2017-02-19');
%xulyfile( ews_lc.cfout_2017_02_18,ews_lc.cfout_2017_02_18_1, '2017-02-18');
%xulyfile( ews_lc.cfout_2017_02_17,ews_lc.cfout_2017_02_17_1, '2017-02-17');
%xulyfile( ews_lc.cfout_2017_02_16,ews_lc.cfout_2017_02_16_1, '2017-02-16');
%xulyfile( ews_lc.cfout_2017_02_15,ews_lc.cfout_2017_02_15_1, '2017-02-15');
%xulyfile( ews_lc.cfout_2017_02_14,ews_lc.cfout_2017_02_14_1, '2017-02-14');
%xulyfile( ews_lc.cfout_2017_02_13,ews_lc.cfout_2017_02_13_1, '2017-02-13');
%xulyfile( ews_lc.cfout_2017_02_12,ews_lc.cfout_2017_02_12_1, '2017-02-12');
%xulyfile( ews_lc.cfout_2017_02_11,ews_lc.cfout_2017_02_11_1, '2017-02-11');
%xulyfile( ews_lc.cfout_2017_02_10,ews_lc.cfout_2017_02_10_1, '2017-02-10');
%xulyfile( ews_lc.cfout_2017_02_09,ews_lc.cfout_2017_02_09_1, '2017-02-09');
%xulyfile( ews_lc.cfout_2017_02_08,ews_lc.cfout_2017_02_08_1, '2017-02-08');
%xulyfile( ews_lc.cfout_2017_02_07,ews_lc.cfout_2017_02_07_1, '2017-02-07');
%xulyfile( ews_lc.cfout_2017_02_06,ews_lc.cfout_2017_02_06_1, '2017-02-06');
%xulyfile( ews_lc.cfout_2017_02_05,ews_lc.cfout_2017_02_05_1, '2017-02-05');
%xulyfile( ews_lc.cfout_2017_02_04,ews_lc.cfout_2017_02_04_1, '2017-02-04');
%xulyfile( ews_lc.cfout_2017_02_03,ews_lc.cfout_2017_02_03_1, '2017-02-03');
%xulyfile( ews_lc.cfout_2017_02_02,ews_lc.cfout_2017_02_02_1, '2017-02-02');
%xulyfile( ews_lc.cfout_2017_02_01,ews_lc.cfout_2017_02_01_1, '2017-02-01');
%xulyfile( ews_lc.cfout_2017_01_31,ews_lc.cfout_2017_01_31_1, '2017-01-31');
%xulyfile( ews_lc.cfout_2017_01_30,ews_lc.cfout_2017_01_30_1, '2017-01-30');
%xulyfile( ews_lc.cfout_2017_01_29,ews_lc.cfout_2017_01_29_1, '2017-01-29');

%cashflow_out(ews_lc.cfout_2017_02_28_1);
%cashflow_out(ews_lc.cfout_2017_02_27_1);
%cashflow_out(ews_lc.cfout_2017_02_26_1);
%cashflow_out(ews_lc.cfout_2017_02_25_1);
%cashflow_out(ews_lc.cfout_2017_02_24_1);
%cashflow_out(ews_lc.cfout_2017_02_23_1);
%cashflow_out(ews_lc.cfout_2017_02_22_1);
%cashflow_out(ews_lc.cfout_2017_02_21_1);
%cashflow_out(ews_lc.cfout_2017_02_20_1);
%cashflow_out(ews_lc.cfout_2017_02_19_1);
%cashflow_out(ews_lc.cfout_2017_02_18_1);
%cashflow_out(ews_lc.cfout_2017_02_17_1);
%cashflow_out(ews_lc.cfout_2017_02_16_1);
%cashflow_out(ews_lc.cfout_2017_02_15_1);
%cashflow_out(ews_lc.cfout_2017_02_14_1);
%cashflow_out(ews_lc.cfout_2017_02_13_1);
%cashflow_out(ews_lc.cfout_2017_02_12_1);
%cashflow_out(ews_lc.cfout_2017_02_11_1);
%cashflow_out(ews_lc.cfout_2017_02_10_1);
%cashflow_out(ews_lc.cfout_2017_02_09_1);
%cashflow_out(ews_lc.cfout_2017_02_08_1);
%cashflow_out(ews_lc.cfout_2017_02_07_1);
%cashflow_out(ews_lc.cfout_2017_02_06_1);
%cashflow_out(ews_lc.cfout_2017_02_05_1);
%cashflow_out(ews_lc.cfout_2017_02_04_1);
%cashflow_out(ews_lc.cfout_2017_02_03_1);
%cashflow_out(ews_lc.cfout_2017_02_02_1);
%cashflow_out(ews_lc.cfout_2017_02_01_1);
%cashflow_out(ews_lc.cfout_2017_01_31_1);
%cashflow_out(ews_lc.cfout_2017_01_30_1);
%cashflow_out(ews_lc.cfout_2017_01_29_1);



%tong_hop_cau_hoi(ews_lc.DSKH_lc_28022017);









