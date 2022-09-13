#!/bin/bash

# CURRENTLY, IN ORDER TO BUILD SOME TABLES WE NEED A HIGHMEM MACHINE
set -x
export ES_HOST="${ES_HOST:-localhost}"
export CLICKHOUSE_HOST="${CLICKHOUSE_HOST:-localhost}"
export SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

if [ $# -ne 1 ]; then
  echo "Recreates ot database and loads data."
  echo "Example: $0 gs://genetics-portal-output/190504"
  exit 1
fi
base_path="${1}"
cpu_count=$(nproc --all)
echo "${cpu_count} CPUs available for parallelisation."

gsutil -m cp -r $base_path /tmp/data
echo "Data loading exit status: $?"

load_foreach_parquet() {
  # you need two parameters, the path_prefix to make the wildcard and
  # the table_name name to load into
  local path_prefix=$1
  local table_name=$2
  echo "[Clickhouse] Loading $path_prefix files into table $table_name"
  local q="clickhouse-client -h ${CLICKHOUSE_HOST} --query=\"insert into ${table_name} format Parquet\" "

  # Set max-procs to 0 to allow xargs to max out allowed process count.
  ls "${path_prefix}"/part-0000*.parquet |
    xargs --max-procs=$(expr $cpu_count / 4) -t -I % \
      bash -c "cat % | ${q}"
  echo "[Clickhouse] Done loading $path_prefix files into table $table_name"
}

# Load files into Elasticsearch instance from Google Storage.
#
# Takes threes arguments:
#
# $1 - Path to data in google storage.
# $2 - The Elasticsearch index to add the data to.
# $3 - JSON file specifying index.
#
# Examples
#
#   load_json_for_elastic \
#     gs://open-targets-genetics-data/22.08/json/lut/study-index \
#     study \
#     /path/to/file/index_settings_studies.json \
#
# Returns the exit code of the last command executed in debug mode or 0
#   otherwise.
load_json_for_elastic() {
  local data_path=$1
  local index=$2
  local index_file=$3
  echo "[Elasticsearch] Loading $data_path into $index"
  for f in ${data_path}/part-*.json; do
    cat $f | esbulk -0 -server localhost:9200 -index $index -size 2000 -w $(expr $cpu_count / 2)
  done
}

## Database setup
echo "Initialising database..."
clickhouse-client --query="drop database if exists ot;"

intermediateTables=(
  studies
  studies_overlap
  variants
  v2d
  v2g_scored
  d2v2g_scored
  v2d_coloc
  v2d_credset
  v2d_sa_gwas
  v2d_sa_molecular_trait
  l2g
  manhattan
)
## Create intermediary tables
for t in "${intermediateTables[@]}"; do
  echo "[Clickhouse] Creating intermediary table: ${t}_log"
  clickhouse-client -m -n <"${SCRIPT_DIR}/${t}_log.sql"
done

echo "[Elasticsearch] Create indexes"
for idx in studies genes variants; do
  local es_uri="${ES_HOST}:9200"
  curl -XDELETE $es_uri/$idx &>/dev/null
  echo "[Elasticsearch] Create index $es_uri/$idx with settings file $SCRIPT_DIR/index_settings_$idx.json"
  curl -XPUT -H 'Content-Type: application/json' --data @$SCRIPT_DIR/index_settings_$idx.json $es_uri/$idx
done

## Load data
{
  load_foreach_parquet "${base_path}/lut/study-index" "ot.studies_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/studies.sql"
  echo "[Clickhouse] Done loading final studies from log table."
} &
{
  load_foreach_parquet "${base_path}/lut/overlap-index" "ot.studies_overlap_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/studies_overlap.sql"
  echo "[Clickhouse] Done loading final studies_overlap from log table."
} &
{
  load_foreach_parquet "${base_path}/lut/variant-index" "ot.variants_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/variants.sql"
  echo "[Clickhouse] Done loading final variant from log table."
} &
{
  load_foreach_parquet "${base_path}/d2v2g_scored" "ot.d2v2g_scored_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/d2v2g_scored.sql"
  echo "[Clickhouse] Done loading final d2v2g_scored from log table."
} &
{
  load_foreach_parquet "${base_path}/v2d" "ot.v2d_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/v2d.sql"
  echo "[Clickhouse] Done loading final v2d from log table."
} &
{
  load_foreach_parquet "${base_path}/v2g_scored" "ot.v2g_scored_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/v2g_scored.sql"
  echo "[Clickhouse] Done loading final v2g_scored from log table."
  echo "Create v2g structure"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/v2g_structure.sql"
} &
{
  load_foreach_parquet "${base_path}/v2d_coloc" "ot.v2d_coloc_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/v2d_coloc.sql"
  echo "[Clickhouse] Done loading final v2d_coloc from log table."
} &
{
  load_foreach_parquet "${base_path}/v2d_credset" "ot.v2d_credset_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/v2d_credset.sql"
  echo "[Clickhouse] Done loading final v2d_credset from log table."
} &
{
  load_foreach_parquet "${base_path}/sa/gwas" "ot.v2d_sa_gwas_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/v2d_sa_gwas.sql"
  echo "[Clickhouse] Done loading final v2d_sa_gwas from log table."
} &
{
  load_foreach_parquet "${base_path}/sa/molecular_trait" "ot.v2d_sa_molecular_trait_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/v2d_sa_molecular_trait.sql"
  echo "[Clickhouse] Done loading final v2d_sa_molecular_trait from log table."
} &
{
  load_foreach_parquet "${base_path}/l2g" "ot.l2g_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/l2g.sql"
  echo "[Clickhouse] Done loading final l2g from log table."
} &
{
  load_foreach_parquet "${base_path}/manhattan" "ot.manhattan_log"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/manhattan.sql"
  echo "[Clickhouse] Done loading final manhattan from log table."
} &
{
  echo "Load gene index"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n <"${SCRIPT_DIR}/genes.sql"
  load_foreach_parquet "${base_path}/lut/genes-index" "ot.genes"
} &
{
  echo "[Elasticsearch] load studies data"
  load_json_for_elastic \
    "$base_path/search/study" \
    studies \
    "${SCRIPT_DIR}/index_settings_studies.json"

} &
{
  echo "[Elasticsearch] load genes data"
  load_json_for_elastic \
    "$base_path/search/gene" \
    genes \
    "${SCRIPT_DIR}/index_settings_genes.json"
} &
{
  echo "[Elasticsearch] load genes data"
  load_json_for_elastic \
    "$base_path/search/variant" \
    variants \
    "${SCRIPT_DIR}/index_settings_variants.json"
} &
wait

## Drop intermediate tables
for t in "${intermediateTables[@]}"; do
  table="${t}_log"
  echo "Deleting intermediate table: ${table}"
  clickhouse-client -h "${CLICKHOUSE_HOST}" -m -n -q " drop table ot.${table}"
done
