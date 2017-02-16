--
-- Copyright (c) 2017 SUSE LLC
--
-- This software is licensed to you under the GNU General Public License,
-- version 2 (GPLv2). There is NO WARRANTY for this software, express or
-- implied, including the implied warranties of MERCHANTABILITY or FITNESS
-- FOR A PARTICULAR PURPOSE. You should have received a copy of GPLv2
-- along with this software; if not, see
-- http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.
--
--

CREATE OR REPLACE PROCEDURE
queue_image(image_id_in IN NUMBER, immediate_in IN NUMBER := 1)
IS
    org_id_tmp NUMBER;
BEGIN
    IF immediate_in > 0
    THEN
          update_image_needed_cache(image_id_in);
    ELSE
          SELECT org_id INTO org_id_tmp FROM suseImageInfo WHERE id = image_id_in;

          INSERT
            INTO rhnTaskQueue
                 (org_id, task_name, task_data)
          SELECT org_id_tmp,
                 'update_image_errata_cache',
                 image_id_in
          FROM DUAL
          WHERE NOT EXISTS
            (SELECT 1 FROM rhnTaskQueue
               WHERE org_id = org_id_tmp
               AND task_name = 'update_image_errata_cache'
               AND task_data = image_id_in
            );
    END IF;
END queue_image;
/
SHOW ERRORS
