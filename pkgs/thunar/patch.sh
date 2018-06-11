#!/bin/bash

inform 'Executing exo-csource'
cd "$PKGSRC_DIR"/thunar
exo-csource --strip-comments --strip-content --static --name=thunar_standard_view_ui thunar-standard-view-ui.xml > thunar-standard-view-ui.h
exo-csource --strip-comments --strip-content --static --name=thunar_launcher_ui thunar-launcher-ui.xml > thunar-launcher-ui.h
