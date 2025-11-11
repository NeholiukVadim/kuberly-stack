# README #

```bash
export AWS_PROFILE=psl_dev_stage
terragrunt run plan --all --iam-assume-role "arn:aws:iam::743267407654:role/KuberlyRole-8b4ea525-e94b-4f38-b498-89ce346b568e" --experiment-mode --no-auto-init=false --source-update --filter 'eks' --non-interactive --summary-per-unit --report-format json --report-file report.json
```

```bash
terragrunt run --all plan --queue-include-dir './modules/eks' --queue-strict-include --non-interactive --source-update --iam-assume-role "arn:aws:iam::743267407654:role/KuberlyRole-8b4ea525-e94b-4f38-b498-89ce346b568e"
```
