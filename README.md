<!--
SPDX-FileCopyrightText: NOI Techpark <digital@noi.bz.it>

SPDX-License-Identifier: CC0-1.0
-->

# SFSCON Pdf Downloader
Tiny graphical application to download all speakers PDF files for SFSCON.  
Then they are saved in the corresponding directory with the following scheme:  
`Day x/Room - Track/Time - Speaker - Title.pdf`
An real example would be:  
`Day 1/Seminar 3 - Developers Track/1520 - Simon Dalvai - F-Droid - The place for your FOSS Apps.pdf`

Created with the Godot Engine 4.1.x.

## Table of content
- [SFSCON Pdf Downloader](#sfscon-pdf-downloader)
  - [Table of content](#table-of-content)
  - [Prerequisites](#prerequisites)
  - [Configuration](#configuration)
  - [Getting started](#getting-started)
  - [License](#license)
  - [REUSE](#reuse)


## Prerequisites

To develop and build the application, you need the Godot 4.1.x executable you can download from https://godotengine.org/download

## Configuration

To run this application, you need a valid '/SFSCON-mapping.csv' file with the correct mapping for talks to their track and room.
So the application is able to save the files in the correct folders.

## Getting started
Open the Godot Engine executable and open the `/app/project.godot` file to open the project.

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

