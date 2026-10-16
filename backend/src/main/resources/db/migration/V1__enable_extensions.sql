-- btree_gist provides GiST operator classes for scalar types, required by the exclusion
-- constraints that prevent overlapping crew/asset assignments (BR-003, BR-005).
-- It is a trusted extension: the database owner can install it without superuser rights.
CREATE EXTENSION IF NOT EXISTS btree_gist;
