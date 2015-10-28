ARCH_DIR=$1
PKGSRC_DIR=$2

inform 'Executing exo-csource'
cd ${PKGSRC_DIR}/thunar
exo-csource --strip-comments --strip-content --static --name=thunar_location_buttons_ui thunar-location-buttons-ui.xml > thunar-location-buttons-ui.h
exo-csource --strip-comments --strip-content --static --name=thunar_launcher_ui thunar-launcher-ui.xml > thunar-launcher-ui.h

cd ${ARCH_DIR}/abs/thunar
