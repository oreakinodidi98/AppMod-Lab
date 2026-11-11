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

> [!IMPORTANT]
> Some workshop instructions reference sample application and diagram folders (`src/`, `Python_app/`, `Java_app/`, and `Agentic_SDLC/`) that are not included in this checkout. Add those assets before running the affected exercises.
