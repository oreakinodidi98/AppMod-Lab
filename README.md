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

Module 03 contains the Azure environment setup, Python and Java deployment
choices, and their shared deployment steps. The remaining flow is
operations (04), Caldova source modernization (05), PetClinic (06), and cleanup
(07).

The [Naming page](appmod-lab/0-prerequisites/prerequisite-0-2-naming.md) describes
the editable owner, environment, and region codes used by the manual Module 03
flow. It adds a random suffix and saves the names in `.envrc`.

## Application source

The workshop starter files are in [`assets/src`](assets/src/),
[`assets/Python_app`](assets/Python_app/), [`assets/Java_app`](assets/Java_app/),
and [`assets/Scenario1App`](assets/Scenario1App/).
Students create their own repository and download the files needed for each
exercise using direct `Invoke-WebRequest` commands after completing the
[repository instructions](appmod-lab/0-prerequisites/prerequisite-0-1-technical.md#create-your-workshop-repository).

Student downloads use the current files on `main`, without hash verification,
and replace existing destination files. Students should download each starter
file only once, review it, and commit it before making changes.

Modules 03 and 05 download only the
starter files they need into the student's repository. Module 06 uses a
separate, facilitator-selected Spring PetClinic checkout; its assessment
screenshots are in [`assets/images`](assets/images/).

The [`AutomaticSetup.ps1`](assets/scripts/AutomaticSetup.ps1),
[`ClassicSetup.ps1`](assets/scripts/ClassicSetup.ps1), and
[`cleanup.ps1`](assets/scripts/cleanup.ps1) are demo references, not student setup
commands. They can create or delete whole environments. The workshop uses module
03 for Azure setup and module 07 for cleanup; student downloads do not include
these scripts.

The optional reference downloader still checks the hashes in
[`lab-files.json`](assets/scripts/lab-files.json). When updating starter files,
keep their manifest hashes and the manifest hash embedded in the downloader
in sync. It is not required by the student instructions.
