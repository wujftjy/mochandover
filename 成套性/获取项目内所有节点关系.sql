/* Formatted on 2018/8/23 13:43:27 (QP5 v5.227.12220.39754) */
WITH t
     AS (SELECT tag.id AS id
           FROM pm_Task_object tag
          WHERE tag.projectId IN
                   (SELECT et.projectid
                      FROM pm_task_object et
                     WHERE et.id = :taskId
                    UNION
                    SELECT eb.projectid
                      FROM pm_task_object eb
                     WHERE eb.subprocessid IN
                              (SELECT a.process_id
                                 FROM engine_activity a
                                WHERE a.activity_id = :taskId))),
     v
     AS (SELECT r.activity_data_relation_id AS rid,
                fac.action_id AS srcId,
                fac.action_name AS srcName,
                ta.activity_id AS targetId,
                ta.activity_name AS targetName
           FROM engine_activity_data_relation r
                LEFT JOIN engine_activity fa
                   ON r.from_activity_id = fa.activity_id
                LEFT JOIN engine_activity_action fac
                   ON fa.activity_id = fac.activity_id
                LEFT JOIN engine_activity ta
                   ON r.to_activity_id = ta.activity_id
          WHERE     r.relationtype = 'DATA'
                AND fa.activity_type = 'TASK_ACTIVITY'
                AND Ta.activity_type <> 'TASK_ACTIVITY'
                AND Ta.activity_type <> 'END_ACTIVITY'
                AND fac.action_id IN (SELECT t.id FROM t)
         UNION
         SELECT r.activity_data_relation_id AS rid,
                fa.activity_id AS srcId,
                fa.activity_name AS srcName,
                tac.action_id AS targetId,
                tac.action_name AS targetName
           FROM engine_activity_data_relation r
                LEFT JOIN engine_activity fa
                   ON r.from_activity_id = fa.activity_id
                LEFT JOIN engine_activity ta
                   ON r.to_activity_id = ta.activity_id
                LEFT JOIN engine_activity_action tac
                   ON ta.activity_id = tac.activity_id
          WHERE     r.relationtype = 'DATA'
                AND fa.activity_type <> 'TASK_ACTIVITY'
                AND Ta.activity_type = 'TASK_ACTIVITY'
                AND tac.action_id IN (SELECT t.id FROM t)
         UNION
         SELECT r.activity_data_relation_id AS rid,
                fac.action_id AS srcId,
                fac.action_name AS srcName,
                tac.action_id AS targetId,
                tac.action_name AS targetName
           FROM engine_activity_data_relation r
                LEFT JOIN engine_activity fa
                   ON r.from_activity_id = fa.activity_id
                LEFT JOIN engine_activity_action fac
                   ON fa.activity_id = fac.activity_id
                LEFT JOIN engine_activity ta
                   ON r.to_activity_id = ta.activity_id
                LEFT JOIN engine_activity_action tac
                   ON ta.activity_id = tac.activity_id
          WHERE     NVL (fac.action_id, '0') <> '0'
                AND NVL (tac.action_id, '0') <> '0'
                AND r.relationtype = 'DATA'
                AND fa.activity_type = 'TASK_ACTIVITY'
                AND Ta.activity_type = 'TASK_ACTIVITY'
                AND tac.action_id IN (SELECT t.id FROM t)
         UNION
         SELECT aso.relationid AS rid,
                aso.srctaskid AS srcId,
                ftc.name AS srcName,
                aso.targettaskid AS targetId,
                ttc.name AS targetName
           FROM pm_task_association aso
                LEFT JOIN pm_task_object ftc ON aso.srctaskid = ftc.id
                LEFT JOIN pm_task_object ttc ON aso.targettaskid = ttc.id
          WHERE aso.targettaskid IN (SELECT t.id FROM t)
         UNION
         SELECT r.activity_data_relation_id AS rid,
                ta.id AS srcId,
                ta.name AS srcName,
                fac.action_id AS targetId,
                fac.action_name AS targetName
           FROM engine_activity_data_relation r
                LEFT JOIN engine_process pb
                   ON R.FROM_ACTIVITY_ID = Pb.start_NODE_ID
                LEFT JOIN engine_activity_action fac
                   ON R.to_ACTIVITY_ID = fac.activity_id
                LEFT JOIN pm_task_object ta
                   ON TA.SUBPROCESSID = pb.process_id
          WHERE     NVL (pb.process_id, '0') <> '0'
                AND r.relationtype = 'DATA'
                AND ta.id IN (SELECT t.id FROM t)),
     AIP
     AS (SELECT evt.srcid id
           FROM (SELECT v.*,
                        (SELECT COUNT (*)
                           FROM v v3
                          WHERE v3.targetid = v.srcid)
                           cn
                   FROM v) evt
         UNION
         SELECT evt.targetid id
           FROM (SELECT v.*,
                        (SELECT COUNT (*)
                           FROM v v3
                          WHERE v3.targetid = v.srcid)
                           cn
                   FROM v) evt),
     PT
     AS (SELECT D.ID
           FROM PM_DATA_OBJECT D
          WHERE D.DEFAULTSET = 1 AND (d.taskId IN (SELECT AIP.ID FROM AIP))),
     TP
     AS (SELECT TA.NAME N1,
                AD.VERSIONNAME V1,
                A.SRCID S1,
                A.Srcrevision SV1,
                AD.TASKID T1,
                TB.NAME N2,
                BD.VERSIONNAME V2,
                A.TARGETID S2,
                A.TARGETREVISION SV2,
                BD.TASKID T2
           FROM pm_association_relation_old a
                LEFT JOIN pm_Data_object_old ad
                   ON a.srcid = ad.id AND a.srcrevision = ad.revision
                LEFT JOIN PM_TASK_OBJECT TA ON AD.TASKID = TA.ID
                LEFT JOIN pm_Data_object_old bd
                   ON a.targetid = bd.id AND a.targetrevision = bd.revision
                LEFT JOIN PM_TASK_OBJECT TB ON BD.TASKID = TB.ID
          WHERE     a.description IN ('1', '3')
                AND a.srcid IN (SELECT ID FROM PT)
                AND a.targetid IN (SELECT ID FROM PT)
                AND (   ad.statusid IN ('published')
                     OR ad.sharestatusid IN ('shared')
                     OR (ad.statusid IN ('confirmed')))),
     king
     AS (SELECT ROWNUM cn, tpv.*
           FROM (SELECT N1 "name",
                        V1 "version",
                        S1 "dataId",
                        SV1 "revision",
                        T1 "taskId"
                   FROM tp
                 UNION
                 SELECT N2,
                        V2,
                        S2,
                        SV2,
                        T2
                   FROM tp) tpv)
                   
                   
      --    select 'CREATE (D'||king.cn||':DBS {ind:'||king.cn||',name:'||king."version"||king."name"||',version:'||king."version"||',dataId:'||king."dataId"||',revision:'||king."revision"||',taskId:'||king."taskId"||'})' from king;         
                   
, keaf as (SELECT (SELECT king.cn
          FROM king
         WHERE king."dataId" = tp.s1 AND king."revision" = tp.sv1)
          s,
       (SELECT king.cn
          FROM king
         WHERE king."dataId" = tp.s2 AND king."revision" = tp.sv2)
          e
  FROM tp )
  
  select 'CREATE (D'||keaf.s||')-[:mapping]->(D'||keaf.e||')' from keaf;