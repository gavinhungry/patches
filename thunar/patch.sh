for P in ${1}/*.patch; do
  patch -N -r - -p0 < $P;
done

cd abs/thunar/src/Thunar-1.6.5/thunar/
echo exo-csource
exo-csource --strip-comments --strip-content --static --name=thunar_location_buttons_ui thunar-location-buttons-ui.xml > thunar-location-buttons-ui.h
exo-csource --strip-comments --strip-content --static --name=thunar_launcher_ui thunar-launcher-ui.xml > thunar-launcher-ui.h
