# AppMod-Lab

A facilitator-led workshop for modernizing applications with GitHub Copilot and operating them on Azure Kubernetes Service.

The workshop site uses Jekyll and the Just-the-Docs theme. Start at [`index.md`](index.md),
read [About this workshop](about.md), or go directly to the
[prerequisites](appmod-lab/0-prerequisites/index.md).

## Preview locally

Install Ruby and Bundler, then run:

```sh
bundle install
bundle exec jekyll serve --livereload
```

Open <http://127.0.0.1:4000/AppMod-Lab/>. The `/AppMod-Lab` project path is
configured as `baseurl` in `_config.yml`; keep its capitalization when publishing
to GitHub Pages.

## Workshop structure

Each numbered folder under [`appmod-lab/`](appmod-lab/) contains a short `index.md`
overview and separate exercise files. The overview's `has_children` setting and
the exercises' `parent` and `nav_order` settings provide the expandable site navigation.

Site pages use `{{ site.baseurl }}{% link path/to/page.md %}` for internal links.
The link tag resolves the page's pretty URL; the prefix adds the GitHub Pages
project path. Jekyll 3 does not add that prefix to link tags automatically.
Keep `relative_url` on image paths so they use the same project path.

After changing page links, check the generated site, not just whether the source
files exist:

```powershell
bundle exec jekyll build
pwsh -NoProfile -File .\tests\site-links.Tests.ps1
```

The site-link workflow runs these checks on pushes and pull requests. It rejects
links that omit the project path or point to missing generated pages or files.

Module 04 contains the Python and Java deployment choices and their shared
deployment steps. The remaining flow is operations (05), Caldova source
modernization (06), PetClinic (07), and cleanup (08).

The [Naming page](appmod-lab/0-prerequisites/prerequisite-0-2-naming.md) defines
the shared resource naming pattern. The instructions and reference scripts use
[`lab-names.ps1`](assets/scripts/lab-names.ps1) to generate names and tags from
the same values. Keep that helper in the environment download manifest.

## Application source

The workshop starter files are in [`assets/src`](assets/src/),
[`assets/Python_app`](assets/Python_app/), [`assets/Java_app`](assets/Java_app/),
and [`assets/Scenario1App`](assets/Scenario1App/).
Students create their own repository and download the files needed for each
exercise using the [setup instructions](appmod-lab/0-prerequisites/prerequisite-0-1-technical.md#create-your-workshop-repository).

The downloader checks the SHA-256 hashes in [`lab-files.json`](assets/scripts/lab-files.json)
and refuses to overwrite existing files. When updating a starter file, update its
manifest hash, the manifest hash in the downloader, and the downloader hash in the
prerequisites together. Publish those changes before asking students to use them.

Module 06 downloads the original Caldova source with `-Module caldova-source`.
Module 07 uses a separate, facilitator-selected Spring PetClinic checkout; its
assessment screenshots are in [`assets/images`](assets/images/).

The copied [`AutomaticSetup.ps1`](assets/scripts/AutomaticSetup.ps1),
[`ClassicSetup.ps1`](assets/scripts/ClassicSetup.ps1), and
[`cleanup.ps1`](assets/scripts/cleanup.ps1) are demo references, not student setup
commands. They can create or delete whole environments. The workshop uses module
03 for Azure setup and module 08 for cleanup; the downloader does not copy these
scripts into student repositories.
