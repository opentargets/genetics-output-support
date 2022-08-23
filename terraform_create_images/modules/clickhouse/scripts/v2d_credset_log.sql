create database if not exists ot;
create table if not exists ot.v2d_credset_log(
    study_id String,
    lead_chrom String,
    lead_pos UInt32,
    lead_ref String,
    lead_alt String,
    lead_variant_id String,
    tag_chrom String,
    tag_pos UInt32,
    tag_ref String,
    tag_alt String,
    tag_variant_id String,
    bio_feature Nullable(String),
    is95_credset UInt8,
    is99_credset UInt8,
    logABF Nullable(Float64),
    multisignal_method String,
    phenotype_id Nullable(String),
    gene_id Nullable(String),
    postprob Float64,
    postprob_cumsum Float64,
    tag_beta Float64,
    tag_beta_cond Float64,
    tag_pval Float64,
    tag_pval_cond Float64,
    tag_se Float64,
    tag_se_cond Float64,
    type String
) engine = Log;