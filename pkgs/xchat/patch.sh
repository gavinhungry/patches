for P in ${1}/*.patch; do
  patch -N -r - -p0 < $P;
done

XCHAT_DIR=abs/xchat/src/xchat-2.8.8
cp patches/xchat/xchat.png $XCHAT_DIR
cp patches/xchat/empty.png $XCHAT_DIR/src/pixmaps/fileoffer.png
cp patches/xchat/empty.png $XCHAT_DIR/src/pixmaps/highlight.png
cp patches/xchat/empty.png $XCHAT_DIR/src/pixmaps/message.png
