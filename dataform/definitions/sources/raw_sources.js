// Raw layer: external tables created by Terraform over the GCS landing bucket.
// Declaring them lets every model use ref("customers") and builds the lineage graph.

const rawDataset = dataform.projectConfig.vars.raw_dataset;

["customers", "products", "orders", "order_items"].forEach((table) => {
  declare({
    schema: rawDataset,
    name: table,
  });
});
