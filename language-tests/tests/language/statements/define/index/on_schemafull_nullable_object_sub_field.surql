/**
[test]

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
error = "The field 'address.city' does not exist"

[[test.results]]
error = "Cannot set field `address.city` with type `string` as it mismatched with field `address` with type `null | string | { city: string }`"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
error = "Cannot set field `address.city` with type `string` as it mismatched with field `address` with type `null | { city: string } | { town: string }`"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "NONE"

[[test.results]]
value = "[{ address: NULL, id: person:1 }]"

[[test.results]]
value = "[{ address: { city: 'Berlin' }, id: person:2 }]"

[[test.results]]
value = "[person:2]"

[[test.results]]
value = "[NULL]"

*/
-- Issue #7524: on a SCHEMAFULL table, DEFINE INDEX on a sub-field of a
-- nullable object (`null | { ... }`) must work exactly as it already does for
-- `option<{ ... }>` (which desugars to `none | { ... }`), and the sub-field
-- must be declarable with DEFINE FIELD without a type mismatch against the
-- nullable parent.
--
-- A union variant that is `null` is treated like a `none` variant: it carries
-- no sub-fields of its own, so it never blocks the sub-field path. Every other
-- variant must still be object-like, so a union mixing an object with a
-- concrete scalar stays rejected.

-- `null | { city: string }` -- the exact case from the issue.
DEFINE TABLE t_null_first SCHEMAFULL;
DEFINE FIELD address ON t_null_first TYPE null | { city: string } DEFAULT NULL;
DEFINE INDEX person_city ON t_null_first FIELDS address.city;
DEFINE FIELD address.city ON t_null_first TYPE string;

-- The reversed union `{ city: string } | null` behaves the same.
DEFINE TABLE t_null_last SCHEMAFULL;
DEFINE FIELD address ON t_null_last TYPE { city: string } | null DEFAULT NULL;
DEFINE INDEX person_city ON t_null_last FIELDS address.city;
DEFINE FIELD address.city ON t_null_last TYPE string;

-- `option<null | { city: string }>`, i.e. `none | null | { city: string }`.
DEFINE TABLE t_opt_null SCHEMAFULL;
DEFINE FIELD address ON t_opt_null TYPE option<null | { city: string }>;
DEFINE INDEX person_city ON t_opt_null FIELDS address.city;

-- A `null` union over the non-literal `object` kind also resolves.
DEFINE TABLE t_null_object SCHEMAFULL;
DEFINE FIELD address ON t_null_object TYPE null | object DEFAULT NULL;
DEFINE INDEX person_city ON t_null_object FIELDS address.city;

-- Index kind is irrelevant -- UNIQUE over a nullable object sub-field too.
DEFINE TABLE t_unique SCHEMAFULL;
DEFINE FIELD address ON t_unique TYPE null | { city: string } DEFAULT NULL;
DEFINE INDEX person_city ON t_unique FIELDS address.city UNIQUE;

-- Negative: a union mixing an object with a concrete non-object variant does
-- not permit sub-field access and is still rejected, both for the index and
-- for the sub-field definition.
DEFINE TABLE t_mixed SCHEMAFULL;
DEFINE FIELD address ON t_mixed TYPE null | string | { city: string } DEFAULT NULL;
DEFINE INDEX person_city ON t_mixed FIELDS address.city;
DEFINE FIELD address.city ON t_mixed TYPE string;

-- Negative: with two distinct object variants the sub-field must exist in
-- *every* object variant; `city` is absent from `{ town: string }`.
DEFINE TABLE t_two_objects SCHEMAFULL;
DEFINE FIELD address ON t_two_objects TYPE null | { city: string } | { town: string } DEFAULT NULL;
DEFINE FIELD address.city ON t_two_objects TYPE string;

-- Values round-trip and are actually indexed.
DEFINE TABLE person SCHEMAFULL;
DEFINE FIELD address ON person TYPE null | { city: string } DEFAULT NULL;
DEFINE INDEX person_city ON person FIELDS address.city;
CREATE person:1 SET address = NULL;
CREATE person:2 SET address = { city: 'Berlin' };
SELECT VALUE id FROM person WHERE address.city = 'Berlin';
SELECT VALUE address FROM person:1;
