> [!IMPORTANT]
> This repository is archived. Open Targets Genetics is now merged into Platform.
> This process has now been taken over by [POS](https://github.com/opentargets/platform-output-support).

# Open Targets: Genetics-output-support overview

Genetics Output Support (POS) provides tools to prepare the Genetics data for public distribution. Distribution is either part of the public facing web portal, or through GCP Bigquery.

### Requirement

- Terraform
- Jq
- Make

### How to run the different steps

Simply run the following command:

```make```

The output shows the possible action to run

```
Usage:
  make
  help             show help message
  disk             Create GCP Disk snapshots for Clickhouse and ElasticSearch.
  bigquerydev      Big Query Dev
  bigqueryprod     Big Query Production
  sync             Sync the pre-data bucket to private ftp and public ftp
  syncgs           Copy data from pre-release to release 
```

Variables are stored in the **config.tfvars**. Typically these are the only variables which need updating, but it may be necessary from time to time to update variables in the individual modules.

The current POS steps are:

```make disk``` generates two GCP disk [images](https://cloud.google.com/sdk/gcloud/reference/compute/images/create): one for Elasticsearch and one for Clickhouse. These can be subsequently mounted as disks to VMs running the necessary database.

```make bigquerydev``` it generates a bigquery dataset in eu-dev

```make bigqueryprod``` it generates a bigquery dataset in production

```make sync``` Synch the data from the Google Storage to EBI FTP (internal use)

```make syncgs``` Synch the data from the google storage pre-release to production (internal use)

## Create disk images

- Running `make disk` will deploy the resources to create the resources for an API/UI release. To see the logs while this process completes run:

```
gcloud --project=open-targets-genetics-dev compute ssh gos-vm-support-vm-9zatib6c \
-- sudo journalctl -n 500 -f -u google-startup-scripts.service 
```

Replacing the name of the VM with the value printed to terminal under `pos_support_vm_name`

# Copyright

Copyright 2018-2021 Open Targets

Bristol Myers Squibb <br>
European Bioinformatics Institute - EMBL-EBI <br>
GSK <br>
Sanofi <br>
Wellcome Sanger Institute <br>

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.

You may obtain a copy of the License at

   <http://www.apache.org/licenses/LICENSE-2.0>

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

<https://github.com/opentargets/platform-output-support.git>
