Intel GETi Flutter UI Widgets.

This Flutter package contains useful widgets that works along with Intel GETi.

## Features

| Features                                      | Supported?         |
| -------                                       | :--------------:   |
| Grid of thumbnail images with multi-select    | :heavy_check_mark: |
| Object Detection Annotation Widget            | :heavy_check_mark: |
| Classification Annotation Widget              | :heavy_check_mark: |
| Instance Segmentation Widget                  | :grey_exclamation: |


## Getting started
* You should have access to an Intel GETi server to try out the APIs.
* You can still utilize the widget by mocking API responses.
* Add the following lines of code to `pubspec.yaml` to add the package.
```
...

dependencies:
    intel_geti_ui:
        git:
            url: https://github.com/kukim98/geti_flutter_ui.git
            ref: main

...
```
* Save the changes and run `flutter pub get` to download the package.


## Usage
* Please refer to `example` code for a simple demo.


## Additional information
* This package is dependent on [geti_dart_api](https://github.com/kukim98/geti_dart_api), but the widgets only utilize the data structure of Intel GETi.
