# AppMod-Lab

A facilitator-led workshop for modernizing applications with GitHub Copilot and operating them on Azure Kubernetes Service.

The workshop site uses Jekyll and the Just-the-Docs theme. Start at [`index.md`](index.md) or go directly to the [prerequisites](appmod-lab/0-prerequisites/index.md).

## Preview locally

Install Ruby and Bundler, then run:

```sh
bundle install
bundle exec jekyll serve --livereload
```

Open the local URL printed by Jekyll. The source is compatible with GitHub Pages; configure Pages for this repository before publishing.

## Workshop structure

Each numbered folder under [`appmod-lab/`](appmod-lab/) contains a short `index.md`
overview and separate exercise files. The overview's `has_children` setting and
the exercises' `parent` and `nav_order` settings provide the expandable site navigation.

Site pages use Jekyll `{% link path/to/page.md %}` tags for internal links so they
resolve correctly with pretty URLs and the GitHub Pages project path.

## Application source

The application source is maintained in [AKS_AppMod_Demos](https://github.com/oreakinodidi98/AKS_AppMod_Demos), not in this documentation repository:

* [Java todo application](https://github.com/oreakinodidi98/AKS_AppMod_Demos/tree/main/src)
* [Python Caldova](https://github.com/oreakinodidi98/AKS_AppMod_Demos/tree/main/Python_app)
* [Java Caldova](https://github.com/oreakinodidi98/AKS_AppMod_Demos/tree/main/Java_app)

Follow the [working-copy instructions](appmod-lab/0-prerequisites/prerequisite-0-1-technical.md#create-your-working-copy)
to clone this documentation repository (`LAB_REPO`) and a separate disposable
application fork (`LAB_APP_REPO`). Modernization and application builds use the
application fork; deployment uses the template in this repository.
