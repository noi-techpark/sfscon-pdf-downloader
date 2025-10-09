<!--
SPDX-FileCopyrightText: NOI Techpark <digital@noi.bz.it>

SPDX-License-Identifier: CC0-1.0
-->

# SFSCON Pdf Downloader

[![REUSE Compliance](https://github.com/noi-techpark/sfscon-pdf-downloader/actions/workflows/reuse.yml/badge.svg)](https://github.com/noi-techpark/odh-docs/wiki/REUSE#badges)

Tiny GUI application to download all speakers PDF files for SFSCON.  
Then they are saved in the corresponding directory with the following scheme  
`Day x/Room - Track/Time - Speaker.pdf`  
An real example would be  
`Day 1/Seminar 3 - Developers Track/1520 - Simon Dalvai.pdf`

Note: The title is not used in the file name intentionally, because it causes a lot of problems with special characters etc.

Created with the Godot Engine 4.3  
Get it here https://github.com/godotengine/godot-builds/releases/tag/4.3-stable

## Table of content
- [SFSCON Pdf Downloader](#sfscon-pdf-downloader)
  - [Table of content](#table-of-content)
  - [How to use](#how-to-use)
  - [Prerequisites](#prerequisites)
  - [Getting started](#getting-started)
  - [License](#license)
  - [REUSE](#reuse)


## How to use
Once you started the application, you need to open the talks csv file, you exported from the SFSCON admin page, under the talks section.
Then the application auto-magically creates all the directories and puts the Pdf files in their correct places.
The directories and Pdf files will be created in the same directory, the talk csv file is located.
After the first time, the path is saved, so on next opening, the file dialog already shows the correct directory.

You can read eventual errors or talks without Pdf in the error log. 

## Prerequisites
To develop and build the application, you need the Godot 4.2.2 executable you can download from https://godotengine.org/download.  
If a new version is available, Godot upgrades the project automatically to the latest version. But some functionality might break.

## Getting started
Open the Godot Engine executable and open the [app/project.godot](app/project.godot) file to open the project.

## License
The code in this project is licensed under the GNU AFFERO GENERAL PUBLIC LICENSE Version 3 license. See the [LICENSE.md](LICENSE.md) file for more information.

## REUSE
This project is [REUSE](https://reuse.software) compliant, more information about the usage of REUSE in NOI Techpark repositories can be found [here](https://github.com/noi-techpark/odh-docs/wiki/Guidelines-for-developers-and-licenses#guidelines-for-contributors-and-new-developers).

Since the CI for this project checks for REUSE compliance you might find it useful to use a pre-commit hook checking for REUSE compliance locally. The [pre-commit-config](.pre-commit-config.yaml) file in the repository root is already configured to check for REUSE compliance with help of the [pre-commit](https://pre-commit.com) tool.

Install the tool by running:
```bash
pip install pre-commit
```
Then install the pre-commit hook via the config file by running:
```bash
pre-commit install
```

