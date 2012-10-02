for P in ${1}/*.patch; do
  patch -N -r - -p0 < $P;
done

cd abs/thunar/src/Thunar-1.4.0/thunar/
echo exo-csource thunar_location_buttons_ui
exo-csource --strip-comments --strip-content --static --name=thunar_location_buttons_ui thunar-location-buttons-ui.xml > thunar-location-buttons-ui.h
