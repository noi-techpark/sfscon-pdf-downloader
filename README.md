<!--
SPDX-FileCopyrightText: NOI Techpark <digital@noi.bz.it>

SPDX-License-Identifier: CC0-1.0
-->

# SFSCON Pdf Downloader

[![REUSE Compliance](https://github.com/noi-techpark/sfscon-pdf-downloader/actions/workflows/reuse.yml/badge.svg)](https://github.com/noi-techpark/odh-docs/wiki/REUSE#badges)

Tiny graphical application to download all speakers PDF files for SFSCON.  
Then they are saved in the corresponding directory with the following scheme  
`Day x/Room - Track/Time - Speaker.pdf`  
An real example would be  
`Day 1/Seminar 3 - Developers Track/1520 - Simon Dalvai.pdf`

Note: The title is not used in the file name intentionally, because it causes a lot of problems with special characters etc.

Created with the Godot Engine 4.1.x

## Table of content
- [SFSCON Pdf Downloader](#sfscon-pdf-downloader)
  - [Table of content](#table-of-content)
  - [Prerequisites](#prerequisites)
  - [Configuration](#configuration)
  - [Getting started](#getting-started)
  - [How to](#how-to)
  - [License](#license)
  - [REUSE](#reuse)


## Prerequisites
To develop and build the application, you need the Godot 4.1.x executable you can download from https://godotengine.org/download

## Configuration
To run this application, you need a valid [SFSCON-mapping.csv](SFSCON-mapping.csv) file with the correct mapping for talks to their track and room.
Once you created the mapping, copy it into the app directory in a txt format  
`cp SFSCON-mapping.csv app/SFSCON-mapping.txt`

Note: Godot sees csv files as translations files and does per default convert them in other files etc.
To prevent this behavior, the file can simply be in a txt format.

## Getting started
Open the Godot Engine executable and open the [app/project.godot](app/project.godot) file to open the project.

## How to
Once you started the application, you need to open the talks csv file, you exported from the SFSCON admin page.
Then the application auto-magically creates all the directories and puts the Pdf files in their correct places.
The directories and Pdf files will be created in the same directory, the talk csv file is located.
After the first time, the path is saved, so on next opening, the file dialog already shows the correct directory.

You can read eventual errors or talks without Pdf in the error log. 

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

