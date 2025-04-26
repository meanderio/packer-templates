# VM Template for Hadoop Nodes via Packer

### Project Structure

```bash
tree
.
├── config
│   ├── files
│   │   └── 99-pve.cfg
│   ├── http
│   │   ├── meta-data
│   │   └── user-data
│   └── ubuntu-noble-hadoop.pkr.hcl
├── credentials.pkr.hcl.template
└── README
```

### Punch List

1. cp credentials.pkr.hcl.template to credentials.pkr.hcl
2. update variables inside credentials.pkr.hcl
3. update user-data with username and encoded password
4. update ubuntu-noble-hadoop-pkr.hcl with any edits
5. validate and build the image template

### Validate and Build

```bash
# run these commands from inside the config folder
packer validate -var-file='../credentials.pkr.hcl' ubuntu-noble-hadoop.pkr.hcl
packer build -var-file='../credentials.pkr.hcl' ubuntu-noble-hadoop.pkr.hcl
```
