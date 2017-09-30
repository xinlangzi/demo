module Sqls
  class Template

    def self.run(sql)
      ApplicationRecord.connection.select_all(sql)
    end

    TRUCKER_MILES_BY_DATE =<<EOF
SELECT truckers.id AS id, truckers.name AS name, truckers.phone_mobile AS phone, IFNULL(SUM(oc.complete_mileage), 0) AS miles, SUM(vacations.weight_factor) AS weight_factor, COUNT(DISTINCT oc.container_id) AS containers
FROM companies AS truckers
LEFT OUTER JOIN (
 SELECT operations.complete_mileage, operations.trucker_id, operations.container_id
 FROM operations
 WHERE operations.actual_appt = '%s'
) AS oc ON oc.trucker_id = truckers.id
LEFT OUTER JOIN vacations ON truckers.id = vacations.user_id AND '%s' BETWEEN DATE(vacations.vstart) AND IFNULL(DATE(vacations.vend), DATE(vacations.vstart))
WHERE (truckers.deleted_at IS NULL OR truckers.deleted_at >= '%s') AND
 (truckers.termination_date IS NULL OR truckers.termination_date >= '%s') AND
 truckers.hire_date <= '%s' AND truckers.hub_id = %s
GROUP BY truckers.id
ORDER BY truckers.name ASC;
EOF

  TRUCKER_VACATION_STATS =<<EOF
SELECT dates.date, truckers.id, vacations.weight_factor
FROM
(
  SELECT * FROM (SELECT ADDDATE('#{Date.today.beginning_of_year}', t2*100 + t1*10 + t0) date FROM (SELECT 0 t0 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t0,  (SELECT 0 t1 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t1, (SELECT 0 t2 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t2) v WHERE date BETWEEN '%{start}' AND '%{end}'
) AS dates
LEFT OUTER JOIN companies AS truckers ON truckers.hire_date <= dates.date AND truckers.type = 'Trucker'
AND (truckers.deleted_at IS NULL OR truckers.deleted_at >= dates.date)
AND (truckers.termination_date IS NULL OR truckers.termination_date >= dates.date)
AND truckers.hub_id = %{hub_id}
LEFT OUTER JOIN vacations ON vacations.user_id = truckers.id AND dates.date BETWEEN vacations.vstart AND IFNULL(vacations.vend, vacations.vstart)
WHERE dates.date IS NOT NULL
ORDER BY dates.date ASC
EOF

  ASSIGNED_MILES_STATS =<<EOF
SELECT dates.date, operations.container_id, SUM(operations.complete_mileage) AS miles
FROM
(
  SELECT * FROM (SELECT ADDDATE('#{Date.today.beginning_of_year}', t2*100 + t1*10 + t0) date FROM (SELECT 0 t0 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t0,  (SELECT 0 t1 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t1, (SELECT 0 t2 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t2) v WHERE date BETWEEN '%{start}' AND '%{end}'
) AS dates
INNER JOIN operations ON operations.actual_appt = dates.date AND operations.trucker_id IS NOT NULL
INNER JOIN containers ON containers.id = operations.container_id AND containers.confirmed = true AND containers.hub_id = %{hub_id}
GROUP BY dates.date, operations.container_id, operations.trucker_id
ORDER BY dates.date ASC
EOF

  UNASSIGNED_MILES_STATS =<<EOF
SELECT dates.date, operations.container_id, SUM(operations.complete_mileage) AS miles
FROM
(
  SELECT * FROM (SELECT ADDDATE('#{Date.today.beginning_of_year}', t2*100 + t1*10 + t0) date FROM (SELECT 0 t0 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t0,  (SELECT 0 t1 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t1, (SELECT 0 t2 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t2) v WHERE date BETWEEN '%{start}' AND '%{end}'
) AS dates
INNER JOIN operations ON operations.actual_appt = dates.date AND operations.trucker_id IS NULL
INNER JOIN containers ON containers.id = operations.container_id AND containers.confirmed = true AND containers.hub_id = %{hub_id}
GROUP BY dates.date, operations.container_id
ORDER BY dates.date ASC
EOF

  DROPPED_WITHOUT_APPT =<<EOF
SELECT dates.date, operations.container_id, SUM(operations.complete_mileage) AS miles
FROM
(
  SELECT * FROM (SELECT ADDDATE('#{Date.today.beginning_of_year}', t2*100 + t1*10 + t0) date FROM (SELECT 0 t0 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t0,  (SELECT 0 t1 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t1, (SELECT 0 t2 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t2) v WHERE date BETWEEN '%{start}' AND '%{end}'
) AS dates
INNER JOIN operations ON operations.appt IS NULL AND DATE(operations.operated_at) = dates.date
INNER JOIN operation_types ON operations.operation_type_id = operation_types.id AND operation_types.otype = 'Drop'
INNER JOIN containers ON containers.id = operations.container_id AND containers.confirmed = true AND containers.hub_id = %{hub_id}
GROUP BY dates.date, operations.container_id
ORDER BY dates.date ASC
EOF

  PREALERT_WITH_ETA =<<EOF
SELECT dates.date, operations.container_id, SUM(operations.complete_mileage) AS miles
FROM
(
  SELECT * FROM (SELECT ADDDATE('#{Date.today.beginning_of_year}', t2*100 + t1*10 + t0) date FROM (SELECT 0 t0 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t0,  (SELECT 0 t1 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t1, (SELECT 0 t2 union SELECT 1 union SELECT 2 union SELECT 3 union SELECT 4 union SELECT 5 union SELECT 6 union SELECT 7 union SELECT 8 union SELECT 9) t2) v WHERE date BETWEEN '%{start}' AND '%{end}'
) AS dates
INNER JOIN containers ON (containers.confirmed = false AND containers.pending_receivable = false AND containers.hub_id = %{hub_id}) AND ((containers.terminal_eta = dates.date AND containers.type = 'ImportContainer') OR (containers.rail_cutoff_date = dates.date AND containers.type = 'ExportContainer'))
INNER JOIN operations ON containers.id = operations.container_id
GROUP BY dates.date, containers.id
ORDER BY dates.date ASC
EOF

  end
end