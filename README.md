# Test Report Merge

Merge test submissions from one or more devices with `checkbox-cli` and generate a single HTML test report.

## Requirements

- Bash
- `checkbox-cli` installed and available on `PATH`, with support for `merge-submissions` and `merge-reports`

## Directory structure

Place `merge-test-reports.sh` in the test report root directory. The script treats each non-hidden immediate subdirectory as a device directory and reads `*.xz` files from its immediate subdirectories. For example:

```text
testreport/
├── merge-test-reports.sh
├── Device-A/
│   ├── Automatic/
│   │   └── submission.tar.xz
│   ├── Stress/
│   │   └── submission.tar.xz
│   └── Re-run/
│       └── submission.tar.xz
└── Device-B/
    └── checkbox-ng/
        └── submission.tar.xz
```

There may be one or more device directories. `Automatic`, `Stress`, `checkbox-ng`, and `Re-run` are example subdirectory names; each device directory must contain at least one input file matching `*/*.xz`. Do not place unrelated non-hidden subdirectories in the root directory.

## Usage

```bash
cd ~/testreport
bash ./merge-test-reports.sh
```

The script prompts for:

1. `Model name`
2. `Code name`
3. `Milestone`
4. `Image version`

Each value must be non-empty, must not consist only of whitespace, and cannot contain `/`. For example, entering `ThinkPad-L14`, `Blanc3`, `Full-RC1`, and `20261106-1175` produces:

```text
ThinkPad-L14_Blanc3_Full-RC1_20261106-1175_test-report.html
```

## Output and notes

- Submissions for each device are merged into `<device-directory-name>.tar.xz` inside that device directory. The merged submission title is the device directory name.
- The script then merges these archives into `<Model name>_<Code name>_<Milestone>_<Image version>_test-report.html` in the test report root directory.
- If an output archive or report already exists, the script lists the existing files and asks for confirmation before overwriting them. Enter `y` or `Y` to continue; any other input cancels the operation.
- The script displays progress messages in English. If a step fails, it stops; files already generated are not rolled back.
- `checkbox-cli` warns that merged submission archives must not be uploaded to the Certification website.
