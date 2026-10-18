-- Closed vocabulary for resource categories (ORI-401, LOG-001), mirrored by the ResourceCategory enum.
-- The baseline left the column free text; every category used so far is in the list.

ALTER TABLE resource ADD CONSTRAINT ck_resource_category CHECK (category IN (
    'LIFE_SUPPORT','FOOD','FUEL','SPARE_PART','MEDICAL','SCIENTIFIC','OTHER'));
