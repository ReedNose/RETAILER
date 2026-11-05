// Smart key helpers: batch_id = "{sku}_{unique_string}", e.g. "ML_2414".
// The sku never contains an underscore, so the FIRST "_" is the split point.

String sku_from_batch_id(String batch_id) => batch_id.split("_").first;

String make_batch_id(String sku, String unique_string) => "${sku}_$unique_string";
