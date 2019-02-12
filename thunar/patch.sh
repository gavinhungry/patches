#!/bin/bash

inform 'Executing exo-csource'
cd "$PKGSRC_DIR"/thunar

for COMPONENT in thunar_launcher_ui thunar_renamer_dialog_ui thunar_standard_view_ui thunar_window_ui; do
  exo-csource --strip-comments --strip-content --static --name=$COMPONENT ${COMPONENT//_/-}.xml > ${COMPONENT//_/-}.h
done
