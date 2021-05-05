# org-diagrams
`org-diagrams` allows you to insert diagrams into your org files with minimal hassle. You can create a diagram automatically in some format, edit it and save it. `org-diagrams` handles exporting it to an image and inserting the link to it in your file. Most of the parameters are fairly customizable, with more to come

## Usage
The package provides two main functions to work with diagrams -
1. `org-diagrams-insert-at-point-and-edit` creates a new diagram, naming it using the symbol at point. It replaces the symbol with a link to the (eventually) exported image, and opens the diagram with the configured diagram editor
2. `org-diagrams-edit-at-point` edits the diagram associates with the link at point
In both cases, editing and saving the diagram automatically re-exports the image, keeping the diagram linked in the org file up-to-date

## Configuration
There are many customizable options, exposed through (documented) variables. Use `M-x describe-variable <CR> org-diagrams` to see all of them. Some of the important ones are -
* `org-diagrams-source-dir` - The directory to store diagrams (in their original format)
* `org-diagrams-dest-dir` - The directory to export diagrams as images to
* `org-diagrams-editor` - The application used to open and edit diagrams
* `org-diagrams-diagram-template` - Path to a template, which is copied into every new diagram (if provided)

## Dependencies
Uses [diagon-ally](https://github.com/anihm136/diagon-ally) as a file watcher and exporter. Install it as described in the README, everything else is managed by `org-diagrams`
